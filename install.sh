#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════
#   HyprZen Fusion — One-Shot Arch Installer
#
#   Installs the complete HyprZen desktop:
#     • HyprZen    — Hyprland rice (kitty,
#                    themes, scripts, wallpapers)
#     • ZenShell   — Quickshell Dynamic Island / Dock / Spotlight /
#                    Desktop Widgets suite (default bar + launcher)
#
#   From-scratch friendly: takes a bare Arch install and leaves you
#   with a working, themed Hyprland session. Tolerant of missing
#   AUR packages (warns, keeps going) so nothing dead-ends.
#
#   Re-running is safe: your current theme, shell settings and dock
#   pins are preserved, and only the code is refreshed.
#
#   Usage:
#     bash install.sh                 # install / update
#     bash install.sh --with-camera   # + virtual camera daemon
#     bash install.sh --theme noir    # force a theme on this run
#     bash install.sh --help
# ═══════════════════════════════════════════════════════════════════

set -euo pipefail

# ── Colors / helpers ────────────────────────────────────────────────
B='\033[0;34m'; G='\033[0;32m'; R='\033[0;31m'; Y='\033[1;33m'
C='\033[0;36m'; M='\033[0;35m'; N='\033[0m'; BD='\033[1m'

log()  { printf "${B}  ->${N} %b\n" "$*"; }
ok()   { printf "${G}  ok${N} %b\n" "$*"; }
warn() { printf "${Y}  !!${N} %b\n" "$*"; }
err()  { printf "${R}  xx${N} %b\n" "$*"; }
step() { printf "\n${M}──────────────────────────────────────────────${N}\n${C}${BD}%b${BD}${N}\n${M}──────────────────────────────────────────────${N}\n" "$*"; }

banner() {
    if command -v figlet &> /dev/null; then
        figlet "HyprZen Fusion" | sed 's/^/    /'
    elif command -v toilet &> /dev/null; then
        toilet -f mono12 "HyprZen Fusion" | sed 's/^/    /'
    else
        cat <<'EOF'
    ┌──────────────────────────────────────────────┐
    │            H Y P R Z E N   F U S I O N        │
    │   Hyprland rice + Quickshell Dynamic Island  │
    └──────────────────────────────────────────────┘
EOF
    fi
    printf "      %bHyprZen (rice) + ZenShell (island/dock/spotlight)%b\n" "$C" "$N"
}

usage() {
    cat <<'EOF'
HyprZen Fusion installer

Usage:
  bash install.sh [options]

Options:
  --with-camera       Also build the Camera Effects daemon and load the
                      v4l2loopback virtual camera. Adds OpenCV, onnxruntime,
                      ffmpeg, EasyEffects and the kernel module (~140 MB).
  --theme <name>      Apply this theme after installing instead of keeping
                      the current one. Fresh installs default to catppuccin.
  -h, --help          Show this help.

The installer is idempotent. On a re-run it refreshes the code, but keeps
~/.config/quickshell/shell_settings.json, the dock's pinned apps and your
current HyprZen theme.
EOF
}

# ── Arguments ───────────────────────────────────────────────────────
WITH_CAMERA=0
THEME_OVERRIDE=""
while [ "$#" -gt 0 ]; do
    case "$1" in
        --with-camera) WITH_CAMERA=1 ;;
        --theme)
            if [ "$#" -lt 2 ]; then
                err "--theme needs a theme name."
                exit 2
            fi
            THEME_OVERRIDE="$2"
            shift
            ;;
        --theme=*) THEME_OVERRIDE="${1#*=}" ;;
        -h|--help) usage; exit 0 ;;
        *)
            err "Unknown option: $1"
            usage
            exit 2
            ;;
    esac
    shift
done

# ── Resolve script location ─────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
REPO_HYPRZEN="$SCRIPT_DIR/hyprzen"
REPO_ZENSHELL="$SCRIPT_DIR/zenshell"
DEFAULT_THEME="catppuccin"
QS_PARENT="$HOME/.config/quickshell"
QS_DEST="$QS_PARENT/dynamic-island"
QS_SETTINGS="$QS_PARENT/shell_settings.json"

# ── Preflight ───────────────────────────────────────────────────────
banner
printf "\n"

if [ "$(id -u)" -eq 0 ]; then
    err "Do not run as root. Run as your normal user; sudo is used internally."
    exit 1
fi
if ! command -v pacman &> /dev/null; then
    err "This installer targets Arch-based distributions (pacman not found)."
    exit 1
