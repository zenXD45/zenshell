<div align="center">

# 🌸 HyprZen

**The behaviour-and-colour half of [HyprZen](../README.md).**

A minimal Hyprland config for Arch Linux that ships **15 generated themes**, a
wallpaper-driven colour pipeline, and a scratchpad — and deliberately ships
*no* bar, launcher, or notification daemon.

<p>
  <a href="#themes">Themes</a> •
  <a href="#installation">Installation</a> •
  <a href="#how-theming-works">How theming works</a>
</p>

</div>

---

## What this is

ZenShell ([`../zenshell`](../zenshell/README.md)) is the interface. HyprZen is
everything underneath: keybinds, window rules, animation, workspace behaviour,
and the theme system that tints the terminal, GTK apps, Neovim and VSCodium at
once.

If you're using the full project, you normally **never run `setup.sh`** — the
top-level `./install.sh` calls it for you.

## Themes

15 themes, each a single TOML file in `.config/hypr/themes/source/`:

| Light | Dark | Dynamic |
| :--- | :--- | :--- |
| Alabaster | Aetheria | **Dynamic** (pywal) |
| Akane | Catppuccin | **Matugen** |
| Eva Theme | Gruvbox | |
| Lavender | Noir | |
| Rosé Pine | Nord | |
| | One Dark | |
| | Osaka Jade | |
| | Tokyo Night | |

`SUPER + T` opens the theme picker in the ZenShell island. Switching a theme
rewrites the Hyprland borders, blur, rounding and shadow opacity, then re-tints
kitty, `nvim`, VSCodium, GTK and the CSS in one pass.

### Two themes are computed, not written

- **`dynamic`** runs `scripts/dynamic-colors.sh`, which shells out to `pywal`
  against your current wallpaper and generates `dynamic.lua` from the result.
- **`matugen`** hands the wallpaper to Matugen, which regenerates the palette the
  same way.

Both keep `current_theme.lua` in sync, so anything that needs to know *which*
theme is active — including ZenShell — reads one pointer rather than guessing.

## Installation

> **Recommended:** use the repository's top-level installer, which runs this
> component's setup and then symlinks it:
>
> ```bash
> git clone https://github.com/zenXD45/zenshell.git
> cd zenshell
> ./install.sh
> ```

Standalone, on **Arch Linux** or an Arch derivative (CachyOS, EndeavourOS,
Manjaro, Garuda):

```bash
./setup.sh    # packages, AUR deps, fonts
./install.sh  # symlink .config/* into ~/.config, link ~/scripts, copy wallpapers
```

Then `hyprctl reload`, or `SUPER + CTRL + R`.

`setup.sh` and `install.sh` are both idempotent — re-running them skips what's
already in place.

## Keybinds

ZenShell claims the plain `SUPER+` keys. These are the ones HyprZen keeps:

| Action | Shortcut |
| :--- | :--- |
| Terminal (kitty) | `SUPER + ENTER` |
| Browser (Firefox) | `SUPER + B` |
| Files (Thunar) | `SUPER + E` |
| Editor (VSCodium) | `SUPER + C` |
| wlogout | `SUPER + X` |
| Caffeine (hold off idle) | `SUPER + SHIFT + C` |
| Close window | `SUPER + Q` |
| Fullscreen | `SUPER + F` |
| Maximize | `SUPER + ALT + F` |
| Float | `SUPER + SHIFT + F` |
| Pseudo-tty | `SUPER + P` |
| Opaque / blur | `SUPER + O` |
| Focus | `SUPER + H/J/K/L` or arrows |
| Move | `SUPER + SHIFT + H/J/K/L` |
| Resize | `SUPER + ALT + arrows` |
| Workspace 1–10 | `SUPER + 1…0` |
| Send to workspace | `SUPER + SHIFT + 1…0` |
| Cycle workspace | `SUPER + CTRL + ←/→`, `SUPER + scroll` |
| Overview | `SUPER + TAB` |
| Scratchpad | `SUPER + S` |
| Screenshot (full / annotate / clipboard) | `Print` / `SUPER + Print` / `SUPER + CTRL + Print` |
| Lock | `SUPER + SHIFT + L` |
| Reload config | `SUPER + CTRL + R` |
| Exit Hyprland | `SUPER + CTRL + Q` |

Volume, mic, brightness and playback keys drive `wpctl` and `brightnessctl`
directly — no OSD daemon to install or keep alive.

Every binding is checked by `scripts/check_keybinds.py` at the repository root,
which fails CI if a bound binary isn't in the installer's package list.

## How theming works

The point of the generator is that **no palette is hand-edited downstream**.

```text
themes/source/<name>.toml     ← the only file you edit
        │
        │  scripts/gen-themes.py
        ▼
themes/<name>.lua             ← borders, blur, rounding, shadows
themes/<name>.conf            ← Hyprlang (animations, decorations)
themes/<name>.css             ← GTK (wlogout, etc.)
kitty/themes/<name>.conf      ← terminal colours
themes/themes.json            ← manifest read by the UI and switcher
```

`python3 scripts/gen-themes.py` regenerates all of it; `--check` fails if the
committed artifacts are stale. Geometry — gaps, borders, rounding, blur passes,
inactive opacity — comes from the same file, so a theme can change the *feel* of
the compositor, not just its colours.

## Structure

```text
hyprzen/
├── .config/
│   ├── hypr/            # core config, modules, themes
│   ├── kitty/           # terminal config + generated themes
│   ├── nvim/            # Neovim config, theme-aware
│   ├── wlogout/         # logout screen, theme-aware
│   ├── zsh/             # shell config (Oh My Zsh + Powerlevel10k)
│   ├── fastfetch/       # neofetch-style system info
│   └── wal/             # pywal templates
├── scripts/
│   ├── gen-themes.py           # theme generator
│   ├── theme-switch.sh         # apply a theme everywhere
│   ├── dynamic-colors.sh       # pywal → dynamic.lua / .conf
│   ├── wallpaper-selector.sh   # apply a wallpaper (island calls this)
│   ├── wallpaper-random.sh
│   └── caffeine.sh
├── wallpapers/          # per-theme wallpaper folders
├── install.sh           # symlink configs into ~/.config
└── setup.sh             # packages, AUR deps, fonts
```

## Notes

- **ZenShell is the only UI.** waybar, rofi, swaync and eww are gone by design,
  not by accident — see the [root README](../README.md#keybinds).
- **Nothing here hardcodes a path.** Configs resolve through `~/scripts`,
  `~/wallpapers` and `$HOME`, so the repo works wherever it's cloned.

---

<div align="center">
  <i>Stay minimal. Stay zen.</i>
</div>
