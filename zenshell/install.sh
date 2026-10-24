#!/bin/bash
# Zen Shell - One-Click Installation Script
# Part of the HyprZen monorepo (https://github.com/zenXD45/zenshell)
#
# Usage:
#   bash install.sh                 # install / update ZenShell
#   bash install.sh --with-camera   # + Camera Effects daemon and virtual camera
#   bash install.sh --help
#
# Re-running is safe: the code is refreshed, but shell_settings.json and the
# dock's pinned apps are preserved. When this script is run from the deployed
# directory itself, it updates in place instead of moving its own cwd away.

set -e

WITH_CAMERA=0
for arg in "$@"; do
    case "$arg" in
        --with-camera) WITH_CAMERA=1 ;;
        -h|--help)
            sed -n '2,13p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
            exit 0
            ;;
        *)
            echo "Unknown option: $arg" >&2
            exit 2
            ;;
    esac
done

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

if [ "$(id -u)" -eq 0 ]; then
    print_error "Do not run as root. Run as your normal user; sudo is used internally."
fi
if ! command -v pacman &> /dev/null; then
    print_error "This installer targets Arch-based distributions (pacman not found)."
fi

# --- AUR Helper ---
# ZenShell itself is all official packages. A helper is still bootstrapped
# (when possible) because the repo's other installers and the camera setup may
# need AUR builds; a missing helper must not stop a shell-only install.
AUR_HELPER=""
if command -v paru &> /dev/null; then
    AUR_HELPER="paru"
elif command -v yay &> /dev/null; then
    AUR_HELPER="yay"
else
    print_info "No AUR helper found — bootstrapping paru-bin..."
    sudo -v || true
    PARU_BUILD="$(mktemp -d "${TMPDIR:-/tmp}/zenshell-paru.XXXXXX")"
    if command -v git &> /dev/null && command -v makepkg &> /dev/null \
        && git clone --depth=1 https://aur.archlinux.org/paru-bin.git "$PARU_BUILD/paru-bin" &> /tmp/zenshell-paru-clone.log \
        && ( cd "$PARU_BUILD/paru-bin" && makepkg -si --noconfirm &> /tmp/zenshell-paru-build.log ); then
        AUR_HELPER="paru"
        print_success "paru installed."
    else
        print_warn "Could not bootstrap paru (logs: /tmp/zenshell-paru-*.log). Continuing without AUR."
    fi
    rm -rf "$PARU_BUILD"
fi
if [ -n "$AUR_HELPER" ]; then
    print_info "Using AUR helper: ${BOLD}$AUR_HELPER${NC}"
fi

# --- Dependencies ---
# quickshell is in the official extra repo. quickshell-git (the old entry) is
# AUR-only and, on CachyOS, used to pull in Noctalia's fork instead of upstream.
DEPENDENCIES=(
    "git"
    "python"
    "python-dbus"
    "python-gobject"
    "quickshell"
    "qt6-5compat"
    "playerctl"
    "wl-clipboard"
    "cliphist"
    "bluez-utils"
    "networkmanager"
    "hypridle"
    "hyprlock"
    "socat"
    "jq"
    "awww"
    "matugen"
    "imagemagick"
    "libnotify"
    "upower"
    "brightnessctl"
    "hyprshot"
    "satty"
    "curl"
)

print_info "Checking system dependencies..."
for pkg in "${DEPENDENCIES[@]}"; do
    # pacman -T also succeeds when another package provides this name.
    if pacman -T "$pkg" &> /dev/null; then
        print_success "$pkg is already installed."
    else
        print_info "Installing $pkg..."
        sudo pacman -S --needed --noconfirm "$pkg"
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
SETTINGS_FILE="$HOME/.config/quickshell/shell_settings.json"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
SCRIPT_DIR="$(readlink -f "$SCRIPT_DIR")"

# Running from the deployed directory is the common `cd dynamic-island &&
# ./install.sh` case. Moving that directory into a backup would delete the
# script's own cwd and leave no install behind, so update in place instead.
IN_PLACE=0
if [ "$SCRIPT_DIR" = "$(readlink -f "$INSTALL_DIR" 2> /dev/null || echo "$INSTALL_DIR")" ]; then
    IN_PLACE=1
    print_success "Running from the install directory — updating in place."
fi

# The dock stores its pins inside the install tree. Preserve them across the
# refresh; otherwise every reinstall resets the user's dock.
PINNED_BAK=""
if [ "$IN_PLACE" -eq 0 ] && [ -f "$INSTALL_DIR/modules/dock/pinned_apps.json" ]; then
    PINNED_BAK="$(mktemp "${TMPDIR:-/tmp}/zenshell-pins.XXXXXX")"
    cp "$INSTALL_DIR/modules/dock/pinned_apps.json" "$PINNED_BAK"