fi
for d in "$REPO_HYPRZEN" "$REPO_ZENSHELL"; do
    if [ ! -d "$d" ]; then
        err "Missing '$d'. Run this script from the root of the cloned HyprZen repo."
        exit 1
    fi
done

step "One-shot install: deps, configs, fonts, plugins, services, theme"
log "This installs packages and refreshes managed dotfiles."
log "Existing theme, shell settings and dock pins are kept on a re-run."
sudo -v || { err "sudo required."; exit 1; }
printf "  Ready. Starting install in a moment...\n"
sleep 2

# ── Package helpers ─────────────────────────────────────────────────
# `pacman -T` succeeds when a package is installed *or* provided by another
# package (e.g. qt6ct-kde provides qt6ct). `pacman -Qi` does not, which is why
# the old checks reinstalled packages that were already satisfied.
installed() { pacman -T "$1" &> /dev/null; }

# ── Official packages ───────────────────────────────────────────────
step "Official packages (pacman)"
OFFICIAL_PKGS=(
    # Window / compositor & core UI
    hyprland hyprlock hypridle hyprsunset kitty
    xdg-desktop-portal-hyprland xdg-desktop-portal-gtk
    # ZenShell needs NO waybar/rofi — the island + dock are the default.
    # Notifications are owned by ZenShell's island, not swaync.
    # Audio / OSD / input
    pipewire pipewire-pulse wireplumber pavucontrol playerctl brightnessctl
    # Clipboard / screenshot / clipboard utils
    cliphist wl-clipboard
    # System bits
    polkit-gnome network-manager-applet upower bluez-utils power-profiles-daemon
    socat inotify-tools xdg-utils libnotify glib2 pciutils
    # ZenShell Qt runtime (Qt5Compat.GraphicalEffects used by the island/dock)
    qt6-5compat
    # Qt app theming (qt6ct-kde also satisfies this)
    qt6ct
    # Wallpaper / theme pipeline (pywal itself is AUR — see install_pywal)
    awww imagemagick matugen
    # Screenshot helpers bound in the keybinds (waypaper is AUR)
    satty hyprshot
    # ZenShell's compositor runtime. This used to be `quickshell-git` in the AUR
    # because Noctalia's fork (noctalia-qs) had replaced upstream; upstream
    # quickshell is in extra now, so a fresh install neither builds from the AUR
    # nor drags Noctalia back in.
    quickshell
    # Terminal apps
    btop fastfetch cava thunar neovim
    # Desktop apps bound in modules/keybinds.lua (SUPER+B / SUPER+E / SUPER+C).
    # helium-browser-bin and vscodium-bin are AUR packages (see AUR_PKGS);
    # nautilus and firefox are official. The binaries the keybinds call are
    # helium-browser, nautilus and codium.
    nautilus firefox
    # Shell tools (used by the zsh aliases / fzf-tab)
    eza bat fzf
    # Toolchain (only needed for the AUR builds — hyprswitch, pywal, paru)
    base-devel git cmake cpio pkgconf gcc make unzip wget curl jq npm ripgrep fd rust
    # Networks
    impala
    # Fonts / GTK theming
    # adw-gtk-theme is the libadwaita GTK3 port your settings.ini/gsettings
    # already name as `adw-gtk3`/`adw-gtk3-dark`. It is what actually renders
    # themes/*.css for GTK apps, so without it every GTK app is unthemed and the
    # wlogout CSS is dead weight. It lives in extra since the 2026 move — the
    # AUR entry this installer used to carry (`adw-gtk3`) no longer exists.
    # JetBrainsMono Nerd is what kitty and ZenShell actually ask for by name;
    # Google Sans Flex is downloaded below because no distro ships it.
    adw-gtk-theme ttf-jetbrains-mono-nerd noto-fonts noto-fonts-emoji papirus-icon-theme
    # Python (monitors / control scripts)
    python python-dbus python-gobject
    # Shell
    zsh
    # GTK3 runtime for the GTK theme CSS imported by the dotfiles
    gtk3
)
log "Checking ${#OFFICIAL_PKGS[@]} official packages..."
# Filter through `pacman -T` first. `--needed` only skips an exact package name;
# it does not know that qt6ct-kde provides qt6ct or that hyprland-git provides
# hyprland. Passing those names in one transaction can produce a file conflict
# and abort *every* package in the list, so never hand pacman a satisfied name.
OFFICIAL_TODO=()
for pkg in "${OFFICIAL_PKGS[@]}"; do
    if ! installed "$pkg"; then
        OFFICIAL_TODO+=("$pkg")
    fi
