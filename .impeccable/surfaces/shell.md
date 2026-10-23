# Surface Brief — ZenShell AGS

## Scope and visitor mode

Mode: **Operate**. The visitor is the user at their desk, mid-session, reaching
for a control or a notification. This surface is the AGS v3 replacement for the
Quickshell ZenShell. Surfaces in scope: bar, control centre, notification
centre, app launcher, OSD, power menu. Plus the notification daemon itself,
which AGS must own once Quickshell is retired.

Platform: native GTK4 / Wayland layer-shell desktop. The design language is CSS
(GTK CSS). No browser, no network origin. The viewport is the monitor.

## Audience, job, action, proof, constraints

- **Audience:** one power user, Hyprland on CachyOS, treats the desktop as a
  project.
- **Job:** read and change system state without leaving the keyboard path.
- **Action:** adjust sound, display and connectivity; read notifications; launch
  an app; change power state.
- **Proof:** live values from the real system — real volume percentage, real
  SSID, real battery charge, real workspace and window counts, real
  notification text.
- **Constraints:** one palette for the whole desktop (the generated
  `@define-color` CSS is the only colour authority); no hardcoded colour
  anywhere in the shell; every surface must be reachable and dismissible by
  keyboard; GTK4 CSS dialect only — no CSS features GTK4 lacks.

## Established world (inherited, not invented)

The visual identity is settled by the existing HyprZen system and must be
inherited, not replaced:

- **Palette:** 15 generated themes. Active theme's `current.css` supplies
  `bg_base`, `bg_surface`, `bg_overlay`, `accent`, `accent_soft`,
  `accent_glow`, `secondary`, `text`, `subtext`, `border_color`, `urgent`.
  AGS consumes that file directly — no translation layer.
- **Material:** translucent glass pane, `rgba(surface, 0.88)`, 1px
  `border_color` hairline, soft downward shadow, inner top light.
- **Radius:** from the theme's own `geometry.rounding` (12–18 across themes).
- **Type:** Fira Sans for prose and labels, Nerd Font mono for clock, values
  and glyphs. JetBrainsMono Nerd Font and Fira Sans are both installed.
- **Motion:** long decelerating arrival (300ms), quicker exit (150ms), 220ms
  base. The existing Quickshell shell's rhythm is the reference.

## Chosen direction

**Column** — one vertical instrument on the right edge, read top to bottom,
with a detached top bar for the always-visible line (workspaces, active
window, clock, power). Control and notifications share the column so status
is one place rather than scattered.

Memorable moment: the notification list ranks by time inside the same column
as the controls, so a new notification arrives into a list you are already
reading rather than into a separate window you have to find.

## Unresolved decisions

- Whether the dock, spotlight, clipboard, theme/wallpaper pickers, cheatsheet
  and settings app get ported later. Out of scope this pass; the launcher
  already provides app search.
- Whether AGS takes over the notification daemon immediately or coexists with
  Quickshell during a transition window.

## Direction contract

**THESIS:** The shell is one vertical instrument on the right edge and one
horizontal line at the top; it refuses the category default of scattering
status across a bar, a corner widget and a popup layer.

**OWN-WORLD:** Translucent glass panes over the wallpaper, hairline borders
tinted by the theme accent, one accent colour carrying selection, focus and
live state, Fira Sans prose against Nerd Font mono numerals, radius taken
from the theme's own rounding value.

**STORY:** The user opens the column to adjust sound, display and
connectivity, and reads notifications in the same downward sweep. The top bar
answers "where am I and what is running" without being opened. Every value
shown is real, read from the live system.

**FIRST VIEWPORT:** A 46px detached top bar across the top edge: five
workspace pips at left, the active window title, then at right the battery,
volume and network glyphs with values and the clock. A 384px column anchored
to the right edge from 66px below the bar to 22px above the bottom, rounded
22px, holding in order: a section label with the network name, the volume
slider, the brightness slider, connectivity chips, then the notification
list as time-ranked rows with a 2px accent spine per row and action buttons
on the newest row.

**FORM:** Third in my grounded list of seven compositions — independent
floating capsules, an edge-docked rail, the column, a bottom shelf, a
single centred stage, a split column, and a full-bleed overlay. The roll
dealt index 3, and the column is the one that keeps control and notifications
in one sweep without taking the whole screen.

**SEED REFERENCE:** seed:85c13100d48c88f4

**FINISH:** unreviewed and undocumented is unfinished; this build ends with
the finish review, the verdict, DESIGN.md, and every shipping raster carrying
its provenance
