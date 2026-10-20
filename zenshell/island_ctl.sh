#!/bin/bash
if [ -z "$1" ]; then
    echo "Usage: $0 <launcher|wallpapers|themes|power|control|profiles|bar-settings|bar|island>"
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
elif [ "$1" == "profiles" ] || [ "$1" == "profile-switch" ]; then
    quickshell ipc -p "$CONFIG_PATH" call profile menu
elif [ "$1" == "bar-settings" ]; then
    quickshell ipc -p "$CONFIG_PATH" call profile settings
elif [ "$1" == "bar" ]; then
    quickshell ipc -p "$CONFIG_PATH" call profile switchTo bar
elif [ "$1" == "island" ]; then
    quickshell ipc -p "$CONFIG_PATH" call profile switchTo island
else
    echo "Invalid state: $1"
    exit 1
fi
