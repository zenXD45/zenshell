#!/bin/bash
# Zen Shell - One-Click Installation Script
# Part of the HyprZen monorepo (https://github.com/zenXD45/zenshell)

set -e

# --with-camera also installs the Camera Effects daemon and its dependencies
# (OpenCV, onnxruntime and the v4l2loopback module: ~140 MB). It is opt-in
# because most installs never touch the virtual camera.
WITH_CAMERA=0
if [ "${1:-}" == "--with-camera" ]; then
    WITH_CAMERA=1
fi

# --- Colors and Formatting ---
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color
BOLD='\033[1m'

print_info() { echo -e "${BLUE}[*]${NC} $1"; }
print_success() { echo -e "${GREEN}[+]${NC} $1"; }
print_warn() { echo -e "${YELLOW}[!]${NC} $1"; }
print_error() { echo -e "${RED}[x]${NC} $1"; exit 1; }

echo -e "${CYAN}${BOLD}"
echo "=========================================="
echo "          Zen Shell Installer"
echo "=========================================="
echo -e "${NC}"

# --- Check AUR Helper ---
if command -v yay &> /dev/null; then
    AUR_HELPER="yay"
elif command -v paru &> /dev/null; then
    AUR_HELPER="paru"
else
    print_error "Neither 'yay' nor 'paru' was found. Please install one first."
fi

print_info "Using AUR helper: ${BOLD}$AUR_HELPER${NC}"

# --- Dependencies ---
DEPENDENCIES=(
    "git"
    "python"
    "python-dbus"
    "python-gobject"
    "playerctl"
    "wl-clipboard"
    "cliphist"
    "bluez-utils"
    "networkmanager"
    "hypridle"
    "hyprlock"
    "socat"
    "jq"
)

AUR_DEPENDENCIES=(
    "quickshell-git"
)

print_info "Checking system dependencies..."
for pkg in "${DEPENDENCIES[@]}"; do
    if pacman -Qs "^${pkg}$" &> /dev/null; then
        print_success "$pkg is already installed."
    else
        print_info "Installing $pkg..."
        sudo pacman -S --noconfirm "$pkg"
    fi
done

print_info "Checking AUR dependencies..."
for pkg in "${AUR_DEPENDENCIES[@]}"; do
    if pacman -Qs "^${pkg}$" &> /dev/null || pacman -Qm "^${pkg}$" &> /dev/null; then
        print_success "$pkg is already installed."
    else
        print_info "Installing $pkg from AUR..."
        $AUR_HELPER -S --noconfirm "$pkg"
    fi
done

# --- Google Sans Flex (the shell's UI face) ---
# One variable font carrying the wght, wdth, opsz, slnt and ROND axes, so
# every weight the interface asks for is the same file rather than a dozen
# separate ones. It is not in any distro repo, so it is fetched from the
# google/fonts upstream and cached in the user's font dir. Keep this explicit:
# a partial install that silently falls back to a generic sans looks like a
# font bug that never reproduces.
print_info "Checking Google Sans Flex..."
if fc-list 2> /dev/null | grep -qi 'Google Sans Flex'; then
    print_success "Google Sans Flex UI font available."
else
    GSF_DIR="$HOME/.local/share/fonts/GoogleSansFlex"
    GSF_URL="https://github.com/google/fonts/raw/main/ofl/googlesansflex/GoogleSansFlex%5BROND%2Copsz%2Cslnt%2Cwdth%2Cwght%5D.ttf"
    mkdir -p "$GSF_DIR"
    if curl -fL -o "$GSF_DIR/GoogleSansFlex.ttf" "$GSF_URL"; then
        fc-cache -f &> /dev/null || true
        print_success "Google Sans Flex installed."
    else
        rm -f "$GSF_DIR/GoogleSansFlex.ttf"
        print_warn "Google Sans Flex download failed - the UI falls back to a generic sans."
    fi
fi

# --- Setup Directories & Backup ---
INSTALL_DIR="$HOME/.config/quickshell/dynamic-island"

if [ -d "$INSTALL_DIR" ]; then
    BACKUP_DIR="${INSTALL_DIR}_backup_$(date +%Y%m%d_%H%M%S)"
    print_warn "Existing Zen Shell installation found at $INSTALL_DIR"
    print_info "Backing up to $BACKUP_DIR..."
    mv "$INSTALL_DIR" "$BACKUP_DIR"
    print_success "Backup complete."
fi

# --- Clone Repository ---
REPO_URL="https://github.com/zenXD45/zenshell.git"
print_info "Cloning HyprZen monorepo..."
TMP_CLONE="$HOME/.cache/hyprzen-install-zen"

# If the script is already inside the downloaded repo, we just copy it.
# Otherwise, we clone the monorepo (containing zenshell/).
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"

