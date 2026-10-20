#!/usr/bin/env python3
"""Smart launcher search: applications + inline calculator.

Usage: get_search.py '<query>'
Output: JSON array of results (kind: app | calc).

The launcher is an application launcher, so normal searches only return
installed applications. Calculator results are still available for arithmetic
queries. Desktop-file icons are resolved to absolute image paths and cached so
the shell can render the real icon instead of a generic fallback or a letter.
"""
import configparser
import glob
import json
import math
import os
import re
import shutil
import subprocess
import sys
import time

HOME = os.path.expanduser("~")
QUERY = sys.argv[1] if len(sys.argv) > 1 else ""
Q = QUERY.strip().lower()

# ── Apps ─────────────────────────────────────────────────────────────
APP_DIRS = [
    "/usr/share/applications",
    os.path.join(HOME, ".local/share/applications"),
    "/var/lib/flatpak/exports/share/applications",
    os.path.join(HOME, ".local/share/flatpak/exports/share/applications"),
]

# ── Icons ────────────────────────────────────────────────────────────
ICON_ROOTS = [
    "/usr/share/icons",
    "/usr/local/share/icons",
    os.path.join(HOME, ".local/share/icons"),
    os.path.join(HOME, ".icons"),
    "/var/lib/flatpak/exports/share/icons",
    os.path.join(HOME, ".local/share/flatpak/exports/share/icons"),
    "/usr/share/pixmaps",
]
ICON_EXTENSIONS = {".png", ".svg", ".xpm", ".jpg", ".jpeg", ".webp"}
ICON_CACHE_DIR = os.path.join(HOME, ".cache", "zenshell")
ICON_CACHE_FILE = os.path.join(ICON_CACHE_DIR, "app-icons.json")
ICON_CACHE_VERSION = 2
ICON_CACHE_MAX_AGE = 7 * 24 * 60 * 60


def truthy(value):
    return str(value or "").strip().lower() in {"1", "true", "yes"}


def icon_theme_name():
    """Return the icon theme used by the desktop, if it can be read."""
    try:
        out = subprocess.check_output(
            ["gsettings", "get", "org.gnome.desktop.interface", "icon-theme"],
            text=True,
            stderr=subprocess.DEVNULL,
            timeout=1,
        )
        theme = out.strip().strip("'\"")
        return theme or "hicolor"
    except Exception:
        return "hicolor"


def icon_size(path):
    """Return an icon's nominal size so tiny theme assets lose to crisp ones."""
    p = path.replace(os.sep, "/")
    if "/symbolic/" in p:
        return 0
    if "/scalable/" in p:
        return 1024
    for size in (512, 256, 128, 96, 64, 48, 32, 24, 22, 16):
        if f"/{size}x{size}/" in p:
            return size
    if "/pixmaps/" in p:
        return 48
    return 0


def icon_score(path, theme):
    """Rank candidates already known to come from the preferred theme."""
    p = path.replace(os.sep, "/")
    score = 0

    if f"/icons/{theme}/" in p:
        score += 320
    elif "/icons/hicolor/" in p:
        score += 300
    elif "/icons/Papirus-Dark/" in p:
        score += 260
    elif "/icons/Papirus/" in p:
        score += 240
    elif "/icons/breeze-dark/" in p:
        score += 220
    elif "/icons/breeze/" in p:
        score += 200
    elif "/icons/Adwaita/" in p:
        score += 190
    elif "/icons/" in p:
        score += 120
    elif "/pixmaps/" in p:
        score += 50

    if "/scalable/" in p:
        score += 500
    if "/apps/" in p or "/categories/" in p:
        score += 80

    score += min(icon_size(path), 256)

    if p.endswith(".svg"):
        score += 60
    elif p.endswith(".png"):
        score += 30
    return score


