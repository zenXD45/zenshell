#!/bin/bash
# ZenShell background watchers: battery, bluetooth and notification monitors.
#
# Idempotent by design. This script used to pkill-then-start with no lock, so two
# copies launched at the same moment (trivial to hit: run start_all.sh twice, or
# start_all.sh plus a manual start) each killed nothing and each started a set,
# leaving two daemons per subsystem watching the same hardware. flock serialises
# concurrent runs, and a liveness probe skips the restart when everything is
# already up.

set -u

DIR="$HOME/.config/quickshell/dynamic-island"
LOCK="${XDG_RUNTIME_DIR:-/tmp}/zen-monitors.lock"

exec 9>"$LOCK"
if ! flock -n 9; then
    echo "monitors: another start_monitors.sh is already running — nothing to do."
    exit 0
fi

# Match on scripts/<name> so a shell whose command line merely mentions the
# script (e.g. a grep) is never mistaken for the daemon itself.
alive() { pgrep -f "scripts/$1" >/dev/null 2>&1; }

if alive battery_monitor.sh && alive bluetooth_monitor.sh && alive notification_monitor.py; then
    echo "monitors: already running (battery, bluetooth, notifications)."
    exit 0
fi

# Restart the whole set, so a single dead watcher can never leave the others
# duplicated.
pkill -f "scripts/battery_monitor.sh"
pkill -f "scripts/bluetooth_monitor.sh"
pkill -f "scripts/notification_monitor.py"
pkill -f "scripts/notification_monitor.sh"

sleep 1

nohup bash "$DIR/scripts/battery_monitor.sh" >/tmp/battery_mon.log 2>&1 &
nohup bash "$DIR/scripts/bluetooth_monitor.sh" >/tmp/bluetooth_mon.log 2>&1 &
nohup python3 "$DIR/scripts/notification_monitor.py" >/tmp/notification_mon.log 2>&1 &

echo "monitors: started (battery, bluetooth, notifications)."
