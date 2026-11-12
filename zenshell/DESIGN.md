# ZenShell menus — design system v2

The language is iOS grouped lists on dark glass: one large title, inset rounded
groups, hairline separators inside a group (never between groups), controls on
the right edge of their row. Accent is a state, not a decoration.

## Rules

1. **Rows, not cards.** A group is one rounded block (radius 14, fill
   `root.ink(0.055)`) containing rows. There is no per-row border, shadow, or
   background except hover/selection.
2. **Hairlines are inside groups only.** 1px, `root.ink(0.07)`, inset from the
   left to the text start (16px, or 50px when the row has a leading glyph) and
   16px from the right. The last row has no hairline.
3. **One accent per panel.** Accent fill marks on/active/selected only: switch
   tracks, slider fill and thumb, checkmarks, the active profile preview. No
   accent icons, no accent titles, no accent borders at rest.
4. **No boxed anything.** No icon tiles, no keycap chips, no value badges, no
   pill buttons in a header. Shortcuts are quiet mono text.
5. **Type floor is 11px.** `font.pixelSize` is an int in Qt — never a decimal.

## Metrics

| token | value | use |
| --- | --- | --- |
| big title | 17 / DemiBold / -0.2 tracking | panel header |
| row label | 14 | group rows |
| row value | 13, `ink(0.46)` | right-aligned state |
| secondary | 11 | descriptions, footer, counters |
| section label | 10 / DemiBold / 0.9 tracking / uppercase | group captions |
| row height | 42–46 (30 dense, 64 profile) | |
| group radius | 14 | |
| panel padding | 16 | all sides |
| gap between groups | 12 (`root.s3`) | |
| switch | 40 × 24, knob 20 | 160ms OutCubic |
| hairline | 1px `ink(0.07)` | |

## Panel anatomy

```
16 padding
title 17 .......................... meta 11 / gear 26     34
12
[ group ]  rows 42, hairline inset 16 (50 with icon)       n × 42
12
[ group ]                                                  ...
12
section label (optional)                                   24
content (list / empty state)                               fills
16 padding
```

## Components

- `Group` — rounded container; children are rows.
- `GroupRow` — icon / label / value / chevron / switch, hairline, hover wash.
- `SwitchControl` — iOS switch.
- `SectionLabel` — uppercase group caption.
- `MenuHeader` — title + optional meta and hint.
- `ListRow`, `SliderRow`, `IconButton`, `HintBar`, `EmptyState`,
  `NotificationItem` — supporting kit.

## Panels

| panel | size (logical) | notes |
| --- | --- | --- |
| Control Center | 460 × 620 | 3 connection rows, 2 sliders, 4 switches, notifications |
| Launcher | 460 × auto | rounded search field, one results group, one footer line |
| Power | 480 × 308 | one group of 5 rows, destructive row in red |
| Profiles | 460 × 260 | two 64px rows with schematic preview + checkmark |
| Clipboard | 560 × 288 | search field in header, one group of 48px rows |
| Keybinds | 680 × 600 | two columns; per-category label + group, action left / key right |
| Themes | 540 × 320 | one group of 46px rows: swatch, name, checkmark |
| Wallpapers | 540 × 220 | horizontal gallery, selected card gets a 2px accent ring |

## Don't

- Don't add a border to a group or a card to hold one row.
- Don't wrap a single row in its own container to "make it pop".
- Don't animate width/height on hover. Color and position only.
- Don't use more than two type sizes in a row.