def pick_icon(candidates, theme):
    """Choose a recognisable theme icon, not a tiny generic fallback."""
    if not candidates:
        return ""

    def crisp(path):
        return icon_size(path) >= 48

    # Papirus/Wayland themes often ship a crisp 48px app icon while hicolor
    # only has a tiny or overly generic file. Use the active theme first.
    themed = [
        path for path in candidates
        if f"/icons/{theme}/" in path.replace(os.sep, "/") and crisp(path)
    ]
    if themed:
        return max(themed, key=lambda path: icon_score(path, theme))

    hicolor = [
        path for path in candidates
        if "/icons/hicolor/" in path.replace(os.sep, "/") and crisp(path)
    ]
    if hicolor:
        return max(hicolor, key=lambda path: icon_score(path, theme))

    other = [path for path in candidates if crisp(path)]
    if other:
        return max(other, key=lambda path: icon_score(path, theme))

    return max(
        candidates,
        key=lambda path: (icon_size(path), icon_score(path, theme)),
    )


def iter_icon_files(root, theme):
    """Walk icon folders once, following theme symlinks without looping."""
    seen_dirs = set()
    stack = [root]
    while stack:
        dirpath = stack.pop()
        real_dir = os.path.realpath(dirpath)
        if real_dir in seen_dirs:
            continue
        seen_dirs.add(real_dir)

        try:
            with os.scandir(dirpath) as scan:
                entries = list(scan)
        except OSError:
            continue

        child_dirs = []
        for entry in entries:
            try:
                if entry.is_dir(follow_symlinks=True):
                    child_dirs.append(entry.path)
                elif entry.is_file(follow_symlinks=True):
                    yield entry.path
            except OSError:
                continue

        # Visit the active theme before the base themes, and hicolor next.
        # Many Papirus-Dark size folders are symlinks into Papirus; resolving
        # through the active-theme path keeps those assets theme-identifiable.
        child_dirs.sort(
            key=lambda path: (
                0 if os.path.basename(path) == theme
                else 1 if os.path.basename(path) == "hicolor"
                else 2,
                path,
            )
        )
        stack.extend(reversed(child_dirs))


def build_icon_map(names):
    """Index the icon themes once, then pick the best file for each name."""
    names = {name for name in names if name}
    if not names:
        return {}, icon_theme_name()

    theme = icon_theme_name()
    found = {}

    for root in ICON_ROOTS:
        if not os.path.isdir(root):
            continue
        for path in iter_icon_files(root, theme):
            filename = os.path.basename(path)
            stem, ext = os.path.splitext(filename)
            if ext.lower() not in ICON_EXTENSIONS:
                continue
            for key in (stem, filename):
                if key in names:
                    found.setdefault(key, []).append(path)

    resolved = {}
    for name in names:
        resolved[name] = pick_icon(found.get(name, []), theme)
    return resolved, theme


def load_icon_cache(names):
    try:
        with open(ICON_CACHE_FILE, encoding="utf-8") as cache:
            data = json.load(cache)
        if data.get("version") != ICON_CACHE_VERSION:
            return None
        if time.time() - float(data.get("built", 0)) > ICON_CACHE_MAX_AGE:
            return None
        icons = data.get("icons")
        if not isinstance(icons, dict) or not all(name in icons for name in names):
            return None
        for name in names:
            path = icons.get(name)
            if path and not os.path.isfile(path):
                return None
        return icons
    except Exception:
        return None


def save_icon_cache(icons, theme):
    try:
        os.makedirs(ICON_CACHE_DIR, exist_ok=True)
        temp = ICON_CACHE_FILE + ".tmp"
        with open(temp, "w", encoding="utf-8") as cache:
            json.dump(
                {
                    "version": ICON_CACHE_VERSION,
                    "built": int(time.time()),
                    "theme": theme,
                    "icons": icons,
                },
                cache,
                ensure_ascii=False,
            )
        os.replace(temp, ICON_CACHE_FILE)
    except Exception:
        pass


def resolve_icons(apps):
    """Turn icon names into absolute files so Image never guesses a generic icon."""
    names = set()
    for app in apps:
        icon = (app.get("icon") or "").strip()
        if icon and not os.path.isabs(os.path.expanduser(icon)):
            names.add(icon)

    icon_map = {}
    if names:
        icon_map = load_icon_cache(names)
        if icon_map is None:
            icon_map, theme = build_icon_map(names)
            save_icon_cache(icon_map, theme)

    for app in apps:
        icon = (app.get("icon") or "").strip()
        if not icon:
            app["icon"] = ""
            continue

        expanded = os.path.expanduser(icon)
        if os.path.isabs(expanded):
            app["icon"] = expanded if os.path.isfile(expanded) else ""
            continue

        path = icon_map.get(icon, "")
        app["icon"] = path if path and os.path.isfile(path) else ""


