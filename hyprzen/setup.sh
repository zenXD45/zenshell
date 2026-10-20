#!/usr/bin/env bash
# =============================================================
#  HyprZen setup — compatibility shim.
#
#  This used to carry its own package list, which drifted away from the
#  top-level installer: it still installed `quickshell-git` and the AUR
#  `adw-gtk3` (both gone/renamed) while ../install.sh had moved to the
#  official `quickshell` and `adw-gtk-theme`. Running it could reinstall the
#  wrong packages over a working setup.
#
#  There is exactly one installer now. This wrapper exists only because the
#  README documents `cd hyprzen && ./setup.sh`.
# =============================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
exec "$SCRIPT_DIR/../install.sh" "$@"