done
if [ "${#OFFICIAL_TODO[@]}" -gt 0 ]; then
    log "${#OFFICIAL_TODO[@]} not yet satisfied — installing those..."
    sudo pacman -S --needed --noconfirm "${OFFICIAL_TODO[@]}"
else
    ok "All official packages already satisfied."
fi
ok "Official packages done."

# Optional official packages. Screen recording is a nice-to-have, not required
# for the desktop to start, so install these best-effort instead of letting one
# missing or failing package abort the run.
step "Optional packages"
OPTIONAL_PKGS=(gpu-screen-recorder gpu-screen-recorder-ui)
for pkg in "${OPTIONAL_PKGS[@]}"; do
    if installed "$pkg"; then
        ok "$pkg already installed."
    elif ! pacman -Si "$pkg" &> /dev/null; then
        warn "$pkg is not in the configured repos — skipping."
    elif sudo pacman -S --needed --noconfirm "$pkg" &> "/tmp/hyprzen-optional-$pkg.log"; then
        ok "$pkg installed."
    else
        warn "$pkg failed (see /tmp/hyprzen-optional-$pkg.log). Continuing."
    fi
done

# ── AUR helper ──────────────────────────────────────────────────────
step "AUR helper"
AUR_HELPER=""
if command -v paru &> /dev/null; then
    AUR_HELPER="paru"
elif command -v yay &> /dev/null; then
    AUR_HELPER="yay"
else
    # paru is AUR-only; `pacman -S paru` can never work. Bootstrap paru-bin
    # with makepkg (base-devel + git are installed above).
    log "No AUR helper found — bootstrapping paru-bin from the AUR..."
    sudo -v || true
    PARU_BUILD="$(mktemp -d "${TMPDIR:-/tmp}/hyprzen-paru.XXXXXX")"
    if git clone --depth=1 https://aur.archlinux.org/paru-bin.git "$PARU_BUILD/paru-bin" &> /tmp/hyprzen-paru-clone.log \
        && ( cd "$PARU_BUILD/paru-bin" && makepkg -si --noconfirm &> /tmp/hyprzen-paru-build.log ); then
        AUR_HELPER="paru"
        ok "paru installed."
    else
        warn "Could not bootstrap paru (logs: /tmp/hyprzen-paru-*.log)."
        warn "AUR packages will be skipped; install an AUR helper and re-run."
    fi
    rm -rf "$PARU_BUILD"
fi
if [ -n "$AUR_HELPER" ]; then
    ok "Using AUR helper: $AUR_HELPER"
fi

# ── AUR packages (tolerant) ─────────────────────────────────────────
step "AUR packages"
# Only what genuinely is AUR-only. quickshell, matugen, satty, hyprshot and
# adw-gtk-theme are in the official repos (see OFFICIAL_PKGS). waypaper,
# wlogout, helium-browser-bin and vscodium-bin are not — the old installer put
# them in the pacman list, so a fresh install failed on the first missing name.
AUR_PKGS=(
    hyprswitch
    bibata-cursor-theme
    waypaper
    wlogout
    helium-browser-bin
    vscodium-bin
)
FAILED_AUR=()

# CachyOS ships `vscodium` (repo) while Arch only has `vscodium-bin` (AUR).
# Both own /usr/bin/codium, so installing vscodium-bin on a CachyOS box would
# hit a file conflict. Treat a working codium binary as satisfied.
aur_satisfied() {
    case "$1" in
        vscodium-bin) command -v codium &> /dev/null ;;
        *) installed "$1" ;;
    esac
}

install_aur_one() {
    local pkg="$1"
    if aur_satisfied "$pkg"; then
        ok "$pkg already satisfied."
        return 0
    fi
    if [ -z "$AUR_HELPER" ]; then
        warn "$pkg needs an AUR helper — skipping."
        FAILED_AUR+=("$pkg")
        return 0
    fi
    log "Installing $pkg..."
    if "$AUR_HELPER" -S --needed --noconfirm "$pkg" &> "/tmp/hyprzen-aur-$pkg.log"; then
        ok "$pkg installed."
    else
        warn "$pkg failed (see /tmp/hyprzen-aur-$pkg.log). Continuing."
        FAILED_AUR+=("$pkg")
    fi
}

for pkg in "${AUR_PKGS[@]}"; do
    install_aur_one "$pkg"
done

