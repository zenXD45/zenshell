#!/usr/bin/env python3
"""
Guard two QML bug classes that silently break ZenShell at runtime.

Neither of these is a syntax error, so `bash -n`, `luac -p` and even a clean
`qmllint` run all pass — the shell just misbehaves:

1. Malformed hex colour literals
   `"#44411"` (five digits) was committed into AppLauncher.qml. Quickshell
   rejects the whole file ("Invalid property assignment: color expected"), and
   because shell.qml imports it the entire island failed to load. Hex colours
   must be 3, 4, 6 or 8 digits.

2. `parent.` inside a `transform:` block
   `transform: Scale { xScale: parent.press }` looks reasonable but `parent` is
   undefined inside a Transform (it is not an Item), so the binding silently
   evaluates to undefined and the animation never runs. Ten of these in
   ControlPanel.qml made every control tile's press feedback dead while spamming
   the log with "Unable to assign [undefined] to double". Reference the item by
   id instead.

Run:  python3 scripts/check_qml.py
Exit: 0 = clean, 1 = at least one finding.
"""
from __future__ import annotations

import re
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
QML_DIR = REPO / "zenshell"

HEX_LITERAL = re.compile(r"""(["'])#([0-9a-fA-F]+)\1""")
TRANSFORM = re.compile(r"\btransform:\s*(Scale|Rotation|Translate)\s*\{")
VALID_HEX_LENGTHS = {3, 4, 6, 8}


def line_of(text: str, index: int) -> int:
    return text.count("\n", 0, index) + 1


def transform_blocks(text: str):
    """Yield (line, transform_type, body) for each transform block."""
    for match in TRANSFORM.finditer(text):
        start = match.end() - 1  # position of the opening brace
        depth = 0
        for i in range(start, len(text)):
            if text[i] == "{":
                depth += 1
            elif text[i] == "}":
                depth -= 1
                if depth == 0:
                    yield line_of(text, match.start()), match.group(1), text[start + 1 : i]
                    break


def check_file(path: Path) -> list[str]:
    findings: list[str] = []
    text = path.read_text(encoding="utf-8")

    for match in HEX_LITERAL.finditer(text):
        digits = match.group(2)
        if len(digits) not in VALID_HEX_LENGTHS:
            findings.append(
                f"{path}:{line_of(text, match.start())}: "
                f"malformed colour {match.group(0)} "
                f"({len(digits)} hex digits; need 3, 4, 6 or 8)"
            )

    for line, kind, body in transform_blocks(text):
        hits = re.findall(r"\bparent\.", body)
        if hits:
            findings.append(
                f"{path}:{line}: `parent.` inside transform: {kind} is undefined "
                f"({len(hits)} binding(s)); use the item id"
            )

    return findings


def main() -> int:
    files = sorted(QML_DIR.rglob("*.qml"))
    if not files:
        print(f"check_qml: no .qml files under {QML_DIR}", file=sys.stderr)
        return 1

    findings: list[str] = []
    for path in files:
        findings.extend(check_file(path))

    if findings:
        print("check_qml: these QML files will misbehave at runtime:\n", file=sys.stderr)
        for finding in findings:
            print(f"  {finding}", file=sys.stderr)
        return 1

    print(f"check_qml: {len(files)} QML files clean (hex colours, transform bindings).")
    return 0


if __name__ == "__main__":
    sys.exit(main())
