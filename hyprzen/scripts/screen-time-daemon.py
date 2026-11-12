#!/usr/bin/env python3
"""Screen-time tracker for Hyprland. Samples the focused window every 5s
and accumulates per-app / per-hour usage into a daily JSON file."""
import json
import os
import subprocess
import sys
import time
from datetime import datetime

DATA_DIR = os.path.expanduser("~/.local/share/screen-time")
os.makedirs(DATA_DIR, exist_ok=True)

PID_FILE = os.path.join(DATA_DIR, "daemon.pid")

# Single-instance guard.
try:
    if os.path.exists(PID_FILE):
        with open(PID_FILE) as f:
            old = int(f.read().strip())
        try:
            os.kill(old, 0)
            # already running
            sys.exit(0)
        except OSError:
            pass
except Exception:
    pass
with open(PID_FILE, "w") as f:
    f.write(str(os.getpid()))

INTERVAL = 5
current_date = None
state = None


def load(date):
    path = os.path.join(DATA_DIR, date + ".json")
    if os.path.exists(path):
        try:
            with open(path) as f:
                d = json.load(f)
            if isinstance(d.get("hours"), list) and len(d["hours"]) == 24:
                return d
        except Exception:
            pass
    return {"date": date, "total": 0, "apps": {}, "hours": [0] * 24}


def save(date, data):
    path = os.path.join(DATA_DIR, date + ".json")
    tmp = path + ".tmp"
    with open(tmp, "w") as f:
        json.dump(data, f)
    os.replace(tmp, path)


def focused_class():
    try:
        out = subprocess.check_output(
            ["hyprctl", "activewindow", "-j"], text=True, timeout=3
        )
        d = json.loads(out)
        return d.get("class") or d.get("initialClass") or ""
    except Exception:
        return ""


def session_paused():
    """True while the session is locked or every monitor is in DPMS off.

    Without this the tracker keeps counting whatever window was last focused
    when the screen goes dark, which inflates the day by hours.
    """
    try:
        out = subprocess.check_output(
            ["loginctl", "show-session", os.environ.get("XDG_SESSION_ID", ""),
             "-p", "LockedHint"],
            text=True, timeout=2,
        )
        if "yes" in out:
            return True
    except Exception:
        pass
    try:
        out = subprocess.check_output(["hyprctl", "monitors", "-j"], text=True, timeout=2)
        monitors = json.loads(out)
        if monitors and not any(m.get("dpmsStatus") for m in monitors):
            return True
    except Exception:
        pass
    return False


import atexit
atexit.register(lambda: os.path.exists(PID_FILE) and os.remove(PID_FILE))

def main():
    global current_date, state
    paused = False
    last_pause_check = 0.0
    while True:
        now = datetime.now()
        date = now.strftime("%Y-%m-%d")
        if date != current_date:
            current_date = date
            state = load(date)
        if now.timestamp() - last_pause_check > 30:
            paused = session_paused()
            last_pause_check = now.timestamp()
        cls = "" if paused else focused_class()
        if cls:
            state["total"] = state.get("total", 0) + INTERVAL
            state["apps"][cls] = state["apps"].get(cls, 0) + INTERVAL
            state["hours"][now.hour] = state["hours"][now.hour] + INTERVAL
            save(date, state)
        time.sleep(INTERVAL)


if __name__ == "__main__":
    main()
PY
chmod +x /home/zen/scripts/screen-time-daemon.py