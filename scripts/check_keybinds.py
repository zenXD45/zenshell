#!/usr/bin/env python3
"""
Verify that every binary a keybind launches is actually provided by install.sh.

Four binds used to point at librewolf / nautilus / codium / wlogout, none of
which the installer shipped, so SUPER+B, SUPER+E, SUPER+C and SUPER+X all did
nothing on a clean machine. This turns that class of bug into a build failure.

Binaries that come from the base system, the AUR helper's own dependency graph,
or Hyprland itself are listed in EXTERNAL. Anything else must appear in
install.sh's OFFICIAL_PKGS or AUR_PKGS array.

Run:  python3 scripts/check_keybinds.py
Exit: 0 = every keybind binary is accounted for, 1 = at least one is not.
"""
from __future__ import annotations

import re
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
INSTALLER = REPO / "install.sh"
KEYBINDS = REPO / "hyprzen/.config/hypr/modules/keybinds.lua"
# Keys resolved at runtime by scripts / ZenShell IPC rather than by a package.
PATH_LIKE = ("~", "/", "$")

# Provided by the base system, Hyprland itself, or pulled in as a dependency of
# something the installer does list. Kept explicit so new omissions are visible.
EXTERNAL = {
    # compositor / session
    "hyprctl", "hyprlock", "hypridle", "Hyprland",
    # session / desktop services
    "loginctl", "systemctl", "notify-send", "gsettings", "dbus-update-activation-environment",
    # media / devices
    "playerctl", "wpctl", "brightnessctl", "nm-applet", "bluetoothctl",
    "nmcli", "powerprofilesctl", "socat",
    # clipboard / capture
    "wl-paste", "cliphist", "hyprshot", "grim", "slurp", "satty",
    # theme / wallpaper
    "awww", "matugen", "wal", "waypaper",
    # ZenShell entry points invoked by absolute path or island_ctl.sh
    "quickshell", "island_ctl.sh",
    # third-party helpers invoked through ~/scripts
    "caffeine.sh",
    # installed as a side effect of a listed package
    "vscodium", "codium",
}


def parse_installed() -> set[str]:
    text = INSTALLER.read_text(encoding="utf-8")
    pkgs: set[str] = set()
    for array in ("OFFICIAL_PKGS", "AUR_PKGS"):
        match = re.search(rf"{array}=\((.*?)\n\)", text, re.S)
        if match:
            pkgs |= set(re.findall(r"[a-z0-9][a-z0-9._+-]*", match.group(1)))
    return pkgs


def parse_keybinds() -> list[tuple[str, str]]:
    """Return (combo, command) for every bind that launches a command."""
    text = KEYBINDS.read_text(encoding="utf-8")
    # The config builds combos by concatenation (S .. " + B"), so expand the
    # local aliases before extracting the combo, otherwise every bind is
    # reported as "+ B".
    aliases = dict(re.findall(r'local (\w+)\s*=\s*"([^"]+)"', text))
    aliases.setdefault("S", "SUPER")

    binds = []
    for line in text.splitlines():
        stripped = line.strip()
        if not stripped.startswith("hl.bind("):
            continue
        cmd = re.search(r'exec_cmd\("([^"]+)"\)', stripped)
        if not cmd:
            continue
        combo_expr = stripped[len("hl.bind(") : stripped.find(",", len("hl.bind("))]
        combo = re.sub(r'\b(\w+)\s*\.\.\s*', lambda m: aliases.get(m.group(1), m.group(1)), combo_expr)
        combo = combo.replace('"', "").strip()
        binds.append((combo, cmd.group(1)))
    return binds


def main() -> int:
    installed = parse_installed()
    binds = parse_keybinds()
    if not binds:
        print("check_keybinds: no exec_cmd keybinds found — is the parser stale?", file=sys.stderr)
        return 1

    unresolved = []
    for combo, command in binds:
        binary = command.split()[0]
        if binary.startswith(PATH_LIKE):
            status = "resolved at runtime (script/IPC path)"
        elif binary in EXTERNAL:
            status = "external / system"
        elif binary in installed:
            status = "installed by install.sh"
        else:
            status = "NOT INSTALLED"
            unresolved.append((combo, command))

    if unresolved:
        print("check_keybinds: these keybinds point at binaries install.sh never ships:\n", file=sys.stderr)
        for combo, command in unresolved:
            print(f"  {combo:<28} -> {command}", file=sys.stderr)
        print("\nAdd the package to install.sh, or remove the bind.", file=sys.stderr)
        return 1

    print(f"check_keybinds: {len(binds)} binds checked, all binaries accounted for.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
