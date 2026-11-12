#!/bin/bash
# Zen Shell - Master Launcher Script
# Starts the Dynamic Island, Dock, Desktop Widgets and the background daemons.
#
# Safe to re-run. Every component is its own quickshell config, and quickshell
# refuses to start a second instance of a config that is already running
# (--no-duplicate is on by default), while start_monitors.sh serialises itself
# with a lock. Re-running this used to be the fastest way to end up with two
# islands and two sets of monitor daemons.

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
QS="${QS_BIN:-quickshell}"

# Background watchers first, so the island has data the moment it draws.
if [ -f "$SCRIPT_DIR/start_monitors.sh" ]; then
    "$SCRIPT_DIR/start_monitors.sh"
fi

launch() {
    local name="$1" path="$2"
    [ -d "$path" ] || return 0
    "$QS" -p "$path" &
    echo "[Zen Shell] $name launched."
}

# The settings window can turn the dock off. Respect that here as well, so a
# fresh login does not resurrect a dock the user deliberately disabled.
dock_enabled() {
    python3 - <<'PY' 2>/dev/null || echo true
import json
from pathlib import Path

path = Path.home() / ".config" / "quickshell" / "shell_settings.json"
try:
    value = json.loads(path.read_text(encoding="utf-8")).get("dock_enabled", True)
except (OSError, ValueError):
    value = True
print("true" if value is not False else "false")
PY
}

launch "Dynamic Island"  "$SCRIPT_DIR"
if [ "$(dock_enabled)" = "false" ]; then
    echo "[Zen Shell] Dock is disabled in settings; skipping it."
else
    launch "Dock"         "$SCRIPT_DIR/modules/dock"
fi
# launch "Desktop Widgets" "$SCRIPT_DIR/modules/desktop-widgets"
# launch "Spotlight"       "$SCRIPT_DIR/modules/spotlight"

echo "[Zen Shell] Started all desktop shell components."
