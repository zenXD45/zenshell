# Brag Plan: ZenShell

## What is this app?

ZenShell is a complete Hyprland desktop shell written in Quickshell/QML — it replaces
waybar, rofi, swaync and eww with a single glassmorphic UI process (dynamic island,
dock, spotlight, clipboard, cheatsheet, control centre, theme & wallpaper pickers,
camera-effects panel).

## The angle

Most Linux shell videos are a wallpaper loop with a bar on top. ZenShell's claim is
harder and more specific: **the shell IS the desktop**. Every screenshot in this video
is the real thing running on the real machine, captured live off the running
Quickshell instance — the same glass panels, the same keybinds, the same generated
themes, the same live webcam feed.

The hook is subtraction: name the four daemons ZenShell deletes, then say "Gone."

## Hook (first 2-3 seconds)

A calm, full-bleed shot of the real desktop (pixel-art Japanese town wallpaper,
ZenShell's dynamic-island clock pill at top-center, the glass clock widget reading
`09:38 / Good morning, Zen` and the weather widget `21° Sunny` on the right). Over it,
small type: `rofi · waybar · swaync · eww`. Then one huge accent word: **`Gone.`**

## Key moments (the middle)

- **The Control Centre** — the real glass panel: Network, Bluetooth, **Camera**,
  Caffeine, Night Light, Do Not Disturb, Mic, brightness + volume sliders, and the
  live notification stack underneath.
- **Spotlight** — `SUPER + SPACE` opens the launcher whose own placeholder reads
  "Search apps or calculate…". A caret blinks in the field and the selection walks
  down the real result list.
- **Camera Effects** — a virtual webcam and virtual microphone built into the shell:
  a live preview, `Video Look Fun Mic Privacy` tabs, presets
  (`Clean Portrait Studio Call Gaming`), a `Center Stage` toggle, `Follow` / `Zoom`
  sliders. Nobody expects a desktop shell to own the webcam pipeline.
- **The Theme Switcher** — the real theme grid: Nord, One Dark, Osaka Jade (live),
  Rosé Pine, Tokyo Night, with the panel's own counter reading `13 / 15`.

## Outro / punchline

