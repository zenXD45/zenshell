# Hyperframes Composition Brief: ZenShell

## Objective

Create a short launch-style brag video for **ZenShell** — a Hyprland desktop shell
written in Quickshell that replaces waybar, rofi, swaync and eww with one glassmorphic
UI process.

Every product frame in this video is a **real screenshot of the real running shell**,
captured on the maintainer's own machine. Do not recreate, redraw, or mock up any of
the ZenShell UI. The screenshots are the product.

## Output

- Composition directory: `brag-output-2026-10-22-083236/composition/`
- Rendered video: `brag-output-2026-10-22-083236/brag.mp4`
- Format: landscape — 1920x1080
- Duration: 21.8 seconds

## Source Material

- Project root: `/home/zen/zenshell`
- Primary files read: `README.md`, `PROJECT.md`,
  `hyprzen/.config/hypr/themes/source/osaka-jade.toml`,
  `hyprzen/.config/hypr/themes/osaka-jade.css`,
  `zenshell/components/ControlPanel.qml`, `zenshell/components/CameraPanel.qml`,
  `zenshell/shell.qml`
- Source of truth: the **live running shell** at `~/.config/quickshell/dynamic-island`
  (deployed copy, which is ahead of the repo), captured live with `grim`
- Product name: **ZenShell**
- Tagline / strongest claim: *"It replaces rofi, waybar, swaync **and** eww in one
  process."* — and the README's own framing: *"ZenShell is the only UI."*
- Key UI or visual moment to recreate: **none — do not recreate anything.** Present the
  real captures. The one thing to author is the typography layer that sits over them.
- Copy that must appear verbatim:
  - `rofi · waybar · swaync · eww`
  - `Gone.`
  - `Control Centre`
  - `Network, Bluetooth, Caffeine, Night Light`
  - `Spotlight`
  - `Search apps or calculate.`
  - `SUPER + SPACE`
  - `Camera Effects`
  - `Virtual webcam + virtual mic`
  - `Theme Switcher`
  - `15 themes, generated — never hand-edited`
  - `ZenShell`
  - `The shell is the entire UI.`
  - `15 themes` / `2 shell profiles` / `one installer`

### Prepared screenshot assets (already in `composition/assets/shots/`)

Every asset is a **live capture of the running shell**, taken from the real
Quickshell instance on the real machine (1920×1080, native, no upscaling, no
redrawing). The theme in every frame is **Osaka Jade** — the theme the shell is
actually running right now.

| File | Source | What it shows |
|---|---|---|
| `desktop.jpg` | live capture, no panel open | Real desktop: pixel-art town wallpaper, ZenShell's island clock pill, the glass clock widget `Good morning, Zen / 09:38 / Thursday, October 22`, the weather widget `21° Sunny / 28° 15°` |
| `control.jpg` | live capture, `island_ctl.sh control` | Real Control Centre: Network, Bluetooth, **Camera**, Caffeine, Night Light, Do Not Disturb, Mic, brightness + volume sliders, the live `Caffeine Enabled` notification, `PROFILE 01` chip |
| `launcher.jpg` | live capture, `island_ctl.sh launcher` | Real Spotlight: the field reads `Search apps or calculate…` with an `esc` chip, and the results `About Xfce` / `Advanced Network Configuration` / `Alacritty` / `btop++` / `Btrfs Assistant` |
| `camera.jpg` | live capture, `island_ctl.sh camera` | Real `Camera Effects` panel: header `Camera Effects / Live · Integrated_Webcam_HD: Integrate`, live webcam preview, tabs `Video Look Fun Mic Privacy`, `PRESETS` (`Clean Portrait Studio Call Gaming`), `CAMERA`, `Center Stage` ON, `Follow` / `Zoom`, footer `idle · 1280×720 · 30 ms · 20 fps` |
| `themes.jpg` | live capture, `island_ctl.sh themes` | Real Theme Switcher: Nord, One Dark, Osaka Jade (selected, green check), Rosé Pine, Tokyo Night, and the panel's own `13 / 15` counter |

