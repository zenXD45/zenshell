#!/usr/bin/env bash
# =============================================================
#  HyprZen Install Script
#  Replaces an old Caelestia setup with HyprZen.
#  Symlinks all configs from the repo's hyprzen/ directory to ~/.config.
#
#  Re-running is safe:
#    • managed symlinks are refreshed in place
#    • real directories are backed up, never deleted
#    • ~/.zshrc and ~/.p10k.zsh are only installed when absent
#    • the current theme is kept unless none has been selected yet
#
#  Options:
#    --no-theme   Do not apply the default theme (the top-level installer
#                 decides that itself, after deploying the shell).
#    --help
# =============================================================

set -e

# Resolve the script's directory so it works regardless of cwd
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$SCRIPT_DIR"
CONFIG_DIR="$HOME/.config"
DEFAULT_THEME="catppuccin"
APPLY_THEME=1

for arg in "$@"; do
    case "$arg" in
        --no-theme) APPLY_THEME=0 ;;
        -h|--help)
            sed -n '2,17p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
            exit 0
            ;;
        *)
            echo "⚠️  Unknown option: $arg (ignored)"
            ;;
    esac
done

echo "🌸 HyprZen Install"
echo "══════════════════"

# ── Helpers ──────────────────────────────────────────────────
# Move a real path out of the way with a timestamp. Symlinks are simply
# removed: their target is the repo (or another config) and backing up a
# link adds nothing. Never deletes a real directory.
backup_existing() {
    local path="$1"
    if [ -L "$path" ]; then
        rm -f "$path"
        echo "  removed symlink: $path"
    elif [ -e "$path" ]; then
        local bak="${path}.bak.$(date +%Y%m%d_%H%M%S)"
        mv "$path" "$bak"
        echo "  backed up: $path  →  $bak"
    fi
}

link_config() {
    local src="$1" dst="$2"
    mkdir -p "$(dirname "$dst")"
    if [ -L "$dst" ] && [ "$(readlink -f "$dst")" = "$(readlink -f "$src")" ]; then
        echo "  linked: $dst (already)"
        return
    fi
    backup_existing "$dst"
    ln -sfn "$src" "$dst"
    echo "  linked: $dst → $src"
}

# Install a file only when the destination does not exist. Existing shell
# configs often carry machine-specific exports (LANG, tool paths); overwriting
# them on every install is how a working shell gets broken by an "update".
install_if_missing() {
    local src="$1" dst="$2"
    if [ -e "$dst" ] || [ -L "$dst" ]; then
        if cmp -s "$src" "$dst" 2> /dev/null; then
            echo "  unchanged: $dst"
        else
            echo "  kept: $dst (differs from repo — not overwriting)"
        fi
        return
    fi
    cp "$src" "$dst"
    echo "  installed: $dst"
}

# ── Step 1: Stop Caelestia / old shell components ────────────
echo ""
echo "🗑  Stopping old shell processes..."

# Only stop the setup being replaced. A blanket `pkill -x quickshell` also
# killed a running ZenShell install, leaving the desktop without a bar until
# the next login. Caelestia's quickshell process carries "caelestia" on its
# command line, so the -f match catches it without touching ZenShell.
for proc in caelestia hyprshell; do
    pkill -x "$proc" 2> /dev/null && echo "  killed: $proc" || true
done
pkill -f 'quickshell.*caelestia' 2> /dev/null && echo "  killed: caelestia (quickshell)" || true

# ── Step 2: Back up the Caelestia config dir ─────────────────
if [ -d "$CONFIG_DIR/caelestia" ] || [ -L "$CONFIG_DIR/caelestia" ]; then
    backup_existing "$CONFIG_DIR/caelestia"
fi

# ── Step 3: Symlink HyprZen configs ──────────────────────────
echo ""
echo "🔗 Linking HyprZen configs..."

