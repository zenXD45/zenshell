#!/usr/bin/env bash
# =============================================================
#  HyprZen Install Script
#  Removes Caelestia setup and replaces with HyprZen.
#  Symlinks all configs from the repo's hyprzen/ directory to ~/.config.
# =============================================================

set -e

# Resolve the script's directory so it works regardless of cwd
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$SCRIPT_DIR"
CONFIG_DIR="$HOME/.config"
DEFAULT_THEME="catppuccin"

echo "🌸 HyprZen Install"
echo "══════════════════"

# ── Step 1: Kill Caelestia / old shell components ────────────
echo ""
echo "🗑  Removing Caelestia setup..."

# Kill any Caelestia-related processes gracefully
for proc in caelestia ags quickshell hyprshell; do
    pkill -x "$proc" 2>/dev/null && echo "  killed: $proc" || true
done

# ── Step 2: Wipe Caelestia config dir ────────────────────────
if [ -d "$CONFIG_DIR/caelestia" ]; then
    rm -rf "$CONFIG_DIR/caelestia"
    echo "  removed: ~/.config/caelestia"
fi

# ── Step 3: (Removed) ────────────────────────────────────────
# We no longer delete individual files here because it could resolve our
# own symlink and delete files inside the git repository.
# Step 5 will cleanly replace the entire ~/.config/hypr directory anyway.
HYPR_DIR="$CONFIG_DIR/hypr"

# ── Step 4: Remove old kitty dir ───────────────────────────────
# (could be a real dir from an old setup, or a broken symlink)
for app in kitty; do
    target="$CONFIG_DIR/$app"
    if [ -L "$target" ]; then
        rm -f "$target"
        echo "  removed symlink: ~/.config/$app"
    elif [ -d "$target" ]; then
        # Backup only if not already backed up
        if [ ! -e "${target}.caelestia.bak" ]; then
            mv "$target" "${target}.caelestia.bak"
            echo "  backed up: ~/.config/$app  →  ~/.config/${app}.caelestia.bak"
        else
            rm -rf "$target"
            echo "  removed: ~/.config/$app"
        fi
    fi
done

# ── Step 5: Symlink HyprZen configs ──────────────────────────
echo ""
echo "🔗 Linking HyprZen configs..."

link() {
    local src="$1" dst="$2"
    mkdir -p "$(dirname "$dst")"
    ln -sfn "$src" "$dst"
    echo "  linked: $dst → $src"
}

# The hypr dir itself: wipe loose files and symlink the whole dir
# Since ~/.config/hypr might have leftover loose files, replace entirely
if [ -e "$HYPR_DIR" ] && [ ! -L "$HYPR_DIR" ]; then
    rm -rf "$HYPR_DIR"
    echo "  cleaned up: ~/.config/hypr (old Caelestia dir)"
fi
link "$DOTFILES_DIR/.config/hypr"    "$CONFIG_DIR/hypr"
link "$DOTFILES_DIR/.config/kitty"   "$CONFIG_DIR/kitty"
link "$DOTFILES_DIR/.config/wlogout" "$CONFIG_DIR/wlogout"
link "$DOTFILES_DIR/.config/fastfetch" "$CONFIG_DIR/fastfetch"
link "$DOTFILES_DIR/.config/wal"     "$CONFIG_DIR/wal"
link "$DOTFILES_DIR/.config/nvim"    "$CONFIG_DIR/nvim"

# ── Zsh config ─────────────────────────────────────────────────
echo ""
echo "🐚 Installing zsh config..."
# Link .zshrc
if [ -L "$HOME/.zshrc" ]; then
    rm -f "$HOME/.zshrc"
fi
cp "$DOTFILES_DIR/.config/zsh/.zshrc" "$HOME/.zshrc"
echo "  installed: ~/.zshrc"
# Link p10k config
cp "$DOTFILES_DIR/.config/zsh/p10k.zsh" "$HOME/.p10k.zsh"
echo "  installed: ~/.p10k.zsh"

# ── Step 6: Install scripts ───────────────────────────────────
echo ""
echo "📜 Installing scripts..."
if [ -d "$HOME/scripts" ] && [ ! -L "$HOME/scripts" ]; then
    rm -rf "$HOME/scripts"
fi
ln -sfn "$DOTFILES_DIR/scripts" "$HOME/scripts"
find "$HOME/scripts/" -maxdepth 1 -type f -name '*.sh' -exec chmod +x {} +
echo "  linked: ~/scripts/"

# ── Step 7: Install curated wallpapers / screenshot dirs ──────
mkdir -p "$HOME/wallpapers"
mkdir -p "$HOME/screenshots"
echo "  created: ~/wallpapers/  ~/screenshots/"
echo ""
echo "🖼️ Installing categorized wallpapers..."
cp -r "$DOTFILES_DIR/wallpapers/"* "$HOME/wallpapers/" 2>/dev/null || echo "  ⚠️ No local wallpapers found to install."

# ── Step 8: Apply default theme ──────────────────────────────
echo ""
echo "🎨 Applying default theme: $DEFAULT_THEME"

if [ -f "$HOME/scripts/theme-switch.sh" ]; then
    # theme-switch.sh may fail when running outside a desktop session
    # (e.g., no Hyprland / Wayland display). Don't let that abort install.
    "$HOME/scripts/theme-switch.sh" "$DEFAULT_THEME" || echo "⚠️  theme-switch.sh exited with errors (this is normal if not in a desktop session)."
else
    echo "⚠️  theme-switch.sh not found, skipping default theme setup."
fi

echo ""
echo "✅ Done! Next steps:"
echo "   1. Ensure required packages are installed: (see README.md)"
echo "      e.g., Hyprland, kitty, python-requests, hyprpaper, python-pywal"
echo "   2. Log in to Hyprland (or restart: hyprctl reload)"
echo "   3. Switch themes: Super+T (island)  or  ~/scripts/theme-switch.sh <theme>"
echo "   4. Pick wallpapers: Super+W (island)  or  ~/scripts/wallpaper-selector.sh set <path>"