def load_apps():
    apps = []
    seen_files = set()
    seen_execs = set()

    for directory in APP_DIRS:
        if not os.path.isdir(directory):
            continue
        for desktop_file in glob.glob(
            os.path.join(directory, "**/*.desktop"), recursive=True
        ):
            if desktop_file in seen_files:
                continue
            seen_files.add(desktop_file)

            try:
                cfg = configparser.ConfigParser(interpolation=None)
                cfg.read(desktop_file, encoding="utf-8")
                entry = cfg["Desktop Entry"]

                if entry.get("Type", "Application").strip() != "Application":
                    continue
                if truthy(entry.get("NoDisplay")) or truthy(entry.get("Hidden")):
                    continue

                try_exec = entry.get("TryExec", "").strip()
                if try_exec and not shutil.which(try_exec):
                    continue

                name = entry.get("Name", "").strip()
                exec_cmd = entry.get("Exec", "").strip()
                if not name or not exec_cmd:
                    continue

                # Keep one row per command. Some packages ship alternate desktop
                # entries (e.g. a Wayland variant) that are still the same app.
                clean_exec = re.sub(r"%[fFuUdDnNickvm]", "", exec_cmd).strip()
                if clean_exec in seen_execs:
                    continue
                seen_execs.add(clean_exec)

                # A readable second line: GenericName is short ("Web Browser"),
                # Comment is longer but human. Never show the exec path — that is
                # what the launcher used to do, and "/usr/bin/nvidia-settings"
                # under every row made the list look like a debug tool.
                generic = entry.get("GenericName", "").strip()
                comment = " ".join(entry.get("Comment", "").split()).rstrip(".")
                sub = generic or comment
                if len(sub) > 72:
                    sub = sub[:69].rstrip() + "…"

                apps.append({
                    "kind": "app",
                    "name": name,
                    "exec": exec_cmd.split("%")[0].strip(),
                    "icon": entry.get("Icon", "").strip(),
                    "sub": sub,
                })
            except Exception:
                continue

    resolve_icons(apps)
    apps.sort(key=lambda app: app["name"].lower())
    return apps


# ── Calculator ────────────────────────────────────────────────────────
TOKEN_RE = re.compile(r"^[\d\s+\-*/()^%.]+$")


def solve():
    expr = QUERY.strip()
    expr = expr[1:].strip() if expr.startswith("=") else expr
    if not expr or len(expr) > 80 or not TOKEN_RE.match(expr):
        return None
    if not re.search(r"[\d]", expr):
        return None
    py_expr = expr.replace("^", "**")
    try:
        result = eval(
            py_expr.replace("÷", "/").replace("×", "*"),
            {"__builtins__": {}},
            {},
        )
    except Exception:
        return None
    if isinstance(result, complex) or not isinstance(result, (int, float)):
        return None
    value = result
    if isinstance(value, float):
        if math.isnan(value) or math.isinf(value):
            return None
        value = round(value, 6)
        value = int(value) if value.is_integer() else value
    return {
        "kind": "calc",
        "name": f"{expr} = {value}",
        "result": str(value),
        "icon": "",
        "sub": "Enter copies result to clipboard",
    }


# ── Assemble ──────────────────────────────────────────────────────────
def main():
    apps = load_apps()
    if not Q:
        results = apps[:60]
    else:
        def rank(app):
            name = app["name"].lower()
            hay = (
                app.get("sub", "") + " " + name + " " + app.get("exec", "")
            ).lower()
            start = name.startswith(Q)
            prefix = hay.startswith(Q)
            return (0 if start else (1 if prefix else 2), name)

        app_hits = [
            app for app in apps
            if Q in app["name"].lower()
            or Q in app.get("sub", "").lower()
            or Q in app.get("exec", "").lower()
        ]
        app_hits.sort(key=rank)
        results = app_hits[:40]
        calc = solve()
        if calc:
            results.append(calc)

    sys.stdout.write(json.dumps(results[:60], ensure_ascii=False) + "\n")


if __name__ == "__main__":
    main()
