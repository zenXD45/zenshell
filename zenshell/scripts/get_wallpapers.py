#!/usr/bin/env python3
"""List wallpapers for the ZenShell island wallpaper picker.

Emits a JSON array of {name, path, filename, theme}.

History:
  * This used to scan ~/Pictures/Wallpapers only, while the installer puts
    wallpapers in ~/wallpapers — so the picker was empty on a fresh install.
    Both locations are scanned now.
  * It emitted path/filename but the QML filter in shell.qml reads wp.name,
    which raised a TypeError on the first keystroke of the search box. The
    `name` field is emitted now (and is the human-readable label).
"""
from __future__ import annotations

import json
import os
import sys
from pathlib import Path

IMAGE_SUFFIXES = {".jpg", ".jpeg", ".png", ".webp"}

# The installer unpacks themed wallpapers into ~/wallpapers/<theme>/; a user may
# also keep their own in the XDG-standard Pictures/Wallpapers.
SEARCH_ROOTS = ("~/wallpapers", "~/Pictures/Wallpapers")


def collect() -> list[dict]:
    seen: set[str] = set()
    results: list[dict] = []

    for raw_root in SEARCH_ROOTS:
        root = Path(raw_root).expanduser()
        if not root.is_dir():
            continue

        for path in sorted(root.rglob("*")):
            if not path.is_file() or path.suffix.lower() not in IMAGE_SUFFIXES:
                continue

            resolved = str(path.resolve())
            if resolved in seen:
                continue
            seen.add(resolved)

            try:
                theme = path.parent.name if path.parent != root else ""
            except OSError:
                theme = ""

            filename = path.name
            stem = path.stem
            # Label: "catppuccin / mountain-fog" so themes stay distinguishable
            # when several themes ship a similarly named image.
            label = f"{theme} / {stem}" if theme else stem

            results.append(
                {
                    "name": label,
                    "path": str(path),
                    "filename": filename,
                    "theme": theme,
                }
            )

    results.sort(key=lambda w: w["name"].lower())
    return results


def main() -> int:
    try:
        print(json.dumps(collect(), ensure_ascii=False))
    except OSError as exc:
        print(f"get_wallpapers: {exc}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
