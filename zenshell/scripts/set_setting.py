#!/usr/bin/env python3
"""Write one value to ~/.config/quickshell/shell_settings.json.

Usage: set_setting.py <key> <json-value>

The QML side passes values through JSON.stringify(), so strings arrive quoted
and arrays/booleans arrive as their JSON representation. Writes are atomic so a
running FileView never observes a half-written settings file.
"""

from __future__ import annotations

import json
import os
import sys
import tempfile
from pathlib import Path


def main() -> int:
    if len(sys.argv) != 3:
        print("usage: set_setting.py <key> <json-value>", file=sys.stderr)
        return 2

    key, raw_value = sys.argv[1], sys.argv[2]
    try:
        value = json.loads(raw_value)
    except json.JSONDecodeError:
        # Accept plain strings from manual CLI use too.
        value = raw_value

    path = Path.home() / ".config" / "quickshell" / "shell_settings.json"
    path.parent.mkdir(parents=True, exist_ok=True)

    data: dict[str, object] = {}
    try:
        parsed = json.loads(path.read_text(encoding="utf-8"))
        if isinstance(parsed, dict):
            data = parsed
    except (FileNotFoundError, json.JSONDecodeError, OSError):
        pass

    data[key] = value

    fd, tmp_name = tempfile.mkstemp(
        prefix=".shell_settings.", suffix=".json", dir=str(path.parent)
    )
    try:
        with os.fdopen(fd, "w", encoding="utf-8") as handle:
            json.dump(data, handle, indent=2, ensure_ascii=False)
            handle.write("\n")
        os.replace(tmp_name, path)
    finally:
        if os.path.exists(tmp_name):
            os.unlink(tmp_name)

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
