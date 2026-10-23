# DESIGN.md — ZenShell (AGS)

The visual system for the AGS v3 shell that replaces the Quickshell-based
ZenShell. This document records what was built, not what was planned.

## The world

The palette is not the shell's to choose. Every colour comes from the active
HyprZen theme's generated CSS (`~/.config/hypr/themes/<slug>.css`), which
`hyprzen/scripts/gen-themes.py` writes from one TOML per theme. That file is
plain GTK CSS — `@define-color` tokens — and GTK4 reads it natively, so the
shell loads it directly as its base stylesheet.

The tokens the shell consumes:

| Token | Role |
| :--- | :--- |
| `bg_base` | The opaque layer under every panel |
| `bg_surface` | The translucent layer over it |
| `bg_overlay` | Reserved; the shell does not use it directly |
| `accent` | Selection, focus, live state, the notification spine |
| `accent_soft` / `accent_glow` | Tinted fills behind accent marks |
| `text` | Primary type |
| `subtext` | Secondary type, values, section labels |
| `border_color` | The hairline on every panel |
| `urgent` | Destructive actions, critical state |

Because the shell reads the theme file, switching themes restyles every
surface at once — including the wallpapers' own `matugen` theme, which
rewrites the same TOML the generator consumes. One palette, one source.

## Material

One material, used by every panel:

- An **opaque base** in the theme's `bg_base`.
- The theme's **translucent `bg_surface`** over it.
- A **1px hairline** in `border_color` around the whole panel.
- A **soft shadow** below it, in `alpha(@bg_base, 0.62)`.
- A **14px radius**, matching the theme's own `rounding` scale.

The two-layer construction matters. The theme's `bg_surface` carries its own
alpha (0.88) — right for a bar over a wallpaper, too transparent for a panel
that has to be read over other windows. Layering an opaque base under it
keeps the exact theme hue while making the panel solid enough to read.

The bar is the exception: it uses `bg_surface` directly, because it sits
against the wallpaper rather than over content.

## Surfaces

### Bar

A 46px strip across the top edge, exclusive so windows do not overlap it.

Left to right: workspace pips, the focused window's class and title, then
battery, volume, network, power profile, clock and date, then the launcher
and power entry points.

The clock is a mono face at 13px. Values — battery percentage, volume,
SSID — are mono too, so they align in a column and read as measurements
rather than words. The window class is a quiet mono tag in front of the
title.

### Column

A 384px panel on the right edge, opened from the bar or `SUPER + N`. It is
the shell's control centre *and* its notification centre, in one downward
sweep: sound, display, connectivity, power, system, then notifications.

Section headings are `section-label`: 10px, uppercase, `0.14em` tracking,
`@subtext`. They name a group and stay quiet over the values beneath them.

Notifications are time-ranked rows. Each carries a 2px **accent spine** on
its left edge, the sending application's name in semibold, a mono timestamp
aligned right, the summary in `@text`, the body in `@subtext`, and action
buttons. The spine is the accent rule: a row the user has seen drops to a
quiet grey, so the live one is findable at a glance.

The list scrolls in a fixed-height region so the controls above it never
move when a notification arrives.

### Launcher

A 620px panel anchored to the bottom edge, opened with `SUPER + SPACE`. A
search field, then a six-column grid of the installed applications, each
tile showing the application's real icon resolved from the GTK icon theme
and its name. Applications come from the XDG desktop entries, so the grid is
exactly the user's own menu.

The grid is a `Gtk.FlowBox`, which wraps and honours a fixed column count,
so it stays a grid at any width.

### OSD

A compact overlay at the bottom edge for volume and brightness, shown by the
media keys and dismissed by itself after 2.5 seconds. It is driven by the
action that caused it, not by watching values for change, so a keypress is
acknowledged immediately and cannot be missed between polls.

### Power menu

Lock, log out, reboot and power off. The last two carry the theme's
`urgent` colour — the only place in the shell where a destructive action is
coloured, so the distinction is unmistakable.

## Type

Two faces, both already installed:

- **Fira Sans** for prose, labels and headings.
- **JetBrainsMono Nerd Font** for the clock, values, timestamps, the
  application class, and every icon glyph.

The scale is 10 / 11 / 12 / 13 / 19px. Section headings are 10px uppercase
and letter-spaced; body text is 12px; a notification summary is 12px in
`@text`; a value is 11px mono in `@subtext`; the clock is 13px mono in
`@text`.

## Alignment

GTK4 labels centre their own text, which is wrong for prose and wrong for
headings. Every label that carries a name — section headings, notification
summaries and bodies, the power menu's labels and descriptions, the
launcher's app names — is explicitly left-aligned through the `Text`
component.

## Icons

Icons come from the Nerd Font, at one weight, at the sizes the context
needs: 15px in the bar and the control rows, 17px in the power menu, 19px
in the launcher, 22px in the OSD. Application tiles use the real desktop
icon instead.

## Motion

The shell does not animate its panels in. GTK's window mapping is immediate
and the panels are positioned by the compositor. The one motion in the shell
is the OSD appearing and disappearing, which is a value change rather than
an entrance.

## What this shell does not do

- No blur or backdrop filter: GTK4's CSS has neither, and the shell's
  translucency comes from the theme's own alpha instead.
- No hover animations: GTK4 has no CSS transitions on most properties.
- No gradients, no glows, no glass effects beyond what the theme's own
  tokens provide.

Those are not omissions of taste but limits of the platform, and a shell that
pretends otherwise is a shell that lies about what it can do.