# pywal: the old AUR `pywal` package was deleted. python-pywal16 is the
# maintained provider (python-pywal is the older fallback). Either one ships
# the `wal` binary that dynamic-colors.sh calls, so accept an existing `wal`
# even when it came from a distro package or a manual install.
install_pywal() {
    if command -v wal &> /dev/null; then
        ok "pywal already available ($(command -v wal))."
        return 0
    fi
    local candidate
    for candidate in python-pywal16 python-pywal; do
        if pacman -Si "$candidate" &> /dev/null; then
            log "Installing $candidate (official)..."
            if sudo pacman -S --needed --noconfirm "$candidate"; then
                ok "$candidate installed."
                return 0
            fi
        elif [ -n "$AUR_HELPER" ]; then
            log "Installing $candidate (AUR)..."
            if "$AUR_HELPER" -S --needed --noconfirm "$candidate" &> "/tmp/hyprzen-aur-$candidate.log"; then
                ok "$candidate installed."
                return 0
            fi
            warn "$candidate failed (see /tmp/hyprzen-aur-$candidate.log)."
        fi
    done
    warn "Could not install pywal — the dynamic theme will use bundled defaults."
    FAILED_AUR+=("python-pywal16")
}
install_pywal

if [ "${#FAILED_AUR[@]}" -gt 0 ]; then
    warn "Some AUR packages failed to build: ${FAILED_AUR[*]}"
    warn "You can retry later: ${AUR_HELPER:-paru} -S ${FAILED_AUR[*]}"
else
    ok "All AUR packages installed."
fi

# ── Fonts ───────────────────────────────────────────────────────────
step "Fonts (JetBrainsMono Nerd + Google Sans Flex)"

# JetBrainsMono Nerd Font — terminal + icon glyphs. Installed from the official
# repo above; this only reports it so the log is honest.
if fc-list 2> /dev/null | grep -qi 'JetBrainsMono.*Nerd'; then
    ok "JetBrainsMono Nerd Font available."
else
    warn "JetBrainsMono Nerd Font not found — kitty/ZenShell glyphs may fall back."
fi

# Google Sans Flex — the desktop's UI face. One variable font carrying the
# wght (100-900), wdth, opsz, slnt and ROND axes, so every weight the
# interface asks for is the same file rather than a dozen separate ones. It is
# not in any distro repo, so it is fetched from the google/fonts upstream and
# cached in the user's font dir. Keep this explicit: a partial install that
# silently falls back to a generic sans looks like a font bug that never
# reproduces.
GSF_DIR="$HOME/.local/share/fonts/GoogleSansFlex"
GSF_URL="https://github.com/google/fonts/raw/main/ofl/googlesansflex/GoogleSansFlex%5BROND%2Copsz%2Cslnt%2Cwdth%2Cwght%5D.ttf"
if fc-list 2> /dev/null | grep -qi 'Google Sans Flex'; then
    ok "Google Sans Flex UI font available."
else
    log "Downloading Google Sans Flex..."
    mkdir -p "$GSF_DIR"
    if curl -fL -o "$GSF_DIR/GoogleSansFlex.ttf" "$GSF_URL"; then
        fc-cache -f &> /dev/null || true
        ok "Google Sans Flex installed."
    else
        rm -f "$GSF_DIR/GoogleSansFlex.ttf"
        warn "Google Sans Flex download failed — the UI falls back to a generic sans."
    fi
fi

# ── Hyprland plugin ─────────────────────────────────────────────────
step "Scroll-overview plugin"
log "Adding hyprland-scroll-overview via hyprpm..."
hyprpm add https://github.com/yayuuu/hyprland-scroll-overview &> /tmp/hyprzen-hyprpm.log || warn "hyprpm add failed (log: /tmp/hyprzen-hyprpm.log)."
hyprpm enable scrolloverview &> /tmp/hyprzen-hyprpm-enable.log || warn "hyprpm enable failed (run at login; exec.lua reloads plugins on start)."

# ── GPU drivers ─────────────────────────────────────────────────────
step "GPU drivers"
if lspci 2> /dev/null | grep -Eiq 'vga.*nvidia|3d.*nvidia'; then
    log "NVIDIA GPU detected — installing nvidia-dkms + nvidia-utils."
    sudo pacman -S --needed --noconfirm nvidia-dkms nvidia-utils linux-headers \
        || warn "NVIDIA install failed; continue (Hyprland may still work via another GPU)."
    ok "NVIDIA drivers installed."
