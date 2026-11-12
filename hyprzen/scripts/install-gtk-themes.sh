#!/usr/bin/env bash
# =============================================================
#  Install the GTK ports used by HyprZen themes (user-level)
#
#  Themes are written to ~/.themes, so no root and no package
#  manager is required. Sources are the upstream projects:
#    • Catppuccin GTK   (catppuccin/gtk)
#    • Rosé Pine GTK    (rose-pine/gtk)
#    • Nordic           (EliverLara/Nordic)
#    • Gruvbox / Tokyo Night / Everforest / Kanagawa
#                       (Fausto-Korpsvart/*, compiled with sassc)
#
#  Themes without an upstream port (noir, alabaster, one-dark,
#  dynamic, matugen) use the system adw-gtk3 / adw-gtk3-dark
#  and are re-coloured from the palette by apply-appearance.py.
#
#  Usage:
#    ./install-gtk-themes.sh [--force]
# =============================================================

set -euo pipefail

DEST="${HOME}/.themes"
CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/hyprzen/gtk-themes"
FORCE=0

for arg in "$@"; do
    case "$arg" in
        -f|--force) FORCE=1 ;;
        -h|--help) sed -n '2,22p' "$0"; exit 0 ;;
        *) echo "install-gtk-themes: unknown option '$arg'" >&2; exit 2 ;;
    esac
done

for cmd in curl tar unzip git; do
    command -v "$cmd" >/dev/null || { echo "install-gtk-themes: missing $cmd" >&2; exit 1; }
done

mkdir -p "$DEST" "$CACHE"
echo "install-gtk-themes: installing into $DEST"

need_install() {
    [ "${FORCE}" -eq 1 ] || [ ! -d "$DEST/$1" ]
}

# ── Catppuccin ────────────────────────────────────────────────
# Releases ship compiled themes; use the accent that matches the
# HyprZen palette (Mocha mauve, Latte lavender).
install_catppuccin() {
    local version="v1.0.3"
    local -A themes=(
        ["catppuccin-mocha-mauve-standard+default"]="Catppuccin-Mocha-Mauve"
        ["catppuccin-latte-lavender-standard+default"]="Catppuccin-Latte-Lavender"
    )
    for archive in "${!themes[@]}"; do
        local dir="${themes[$archive]}"
        need_install "$dir" || { echo "  ✓ $dir"; continue; }
        echo "  → $dir"
        curl -fsSL --retry 3 -o "$CACHE/$archive.zip" \
            "https://github.com/catppuccin/gtk/releases/download/$version/$archive.zip"
        rm -rf "$DEST/$archive"
        unzip -oq "$CACHE/$archive.zip" -d "$DEST"
        rm -rf "$DEST/${dir}" && mv "$DEST/$archive" "$DEST/$dir"
        sed -i "s/$archive/$dir/g" "$DEST/$dir/index.theme"
        # Drop the HiDPI duplicates: GTK scales the standard theme itself.
        rm -rf "$DEST/${archive}-hdpi" "$DEST/${archive}-xhdpi"
    done
}

# ── Rosé Pine ─────────────────────────────────────────────────
install_rose_pine() {
    local version="v2.2.0"
    need_install "Rose-Pine" || { echo "  ✓ Rose-Pine"; return; }
    echo "  → Rose-Pine"
    curl -fsSL --retry 3 -o "$CACHE/rp-gtk3.tar.gz" \
        "https://github.com/rose-pine/gtk/releases/download/$version/gtk3.tar.gz"
    curl -fsSL --retry 3 -o "$CACHE/rp-gtk4.tar.gz" \
        "https://github.com/rose-pine/gtk/releases/download/$version/gtk4.tar.gz"
    rm -rf "$CACHE/rp" && mkdir -p "$CACHE/rp"
    tar -xzf "$CACHE/rp-gtk3.tar.gz" -C "$CACHE/rp" 2>/dev/null
    tar -xzf "$CACHE/rp-gtk4.tar.gz" -C "$CACHE/rp" 2>/dev/null
    rm -rf "$DEST/Rose-Pine"
    cp -r "$CACHE/rp/gtk3/rose-pine-gtk" "$DEST/Rose-Pine"
    sed -i 's/^Name=.*/Name=Rose-Pine/; s/^GtkTheme=.*/GtkTheme=Rose-Pine/; s/^MetacityTheme=.*/MetacityTheme=Rose-Pine/' \
        "$DEST/Rose-Pine/index.theme"
    # libadwaita ignores theme folders; this file is the upstream override and
    # documents what apply-appearance.py writes from the TOML palette.
    mkdir -p "$DEST/Rose-Pine/gtk-4.0"
    cp "$CACHE/rp/gtk4/rose-pine.css" "$DEST/Rose-Pine/gtk-4.0/gtk.css"
}

