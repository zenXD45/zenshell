#!/usr/bin/env bash

# Toggle hypridle for "Caffeine" mode (keep screen awake)
if pgrep -x hypridle > /dev/null; then
    pkill -x hypridle
    notify-send -a "Caffeine" -u normal -t 3000 -i "weather-clear-night" "Caffeine Enabled" "Screen will stay awake."
else
    # Detach fully so the daemon survives this script exiting.
    setsid hypridle >/dev/null 2>&1 &
    notify-send -a "Caffeine" -u normal -t 3000 -i "weather-clear" "Caffeine Disabled" "Normal sleep schedule restored."
fi
