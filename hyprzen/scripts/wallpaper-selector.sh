#!/usr/bin/env bash
# =============================================================
#  HyprZen Wallpaper Setter (ZenShell is the default UI)
#  Usage:
#    wallpaper-selector.sh <path-to-image>
#
#  Sets the current wallpaper AND keeps ~/wallpapers/current in
#  sync so hyprlock + the on-boot wallpaper (awww) match the one
#  you pick inside the ZenShell island.
# =============================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
CURRENT_LINK="$HOME/wallpapers/current"
WALL="${1:-}"

if [ -z "$WALL" ] || [ ! -f "$WALL" ]; then
    echo "Usage: wallpaper-selector.sh <path-to-image>"
    exit 1
fi

# Keep the 'current' link in sync (hyprlock reads this at lock time,
# exec.lua feeds it to awww at session start).
mkdir -p "$HOME/wallpapers"
ln -sf "$WALL" "$CURRENT_LINK"

# Apply with awww (smooth transition)
awww img "$WALL" \
    --transition-type grow \
    --transition-pos 0.5,0.5 \
    --transition-duration 1.2 \
    --transition-fps 60

# Repaint the theme only for wallpaper-derived themes. Picking a wallpaper
# while a static theme (noir, gruvbox, …) is active must NOT switch the UI to
# Matugen — that used to happen unconditionally, silently clobbering the
# user's theme choice.
ACTIVE_THEME=""
if [ -f "$HOME/.config/hypr/themes/current_theme.conf" ]; then
    ACTIVE_THEME="$(sed -nE 's|.*themes/([^/]+)\.conf.*|\1|p' \
        "$HOME/.config/hypr/themes/current_theme.conf" | head -n1)"
fi

case "$ACTIVE_THEME" in
    matugen)
        if ! command -v matugen &> /dev/null; then
            notify-send "󰟡 HyprZen" "matugen is not installed — theme unchanged" --icon=dialog-error 2>/dev/null || true
        elif matugen -c "$HOME/.config/matugen/config.toml" image "$WALL" --prefer saturation --source-color-index 0 >/dev/null 2>&1; then
            python3 "$SCRIPT_DIR/gen-themes.py" >/dev/null 2>&1
            ln -sfn "$HOME/.config/hypr/themes/matugen.css" "$HOME/.config/hypr/themes/current.css"
            hyprctl reload 2>/dev/null || true
            pkill -SIGUSR1 kitty 2>/dev/null || true
            notify-send "󰟡 HyprZen" "Material You colors applied!" --icon=color-select 2>/dev/null || true
        else
            notify-send "󰟡 HyprZen" "Material You generation failed" --icon=dialog-error 2>/dev/null || true
        fi
        ;;
    dynamic)
        # dynamic-colors.sh writes its own pointers and reloads Hyprland.
        if [ -x "$SCRIPT_DIR/dynamic-colors.sh" ]; then
            "$SCRIPT_DIR/dynamic-colors.sh" "$WALL" \
                || notify-send "󰟡 HyprZen" "Dynamic color generation failed" --icon=dialog-error 2>/dev/null || true
        fi
        ;;
    *)
        # Static theme: wallpaper only.
        notify-send "󰸉 HyprZen" "Wallpaper set" --icon=preferences-desktop-wallpaper 2>/dev/null || true
        ;;
esac