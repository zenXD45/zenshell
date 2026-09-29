#!/usr/bin/env bash
# =============================================================
#  HyprZen Full Setup Script
#  1. Installs all required dependencies (Arch Linux)
#  2. Runs the install.sh script to link configs
# =============================================================

set -e

echo "🌸 Starting HyprZen Setup..."

# Ensure we are on an Arch-based distro
if ! command -v pacman &> /dev/null; then
    echo "❌ Error: This script requires an Arch-based distribution (pacman not found)."
    exit 1
fi

echo "📦 Installing dependencies..."

# ── 1. Core Hyprland & Wayland UI ──
# waybar + rofi were removed — ZenShell (island/dock/spotlight) is
# the default bar/launcher now.
PKGS="hyprland hyprlock hypridle hyprsunset kitty"

# ── 2. Utilities (Screenshots, Audio, Info, File Manager, Power) ──
PKGS="$PKGS cliphist wl-clipboard playerctl btop pavucontrol fastfetch cava thunar power-profiles-daemon neovim ripgrep fd npm jq awww cmake cpio pkgconf gcc make unzip wget"

# ── 3. Fonts ──
PKGS="$PKGS ttf-jetbrains-mono-nerd"

echo "Running pacman to install official packages..."
sudo pacman -S --needed --noconfirm $PKGS

# ── 4. AUR / Extra Packages ──
# Some of these may be in the official repos on CachyOS or need an AUR helper.
# wlogout and pywal are no longer in official Arch repos (dropped upstream),
# so they live here; --needed handles overlap with official packages.
# quickshell-git is REQUIRED (the stable 'quickshell' package conflicts).
AUR_PKGS="quickshell-git hyprswitch matugen satty hyprshot waypaper wlogout pywal adw-gtk3 bibata-cursor-theme"

if command -v yay &> /dev/null; then
    echo "Running yay to install AUR packages..."
    yay -S --needed --noconfirm $AUR_PKGS
elif command -v paru &> /dev/null; then
    echo "Running paru to install AUR packages..."
    paru -S --needed --noconfirm $AUR_PKGS
else
    echo "⚠️  AUR helper (yay/paru) not found!"
    echo "   Please manually install these packages from the AUR if they failed above: $AUR_PKGS"
fi

echo "✅ Dependencies installed successfully!"
echo ""

echo "🔤 Installing GeistMono Nerd Font..."
FONT_DIR="$HOME/.local/share/fonts/GeistMono"
if [ ! -d "$FONT_DIR" ]; then
    mkdir -p "$FONT_DIR"
    wget -q --show-progress -O /tmp/GeistMono.zip "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/GeistMono.zip"
    unzip -q /tmp/GeistMono.zip -d "$FONT_DIR"
    rm /tmp/GeistMono.zip
    fc-cache -fv &>/dev/null
    echo "✅ GeistMono Nerd Font installed!"
else
    echo "✅ GeistMono Nerd Font already installed."
fi
echo ""

echo "🧩 Installing Hyprland Plugins..."
if command -v hyprpm &> /dev/null; then
    hyprpm update || true
    hyprpm add https://github.com/yayuuu/hyprland-scroll-overview.git || true
    hyprpm enable scrolloverview || true
    echo "✅ Hyprland plugins installed!"
else
    echo "⚠️  hyprpm not found. Please install hyprland headers/plugins manager."
fi

echo ""
echo "🔗 Proceeding to link configurations..."

# Run the existing symlink installer
if [ -f "./install.sh" ]; then
    chmod +x ./install.sh
    ./install.sh
else
    echo "❌ Error: install.sh not found in the current directory."
    exit 1
fi

echo "🎉 All done! You can now log into Hyprland."
