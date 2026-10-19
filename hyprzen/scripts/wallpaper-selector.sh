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

# Auto-generate colors with Matugen (only if installed)
if command -v matugen &> /dev/null; then
    if matugen -c "$HOME/.config/matugen/config.toml" image "$WALL" --prefer saturation --source-color-index 0 >/dev/null 2>&1; then
        python3 "$SCRIPT_DIR/gen-themes.py" >/dev/null 2>&1
        echo 'require("themes.matugen")' > "$HOME/.config/hypr/themes/current_theme.lua"
        echo 'source = ~/.config/hypr/themes/matugen.conf' > "$HOME/.config/hypr/themes/current_theme.conf"
        ln -sf ~/.config/kitty/themes/matugen.conf ~/.config/kitty/themes/current.conf
        ln -sfn "$HOME/.config/hypr/themes/matugen.css" "$HOME/.config/hypr/themes/current.css"
        hyprctl reload 2>/dev/null || true
        pkill -SIGUSR1 kitty 2>/dev/null || true
        notify-send "󰟡 HyprZen" "Material You colors applied!" --icon=color-select 2>/dev/null || true
    else
        notify-send "󰟡 HyprZen" "Material You generation failed" --icon=dialog-error 2>/dev/null || true
    fi
fi