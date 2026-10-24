#!/bin/bash
# Camera Effects — build and install the daemon half of the plugin.
#
# Ported for ZenShell from alanfortlink/camera-effects (MIT). The upstream
# install.sh expects the Omarchy shell (it symlinks the plugin into
# ~/.config/omarchy/plugins and calls omarchy-plugin-enable). This script does
# the same work without any of that: it keeps an upstream checkout, builds the
# daemon, and installs the user half into ~/.local.
#
#   camera_effects_install.sh            build + install the user half (no root)
#   camera_effects_install.sh --root     also create the virtual camera (asks for
#                                        a password through polkit)
#
# Root is only needed for the v4l2loopback device, the boot unit and the
# optional "hide raw camera" udev rules.
set -euo pipefail

UPSTREAM_URL=${CAMERA_EFFECTS_UPSTREAM:-https://github.com/alanfortlink/camera-effects.git}
DATA=${XDG_DATA_HOME:-$HOME/.local/share}
LIB=$HOME/.local/lib/camera-effects
SHARE=$DATA/camera-effects
SRC=$SHARE/src
CACHE=${XDG_CACHE_HOME:-$HOME/.cache}/camera-effects
BIN=$HOME/.local/bin
MODE=${1:-}

say() { printf '› %s\n' "$*"; }
die() { printf 'error: %s\n' "$*" >&2; exit 1; }

# ── Dependencies ─────────────────────────────────────────────────────────────
# The panel runs this script on every shell start, so the polkit prompt for the
# package install used to come back at every single login (and a dismissed
# prompt is remembered by nobody, so it came back anyway). Ask once, remember
# the attempt, and after that print the command to run instead of asking.
missing=()
# Build deps first, then the runtime pieces the panel actually uses: ffmpeg
# measures the pipeline, EasyEffects carries the virtual microphone. Both are
# opt-in with the camera, never pulled in by a shell-only install.
for p in gcc make pkgconf opencv onnxruntime-cpu pipewire ffmpeg easyeffects; do
  pacman -Q "$p" >/dev/null 2>&1 || missing+=("$p")
done
DEPS_MARKER=$CACHE/deps-prompted
if ((${#missing[@]})); then
  if [[ -f $DEPS_MARKER ]]; then
    say "missing packages: ${missing[*]}"
    say "already asked once — not asking again."
    say "install them yourself to finish this: sudo pacman -S --needed ${missing[*]}"
    say "(to be asked again, delete $DEPS_MARKER)"
    die "missing build dependencies"
  fi
  mkdir -p "$CACHE"
  printf '%s\n' "${missing[*]}" >"$DEPS_MARKER"
  say "installing missing packages: ${missing[*]}"
  if command -v pkexec >/dev/null 2>&1; then
    if ! pkexec pacman -S --needed --noconfirm "${missing[@]}"; then
      say "the install did not go through; not asking again (delete $DEPS_MARKER to retry)"
      die "missing build dependencies"
    fi
  else
    say "no polkit agent: install them yourself with: sudo pacman -S ${missing[*]}"
    die "missing build dependencies"
  fi
  rm -f "$DEPS_MARKER"   # they are in now, so a later miss may ask again
else
  rm -f "$DEPS_MARKER"   # all present: allow a future prompt again
fi

# ── Upstream checkout ────────────────────────────────────────────────────────
mkdir -p "$SHARE"
if [ ! -d "$SRC/.git" ]; then
  say "cloning $UPSTREAM_URL"
  rm -rf "$SRC"
  git clone --depth 1 "$UPSTREAM_URL" "$SRC"
else
  # Update in place, but never on top of local edits: a dirty tree is the
  # user's, not ours.
  if [ -z "$(git -C "$SRC" status --porcelain 2>/dev/null)" ]; then
    say "updating the upstream checkout"
    git -C "$SRC" pull --ff-only --quiet || say "update skipped (offline or diverged)"
  else
    say "upstream checkout has local changes: leaving it alone"
  fi
fi

# ── Build ────────────────────────────────────────────────────────────────────
BUILD=$CACHE/build/$(printf %s "$SRC" | md5sum | cut -c1-10)
mkdir -p "$BUILD"
say "building the daemon (log: $CACHE/build.log)"
if ! make -C "$SRC/daemon" BUILD="$BUILD" -j"$(nproc)" >"$CACHE/build.log" 2>&1; then
  tail -n 20 "$CACHE/build.log" >&2
  die "build failed; full log: $CACHE/build.log"
fi

# ── Install (user half) ──────────────────────────────────────────────────────
say "installing to $LIB and $SHARE"
install -d "$LIB" "$SHARE/models" "$SHARE/assets" "$SHARE/wireplumber" "$BIN" "$SHARE"
install -m 755 "$BUILD/camera-effects-server" "$LIB/camera-effects-server"
install -m 755 "$SRC/scripts/camera-effects-setup" "$LIB/camera-effects-setup"
install -m 755 "$SRC/scripts/camera-effects-mic-hide" "$LIB/camera-effects-mic-hide"
install -m 644 "$SRC"/models/*.onnx "$SHARE/models/"
install -m 644 "$SRC"/assets/*.png "$SHARE/assets/"
install -m 644 "$SRC"/wireplumber/*.lua "$SHARE/wireplumber/"
ln -sfn "$LIB/camera-effects-server" "$BIN/camera-effects-server"

# The panel calls this script by path, so keep a copy where it expects it.
# (Skip it when we *are* that copy: install would fail with "same file" and the
# script would exit non-zero even though the build was fine.)
if [[ "$(readlink -f "${BASH_SOURCE[0]}")" != "$(readlink -f "$SHARE/install.sh")" ]]; then
  install -m 755 "${BASH_SOURCE[0]}" "$SHARE/install.sh"
fi

# Remember which upstream commit this build came from: the shell compares it
# with the checkout and rebuilds when it moves.
git -C "$SRC" rev-parse HEAD > "$LIB/installed-commit" 2>/dev/null || date +%s > "$LIB/installed-commit"

# ── Root half (optional) ─────────────────────────────────────────────────────
if [ "$MODE" = "--root" ]; then
  say "creating the virtual camera (polkit will ask for your password)"
  pkexec "$LIB/camera-effects-setup" install "$LIB/camera-effects-server" "$LIB/camera-effects-setup"
else
  say "skipping the root part; run this with --root to create the virtual camera"
fi

say "done"
