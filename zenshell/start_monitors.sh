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

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
LOCK="${XDG_RUNTIME_DIR:-/tmp}/zen-monitors.lock"

exec 9>"$LOCK"
if ! flock -n 9; then
    echo "monitors: another start_monitors.sh is already running — nothing to do."
    exit 0
fi

# Match on scripts/<name> so a shell whose command line merely mentions the
# script (e.g. a grep) is never mistaken for the daemon itself.
    alive() {
        local count
        count=$(pgrep -f "scripts/$1" | wc -l)
        [ "$count" -ge 1 ]
    }

    if alive battery_monitor.sh && alive bluetooth_monitor.sh && alive notification_monitor.py; then
        echo "monitors: already running (battery, bluetooth, notifications)."
        exit 0
    fi

    # Kill any stale watchers before starting
    pkill -f "scripts/battery_monitor.sh" || true
    pkill -f "scripts/bluetooth_monitor.sh" || true
    pkill -f "scripts/notification_monitor.py" || true
    sleep 0.2
pkill -f "scripts/notification_monitor.sh"

sleep 1

# 9>&- closes the lock fd in each child. Without it the daemons inherit the
# flock and hold it for their whole lifetime, so the next run of this script
# always bails out with "another start_monitors.sh is already running" even
# though nothing is starting.
nohup bash "$DIR/scripts/battery_monitor.sh" >/tmp/battery_mon.log 2>&1 9>&- &
nohup bash "$DIR/scripts/bluetooth_monitor.sh" >/tmp/bluetooth_mon.log 2>&1 9>&- &
nohup python3 "$DIR/scripts/notification_monitor.py" >/tmp/notification_mon.log 2>&1 9>&- &

echo "monitors: started (battery, bluetooth, notifications)."
