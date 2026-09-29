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
#   Usage:  bash install.sh
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

# ── Resolve script location ─────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
REPO_HYPRZEN="$SCRIPT_DIR/hyprzen"
REPO_ZENSHELL="$SCRIPT_DIR/zenshell"
DEFAULT_THEME="catppuccin"

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
log "This will install packages and overwrite existing dotfiles."
log "(Backups are taken where needed.)"
sudo -v || { err "sudo required."; exit 1; }
printf "  Ready. Starting install in a moment...\n"
sleep 2

# ── Official packages ───────────────────────────────────────────────
step "Official packages (pacman)"
OFFICIAL_PKGS=(
    # Window / compositor & core UI
    hyprland hyprlock hypridle hyprsunset kitty
    xdg-desktop-portal-hyprland
    # ZenShell needs NO waybar/rofi — the island + dock are the default.
    # Notifications are owned by ZenShell's island, not swaync.
    # Audio / OSD / input
    pipewire pipewire-pulse wireplumber pavucontrol playerctl brightnessctl
    # Clipboard / screenshot / clipboard utils
    cliphist wl-clipboard
    # System bits
    polkit-gnome network-manager-applet upower bluez-utils power-profiles-daemon
    socat inotify-tools xdg-utils libnotify glib2
    # ZenShell Qt runtime (Qt5Compat.GraphicalEffects used by the island/dock)
    qt6-5compat
    # Wallpaper / theme pipeline (pywal itself moved to the AUR — see AUR_PKGS)
    awww imagemagick
    # Terminal apps
    btop fastfetch cava thunar neovim
    # Desktop apps bound in modules/keybinds.lua (SUPER+B / SUPER+E / SUPER+C).
    # These must stay in sync with the keybinds or the binds are dead on arrival.
    firefox vscodium
    # Shell tools (used by the zsh aliases / fzf-tab)
    eza bat fzf
    # Toolchain (needed by AUR builds: matugen, quickshell)
    base-devel git cmake cpio pkgconf gcc make unzip wget curl jq npm ripgrep fd rust
    # Networks
    impala
    # Fonts / GTK theming
    # adw-gtk3 dropped from the official repos in 2026 — it lives in the AUR now.
    # It is what actually renders themes/*.css, so without it every GTK app is
    # unthemed and the wlogout CSS is dead weight.
    ttf-jetbrains-mono-nerd noto-fonts-emoji papirus-icon-theme
    # Python (monitors / control scripts)
    python python-dbus python-gobject
    # Shell
    zsh
)
log "Installing ${#OFFICIAL_PKGS[@]} official packages (--needed)..."
sudo pacman -S --needed --noconfirm "${OFFICIAL_PKGS[@]}"
ok "Official packages done."

# ── AUR helper ──────────────────────────────────────────────────────
step "AUR helper"
AUR_HELPER=""
if command -v paru &> /dev/null; then
    AUR_HELPER="paru"
elif command -v yay &> /dev/null; then
    AUR_HELPER="yay"
else
    log "No AUR helper found — installing paru (official repo)..."
    sudo pacman -S --needed --noconfirm paru
    AUR_HELPER="paru"
fi
ok "Using AUR helper: $AUR_HELPER"

# ── AUR packages (tolerant) ─────────────────────────────────────────
step "AUR packages"
# quickshell-git REQUIRED (conflicts with the older/stable 'quickshell').
# Everything else: helper + --needed skips whatever is already satisfied.
AUR_PKGS=(
    quickshell-git
    hyprswitch
    matugen
    satty
    hyprshot
    waypaper

    bibata-cursor-theme
    # These used to be referenced only from hyprzen/setup.sh, which the top-level
    # installer never ran — leaving wlogout/pywal/adw-gtk3 uninstalled while
    # keybinds, dynamic-colors.sh and every themes/*.css still expected them.
    wlogout
    pywal
    adw-gtk3
)
FAILED_AUR=()
for pkg in "${AUR_PKGS[@]}"; do
    if pacman -Qi "$pkg" &> /dev/null; then
        ok "$pkg already installed."
        continue
    fi
    log "Installing $pkg..."
    if $AUR_HELPER -S --needed --noconfirm "$pkg" &> /tmp/hyprzen-aur-$pkg.log; then
        ok "$pkg installed."
    else
        warn "$pkg failed (see /tmp/hyprzen-aur-$pkg.log). Continuing."
        FAILED_AUR+=("$pkg")
    fi