The real desktop again, quiet, with the lockup: **ZenShell** — "The shell is the
entire UI." — then the README's own counters: `15 themes · 2 shell profiles · one
installer`.

## User flow worth showing

1. **Entry** — the desktop at rest. ZenShell's island, clock and weather widgets are
   already the only chrome; no waybar, no rofi.
2. **Key action** — `SUPER + SPACE` → Spotlight (`SUPER + N` → Control Centre,
   `SUPER + ALT + C` → Camera Effects, `SUPER + T` → Theme Switcher).
3. **Result** — every destination is a ZenShell surface over the same wallpaper, and
   the shell stays a single process throughout.

## Tone

- Preset: `app-store`
- Creative direction: a real product film for a real desktop — glassmorphic, confident,
  feature-forward, shot entirely on the live machine.
- Interpretation: clean reveals, no jokes, no mess. Every scene is the actual screen
  with one tight caption card. Motion is a slow camera push plus a single card
  entrance — confidence through restraint, never through effects.

## Format: landscape — 1920x1080
## Duration: 21.8s

## Visual identity (from the project)

Source: the theme the shell is **actually running right now** —
`hyprzen/.config/hypr/themes/source/osaka-jade.toml` and the generated
`hyprzen/.config/hypr/themes/osaka-jade.css`. The video matches the live desktop, not
a different theme.

- Background: `#0f1715` — surface `rgba(24,34,31,0.88)` — overlay `rgba(8,12,11,0.75)`
- Accent: `#1db954` (Osaka Jade green) — the one accent used for emphasis
- Text: `#d3c6aa` — subtext `#9da9a0` — urgent `#e67e80`
- Display font: **Fira Sans** (the project's UI font, installed by `install.sh`)
- Mono font: **JetBrains Mono** for the `SUPER + SPACE` keycap — the project's terminal
  and icon-glyph face
- Strongest visual element: the real glass panel language — near-black translucent
  surfaces, rounded corners, a green hairline border, heavy backdrop blur

## Share copy (draft)

I deleted waybar, rofi, swaync and eww and wrote the whole desktop in one Quickshell
process. It even owns the webcam.

## Audio direction

- Role: warm bed — one steady, clean music track under a consistent light SFX layer.
- Music: `happy-beats-business-moves-vol-12-by-ende-dot-app.mp3` (steady and clean,
  109.96 BPM, 117.36s), trimmed to 21.8s with a 0.5s fade-in and a 2.2s fade-out baked
  in, then peak-limited and mastered to −12.3 LUFS at unity.
- Music treatment: composition `data-volume="0.50"` → the bed lands at ≈ −18 LUFS in
  the finished mix. Fade out from 19.6s to 21.8s so the lockup lands on a decaying
  bed. Never above 0.5.
- Music cue guidance: bundled preset at
  `assets/cues/happy-beats-business-moves-vol-12-by-ende-dot-app.music-cues.json`
  (109.96 BPM).
  - strongCue locks (3, the max): **10.93s** (Camera Effects card), **17.47s**
    (ZenShell lockup), **18.56s** (tagline)
  - beat-grid: **1.64s** (`Gone.`), **7.64 / 8.19 / 8.74s** (Spotlight selection
    travel), **14.20 / 14.73 / 15.29 / 15.84 / 16.38s** (five theme tiles)
- Audio-reactive treatment: subtle. `assets/audio-data.json` holds 654 frames × 16
  bands at 30fps (extracted with `hyperframes-creative/scripts/extract-audio-data.py`).
  The hero glow behind `Gone.` breathes with RMS + bass, and the caption cards' green
  hairline warms with the same envelope. No waveform, no equalizer bars, no
  musical-note graphics.
- SFX posture: sparse-but-consistent. Low/medium HF-risk files only.
- Audio-coupled moments:
  - 1.64s — `Gone.` slam, weighty bell
  - 7.64 / 8.19 / 8.74s — soft click per Spotlight row the selection visits
  - 10.93s — a toggle click on the Camera Effects reveal
  - 14.20 → 16.38s — one very light drop per theme tile
  - 17.47s — logo payoff bell under the `ZenShell` lockup
- Restraint rule: no risers, no whooshes, no drums over the copy. The music is a bed,
  not a driver; nothing may play over the 17.5–21.8s lockup except the bed.

## Storyboard

### Scene 1 — "Gone." — 3.3s (0.00–3.30)

Full-bleed live capture of the real desktop (`assets/shots/desktop.jpg`): pixel-art
town wallpaper, ZenShell's island clock pill, the glass clock widget
`Good morning, Zen / 09:38 / Thursday, October 22`, and the weather widget
`21° Sunny`. Slow push-in, scale 1.02 → 1.08.

- 0.35 — type `rofi · waybar · swaync · eww` fades in, letter-spaced, centred.
  **Hold ≥1.2s.**
- 1.64 — display word `Gone.` slams in large, accent green `#1db954`. **Hold ≥1.4s.**
  (`// beat-locked: 1.64s`)
- 2.50 — small lockup fades in bottom-left: `ZenShell` + a `Hyprland` chip.

Sequential/interaction: yes — two text arrivals (label, then the payoff word), then a
small lockup.
Audio intent: confident, quiet authority; one weighty hit under "Gone."
Audio-coupled idea: the "Gone." slam lands on the beat at 1.64s with a single bell.
Music: steady, clean, low.
Transition mood: clean → Scene 2

### Scene 2 — Control Centre — 3.2s (3.30–6.50)

Full-bleed live capture of the real Control Centre (`assets/shots/control.jpg`): the
glass panel with Network / Bluetooth / **Camera** tiles, Caffeine / Night Light / Do
Not Disturb / Mic, brightness + volume sliders, and the live `Caffeine Enabled`
notification. The clock and weather widgets stay on the right. Slow push-in toward the
panel, scale 1.00 → 1.07.

- 3.79 — caption card slides in bottom-left: title `Control Centre`, subtext
  `Network, Bluetooth, Camera, Caffeine`. **Hold ≥1.6s.**

Sequential/interaction: no — one card entrance, then a held reveal.
Audio intent: soft, presentational.
Audio-coupled idea: a soft drop on the card landing.
Music: steady, clean, low.
Transition mood: clean → Scene 3

### Scene 3 — Spotlight — 3.5s (6.50–10.00)

Full-bleed live capture of the real Spotlight launcher (`assets/shots/launcher.jpg`):
the field reads `Search apps or calculate…` with an `esc` chip, and the result list
runs `About Xfce` / `Advanced Network Configuration` / `Alacritty` / `btop++` /
`Btrfs Assistant`.

- 6.95 — caption card with a `SUPER + SPACE` keycap: title `Spotlight`, subtext
  `Search apps or calculate.` **Hold ≥1.6s.**
- 6.85 — a caret blinks inside the real search field.
- 7.64 → 8.19 → 8.74 — a green outline walks three real result rows
  (`Advanced Network Configuration` → `Alacritty` → `btop++`).
  (`// beat-grid: row 1 at 7.64s, row 2 at 8.19s, row 3 at 8.74s`)

Sequential/interaction: yes — simulated arrow-key navigation down a real result list.
Audio intent: light, tactile, like a fast keyboard.
Audio-coupled idea: one soft click per row the selection visits.
Music: steady, clean, low.
Transition mood: clean → Scene 4

### Scene 4 — Camera Effects — 3.1s (10.00–13.10)

Full-bleed live capture of the real `Camera Effects` panel
(`assets/shots/camera.jpg`): the header `Camera Effects / Live · Integrated_Webcam_HD:
Integrate`, a live webcam preview, the tabs `Video Look Fun Mic Privacy`, `PRESETS`
(`Clean Portrait Studio Call Gaming`), `CAMERA`, the `Center Stage` toggle ON, and the
`Follow` / `Zoom` sliders, with the live `idle · 1280×720 · 30 ms · 20 fps` footer.
Slow push-in, scale 1.00 → 1.07.

- 10.93 — caption card enters **top-left** (the panel fills the frame, so the card
  sits clear of it): title `Camera Effects`, subtext `Virtual webcam + virtual mic`.
  **Hold ≥1.6s.** (`// beat-locked: 10.93s`)
- 12.05 — four real feature chips fade up under the subtext: `Center Stage`,
  `Presets`, `Ambience`, `Reactions`.

Sequential/interaction: yes — the card and then the chip row.
Audio intent: a beat of surprise; the feature is the payoff.
Audio-coupled idea: a toggle click exactly on the reveal.
Music: steady, clean, low, with the bed opening up slightly across this scene.
Transition mood: clean → Scene 5

### Scene 5 — Theme Switcher — 3.9s (13.10–17.00)

Full-bleed live capture of the real Theme Switcher (`assets/shots/themes.jpg`): the
panel's own title, `13 / 15` counter, and the live theme tiles Nord, One Dark,
Osaka Jade (selected, green check), Rosé Pine, Tokyo Night. Slow push-in, scale
1.00 → 1.06.

- 13.64 — caption card enters bottom-left: title `Theme Switcher`, subtext
  `15 themes, generated — never hand-edited`. **Hold ≥1.6s.**
- 14.20 → 16.38 — a green outline walks five real theme tiles, one per beat.
  (`// beat-grid: 14.20, 14.73, 15.29, 15.84, 16.38`)

Sequential/interaction: yes — five sequential highlights over the real theme tiles.
Audio intent: light, percussive texture; nothing loud.
Audio-coupled idea: one very light drop per tile, all at low volume.
Music: steady, clean, low.
Transition mood: soft → Scene 6

### Scene 6 — Lockup — 4.8s (17.00–21.80)

The real desktop again, slow pull-back, scale 1.06 → 1.00, over a bottom-left scrim.

- 17.47 — display lockup `ZenShell` enters bottom-left. (`// beat-locked: 17.47s`)
  **Hold ≥0.9s.**
- 18.56 — tagline `The shell is the entire UI.` fades in under it.
  (`// beat-locked: 18.56s`) **Hold ≥1.5s.**
- 19.10 — a row of three chips slides in along the bottom: `15 themes`,
  `2 shell profiles`, `one installer`. **Hold ≥2.0s.**
- The lockup **holds to the last frame** — it is the poster, so nothing fades out
  under it. The music fades from 19.6s to 21.8s and leaves the lockup clean.

Sequential/interaction: yes — three staged arrivals building the final card.
Audio intent: resolved, quiet, a little air under the lockup.
Audio-coupled idea: a single logo-payoff bell under the lockup, then the bed decays.
Music: steady bed fading from 19.6s to 21.8s.
Transition mood: hold → end

**Music mood for this video:** steady, clean, corporate-adjacent — a bed, never a driver.
**Audio summary:** one 109.96 BPM bed at low volume with a light, consistent SFX layer —
a bell under "Gone.", soft clicks walking the Spotlight list, a toggle on the Camera
Effects reveal, light drops across the theme tiles, and a logo bell on the lockup.

## Grounding notes

Every on-screen claim traces to the repo:

| On screen | Source |
|---|---|
| `rofi · waybar · swaync · eww` / `Gone.` | README: "rofi, waybar, swaync and eww were removed rather than left dormant" |
| `Control Centre`, `Network, Bluetooth, Camera, Caffeine` | `zenshell/components/ControlPanel.qml` + the live capture |
| `Spotlight`, `Search apps or calculate.` | `zenshell/modules/spotlight` + the live capture |
| `SUPER + SPACE` | README keybind table: "App launcher — `SUPER + Space`" |
| `Camera Effects`, `Virtual webcam + virtual mic` | README: "A virtual webcam and virtual microphone" |
| `Center Stage`, `Presets`, `Ambience`, `Reactions` | README camera-effects bullet + `CameraPanel.qml` |
| `Theme Switcher`, `15 themes, generated — never hand-edited` | README: "15 themes, one source of truth"; "Themes are generated, never hand-edited." |
| `ZenShell` / `The shell is the entire UI.` | README: "A Hyprland desktop where ZenShell is the entire UI." |
| `15 themes · 2 shell profiles · one installer` | README front-matter line, verbatim |
| `./install.sh` (not on screen) | README installation block |

No personal data, hostnames, or secrets are carried into the video. The only human
presence is the user's own webcam feed inside the Camera Effects preview — the live
camera is pointed at a blurred wall in that capture, and it is used deliberately
because the live preview is the feature.

## Delivered master

- `brag.mp4` — 1920×1080, 30fps, 21.80s, 654 frames, H.264 + AAC stereo
- Integrated loudness **−18.1 LUFS**, true peak **−1.3 dBFS** (no clipping; platforms
  normalise to ≈ −14 LUFS without limiting hard)
- `brag.jpg` — poster pulled from **21.4s** (the settled lockup), baked in as frame 0
  so every thumbnail grabber shows the finished product