if [ -f "$SCRIPT_DIR/shell.qml" ] && [ "$SCRIPT_DIR" != "$INSTALL_DIR" ]; then
    print_info "Local repository detected. Copying files to $INSTALL_DIR..."
    mkdir -p "$HOME/.config/quickshell"
    cp -r "$SCRIPT_DIR" "$INSTALL_DIR"
elif [ "$SCRIPT_DIR" == "$INSTALL_DIR" ]; then
    print_success "Already running from the install directory!"
else
    mkdir -p "$HOME/.config/quickshell"
    rm -rf "$TMP_CLONE"
    git clone --depth 1 "$REPO_URL" "$TMP_CLONE"
    cp -r "$TMP_CLONE/zenshell" "$INSTALL_DIR"
    rm -rf "$TMP_CLONE"
fi

# Ensure scripts are executable
chmod +x "$INSTALL_DIR"/*.sh
chmod +x "$INSTALL_DIR"/scripts/*.sh 2>/dev/null || true
chmod +x "$INSTALL_DIR"/scripts/*.py 2>/dev/null || true
find "$INSTALL_DIR"/modules -type f \( -name "*.sh" -o -name "*.py" \) -exec chmod +x {} + 2>/dev/null || true

# --- Camera Effects (optional) ---
if [ "$WITH_CAMERA" == "1" ]; then
    print_info "Installing Camera Effects dependencies..."
    CAMERA_DEPS=("opencv" "onnxruntime-cpu" "v4l2loopback-dkms" "v4l2loopback-utils" "dkms")
    for pkg in "${CAMERA_DEPS[@]}"; do
        pacman -Qs "^${pkg}$" &> /dev/null || sudo pacman -S --noconfirm "$pkg"
    done
    print_info "Building the camera-effects daemon..."
    "$INSTALL_DIR"/scripts/camera_effects_install.sh || print_warn "Camera Effects build failed; the panel can retry it."
    print_info "Creating the virtual camera (asks for your password)..."
    pkexec "$HOME/.local/lib/camera-effects/camera-effects-setup" install \
        "$HOME/.local/lib/camera-effects/camera-effects-server" \
        "$HOME/.local/lib/camera-effects/camera-effects-setup" \
        || print_warn "Could not create the virtual camera yet; the panel can retry it."
fi

print_success "Zen Shell installed successfully!"

# --- Post-Installation Instructions ---
echo ""
echo -e "${CYAN}${BOLD}==========================================${NC}"
echo -e "${GREEN}Installation Complete!${NC}"
echo ""
echo -e "To start the entire Zen Shell Desktop Suite automatically, add this to your ${BOLD}hyprland.conf${NC} (or hyprland lua config):"
echo -e "${YELLOW}exec-once = ~/.config/quickshell/dynamic-island/start_all.sh${NC}"
echo ""
echo -e "Keybindings (ZenShell is the default UI — hyprzen ships no waybar/rofi/swaync):"
echo -e "  ${BOLD}App Launcher:${NC}      ${YELLOW}SUPER+Space → island_ctl.sh launcher${NC}"
echo -e "  ${BOLD}Cheatsheet:${NC}        ${YELLOW}SUPER+comma → island_ctl.sh cheatsheet${NC}"
echo -e "  ${BOLD}Clipboard:${NC}         ${YELLOW}SUPER+V → island_ctl.sh clipboard${NC}"
echo -e "  ${BOLD}Themes:${NC}            ${YELLOW}SUPER+T → island_ctl.sh themes${NC}"
echo -e "  ${BOLD}Wallpapers:${NC}        ${YELLOW}SUPER+W → island_ctl.sh wallpapers${NC}"
echo -e "  ${BOLD}Control Center:${NC}    ${YELLOW}SUPER+N → island_ctl.sh control${NC}"
echo -e "  ${BOLD}Power Menu:${NC}        ${YELLOW}SUPER+Escape → island_ctl.sh power${NC}"
echo -e "  ${BOLD}Power Profiles:${NC}    ${YELLOW}SUPER+SHIFT+P → island_ctl.sh powerprofile${NC}"
echo -e "  ${BOLD}Shell Profiles:${NC}    ${YELLOW}SUPER+ALT+P → island_ctl.sh profiles${NC}"
echo -e "  ${BOLD}Dock Auto-hide:${NC}    ${YELLOW}SUPER+ALT+D → island_ctl.sh dock${NC}"
echo -e "  ${BOLD}Dock Settings:${NC}     ${YELLOW}SUPER+ALT+SHIFT+D → island_ctl.sh dock-settings${NC}"
echo -e "  ${BOLD}Spotlight Search:${NC}  ${YELLOW}SUPER+SHIFT+M → modules/spotlight/toggle.sh${NC}"
echo -e "  ${BOLD}Camera Effects:${NC}   ${YELLOW}SUPER+ALT+C → island_ctl.sh camera${NC} (or the Camera tile in the notification center)"
echo -e "${CYAN}${BOLD}==========================================${NC}"
echo ""