else
    ok "No NVIDIA GPU detected — skipping."
fi

# ── Oh My Zsh + Powerlevel10k ─────────────────────────────────
step "Oh My Zsh + Powerlevel10k"
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    log "Cloning oh-my-zsh..."
    git clone --depth=1 https://github.com/ohmyzsh/ohmyzsh.git "$HOME/.oh-my-zsh" \
        && ok "oh-my-zsh cloned." \
        || warn "oh-my-zsh clone failed — zsh config may not work."
else
    ok "oh-my-zsh already present."
fi

# p10k theme for OMZ
P10K_DIR="$HOME/.oh-my-zsh/custom/themes/powerlevel10k"
if [ ! -d "$P10K_DIR" ]; then
    log "Installing powerlevel10k theme..."
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$P10K_DIR" \
        && ok "powerlevel10k installed." \
        || warn "powerlevel10k clone failed."
else
    ok "powerlevel10k already present."
fi

# OMZ custom plugins (installed into ~/.oh-my-zsh/custom/plugins/)
OMZ_PLUGINS=(
    "zsh-autosuggestions|https://github.com/zsh-users/zsh-autosuggestions"
    "zsh-syntax-highlighting|https://github.com/zsh-users/zsh-syntax-highlighting"
    "zsh-completions|https://github.com/zsh-users/zsh-completions"
    "zsh-history-substring-search|https://github.com/zsh-users/zsh-history-substring-search"
    "fzf-tab|https://github.com/Aloxaf/fzf-tab"
)
for entry in "${OMZ_PLUGINS[@]}"; do
    name="${entry%%|*}"
    url="${entry##*|}"
    dest="$HOME/.oh-my-zsh/custom/plugins/$name"
    if [ ! -d "$dest" ]; then
        log "Installing plugin: $name..."
        git clone --depth=1 "$url" "$dest" 2>/dev/null \
            && ok "  $name installed." \
            || warn "  $name failed — install manually later."
    else
        ok "Plugin $name already present."
    fi
done

# Set default shell to zsh
CURRENT_SHELL="$(getent passwd "$USER" | cut -d: -f7)"
if [ "$CURRENT_SHELL" != "$(command -v zsh)" ]; then
    log "Setting default shell to zsh..."
    chsh -s "$(command -v zsh)" 2>/dev/null \
        && ok "Default shell → zsh." \
        || warn "chsh failed — run: chsh -s \$(command -v zsh)"
else
    ok "Default shell already zsh."
fi

# ── Deploy HyprZen configs ──────────────────────────────────────────
step "HyprZen configs (symlinks + scripts + wallpapers)"
log "Running hyprzen/install.sh ..."
# --no-theme: the top-level installer decides whether to apply a theme, so a
# re-run does not reset the user's current theme to the default.
bash "$REPO_HYPRZEN/install.sh" --no-theme || warn "hyprzen/install.sh exited with errors."
ok "HyprZen configs deployed."

# ── Deploy ZenShell ─────────────────────────────────────────────────
step "ZenShell suite (Dynamic Island / Dock / Spotlight / Widgets)"
mkdir -p "$QS_PARENT"

# The dock writes its pins into the install directory. Preserve that one file
# across the code refresh — otherwise every reinstall silently unpins the
# user's apps back to the repo defaults.
PINNED_BAK=""
if [ -f "$QS_DEST/modules/dock/pinned_apps.json" ]; then
    PINNED_BAK="$(mktemp "${TMPDIR:-/tmp}/hyprzen-pins.XXXXXX")"
    cp "$QS_DEST/modules/dock/pinned_apps.json" "$PINNED_BAK"
fi

if [ -d "$QS_DEST" ] || [ -L "$QS_DEST" ]; then
    bak="${QS_DEST}.bak.$(date +%Y%m%d_%H%M%S)"
    log "Existing install found — backing up to $bak"
    mv "$QS_DEST" "$bak"
fi
cp -r "$REPO_ZENSHELL" "$QS_DEST"

if [ -n "$PINNED_BAK" ]; then
    cp "$PINNED_BAK" "$QS_DEST/modules/dock/pinned_apps.json"
    rm -f "$PINNED_BAK"
    ok "Dock pins preserved."
fi

# Python leaves __pycache__ inside the repo when its scripts have been run.
# Copying it into the install makes stale bytecode look newer than edited
# sources, so ship source only.
find "$QS_DEST" -type d -name __pycache__ -prune -exec rm -rf {} + 2> /dev/null || true
find "$QS_DEST" -type f -name '*.pyc' -delete 2> /dev/null || true