# Link whole config dirs. A pre-existing real dir is backed up first, so a
# fresh clone never destroys a working hand-made config.
link_config "$DOTFILES_DIR/.config/hypr"    "$CONFIG_DIR/hypr"
link_config "$DOTFILES_DIR/.config/kitty"   "$CONFIG_DIR/kitty"
link_config "$DOTFILES_DIR/.config/matugen" "$CONFIG_DIR/matugen"
# Link only gtk.css, not the whole gtk-{3,4}.0 dirs: they also hold per-user
# state (settings.ini, bookmarks, recently-used.xbel) that must not live in git.
link_config "$DOTFILES_DIR/.config/gtk-3.0/gtk.css" "$CONFIG_DIR/gtk-3.0/gtk.css"
link_config "$DOTFILES_DIR/.config/gtk-4.0/gtk.css" "$CONFIG_DIR/gtk-4.0/gtk.css"
link_config "$DOTFILES_DIR/.config/wlogout" "$CONFIG_DIR/wlogout"
link_config "$DOTFILES_DIR/.config/fastfetch" "$CONFIG_DIR/fastfetch"
link_config "$DOTFILES_DIR/.config/wal"     "$CONFIG_DIR/wal"
link_config "$DOTFILES_DIR/.config/nvim"    "$CONFIG_DIR/nvim"
# The system typography — Google Sans Flex as the UI face. Link the single
# file rather than the whole fontconfig dir, which also holds user state.
link_config "$DOTFILES_DIR/.config/fontconfig/fonts.conf" "$CONFIG_DIR/fontconfig/fonts.conf"

# ── Step 4: Zsh config ───────────────────────────────────────
echo ""
echo "🐚 Installing zsh config..."
# These are real files, not links, because zsh/p10k expect writable files and
# users routinely edit them. Keep an existing file; a reinstall must not
# clobber machine-specific exports.
install_if_missing "$DOTFILES_DIR/.config/zsh/.zshrc" "$HOME/.zshrc"
install_if_missing "$DOTFILES_DIR/.config/zsh/p10k.zsh" "$HOME/.p10k.zsh"

# ── Step 5: Install scripts ──────────────────────────────────
echo ""
echo "📜 Installing scripts..."
link_config "$DOTFILES_DIR/scripts" "$HOME/scripts"
find "$HOME/scripts/" -maxdepth 1 -type f -name '*.sh' -exec chmod +x {} +
echo "  linked: ~/scripts/"

# ── Step 6: Install curated wallpapers / screenshot dirs ─────
mkdir -p "$HOME/wallpapers"
mkdir -p "$HOME/screenshots"
echo "  created: ~/wallpapers/  ~/screenshots/"
echo ""
echo "🖼️  Installing categorized wallpapers (keeping existing files)..."
# -n: never overwrite a wallpaper the user picked or added themselves.
cp -rn "$DOTFILES_DIR/wallpapers/." "$HOME/wallpapers/" 2> /dev/null \
    || echo "  ⚠️  No local wallpapers found to install."

# ── Step 7: Apply default theme (only on a fresh install) ────
echo ""
if [ "$APPLY_THEME" -eq 0 ]; then
    echo "🎨 Theme left to the top-level installer."
elif [ -f "$CONFIG_DIR/hypr/themes/current_theme.lua" ]; then
    echo "🎨 Keeping current theme ($(sed -n 's/.*themes\.\([^"]*\)").*/\1/p' "$CONFIG_DIR/hypr/themes/current_theme.lua" | head -n 1))."
elif [ -f "$HOME/scripts/theme-switch.sh" ]; then
    echo "🎨 No theme selected yet — applying default: $DEFAULT_THEME"
    # theme-switch.sh may fail when running outside a desktop session
    # (e.g., no Hyprland / Wayland display). Don't let that abort install.
    "$HOME/scripts/theme-switch.sh" "$DEFAULT_THEME" || echo "⚠️  theme-switch.sh exited with errors (this is normal if not in a desktop session)."
else
    echo "⚠️  theme-switch.sh not found, skipping default theme setup."
fi

echo ""
echo "✅ Done! Next steps:"
echo "   1. Ensure required packages are installed: (see README.md)"
echo "      e.g., Hyprland, kitty, quickshell, awww, python-pywal16"
echo "   2. Log in to Hyprland (or restart: hyprctl reload)"
echo "   3. Switch themes: Super+T (island)  or  ~/scripts/theme-switch.sh <theme>"
echo "   4. Pick wallpapers: Super+W (island)  or  ~/scripts/wallpaper-selector.sh set <path>"