fi

if [ "$IN_PLACE" -eq 0 ] && { [ -d "$INSTALL_DIR" ] || [ -L "$INSTALL_DIR" ]; }; then
    BACKUP_DIR="${INSTALL_DIR}_backup_$(date +%Y%m%d_%H%M%S)"
    print_warn "Existing Zen Shell installation found at $INSTALL_DIR"
    print_info "Backing up to $BACKUP_DIR..."
    mv "$INSTALL_DIR" "$BACKUP_DIR"
    print_success "Backup complete."
fi

# --- Copy / Clone the Shell ---
REPO_URL="https://github.com/zenXD45/zenshell.git"
TMP_CLONE="$HOME/.cache/hyprzen-install-zen"

if [ "$IN_PLACE" -eq 1 ]; then
    print_success "Files already in place."
elif [ -f "$SCRIPT_DIR/shell.qml" ]; then
    print_info "Local repository detected. Copying files to $INSTALL_DIR..."
    mkdir -p "$INSTALL_DIR"
    cp -r "$SCRIPT_DIR/." "$INSTALL_DIR"
else
    print_info "Cloning HyprZen monorepo..."
    mkdir -p "$HOME/.config/quickshell"
    rm -rf "$TMP_CLONE"
    git clone --depth 1 "$REPO_URL" "$TMP_CLONE"
    cp -r "$TMP_CLONE/zenshell" "$INSTALL_DIR"
    rm -rf "$TMP_CLONE"
fi

if [ -n "$PINNED_BAK" ]; then
    cp "$PINNED_BAK" "$INSTALL_DIR/modules/dock/pinned_apps.json"
    rm -f "$PINNED_BAK"
    print_success "Dock pins preserved."
fi

# Never ship stale bytecode: the repo may contain __pycache__ from local runs.
find "$INSTALL_DIR" -type d -name __pycache__ -prune -exec rm -rf {} + 2> /dev/null || true
find "$INSTALL_DIR" -type f -name '*.pyc' -delete 2> /dev/null || true

# Ensure scripts are executable
chmod +x "$INSTALL_DIR"/*.sh
chmod +x "$INSTALL_DIR"/scripts/*.sh 2> /dev/null || true
chmod +x "$INSTALL_DIR"/scripts/*.py 2> /dev/null || true
find "$INSTALL_DIR"/modules -type f \( -name '*.sh' -o -name '*.py' \) -exec chmod +x {} + 2> /dev/null || true

# shell_settings.json lives one level above the install dir. Seeding it turns
# the compiled defaults into real persisted settings; re-seeding it would undo
# the user's UI scale, motion and profile choices, so only create it once.
if [ -f "$SETTINGS_FILE" ]; then
    print_success "shell_settings.json already present — keeping your settings."
else
    mkdir -p "$(dirname "$SETTINGS_FILE")"
    cp "$INSTALL_DIR/shell_settings.json" "$SETTINGS_FILE"
    print_success "Seeded $SETTINGS_FILE"
fi

# --- Camera Effects (optional) ---
if [ "$WITH_CAMERA" -eq 1 ]; then
    print_info "Installing Camera Effects dependencies..."
    CAMERA_DEPS=("opencv" "onnxruntime-cpu" "v4l2loopback-dkms" "v4l2loopback-utils" "dkms" "ffmpeg" "easyeffects")
    for pkg in "${CAMERA_DEPS[@]}"; do
        if pacman -T "$pkg" &> /dev/null; then
            print_success "$pkg is already installed."
        elif pacman -Si "$pkg" &> /dev/null; then
            sudo pacman -S --needed --noconfirm "$pkg" \
                || print_warn "$pkg failed to install — the camera panel may not work."
        else
            print_warn "$pkg is not in the configured repos — skipping."
        fi
    done
    print_info "Building the camera-effects daemon..."
    "$INSTALL_DIR"/scripts/camera_effects_install.sh || print_warn "Camera Effects build failed; the panel can retry it."
    if [ -x "$HOME/.local/lib/camera-effects/camera-effects-setup" ] && command -v pkexec &> /dev/null; then
        print_info "Creating the virtual camera (asks for your password)..."
        pkexec "$HOME/.local/lib/camera-effects/camera-effects-setup" install \
            "$HOME/.local/lib/camera-effects/camera-effects-server" \
            "$HOME/.local/lib/camera-effects/camera-effects-setup" \
            || print_warn "Could not create the virtual camera yet; the panel can retry it."
    fi
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