# ── Nordic ────────────────────────────────────────────────────
install_nordic() {
    local version="v2.2.0"
    need_install "Nordic" || { echo "  ✓ Nordic"; return; }
    echo "  → Nordic"
    curl -fsSL --retry 3 -o "$CACHE/nordic.tar.xz" \
        "https://github.com/EliverLara/Nordic/releases/download/$version/Nordic-v40.tar.xz"
    rm -rf "$CACHE/nordic" && mkdir -p "$CACHE/nordic"
    tar -xJf "$CACHE/nordic.tar.xz" -C "$CACHE/nordic" 2>/dev/null
    rm -rf "$DEST/Nordic"
    mv "$CACHE/nordic/Nordic-v40" "$DEST/Nordic"
}

# ── sassc (needed only to compile the Fausto themes) ─────────
# Arch ships sassc as a package, but we refuse to require root: extract the
# official package into the cache and put it on PATH for this run.
ensure_sassc() {
    command -v sassc >/dev/null && return 0
    command -v pacman >/dev/null || return 1
    local root="$CACHE/sassroot"
    if [ ! -x "$root/usr/bin/sassc" ]; then
        mkdir -p "$root"
        local url
        for pkg in sassc libsass; do
            url=$(pacman -Sp --print-format '%l' "$pkg" 2>/dev/null | grep -E "/${pkg}-[0-9]" | head -1)
            [ -n "$url" ] || return 1
            curl -fsSL --retry 3 -o "$CACHE/$pkg.pkg.tar.zst" "$url"
            bsdtar -xf "$CACHE/$pkg.pkg.tar.zst" -C "$root"
        done
    fi
    export PATH="$root/usr/bin:$PATH"
    export LD_LIBRARY_PATH="$root/usr/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
    command -v sassc >/dev/null
}

# ── Fausto-Korpsvart themes ───────────────────────────────────
install_fausto() {
    local repo="$1" name="$2" variant="$3"
    need_install "$name-Dark" || { echo "  ✓ $name-Dark"; return; }
    echo "  → $name-Dark"
    if ! ensure_sassc; then
        echo "    ! sassc unavailable — skipping $name (install sassc and re-run)" >&2
        return
    fi
    local src="$CACHE/src/$repo"
    if [ ! -d "$src/.git" ]; then
        rm -rf "$src"
        git clone --depth 1 "https://github.com/Fausto-Korpsvart/$repo.git" "$src"
    fi
    ( cd "$src/themes" && ./install.sh -d "$DEST" -c dark -t "$variant" >/dev/null )
}

echo "Catppuccin"
install_catppuccin
echo "Rosé Pine"
install_rose_pine
echo "Nordic"
install_nordic
echo "Gruvbox / Tokyo Night / Everforest / Kanagawa"
install_fausto "Gruvbox-GTK-Theme" "Gruvbox-Yellow" "yellow"
install_fausto "Tokyonight-GTK-Theme" "Tokyonight" "default"
install_fausto "Tokyonight-GTK-Theme" "Tokyonight-Purple" "purple"
install_fausto "Tokyonight-GTK-Theme" "Tokyonight-Green" "green"
install_fausto "Everforest-GTK-Theme" "Everforest-Green" "green"
install_fausto "Kanagawa-GKT-Theme" "Kanagawa-Red" "red"

echo
echo "install-gtk-themes: done. Installed:"
find "$DEST" -maxdepth 1 -mindepth 1 -type d -printf '  %f\n' | sort
echo
echo "Switch themes normally — apply-appearance.py picks the matching GTK theme."