done
if [ "${#FAILED_AUR[@]}" -gt 0 ]; then
    warn "Some AUR packages failed to build: ${FAILED_AUR[*]}"
    warn "You can retry later: $AUR_HELPER -S ${FAILED_AUR[*]}"
else
    ok "All AUR packages installed."
fi

# ── Fonts ───────────────────────────────────────────────────────────
step "Fonts (GeistMono Nerd + Outfit)"

# GeistMono Nerd Font — terminal + icon glyphs.
FONT_DIR="$HOME/.local/share/fonts/GeistMonoNerdFont"
if fc-list 2> /dev/null | grep -qi 'GeistMono.*Nerd'; then
    ok "GeistMono Nerd Font already installed."
else
    log "Downloading GeistMono Nerd Font..."
    mkdir -p "$FONT_DIR"
    curl -fL -o /tmp/geistmono.zip \
        "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/GeistMono.zip" \
        && unzip -oq /tmp/geistmono.zip -d "$FONT_DIR" \
        && rm -f /tmp/geistmono.zip
    fc-cache -f &> /dev/null || true
    ok "Font cached."
fi

# Outfit — the UI font. ZenShell's QML hardcodes `font.family: "Outfit"` in ~89
# places; without this installed every string in the island, dock and control
# panel silently falls back to a generic sans, which is the single most obvious
# sign that the shell was not installed correctly.
#
# There is no Outfit package in the Arch repos (checked: `pacman -Ss outfit` is
# empty), so it is fetched straight from the upstream Google Fonts repository.
# This is the variable-weight build; the upstream repo publishes no static
# instances, and Qt6/fontconfig instance the weight axis fine.
if fc-list 2> /dev/null | grep -qi 'Outfit'; then
    ok "Outfit already installed."
else
    log "Installing Outfit (ZenShell UI font)..."
    OUTFIT_DIR="$HOME/.local/share/fonts/Outfit"
    mkdir -p "$OUTFIT_DIR"
    if curl -fL --retry 2 --connect-timeout 15 \
        -o "$OUTFIT_DIR/Outfit.ttf" \
        "https://raw.githubusercontent.com/google/fonts/main/ofl/outfit/Outfit%5Bwght%5D.ttf" \
        && [ -s "$OUTFIT_DIR/Outfit.ttf" ]; then
        fc-cache -f &> /dev/null || true
        if fc-list 2> /dev/null | grep -qi 'Outfit'; then
            ok "Outfit installed."
        else
            warn "Outfit downloaded but fontconfig did not pick it up."
        fi
    else
        rm -f "$OUTFIT_DIR/Outfit.ttf"
        warn "Could not download Outfit — ZenShell text will use a fallback font."
        warn "  Fix: place any Outfit .ttf in $OUTFIT_DIR and run 'fc-cache -f'."
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
if [ "$CURRENT_SHELL" != "$(which zsh)" ]; then
    log "Setting default shell to zsh..."
    chsh -s "$(which zsh)" 2>/dev/null \
        && ok "Default shell → zsh." \
        || warn "chsh failed — run: chsh -s \$(which zsh)"
else
    ok "Default shell already zsh."
fi

# ── Deploy HyprZen configs ──────────────────────────────────────────
step "HyprZen configs (symlinks + scripts + wallpapers)"
log "Running hyprzen/install.sh ..."
bash "$REPO_HYPRZEN/install.sh" || warn "hyprzen/install.sh exited with errors."
ok "HyprZen configs deployed."

# ── Deploy ZenShell ─────────────────────────────────────────────────
step "ZenShell suite (Dynamic Island / Dock / Spotlight / Widgets)"
QS_DEST="$HOME/.config/quickshell/dynamic-island"
mkdir -p "$HOME/.config/quickshell"
if [ -d "$QS_DEST" ]; then
    bak="${QS_DEST}.bak.$(date +%Y%m%d_%H%M%S)"
    log "Existing install found — backing up to $bak"
    mv "$QS_DEST" "$bak"