chmod +x "$QS_DEST"/*.sh
chmod +x "$QS_DEST"/scripts/*.sh "$QS_DEST"/scripts/*.py 2> /dev/null || true
find "$QS_DEST/modules" -type f \( -name '*.sh' -o -name '*.py' \) -exec chmod +x {} + 2> /dev/null || true
ok "ZenShell deployed to $QS_DEST"

# shell_settings.json is read by shell.qml and modules/dock/shell.qml from
# ~/.config/quickshell/ — one level ABOVE the dynamic-island directory.
# Re-seeding it on every run would undo the user's UI scale, motion and
# profile choices, so only create it when it does not exist yet.
if [ -f "$QS_SETTINGS" ]; then
    ok "shell_settings.json already present — leaving your choices alone."
else
    cp "$REPO_ZENSHELL/shell_settings.json" "$QS_SETTINGS"
    ok "Seeded $QS_SETTINGS"
fi

# ── Camera Effects (optional) ───────────────────────────────────────
if [ "$WITH_CAMERA" -eq 1 ]; then
    step "Camera Effects (virtual camera + microphone)"
    CAMERA_PKGS=(opencv onnxruntime-cpu v4l2loopback-dkms v4l2loopback-utils dkms ffmpeg easyeffects)
    for pkg in "${CAMERA_PKGS[@]}"; do
        if installed "$pkg"; then
            ok "$pkg already installed."
        elif pacman -Si "$pkg" &> /dev/null && sudo pacman -S --needed --noconfirm "$pkg"; then
            ok "$pkg installed."
        else
            warn "$pkg failed to install — the camera panel may not work."
        fi
    done
    log "Building the camera-effects daemon..."
    "$QS_DEST/scripts/camera_effects_install.sh" \
        && ok "camera-effects built." \
        || warn "Camera Effects build failed; the panel can retry it."
    if [ -x "$HOME/.local/lib/camera-effects/camera-effects-setup" ] && command -v pkexec &> /dev/null; then
        log "Creating the virtual camera (asks for your password)..."
        pkexec "$HOME/.local/lib/camera-effects/camera-effects-setup" install \
            "$HOME/.local/lib/camera-effects/camera-effects-server" \
            "$HOME/.local/lib/camera-effects/camera-effects-setup" \
            || warn "Could not create the virtual camera yet; the panel can retry it."
    fi
fi

# ── Theme ───────────────────────────────────────────────────────────
step "Theme"
CURRENT_THEME_FILE="$HOME/.config/hypr/themes/current_theme.lua"
THEMES_JSON="$HOME/.config/hypr/themes/themes.json"

current_theme_name() {
    [ -f "$CURRENT_THEME_FILE" ] || return 0
    sed -n 's/.*require("themes\.\([^"]*\)").*/\1/p' "$CURRENT_THEME_FILE" | head -n 1
}

theme_is_valid() {
    local name="$1"
    [ -n "$name" ] || return 1
    [ -f "$THEMES_JSON" ] || return 0
    jq -e --arg id "$name" 'any(.[]; .id == $id)' "$THEMES_JSON" &> /dev/null
}

apply_theme() {
    local name="$1"
    if [ -f "$HOME/scripts/theme-switch.sh" ]; then
        "$HOME/scripts/theme-switch.sh" "$name" \
            && ok "Theme $name applied." \
            || warn "theme-switch.sh had issues (normal outside a desktop session)."
    else
        warn "~/.config/hypr not linked? theme-switch.sh missing. Configs must be linked."
    fi
}

if [ -n "$THEME_OVERRIDE" ]; then
    if theme_is_valid "$THEME_OVERRIDE"; then
        EFFECTIVE_THEME="$THEME_OVERRIDE"
        apply_theme "$EFFECTIVE_THEME"
    elif [ -f "$CURRENT_THEME_FILE" ]; then
        EFFECTIVE_THEME="$(current_theme_name)"
        warn "Unknown theme '$THEME_OVERRIDE' — keeping $EFFECTIVE_THEME."
    else
        EFFECTIVE_THEME="$DEFAULT_THEME"
        warn "Unknown theme '$THEME_OVERRIDE' — applying $DEFAULT_THEME instead."
        apply_theme "$EFFECTIVE_THEME"
    fi
