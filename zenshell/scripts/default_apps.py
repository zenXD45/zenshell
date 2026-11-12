#!/usr/bin/env python3
"""Read and write default application associations for ZenShell.

Usage:
    default_apps.py get
    default_apps.py set <role> <desktop-file-id>

`get` prints one JSON object mapping each role to the desktop file currently
registered for it, for example {"browser": "firefox.desktop"}. Roles with no
association are omitted so the settings window can show "Not set".

`set` registers the desktop file for every MIME type that makes up a role.
The writes go through xdg-mime, which updates ~/.config/mimeapps.list and
respects XDG_DATA_DIRS, instead of hand-editing the file and losing other
associations.
"""

from __future__ import annotations

import json
import subprocess
import sys

ROLE_MIME_TYPES: dict[str, list[str]] = {
    "browser": [
        "x-scheme-handler/http",
        "x-scheme-handler/https",
        "text/html",
    ],
    "mail": [
        "x-scheme-handler/mailto",
        "message/rfc822",
    ],
    "file_manager": [
        "inode/directory",
    ],
    "text_editor": [
        "text/plain",
    ],
    "image_viewer": [
        "image/png",
        "image/jpeg",
        "image/webp",
        "image/gif",
    ],
    "video_player": [
        "video/mp4",
        "video/x-matroska",
        "video/webm",
        "video/x-msvideo",
    ],
    "audio_player": [
        "audio/mpeg",
        "audio/flac",
        "audio/ogg",
        "audio/x-wav",
    ],
    "pdf_viewer": [
        "application/pdf",
    ],
}


def query_default(mime_type: str) -> str:
    try:
        result = subprocess.run(
            ["xdg-mime", "query", "default", mime_type],
            capture_output=True,
            text=True,
            timeout=5,
        )
    except (FileNotFoundError, subprocess.TimeoutExpired, OSError):
        return ""
    return result.stdout.strip()


def get_defaults() -> dict[str, str]:
    defaults: dict[str, str] = {}
    for role, mime_types in ROLE_MIME_TYPES.items():
        for mime_type in mime_types:
            desktop_id = query_default(mime_type)
            if desktop_id:
                defaults[role] = desktop_id
                break
    return defaults


def set_default(role: str, desktop_id: str) -> int:
    mime_types = ROLE_MIME_TYPES.get(role)
    if not mime_types:
        print(f"unknown role: {role}", file=sys.stderr)
        return 2
    if not desktop_id:
        print("missing desktop file id", file=sys.stderr)
        return 2

    failed = 0
    for mime_type in mime_types:
        try:
            result = subprocess.run(
                ["xdg-mime", "default", desktop_id, mime_type],
                capture_output=True,
                text=True,
                timeout=5,
            )
        except (FileNotFoundError, subprocess.TimeoutExpired, OSError) as error:
            print(f"xdg-mime failed for {mime_type}: {error}", file=sys.stderr)
            failed = 1
            continue
        if result.returncode != 0:
            detail = (result.stderr or result.stdout).strip()
            print(f"xdg-mime rejected {mime_type}: {detail}", file=sys.stderr)
            failed = result.returncode
    return failed


def main() -> int:
    if len(sys.argv) < 2:
        print(__doc__.strip(), file=sys.stderr)
        return 2

    command = sys.argv[1]
    if command == "get":
        print(json.dumps(get_defaults(), ensure_ascii=False))
        return 0

    if command == "set":
        if len(sys.argv) != 4:
            print("usage: default_apps.py set <role> <desktop-file-id>", file=sys.stderr)
            return 2
        return set_default(sys.argv[2], sys.argv[3])

    print(f"unknown command: {command}", file=sys.stderr)
    return 2


if __name__ == "__main__":
    raise SystemExit(main())