fi
cp -r "$REPO_ZENSHELL" "$QS_DEST"
chmod +x "$QS_DEST"/*.sh
chmod +x "$QS_DEST"/scripts/*.sh "$QS_DEST"/scripts/*.py 2> /dev/null || true
find "$QS_DEST/modules" -type f \( -name '*.sh' -o -name '*.py' \) -exec chmod +x {} + 2> /dev/null || true
ok "ZenShell deployed to $QS_DEST"

# shell_settings.json is read by shell.qml and modules/dock/shell.qml from
# ~/.config/quickshell/ — one level ABOVE the dynamic-island directory. Nothing
# in the repo used to create it, so the island and dock silently fell back to
# their compiled-in defaults and the user's choices never persisted.
QS_SETTINGS="$HOME/.config/quickshell/shell_settings.json"
if [ -f "$QS_SETTINGS" ]; then
    ok "shell_settings.json already present — leaving your choices alone."
else
    cp "$REPO_ZENSHELL/shell_settings.json" "$QS_SETTINGS"
    ok "Seeded $QS_SETTINGS"
fi

# ── Apply default theme + wallpaper ─────────────────────────────────
step "Apply default theme: $DEFAULT_THEME"
if [ -f "$HOME/scripts/theme-switch.sh" ]; then
    "$HOME/scripts/theme-switch.sh" "$DEFAULT_THEME" \
        && ok "Theme $DEFAULT_THEME applied." \
        || warn "theme-switch.sh had issues (normal outside a desktop session)."
else
    warn "~/.config/hypr not linked? theme-switch.sh missing. Configs must be linked."
fi

if [ ! -e "$HOME/wallpapers/current" ]; then
    log "Setting a default wallpaper for $DEFAULT_THEME..."
    WALL="$(find "$HOME/wallpapers/$DEFAULT_THEME" -type f \( -iname '*.jpg' -o -iname '*.png' -o -iname '*.webp' \) 2> /dev/null | head -n 1 || true)"
    if [ -n "$WALL" ]; then
        ln -sf "$WALL" "$HOME/wallpapers/current"
        ok "Default wallpaper set: $WALL"
    else
        warn "No wallpapers found for $DEFAULT_THEME — pick one later with Super+W (island picker)."
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
check "zen shell [$QS_DEST/shell.qml]" sh -c '[ -f "$HOME/.config/quickshell/dynamic-island/shell.qml" ]'
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
check "Outfit font (ZenShell UI)"          sh -c 'fc-list 2>/dev/null | grep -qi Outfit'
check "nerd font (icons)"                  sh -c 'fc-list 2>/dev/null | grep -qi nerd'
check "adw-gtk3 (GTK theming)"             sh -c 'gsettings get org.gnome.desktop.interface gtk-theme 2>/dev/null | grep -q adw-gtk3'
check "wlogout (SUPER+X)"                  sh -c 'command -v wlogout'
check "pywal (dynamic theme)"              sh -c 'command -v wal'
check "matugen (wallpaper theme)"          sh -c 'command -v matugen'
check "waypaper"                           sh -c 'command -v waypaper'
check "hyprshot (screenshots)"             sh -c 'command -v hyprshot'
check "keybind binary: kitty"              sh -c 'command -v kitty'
check "keybind binary: firefox"            sh -c 'command -v firefox'
check "keybind binary: thunar"             sh -c 'command -v thunar'
check "keybind binary: codium"             sh -c 'command -v codium'
check "keybind binary: wlogout"            sh -c 'command -v wlogout'
check "zen shell themes.json"              sh -c '[ -f "$HOME/.config/hypr/themes/themes.json" ]'
check "zen shell get_themes.py runs"       sh -c 'python3 "$QS_DEST/scripts/get_themes.py" >/dev/null 2>&1'
check "zen shell get_wallpapers.py runs"   sh -c 'python3 "$QS_DEST/scripts/get_wallpapers.py" >/dev/null 2>&1'
check "shell_settings.json seeded"         sh -c '[ -f "$HOME/.config/quickshell/shell_settings.json" ]'

printf "\n${G}${BD}Checks passed: ${pass}${N}${R}${BD}   Failed: ${fail}${N}\n"

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
           Spotlight       Super+Shift+M
      5. zen shell autostart is wired into exec.lua (start_all.sh).

    If any AUR package failed, retry with:
         paru -S --needed <pkg...>
EOF
printf "\n"

if [ "${#FAILED_AUR[@]}" -gt 0 ]; then
    warn "AUR packages that did NOT install: ${FAILED_AUR[*]}"
fi