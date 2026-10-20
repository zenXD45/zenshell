<div align="center">

# Zen Shell 🏝️

**The entire interface of [HyprZen](../README.md), in one Quickshell process.**

Dynamic Island, dock, an optional command bar, spotlight, control centre,
theme & wallpaper pickers, clipboard, and notifications.

<p>
  <img src="https://img.shields.io/badge/desktop-Hyprland-blue?style=flat-square&logo=hyprland" alt="Hyprland" />
  <img src="https://img.shields.io/badge/shell-Quickshell-purple?style=flat-square&logo=qt" alt="Quickshell" />
  <img src="https://img.shields.io/badge/scripts-Python%20%7C%20Bash-yellow?style=flat-square&logo=python" alt="Python &amp; Bash" />
</p>

<p>
  <a href="#previews">Previews</a> •
  <a href="#whats-in-the-box">What's in the box</a> •
  <a href="#installation">Installation</a> •
  <a href="#hyprland-integration">Hyprland integration</a>
</p>

</div>

---

Zen Shell replaces the four programs a Hyprland setup usually reaches for:
**rofi** (launcher), **waybar** (bar), **swaync** (notifications) and **eww**
(clock/widgets). HyprZen ships none of them, so nothing can conflict with this.

It talks to the system through small Python and Bash helpers in `scripts/` —
that seam is the easiest place to extend it.

## Previews

<p align="center">
  <img src="../docs/images/shell-1.webp" alt="Dynamic Island" width="49%" />
  <img src="../docs/images/shell-2.webp" alt="Dock and widgets" width="49%" />
</p>
<p align="center">
  <img src="../docs/images/shell-3.webp" alt="Control centre" width="49%" />
  <img src="../docs/images/shell-4.webp" alt="Clipboard manager" width="49%" />
</p>
<p align="center">
  <img src="../docs/images/shell-5.webp" alt="Theme switcher" width="49%" />
  <img src="../docs/images/shell-6.webp" alt="Wallpaper picker" width="49%" />
</p>
<p align="center">
  <img src="../docs/images/shell-7.webp" alt="Spotlight search" width="90%" />
</p>

## What's in the box

- **Dynamic Island** — live now-playing with lyrics, notification stack, and
  volume/brightness OSD. Theme-aware: the accent comes from the active theme
  rather than a hardcoded colour.
- **Glassmorphic dock** — bottom taskbar with active-window indicators.
- **Profile 02 command bar** — a floating or edge-mounted rail with workspaces,
  window title, now playing, clock, weather, system status and tray. Layout,
  position and individual widgets are live-configurable from its gear button.
- **Spotlight search** — centre-screen fuzzy app finder (`SUPER + SHIFT + M`).
- **Desktop widgets** — wallpaper-integrated clock, weather and system stats
  (`SUPER + D`).
- **Control centre** — Wi-Fi, Bluetooth, caffeine and microphone mute.
- **Clipboard manager** — `cliphist`-backed history.
- **Keybind cheatsheet** — a searchable index generated from your *actual*
  `keybinds.lua`, so it can't go stale.
- **Theme & wallpaper pickers** — read from the generated theme manifest, so all
  15 themes appear without touching a line of QML.

## Profiles

ZenShell has two shell profiles. Both share the same Quickshell process, theme,
media state, weather, launcher and notification stack, so switching is immediate.

| Profile | Surface |
| :--- | :--- |
| **01 · Island** | Dynamic island, dock and desktop widgets. |
| **02 · Bar** | Floating or edge-mounted command rail with toggleable widgets. The dock and desktop widgets hide while this profile is active. |

Switch from the control center's `PROFILE 01/02` chip, from the `P2` button in
the bar, or directly:

```bash
~/.config/quickshell/dynamic-island/island_ctl.sh profiles      # open the switcher
~/.config/quickshell/dynamic-island/island_ctl.sh bar           # go to Profile 02
~/.config/quickshell/dynamic-island/island_ctl.sh island        # go to Profile 01
~/.config/quickshell/dynamic-island/island_ctl.sh bar-settings  # open bar layout settings
```

The bar's gear button opens **Floating / Edge**, **Top / Bottom**, and widget
toggles. Changes apply live and are stored in `shell_settings.json`; the dock and
desktop-widget processes watch that file, so no process restarts are needed.

## Installation

**Recommended** — the top-level installer handles this and everything ZenShell
depends on:

