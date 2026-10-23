#!/usr/bin/env python3
"""Manage dock pins without racing the dock's FileView.

Usage:
  pin_app.py pin <id> <icon> <exec>
  pin_app.py unpin <id>
  pin_app.py set-order <json-array-of-ids>

Writes are atomic, so the dock either sees the old list or the new one while it
watches pinned_apps.json.  Existing entries are preserved verbatim; reordering
only changes the order of the ids it is given and keeps any unknown pins at the
end.
"""

from __future__ import annotations

import json
import os
import sys
import tempfile
from pathlib import Path

PIN_FILE = Path(__file__).resolve().with_name("pinned_apps.json")


def load() -> list[dict]:
    try:
        parsed = json.loads(PIN_FILE.read_text(encoding="utf-8"))
    except (FileNotFoundError, json.JSONDecodeError, OSError):
        return []
    if not isinstance(parsed, list):
        return []
    return [entry for entry in parsed if isinstance(entry, dict) and entry.get("id")]


def save(entries: list[dict]) -> None:
    PIN_FILE.parent.mkdir(parents=True, exist_ok=True)
    fd, tmp_name = tempfile.mkstemp(
        prefix=".pinned_apps.", suffix=".json", dir=str(PIN_FILE.parent)
    )
    try:
        with os.fdopen(fd, "w", encoding="utf-8") as handle:
            json.dump(entries, handle, indent=2, ensure_ascii=False)
            handle.write("\n")
        os.replace(tmp_name, PIN_FILE)
    finally:
        if os.path.exists(tmp_name):
            os.unlink(tmp_name)


def pin(app_id: str, icon: str, exec_cmd: str) -> None:
    entries = load()
    for entry in entries:
        if entry.get("id") == app_id:
            # Do not overwrite fields a user may have hand-edited.  Fill in a
            # missing launcher only when the old pin cannot launch anything.
            if not entry.get("exec"):
                entry["exec"] = exec_cmd or app_id
            if not entry.get("iconName"):
                entry["iconName"] = icon or app_id
            save(entries)
            return

    entries.append(
        {
            "id": app_id,
            "iconName": icon or app_id,
            "exec": exec_cmd or app_id,
        }
    )
    save(entries)


def unpin(app_id: str) -> None:
    entries = load()
    filtered = [entry for entry in entries if entry.get("id") != app_id]
    if len(filtered) != len(entries):
        save(filtered)


def set_order(raw_ids: str) -> None:
    try:
        ids = json.loads(raw_ids)
    except json.JSONDecodeError as error:
        raise SystemExit(f"invalid order: {error}") from error
    if not isinstance(ids, list) or not all(isinstance(item, str) for item in ids):
        raise SystemExit("order must be a JSON array of strings")

    entries = load()
    by_id = {entry["id"]: entry for entry in entries}
    ordered: list[dict] = []
    seen: set[str] = set()
    for app_id in ids:
        if app_id in by_id and app_id not in seen:
            ordered.append(by_id[app_id])
            seen.add(app_id)
    for entry in entries:
        if entry["id"] not in seen:
            ordered.append(entry)

    if [entry.get("id") for entry in ordered] != [entry.get("id") for entry in entries]:
        save(ordered)


def main() -> int:
    if len(sys.argv) < 3:
        print(__doc__.strip(), file=sys.stderr)
        return 2

    command = sys.argv[1]
    if command == "pin" and len(sys.argv) == 5:
        pin(sys.argv[2], sys.argv[3], sys.argv[4])
    elif command == "unpin" and len(sys.argv) == 3:
        unpin(sys.argv[2])
    elif command == "set-order" and len(sys.argv) == 3:
        set_order(sys.argv[2])
    else:
        print(__doc__.strip(), file=sys.stderr)
        return 2
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
