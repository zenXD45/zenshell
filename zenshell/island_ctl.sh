#!/bin/bash
if [ -z "$1" ]; then
    echo "Usage: $0 <launcher|wallpapers|themes|power|control|weather|profiles|bar-settings|settings [page]|bar|island|dock|dock-settings|camera|camera-snap|mic-mute|camera-output>"
    exit 1
fi

CONFIG_PATH="$HOME/.config/quickshell/dynamic-island"

if [ "$1" == "launcher" ]; then
    quickshell ipc -p "$CONFIG_PATH" call island showLauncher
elif [ "$1" == "wallpapers" ]; then
    quickshell ipc -p "$CONFIG_PATH" call island showWallpapers
elif [ "$1" == "themes" ]; then
    quickshell ipc -p "$CONFIG_PATH" call island showThemes
elif [ "$1" == "power" ]; then
    quickshell ipc -p "$CONFIG_PATH" call island showPower
elif [ "$1" == "control" ]; then
    quickshell ipc -p "$CONFIG_PATH" call island showControlPanel
elif [ "$1" == "powerprofile" ] || [ "$1" == "profile" ]; then
    quickshell ipc -p "$CONFIG_PATH" call island showPowerProfile
elif [ "$1" == "clipboard" ]; then
    quickshell ipc -p "$CONFIG_PATH" call island showClipboard
elif [ "$1" == "cheatsheet" ]; then
    quickshell ipc -p "$CONFIG_PATH" call island showCheatsheet
elif [ "$1" == "weather" ]; then
    quickshell ipc -p "$CONFIG_PATH" call island showWeather
elif [ "$1" == "profiles" ] || [ "$1" == "profile-switch" ]; then
    quickshell ipc -p "$CONFIG_PATH" call profile menu
elif [ "$1" == "bar-settings" ]; then
    quickshell ipc -p "$CONFIG_PATH" call profile settings
elif [ "$1" == "settings" ]; then
    # With a page id the window opens on that page; without one it toggles.
    if [ -n "$2" ]; then
        quickshell ipc -p "$CONFIG_PATH" call settings page "$2"
    else
        quickshell ipc -p "$CONFIG_PATH" call settings toggle
    fi
elif [ "$1" == "bar" ]; then
    quickshell ipc -p "$CONFIG_PATH" call profile switchTo bar
elif [ "$1" == "island" ]; then
    quickshell ipc -p "$CONFIG_PATH" call profile switchTo island
elif [ "$1" == "dock" ]; then
    quickshell ipc -p "$CONFIG_PATH/modules/dock" call qs-dock toggleAutoHide
elif [ "$1" == "dock-settings" ]; then
    quickshell ipc -p "$CONFIG_PATH/modules/dock" call qs-dock showDockMenu
elif [ "$1" == "camera" ]; then
    quickshell ipc -p "$CONFIG_PATH" call island showCamera
elif [ "$1" == "camera-snap" ]; then
    quickshell ipc -p "$CONFIG_PATH" call island cameraSnap
elif [ "$1" == "mic-mute" ]; then
    quickshell ipc -p "$CONFIG_PATH" call island micMute
elif [ "$1" == "camera-output" ]; then
    # camera-output <width> <height> [fps] — restarts the daemon with a new
    # output size. Bigger than the camera's capture size = real-time upscale.
    quickshell ipc -p "$CONFIG_PATH" call island setCameraOutput "$2" "$3" "${4:-30}"
else
    echo "Invalid state: $1"
    exit 1
fi
