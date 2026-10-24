<div align="center">

# ZenShell 🏝️

**A Hyprland desktop where [ZenShell](zenshell/README.md) is the entire UI.**

[![CI](https://github.com/zenXD45/zenshell/actions/workflows/lint.yml/badge.svg)](https://github.com/zenXD45/zenshell/actions/workflows/lint.yml)
![Arch](https://img.shields.io/badge/base-Arch_Linux-1793d3?logo=archlinux&logoColor=white)
![Hyprland](https://img.shields.io/badge/compositor-Hyprland-56b0f5?logo=hyprland&logoColor=white)
![Quickshell](https://img.shields.io/badge/shell-Quickshell-1abc9c?logo=quickshell&logoColor=white)
![License](https://img.shields.io/badge/license-MIT-blue)

15 themes · 2 shell profiles · one installer

[Install](#installation) · [Keybinds](#keybinds) · [Structure](#structure)

</div>

---

![ZenShell desktop — dynamic island, dock and wallpaper](docs/images/shell-1.webp)

One monorepo, two layers — and [ZenShell](zenshell/README.md) is the one you
actually see.

- **[ZenShell](zenshell/README.md)** — the glassmorphic suite on [Quickshell](https://quickshell.outfoxxed.me). Dynamic Island, dock, the Profile 02 command bar, spotlight, launcher, settings, control centre, theme and wallpaper pickers. It replaces **rofi, waybar, swaync *and* eww** in one process.
- **[HyprZen](hyprzen/README.md)** — the substrate underneath. Keybinds, window rules, animation, **15 generated themes** and a wallpaper-driven colour pipeline. Ships no bar, no launcher, no notification daemon.

The split is the whole point: HyprZen owns *behaviour and colour*, ZenShell owns *interface*. Neither can shadow the other, so there is nothing to disable or reconcile.

## Gallery

<p align="center">
  <img src="docs/images/shell-2.webp" alt="Desktop widgets: clock and weather over the wallpaper" width="49%">
  <img src="docs/images/shell-3.webp" alt="Control centre: network, Bluetooth, camera, brightness, volume, toggles and notifications" width="49%">
</p>
<p align="center">
  <img src="docs/images/shell-4.webp" alt="Settings app on the Theme & Colors page" width="49%">
  <img src="docs/images/shell-7.webp" alt="App launcher with search" width="49%">
</p>
<p align="center">
  <img src="docs/images/shell-5.webp" alt="Theme switcher overlay" width="49%">
  <img src="docs/images/shell-6.webp" alt="Wallpaper picker overlay" width="49%">
</p>
<p align="center">
  <img src="docs/images/shell-8.webp" alt="Camera effects panel" width="90%">
</p>

## Features

| | |
| :--- | :--- |
| **15 themes, one source of truth** | Colours live in `themes/source/*.toml`; `gen-themes.py` emits Lua, Hyprlang, CSS, Kitty and a JSON manifest. No hand-edited palette can drift. |
| **Two shell profiles** | Profile 01 is the dynamic island, dock and desktop widgets. Profile 02 is a floating or edge-mounted command bar with toggleable widgets. Both share media, weather, notifications and the launcher; switching is instant. |
| **One settings app** | A searchable page tree — wallpaper, theme, typography and motion, profile and bar, dock, widgets, alerts, power, camera, keyboard. It writes through a single `setValue()` door, so the UI, the shell and `shell_settings.json` never disagree. |
| **Functional dock** | Pinned apps plus running windows only — no tray clutter. Defaults pin kitty, Helium, VSCodium, Nautilus and Firefox. Right-click any app to focus, open a new window, pin/unpin, reorder or close. |
| **Camera effects** | A virtual webcam and virtual microphone (Center Stage, Portrait, Studio Light, backgrounds, filters, reactions, privacy shutter, voice isolation, voice changers), ported from the Omarchy plugin and opened from the notification center. |
| **Dynamic colour** | `dynamic` and `matugen` themes derive the whole palette from your wallpaper via pywal / Matugen. |
| **Theme-aware geometry** | Gaps, borders, rounding, blur and shadow opacity are read from the theme, not hardcoded. |
| **No dead keybinds** | `scripts/check_keybinds.py` parses `keybinds.lua` and fails CI if a bound binary isn't installed by `install.sh`. |
| **Media keys built in** | Volume, mic, brightness and playback go straight through `osd_control.sh`, which changes the value *and* draws the OSD. |
| **Fonts handled** | JetBrainsMono Nerd for terminal/icon glyphs and [Google Sans Flex](https://fonts.google.com/specimen/Google+Sans+Flex) for the UI. JetBrainsMono comes from the official repos; Google Sans Flex is downloaded and cached by the installer. |
| **Reinstall-safe** | A re-run refreshes the code and keeps your theme, `shell_settings.json` and dock pins. Real config dirs are backed up with a timestamp, never deleted. |
| **Portable** | Every path resolves through `$HOME` / `Qt.homePath()`. Clone it anywhere; no edits needed. |

## Structure

```text
hyprzen/     Hyprland config & theming  → ~/.config/hypr, ~/scripts, ~/wallpapers
zenshell/    Quickshell UI suite        → ~/.config/quickshell/dynamic-island
docs/images/ screenshots used by this README
scripts/     repo-level tooling (CI checks)
```

## Installation

> Built for a from-scratch or existing **Arch Linux** install. Tested on Arch + `Hyprland` session; the installer is safe to re-run and skips what is already in place. A re-run refreshes the code but keeps your current theme, `shell_settings.json` and dock pins.

```bash
git clone https://github.com/zenXD45/zenshell.git
cd zenshell
./install.sh
```

Optional flags for the same run:

```bash
./install.sh --with-camera   # + OpenCV, onnxruntime, ffmpeg, EasyEffects, v4l2loopback
./install.sh --theme noir    # force a theme instead of keeping the current one
./install.sh --help
```

Then log into the `Hyprland` session (or `hyprctl reload`). ZenShell autostarts from `exec.lua` → `start_all.sh`; there is no manual `exec-once` line.

What `install.sh` does:

1. Installs official packages — Hyprland, kitty, pipewire, `firefox`, `nautilus`, the toolchain and more. **No waybar, no rofi, no swaync**; the island, dock and optional command bar are the UI.
2. Bootstraps `paru-bin` when no AUR helper exists, then installs the AUR-only packages: `hyprswitch`, `bibata-cursor-theme`, `waypaper`, `wlogout`, `helium-browser-bin`, `vscodium-bin`, and pywal (`python-pywal16`, falling back to `python-pywal`). Everything else the theme pipeline needs — `quickshell`, `matugen`, `satty`, `hyprshot`, `adw-gtk-theme`, `awww`, `qt6ct` — is in the official repos. **Failures warn, they don't abort.**
3. Installs **JetBrainsMono Nerd Font** for terminal and icon glyphs, and downloads/caches **Google Sans Flex** for UI text.
4. Adds and enables the **scroll-overview** `hyprpm` plugin.
5. Detects NVIDIA and installs `nvidia-dkms` / `nvidia-utils`.
6. Configures **zsh**: Oh My Zsh + Powerlevel10k, plus `eza` / `bat` / `fzf` aliases, and offers `chsh`.
7. Runs `hyprzen/install.sh` to symlink configs into `~/.config`, link `~/scripts`, and copy wallpapers into `~/wallpapers`. Existing real config dirs are backed up with a timestamp, never deleted; an existing `~/.zshrc` / `~/.p10k.zsh` is kept.
8. Installs ZenShell to `~/.config/quickshell/dynamic-island`, backing up anything already there while preserving `shell_settings.json` and the dock's pinned apps.
9. Applies the default theme (`catppuccin`) and a matching wallpaper on a fresh install; re-runs keep the current theme and wallpaper.
10. Enables NetworkManager, bluetooth and power-profiles-daemon.
11. **Verifies** the result — key binaries, configs, fonts and the ZenShell Python helpers — and warns about anything missing.

### Manual

If you'd rather run things yourself, the top-level installer is the only entry point — `hyprzen/setup.sh` is now a compatibility shim that runs it:

```bash
./install.sh            # packages, symlinks, ZenShell, default theme
# then: hyprctl reload  (or SUPER+CTRL+R)
```

## ⌨️ Keybinds

Everything lives in `hyprzen/.config/hypr/modules/keybinds.lua`. ZenShell claims the plain `SUPER+` keys; HyprZen keeps terminal, app and system binds out of the way. Combos are unique — the CI checker enforces it.

### ZenShell
| Action | Shortcut |
| :--- | :--- |
| App launcher | `SUPER + Space` |
| Spotlight search | `SUPER + Shift + M` |
| Clipboard | `SUPER + V` |
| Keybind cheatsheet | `SUPER + comma` |
| Control centre & notifications | `SUPER + N` |
| Power menu | `SUPER + Escape` |
| Power profiles | `SUPER + Shift + P` |
| Theme switcher | `SUPER + T` |
| Wallpaper picker | `SUPER + W` |
| Desktop widgets (clock + weather) | `SUPER + D` |

Surfaces without a default binding are reached from the control centre or with
`island_ctl.sh` — the full list is in the [ZenShell README](zenshell/README.md#keybinds).

### Apps
| Action | Shortcut |
| :--- | :--- |
| Terminal (kitty) | `SUPER + Enter` |
| Browser (Helium) | `SUPER + B` |
| Files (Nautilus) | `SUPER + E` |
| Editor (VSCodium) | `SUPER + C` |
| Window switcher (hyprswitch) | `SUPER + Alt + Tab` |

### Windows & workspaces
| Action | Shortcut |
| :--- | :--- |
| Close | `SUPER + Q` |
| Fullscreen | `SUPER + F` |
| Maximize | `SUPER + Alt + F` |
| Float | `SUPER + Shift + F` |
| Pseudo-tty | `SUPER + P` |
| Opaque / blur | `SUPER + O` |
| Focus | `SUPER + H/J/K/L` or arrows |
| Move | `SUPER + Shift + H/J/K/L` |
| Resize | `SUPER + Alt + arrows` |
| Workspace 1–10 | `SUPER + 1…0` |
| Send to workspace | `SUPER + Shift + 1…0` |
| Cycle workspace | `SUPER + Ctrl + ←/→`, `SUPER + scroll` |
| Overview | `SUPER + Tab` |
| Scratchpad | `SUPER + S` |

### Screenshots & system
| Action | Shortcut |
| :--- | :--- |
| Full screen | `Print` |
| Region → annotate | `SUPER + Print` |
| Region → clipboard | `SUPER + Ctrl + Print` |
| Lock | `SUPER + Shift + L` |
| wlogout | `SUPER + X` |
| Caffeine (hold off idle) | `SUPER + Shift + C` |
| Reload config | `SUPER + Ctrl + R` |
| Exit Hyprland | `SUPER + Ctrl + Q` |

Media keys (`XF86Audio*`, `XF86MonBrightness*`) go through `osd_control.sh`, so
the change and the on-screen indicator always happen together.

## Development

```bash
python3 hyprzen/scripts/gen-themes.py          # regenerate theme artifacts
python3 hyprzen/scripts/gen-themes.py --check  # fail if artifacts are stale
python3 scripts/check_keybinds.py              # every bound binary is installed
python3 scripts/check_qml.py                   # QML colour and transform lint
```

CI runs on every push and PR: `bash -n` over the shell scripts, `luac -p` over the theme Lua, Python compilation, the theme-drift check, and the keybind checker.

## Notes

- **ZenShell is the only UI.** rofi, waybar, swaync and eww were removed rather than left dormant — the island owns the launcher, clipboard, cheatsheet, pickers and notifications; the dock and the optional Profile 02 command bar replace the bar.
- **Absolute paths are gone.** Both projects used to hardcode `~/Desktop/hyprzen/...` and a specific username. They now resolve via `~/scripts`, `~/wallpapers` and `$HOME` / `Qt.homePath()`.
- **Themes are generated, never hand-edited.** Edit `hyprzen/.config/hypr/themes/source/*.toml` and re-run the generator; CI fails if you forget.

## License

MIT — see [LICENSE](LICENSE).