**How these were captured.** The shell is live in this session, so the captures are
real: `~/.config/quickshell/dynamic-island/island_ctl.sh <panel>` opens each surface
through its own IPC, `grim` grabs the output, and the panel closes again. Nothing is
mocked, restyled, or composited — each frame is the untouched screen.

### Overlay coordinates (measured on the 1920×1080 assets, inside the scaled shot wrapper)

Because the shot wrapper is Ken-Burns scaled, **overlays that must track the UI live
inside `.shot`**, in the same 1920×1080 coordinate space as the asset.

`launcher.jpg`:
- search field caret: `left 712, top 32, w 3, h 44`
- result rows (outline box `left 676, w 540, h 56`):
  - `Advanced Network Configuration` → `top 170`
  - `Alacritty` → `top 237`
  - `btop++` → `top 302`

`themes.jpg` (outline box `h 100, top 120`):
- Nord `left 603 w 120` · One Dark `left 753 w 124` · Osaka Jade `left 907 w 120`
- Rosé Pine `left 1050 w 120` · Tokyo Night `left 1223 w 120`

## Creative Direction

- Tone preset: `app-store`
- Creative direction: a real product film for a real desktop — glassmorphic, confident,
  feature-forward, shot entirely on the real machine.
- Interpretation: clean reveals, no jokes, no mess. Every scene is the actual screen
  with one tight caption card. Motion is a slow camera push plus a single card
  entrance. Confidence through restraint, never through effects.
- Angle: most Linux shell videos are a wallpaper loop with a bar on top. ZenShell's
  claim is that the shell *is* the desktop. The video proves it by showing the real
  glass panels, the real keybinds, the real generated themes — and by naming the four
  daemons ZenShell deletes.
- Hook: the calm real desktop, then `rofi · waybar · swaync · eww`, then one huge
  accent word: `Gone.`
- Outro / punchline: `ZenShell` / `The shell is the entire UI.` /
  `15 themes · 2 shell profiles · one installer`.
- Avoid:
  - Generic SaaS language
  - Abstract filler visuals
  - Recreating, redrawing, or inventing any ZenShell UI
  - Mock-ups, wireframes, or placeholder panels that could belong to any product

## Visual Identity

Taken from the theme the shell is **actually running** — Osaka Jade, generated by
`hyprzen/gen-themes.py` from `hyprzen/.config/hypr/themes/source/osaka-jade.toml`:

- Background: `#1e1e2e` — surface `rgba(24,24,37,0.88)` — overlay `rgba(17,17,27,0.75)`
- Text: `#d3c6aa` — subtext `#9da9a0` — accent `#1db954` — urgent `#e67e80`
- Display font: **Fira Sans** — the project's own UI font (`install.sh` installs
  `ttf-fira-sans`). Ship it as a local `@font-face` from
  `assets/fonts/FiraSans-{Regular,SemiBold,Bold}.ttf`.
- Mono font: **JetBrains Mono** (bundled by the renderer) for the `SUPER + SPACE`
  keycap. The project uses a Nerd Mono face for exactly this job.
- Visual references from the project: the glass panel language — near-black translucent
  surfaces, 14–24px rounding, a green hairline border, heavy backdrop blur.

## Storyboard

Scene summary (absolute composition time):

1. **"Gone."** — 0.00–3.30 — real desktop, `rofi · waybar · swaync · eww`, then `Gone.`
2. **Control Centre** — 3.30–6.50 — real Control Centre panel, slow push-in on it
3. **Spotlight** — 6.50–10.00 — real Spotlight launcher, blinking caret, selection
   walks down three real result rows, `SUPER + SPACE` keycap
4. **Camera Effects** — 10.00–13.10 — real Camera Effects panel with the live webcam
   preview; caption card enters top-left
5. **Theme Switcher** — 13.10–17.00 — real Theme Switcher; a green outline walks the
   five real theme tiles
6. **Lockup** — 17.00–21.80 — real desktop; `ZenShell`, the tagline, then the three
   README counters

