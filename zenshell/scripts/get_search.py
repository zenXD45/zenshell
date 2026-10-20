#!/usr/bin/env python3
"""Smart launcher search: apps + files + inline calculator.

Usage: get_search.py '<query>'
Output: JSON array of results (kind: app | file | calc).
"""
import glob
import json
import math
import os
import re
import shutil
import subprocess
import sys

HOME = os.path.expanduser("~")
QUERY = sys.argv[1] if len(sys.argv) > 1 else ""
Q = QUERY.strip().lower()

# ── Apps ─────────────────────────────────────────────────────────────
APP_DIRS = ["/usr/share/applications", os.path.join(HOME, ".local/share/applications")]


def load_apps():
    apps = []
    seen = set()
    for d in APP_DIRS:
        if not os.path.isdir(d):
            continue
        for df in glob.glob(os.path.join(d, "**/*.desktop"), recursive=True):
            if df in seen:
                continue
            seen.add(df)
            try:
                import configparser
                cfg = configparser.ConfigParser(interpolation=None)
                cfg.read(df, encoding="utf-8")
                entry = cfg["Desktop Entry"]
                if entry.get("NoDisplay", "false").lower() == "true":
                    continue
                name = entry.get("Name", "")
                exec_cmd = entry.get("Exec", "")
                icon = entry.get("Icon", "")
                if not name or not exec_cmd:
                    continue
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
                    "icon": icon,
                    "sub": sub,
                })
            except Exception:
                continue
    apps.sort(key=lambda a: a["name"].lower())
    return apps


# ── Files ─────────────────────────────────────────────────────────────


def search_files():
    if not Q or len(Q) < 2:
        return []
    cmd = None
    if shutil.which("fd"):
        cmd = ["fd", "--hidden", "--no-ignore", "-t", "f", "-d", "6", "-i", QUERY, HOME]
    else:
        cmd = ["find", HOME,
               "-maxdepth", "6",
               "-type", "f",
               "!", "-path", "*/.*",
               "-iname", f"*{QUERY}*"]
    try:
        out = subprocess.run(cmd, capture_output=True, text=True, timeout=8).stdout
        paths = [p for p in out.splitlines() if p.strip()][:30]
    except Exception:
        return []
    result = []
    for p in paths:
        result.append({
            "kind": "file",
            "name": os.path.basename(p) or p,
            "path": p,
            "icon": "",
            "sub": os.path.dirname(p) or p,
        })
    return result


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
        def rank(a):
            name = a["name"].lower()
            hay = (a.get("sub", "") + " " + name + " " + a.get("exec", "")).lower()
            start = name.startswith(Q)
            prefix = hay.startswith(Q)
            return (0 if start else (1 if prefix else 2), name)

        app_hits = [
            a for a in apps
            if Q in a["name"].lower()
            or Q in a.get("sub", "").lower()
            or Q in a.get("exec", "").lower()
        ]
        app_hits.sort(key=rank)
        results = app_hits[:40] + search_files()
        calc = solve()
        if calc:
            results.append(calc)
    sys.stdout.write(json.dumps(results[:60]) + "\n")


if __name__ == "__main__":
    main()