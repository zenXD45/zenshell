# Product

<!-- impeccable:product-schema 1 -->

## Platform

web

<!-- The design language this product renders is CSS, so it is recorded as
`web` per the schema. Concretely it is a GTK4/CSS desktop shell: the
stylesheet dialect is GTK CSS, the layout engine is GTK's, and the surface is
a Wayland desktop rather than a document. No browser, no network origin, no
responsive breakpoints — the viewport is the monitor. -->

## Stack

AGS v3 (Go/GJS rewrite, gnim reactivity, TSX/JSX) on GTK4, layered with
`Astal.Window` (layer-shell) for desktop surfaces. TypeScript in `.tsx` files.
No build step: `ags run` compiles TSX directly via the bundled esbuild.

## Users

A single power user on CachyOS running Hyprland on Wayland. They treat their
desktop as a project: they keep a dotfiles repo (`~/zenshell`) with generated
theme artifacts, they switch 15 named themes at will, and they expect every
keybind to resolve to a binary that actually exists. They are comfortable
reading source and will audit how a feature is wired.

## Product Purpose

Replace the Quickshell-based ZenShell with an AGS v3 shell that provides the
same daily-driver surfaces — bar, control centre, notification centre, app
launcher, OSD, power menu — at lower memory cost and with native GTK4
theming. Success means the desktop feels finished: no surface is a
placeholder, no action silently does nothing, and the shell is one coherent
object rather than a dozen unrelated windows.

## Positioning

A single-theme-aware shell: the same generated `@define-color` CSS that drives
Hyprland, Kitty and Neovim also drives every AGS surface, so the whole
desktop tints from one wallpaper or one theme choice with no second palette
to maintain.

## Operating Context

- Wayland compositor: Hyprland (IPC via `hyprctl`).
- Theme pipeline: `zenshell/hyprzen/scripts/gen-themes.py` reads one TOML per
  theme from `hypr/themes/source/` and emits `<slug>.css` containing GTK
  `@define-color` tokens plus Hyprlang, Lua and Kitty artifacts. `current.css`
  is a symlink to the active theme's CSS.
- Wallpaper-derived themes: `matugen` rewrites `themes/source/matugen.toml`
  from the current wallpaper; `dynamic` uses pywal.
- Theme switching: `hyprzen/scripts/theme-switch.sh <slug>` relinks
  `current.css` and reloads Hyprland. It does not know AGS exists.
- Available system services on this machine: NetworkManager, BlueZ,
  PowerProfiles, UPower, PipeWire/PulseAudio, `hyprctl`, `brightnessctl`,
  `playerctl`, `cliphist`, `wl-paste`, `matugen`.
- Not installed: the Astal service libraries (`AstalBattery`, `AstalMpris`,
  `AstalHyprland`, `AstalNotifd`, `AstalWireplumber`). Only core `Astal` and
  `AstalIO` exist, so system state must be read over CLI, D-Bus, or `/sys`.

## Capabilities and Constraints

- AGS v3 API surface: `app.start()`, intrinsic JSX widgets, `createState`,
  `createBinding`, `createComputed`, `createPoll`, `createEffect`, `For`,
  `Fragment`. Reactive values are Accessors, not `Variable`.
- JSX only parses in `.tsx` files; a `.ts` file with JSX is a syntax error.
- `Astal.Window` exposes anchor, exclusivity, keymode, layer, monitor and
  per-edge margin. Layer-shell surfaces are not XDG toplevels and do not
  appear in `hyprctl clients`.
- AGS v3 owns its own D-Bus name `io.Astal.<instanceName>`; `ags run` in
  `~/.config/ags` auto-discovers `app.ts`.
- GTK4 CSS supports `@define-color`, `rgba()`, `alpha()` and `color-mix()`,
  so the existing generated theme CSS applies without a translation layer.
- Notification daemon ownership must move from Quickshell to AGS; both
  cannot serve `org.freedesktop.Notifications` at once.
- Undecided: whether the AGS shell keeps the dock, spotlight, clipboard,
  theme/wallpaper pickers, cheatsheet and settings app, or whether a
  separate follow-up pass adds them.

## Brand Commitments

- One palette for the whole desktop. The theme TOML files are the only place
  a colour is defined; no shell hardcodes a colour.
- Every keybind resolves to a binary that ships. A binding to a missing
  command is a bug, not a placeholder.
- Install correctness is a hard requirement: a fresh install must produce a
  working desktop.

## Evidence on Hand

- `hyprzen/scripts/gen-themes.py` — the theme generator and its `@define-color`
  CSS contract.
- `hypr/themes/themes.json` — the manifest of 15 themes with accent, bg,
  surface, fg and rounding per theme.
- `hypr/themes/source/*.toml` — per-theme source of truth including geometry
  (rounding, gaps, border size, shadow colour).
- `hypr/modules/keybinds.lua` — the existing binding scheme and its
  `SUPER`-rooted convention.
- `zenshell/dynamic-island/shell.qml` — the incumbent Quickshell shell, and the
  reference for which surfaces matter to this user.
- No product imagery, marketing copy, testimonials or benchmarks exist for
  this shell. None may be invented.

## Product Principles

1. **One palette, many surfaces.** A theme change must reach the bar, the
   panels and the OSD in the same instant, without a second source of truth.
2. **Every surface earns its place.** A shell that opens but does nothing is
   worse than no shell.
3. **Native over imitate.** GTK4 widgets and layer-shell behave like GTK4 and
   layer-shell; do not rebuild them in another medium's idiom.
4. **Lightweight by construction.** Polling only while a widget is visible;
   no daemon-style background work that a desktop shell does not need.
5. **The daily path is fast.** Switching theme, launching an app, adjusting
   volume and dismissing a notification are all one action away.

## Accessibility & Inclusion

Contrast for body text at or above 4.5:1 against the active theme's surface
is required, and secondary text is tinted from the theme's own hue rather
than neutral grey. Every interactive surface is reachable by keyboard, and
focus is visible. All colour-coded status (battery, network, recording) also
carries a text or glyph label so it does not depend on hue alone.
