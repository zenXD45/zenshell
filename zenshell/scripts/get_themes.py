#!/usr/bin/env python3
"""Emit the theme list consumed by the ZenShell island theme switcher.

The palette used to be hardcoded here, which meant the shell could disagree
with Hyprland about what a theme looked like (osaka-jade shipped as #2b3339
here while Hyprland used 0f1715). It is now generated from the TOML sources by
hyprzen/scripts/gen-themes.py into themes.json next to this file.

Run `python3 hyprzen/scripts/gen-themes.py` after editing any theme.
"""
import json
import sys
from pathlib import Path

THEMES_JSON = Path(__file__).resolve().parent / "themes.json"

FALLBACK = [
    {"id": "noir", "name": "Noir", "icon": "🌑", "accent": "#838996",
     "bg": "#0f0f0f", "surface": "#141414", "fg": "#c0c0c0", "extra": "#c23b3b",
     "dark": True, "rounding": 0},
]


def main() -> int:
    try:
        themes = json.loads(THEMES_JSON.read_text(encoding="utf-8"))
    except FileNotFoundError:
        print(
            f"gen-themes: {THEMES_JSON} is missing; run "
            "'python3 hyprzen/scripts/gen-themes.py'",
            file=sys.stderr,
        )
        return 1
    except json.JSONDecodeError as exc:
        print(f"get_themes: {THEMES_JSON} is not valid JSON: {exc}", file=sys.stderr)
        return 1

    if not isinstance(themes, list) or not themes:
        print("get_themes: themes.json contained no themes", file=sys.stderr)
        themes = FALLBACK

    print(json.dumps(themes, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    sys.exit(main())
