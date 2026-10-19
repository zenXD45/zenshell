#!/bin/bash
# Volume/brightness control for the HyprZen media keys.
#
# This is the glue the keybinds call: it changes the value AND then asks ZenShell
# to draw its OSD through the island's `osd` IPC target. The OSD is not polled —
# shell.qml only renders OSD.qml while displayState = 2, which nothing except
# these IPC handlers sets — so a bind that skips this script (say, a raw `wpctl`)
# changes the value with no overlay at all.

set -u

TYPE="${1:-}"
ACTION="${2:-}"
QS_PATH="$HOME/.config/quickshell/dynamic-island"

usage() {
    echo "usage: $(basename "$0") volume {up|down|mute|mic-mute}" >&2
    echo "       $(basename "$0") brightness {up|down}" >&2
    exit 2
}

show_osd() {
    # Never let a missing/restarting island turn a successful volume change into
    # a failed keypress.
    quickshell ipc -p "$QS_PATH" call osd "$1" >/dev/null 2>&1 || true
}

case "$TYPE" in
    volume)
        case "$ACTION" in
            up)       wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%+ ;;
            down)     wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%- ;;
            mute)     wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle ;;
            mic-mute) wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle
                      show_osd showMic
                      exit 0 ;;
            *)        usage ;;
        esac
        show_osd showVolume
        ;;
    brightness)
        case "$ACTION" in
            up)   brightnessctl set 5%+ ;;
            down) brightnessctl set 5%- ;;
            *)    usage ;;
        esac
        show_osd showBrightness
        ;;
    *)
        usage
        ;;
esac