Full detail in `../brag-plan.md`.

## Audio

- Audio role: warm bed — one steady, clean music track under a consistent light SFX layer.
- Audio arc: bed at 0.30 throughout, decaying from 19.6s to 21.8s under the lockup.
- Music: `assets/music/zenshell-bed.mp3` — `happy-beats-business-moves-vol-12` trimmed
  to 21.8s with a 0.5s fade-in and a 2.2s fade-out baked in. (The source track lives at
  `<skill-dir>/assets/music/`; the trimmed bed is already in the project.)
- Music treatment: `data-volume="0.50"` (the bed is mastered to −12.3 LUFS at unity,
  landing the mix at ≈ −18 LUFS). Never above 0.5.
- Music cue guidance: bundled preset —
  `assets/cues/happy-beats-business-moves-vol-12-by-ende-dot-app.music-cues.json`
  (109.96 BPM).
  - strongCue locks (3, the max): **10.93s** (Camera Effects card), **17.47s**
    (ZenShell lockup), **18.56s** (tagline)
  - beat-grid: **1.64s** (`Gone.`), **7.64 / 8.19 / 8.74s** (spotlight selection travel),
    **14.20 / 14.73 / 15.29 / 15.84 / 16.38 / 16.93s** (six theme tiles)
- Audio-reactive treatment: subtle. `assets/audio-data.json` holds 654 frames × 16
  bands at 30fps (extracted from the trimmed bed with
  `hyperframes-creative/scripts/extract-audio-data.py`). Drive the accent glow behind
  the `Gone.` word and the caption cards' border warmth from RMS + band energy. No
  waveform, no equalizer bars, no musical-note graphics, no strobing.
- Audio-coupled moments:
  - 1.64s — `Gone.` slam, weighty bell
  - 7.64 / 8.19 / 8.74s — soft click per Spotlight row the selection visits
  - 10.93s — toggle click on the Camera Effects reveal
  - 14.20 → 16.38s — one very light drop per theme tile
  - 17.47s — logo payoff bell under the `ZenShell` lockup
- SFX selection guidance: low/medium HF-risk files only —
  `interface/click_003` (selection, simulated user action), `interface/select_008`
  (navigation), `interface/switch_002` (mode change), `interface/drop_003` (sequential
  item), `impact/impactBell_heavy_000` (major reveal), `impact/impactBell_heavy_003`
  (logo payoff). These are already copied into `assets/sfx/`.
- SFX analysis guidance: `<skill-dir>/assets/sfx/sfx-analysis.md`
- Exact SFX choice: Hyperframes chooses filenames, timestamps, density, and volume
  based on the implemented animation.
- Audio files: already copied into `composition/assets/`.

## Hyperframes Instructions

Load the composition-building Hyperframes domain skills — `hyperframes-core`
(composition contract + `data-*` timing), `hyperframes-animation` (motion),
`hyperframes-creative` (design spec, beats, audio-reactive), `hyperframes-keyframes`
(seek-safe keyframes), and `hyperframes-cli` (lint/check/render). /brag is its own
workflow: do not enter the `hyperframes` entry-point intent interview and do not route
into its generic promo / launch-video workflow. Prefer native Hyperframes conventions
over anything in `/brag`.

Requirements:

- Show the real ZenShell UI — every product frame is a supplied screenshot; never
  rebuild it.
- Keep all text readable in the final render (in-feed sizing: headlines ≥ 90px,
  body ≥ 32px, labels ≥ 24px).
- Keep the video within 15–25 seconds (21.8s).
- Include the planned music/SFX layer.
- Honor the planned music treatment (bed at 0.30, baked fade-out).
- Use only 1–3 strong-cue locks; mark them `// beat-locked:`.
- Snap sequential reveals to the beat grid within ±0.10s; mark them `// beat-grid:`.
- Use local assets for audio and media; never absolute paths.
- Run `npx hyperframes check` before render — brag's single gate.
- Keep creation and rendering local.
