#!/usr/bin/env python3
"""Return Hyprland clients with desktop-entry metadata for the dock.

The dock needs more than a window address to make right-click actions useful:
a human-readable name, a launch command for "New window", and a stable icon.
Resolve those from the same .desktop files the rest of the desktop uses.
"""

from __future__ import annotations

import json
import os
import re
import subprocess
from pathlib import Path


FIELD_CODE = re.compile(r"%[fFuUick]")


def clean_exec(value: str) -> str:
    """Turn a desktop Exec line into something launchable by hl.dsp.exec_cmd."""
    return FIELD_CODE.sub("", value).replace("%%", "%").strip()


def parse_desktop(path: Path) -> dict[str, str] | None:
    try:
        lines = path.read_text(encoding="utf-8", errors="replace").splitlines()
    except OSError:
        return None

    section = ""
    values: dict[str, str] = {}
    for raw_line in lines:
        line = raw_line.strip()
        if not line or line.startswith("#"):
            continue
        if line.startswith("[") and line.endswith("]"):
            section = line[1:-1]
            continue
        if section != "Desktop Entry" or "=" not in line:
            continue
        key, value = line.split("=", 1)
        if key in {"Name", "Exec", "Icon", "StartupWMClass", "NoDisplay", "Hidden"}:
            values.setdefault(key, value.strip())

    if values.get("Hidden", "").lower() == "true":
        return None
    if values.get("NoDisplay", "").lower() == "true":
        return None

    name = values.get("Name", "")
    icon = values.get("Icon", "")
    exec_cmd = clean_exec(values.get("Exec", ""))
    wm_class = values.get("StartupWMClass", "")
    if not name and not icon:
        return None
    return {
        "name": name,
        "icon": icon,
        "exec": exec_cmd,
        "wm_class": wm_class,
        "stem": path.stem,
    }


def build_desktop_map() -> dict[str, dict[str, str]]:
    directories = [
        Path("/usr/share/applications"),
        Path.home() / ".local/share/applications",
    ]
    desktop_map: dict[str, dict[str, str]] = {}

    for directory in directories:
        if not directory.exists():
            continue
        for path in directory.rglob("*.desktop"):
            entry = parse_desktop(path)
            if not entry:
                continue
            keys = {
                entry["stem"].lower(),
                entry["name"].lower(),
                entry["wm_class"].lower(),
            }
            for key in keys:
                if key and key not in desktop_map:
                    desktop_map[key] = entry
    return desktop_map


def main() -> int:
    desktop_map = build_desktop_map()
    try:
        output = subprocess.check_output(["hyprctl", "clients", "-j"], text=True)
        clients = json.loads(output)
    except (OSError, subprocess.SubprocessError, json.JSONDecodeError):
        print("[]")
        return 0

    for client in clients:
        cls = str(client.get("class", ""))
        initial_class = str(client.get("initialClass", ""))
        entry = (
            desktop_map.get(initial_class.lower())
            or desktop_map.get(cls.lower())
        )

        client["resolvedIcon"] = (entry or {}).get("icon") or initial_class or cls
        client["resolvedName"] = (entry or {}).get("name") or initial_class or cls
        client["resolvedExec"] = (entry or {}).get("exec") or initial_class or cls

        workspace = client.get("workspace") or {}
        client["workspaceId"] = workspace.get("id", 1)

    print(json.dumps(clients))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