```bash
git clone https://github.com/zenXD45/zenshell.git
cd zenshell
./install.sh
```

Standalone:

```bash
git clone https://github.com/zenXD45/zenshell.git
./zenshell/install.sh
```

The installer backs up anything already at
`~/.config/quickshell/dynamic-island`, resolves dependencies through `paru` or
`yay`, and marks the helper scripts executable. A password prompt is normal —
it's your AUR helper fetching `socat`, `playerctl` and friends.

ZenShell reads themes from `~/scripts/theme-switch.sh` and wallpapers from
`~/wallpapers`, both provided by [HyprZen](../hyprzen/README.md), so install
that half first.

## Hyprland integration

The suite autostarts from HyprZen's `exec.lua` via `start_all.sh` — there's
nothing to add. If you're wiring ZenShell into a *different* Hyprland config:

```ini
exec-once = ~/.config/quickshell/dynamic-island/start_all.sh
```

or, in a Lua config:

```lua
hl.exec_cmd("~/.config/quickshell/dynamic-island/start_all.sh")
```

### Keybinds

With HyprZen these are already bound. If you need them elsewhere, everything
routes through `island_ctl.sh` except spotlight and widgets, which are their own
Quickshell processes:

```lua
local ISLAND = "~/.config/quickshell/dynamic-island/island_ctl.sh"

hl.bind("SUPER", "SPACE",   hl.dsp.exec_cmd(ISLAND .. " launcher"))
hl.bind("SUPER", "comma",   hl.dsp.exec_cmd(ISLAND .. " cheatsheet"))
hl.bind("SUPER", "V",       hl.dsp.exec_cmd(ISLAND .. " clipboard"))
hl.bind("SUPER", "T",       hl.dsp.exec_cmd(ISLAND .. " themes"))
hl.bind("SUPER", "W",       hl.dsp.exec_cmd(ISLAND .. " wallpapers"))
hl.bind("SUPER", "N",       hl.dsp.exec_cmd(ISLAND .. " control"))
hl.bind("SUPER", "escape",  hl.dsp.exec_cmd(ISLAND .. " power"))
hl.bind("SUPER + SHIFT", "P", hl.dsp.exec_cmd(ISLAND .. " powerprofile"))
hl.bind("SUPER + SHIFT", "M",
    hl.dsp.exec_cmd("~/.config/quickshell/dynamic-island/modules/spotlight/toggle.sh"))
hl.bind("SUPER", "D", hl.dsp.exec_cmd(
    "quickshell ipc -p ~/.config/quickshell/dynamic-island/modules/desktop-widgets call widgets toggle"))
```

## Structure

```text
zenshell/
├── shell.qml            # entry point and root island window
├── island_ctl.sh        # open/close island modules over Quickshell IPC
├── start_all.sh         # starts island, dock, widgets and the monitors
├── components/          # UI: launcher, OSD, control panel, pickers, ...
├── modules/
│   ├── dock/            # separate Quickshell process
│   ├── spotlight/       # separate Quickshell process
│   └── desktop-widgets/ # separate Quickshell process
└── scripts/             # the system-data seam: Python & Bash helpers
    ├── get_apps.py          # launcher entries
    ├── get_keybinds.py      # cheatsheet source (parses keybinds.lua)
    ├── get_themes.py        # reads HyprZen's generated themes.json
    ├── get_wallpapers.py    # scans ~/wallpapers and ~/Pictures/Wallpapers
    ├── get_clipboard.py     # cliphist wrapper
    ├── get_lyrics.py        # now-playing lyrics
    ├── get_search.py        # app search, icons and calculator
    ├── set_setting.py       # atomic profile/bar setting writes
    ├── network_ctl.py       # NetworkManager
    ├── bluetooth_ctl.py     # bluez
    └── themes.json          # generated manifest (do not hand-edit)
```

## Notes

- **`themes.json` is generated.** It's produced by
  `hyprzen/scripts/gen-themes.py` and copied by the installer. Edit the TOML
  sources under `hyprzen/.config/hypr/themes/source/`, never this file.
- **Settings are seeded, not owned.** The installer copies `shell_settings.json`
  into `~/.config/quickshell/` only if it's absent, so your runtime changes
  survive reinstalls. Profile and bar changes are written back atomically by
  `scripts/set_setting.py` and watched live by the shell, dock and widgets.
- **Paths are relative.** Everything resolves through `$HOME` /
  `Qt.homePath()`, so the repo runs wherever it's cloned.