elif [ -f "$CURRENT_THEME_FILE" ]; then
    EXISTING_THEME="$(current_theme_name)"
    if theme_is_valid "$EXISTING_THEME"; then
        EFFECTIVE_THEME="$EXISTING_THEME"
        ok "Existing theme preserved: $EFFECTIVE_THEME"
    else
        EFFECTIVE_THEME="$DEFAULT_THEME"
        warn "Current theme '${EXISTING_THEME:-unknown}' is not in themes.json — applying $DEFAULT_THEME."
        apply_theme "$EFFECTIVE_THEME"
    fi
else
    EFFECTIVE_THEME="$DEFAULT_THEME"
    log "No theme selected yet — applying default: $DEFAULT_THEME"
    apply_theme "$EFFECTIVE_THEME"
fi

if [ ! -e "$HOME/wallpapers/current" ]; then
    log "Setting a default wallpaper for $EFFECTIVE_THEME..."
    WALL="$(find "$HOME/wallpapers/$EFFECTIVE_THEME" -type f \( -iname '*.jpg' -o -iname '*.png' -o -iname '*.webp' \) 2> /dev/null | head -n 1 || true)"
    if [ -n "$WALL" ]; then
        ln -sf "$WALL" "$HOME/wallpapers/current"
        ok "Default wallpaper set: $WALL"
    else
        warn "No wallpapers found for $EFFECTIVE_THEME — pick one later with Super+W (island picker)."
    fi
else
    ok "Wallpaper already set."
fi

# ── Services ────────────────────────────────────────────────────────
step "Enable system services"
sudo systemctl enable --now NetworkManager.service 2> /dev/null && ok "NetworkManager enabled" || warn "NetworkManager: skipped/failed"
sudo systemctl enable --now bluetooth.service 2> /dev/null && ok "bluetooth enabled" || warn "bluetooth: skipped/failed"
sudo systemctl enable --now power-profiles-daemon.service 2> /dev/null && ok "power-profiles-daemon enabled" || warn "power-profiles-daemon: skipped/failed"
log "Starting pipewire session services (idempotent)..."
systemctl --user enable --now pipewire.socket pipewire-pulse.socket wireplumber.service 2> /dev/null \
    && ok "pipewire session services enabled" || warn "pipewire session services: skipped (are you in a running session?)"

# ── Verification ────────────────────────────────────────────────────
step "Verification"
pass=0; fail=0
check() { # check <desc> <cmd...>
    local desc="$1"; shift
    if "$@" &> /dev/null; then
        ok "$desc"
        pass=$((pass+1))
    else
        warn "$desc — not found"
        fail=$((fail+1))
    fi
}
check "hyprland"        sh -c 'command -v Hyprland'
check "quickshell"      sh -c 'command -v quickshell'
check "kitty"           sh -c 'command -v kitty'
check "hypridle"        sh -c 'command -v hypridle'
check "hyprlock"        sh -c 'command -v hyprlock'
check "hypr [$HOME/.config/hypr]"   sh -c '[ -e "$HOME/.config/hypr" ]'
check "scripts [$HOME/scripts]"     sh -c '[ -e "$HOME/scripts" ]'
# Use $HOME inside the single-quoted script rather than $QS_DEST: QS_DEST is a
# shell variable of this installer, not an exported one, so the old checks
# expanded to an empty path and always failed.
check "zen shell"                   sh -c '[ -f "$HOME/.config/quickshell/dynamic-island/shell.qml" ]'
check "theme current_theme.lua"     sh -c '[ -f "$HOME/.config/hypr/themes/current_theme.lua" ]'
check "cliphist"        sh -c 'command -v cliphist'
check "zsh"             sh -c 'command -v zsh'
check "oh-my-zsh"       sh -c '[ -d "$HOME/.oh-my-zsh" ]'
check "powerlevel10k"   sh -c '[ -d "$HOME/.oh-my-zsh/custom/themes/powerlevel10k" ]'

# Everything below was previously assumed to be present and was never verified.
# Each of these has actually caused a silently broken feature on a fresh install,
# so they are checked explicitly rather than left to chance.
check "wallpapers [$HOME/wallpapers]"      sh -c '[ -d "$HOME/wallpapers" ] && [ -n "$(ls -A "$HOME/wallpapers" 2>/dev/null)" ]'
check "hypridle config"                    sh -c '[ -f "$HOME/.config/hypr/hypridle.conf" ]'
check "hyprlock config"                    sh -c '[ -f "$HOME/.config/hypr/hyprlock.conf" ]'
check "theme sources"                      sh -c '[ -n "$(ls "$HOME/.config/hypr/themes/source/"*.toml 2>/dev/null)" ]'
check "Google Sans Flex font (ZenShell UI)" sh -c 'fc-list 2>/dev/null | grep -qi "Google Sans Flex"'
check "JetBrainsMono Nerd font (kitty/icons)" sh -c 'fc-list 2>/dev/null | grep -qi "JetBrainsMono.*Nerd"'
# Re-enabled: this check was commented out because adw-gtk3 could never install
# (the AUR name it used was gone). It installs from extra as adw-gtk-theme now,
# so the check tests for the theme directory the dotfiles actually reference.
check "adw-gtk3 theme (GTK theming)"       sh -c '[ -d /usr/share/themes/adw-gtk3-dark ]'
check "wlogout (SUPER+X)"                  sh -c 'command -v wlogout'
check "pywal (dynamic theme)"              sh -c 'command -v wal'
check "matugen (wallpaper theme)"          sh -c 'command -v matugen'
check "waypaper"                           sh -c 'command -v waypaper'
check "hyprshot (screenshots)"             sh -c 'command -v hyprshot'
check "hyprswitch (SUPER+ALT+TAB)"         sh -c 'command -v hyprswitch'
check "keybind binary: kitty"              sh -c 'command -v kitty'
check "keybind binary: helium-browser"      sh -c 'command -v helium-browser'
check "keybind binary: nautilus"           sh -c 'command -v nautilus'
check "keybind binary: codium"             sh -c 'command -v codium'
check "keybind binary: wlogout"            sh -c 'command -v wlogout'
check "zen shell themes.json"              sh -c '[ -f "$HOME/.config/hypr/themes/themes.json" ]'
check "dock pins file"                     sh -c '[ -f "$HOME/.config/quickshell/dynamic-island/modules/dock/pinned_apps.json" ]'
check "zen shell get_themes.py runs"       sh -c 'python3 "$HOME/.config/quickshell/dynamic-island/scripts/get_themes.py" >/dev/null 2>&1'
check "zen shell get_wallpapers.py runs"   sh -c 'python3 "$HOME/.config/quickshell/dynamic-island/scripts/get_wallpapers.py" >/dev/null 2>&1'
check "shell_settings.json seeded"         sh -c '[ -f "$HOME/.config/quickshell/shell_settings.json" ]'
if [ "$WITH_CAMERA" -eq 1 ]; then
    check "camera-effects daemon"          sh -c '[ -x "$HOME/.local/lib/camera-effects/camera-effects-server" ]'
fi

printf "\n${G}${BD}Checks passed: ${pass}${N}${R}${BD}   Failed: ${fail}${N}\n"

# ── Restart ZenShell in a live session ──────────────────────────────
# The config installer no longer kills Quickshell, so the old shell survived
# the file refresh. Restart just the ZenShell configs (not any other
# Quickshell the user runs) so the new QML is what is actually on screen.
if [ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ] && [ -x "$QS_DEST/start_all.sh" ]; then
    step "Restart ZenShell"
    pkill -f "$QS_DEST" 2> /dev/null || true
    sleep 1
    if command -v setsid &> /dev/null; then
        setsid "$QS_DEST/start_all.sh" > /tmp/zenshell-restart.log 2>&1 < /dev/null &
        ok "ZenShell restarted (log: /tmp/zenshell-restart.log)."
    else
        nohup "$QS_DEST/start_all.sh" > /tmp/zenshell-restart.log 2>&1 < /dev/null &
        ok "ZenShell restarted (log: /tmp/zenshell-restart.log)."
    fi
fi

step "Done — reboot or restart"
cat <<'EOF'

    Next steps:
      1. Reboot, then log into the "Hyprland" session.
      2. Wallpaper picker:        Super+W
      3. Theme switcher:          Super+T
      4. Dynamic Island (the default launcher bar/UI):
           Launcher        Super+Space
           Control Center  Super+N
           Clipboard       Super+V
           Cheatsheet      Super+,
           Power menu      Super+Escape
           Power profiles  Super+Shift+P
           Shell profiles  Super+Alt+P
           Spotlight       Super+Shift+M
      5. zen shell autostart is wired into exec.lua (start_all.sh).

    If any AUR package failed, retry with:
         paru -S --needed <pkg...>
EOF
printf "\n"

if [ "${#FAILED_AUR[@]}" -gt 0 ]; then
    warn "AUR packages that did NOT install: ${FAILED_AUR[*]}"
fi
