import Quickshell
import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.Mpris
import Quickshell.Services.Pipewire
import Quickshell.Wayland
import "components"

Scope {
    id: root

    property string font: "JetBrainsMono Nerd Font"
    property real uiScale: 1.25

    readonly property string uiFont: "Google Sans Flex"

    // ── Theme palette ─────────────────────────────────────────────
    // The manifest at ~/.config/hypr/themes/themes.json is the single source
    // of truth: hyprzen/scripts/gen-themes.py writes the same colours the
    // GTK and Hyprland side read, so the shell can never disagree with the
    // desktop about what a theme looks like. QML has no @define-color engine
    // (that is how the old AGS shell consumed current.css), so instead of
    // loading the CSS the shell pulls the palette out of the manifest — same
    // values, one file, no second palette to maintain.
    property color themeBg: "#0f1715"
    property color themeSurface: "#18221f"
    property color themeFg: "#d3c6aa"
    property color themeExtra: "#e67e80"
    property bool themeDark: true
    property int themeRounding: 14

    // Tinted overlays. The alpha stays exactly as the original design had it;
    // only the hue comes from the theme, so a light theme shades its glass
    // where a dark theme lifts it — the direction flips with the palette
    // instead of being hardcoded to white-on-black.
    function ink(alpha: real): color {
        return Qt.rgba(root.themeFg.r, root.themeFg.g, root.themeFg.b, alpha);
    }
    function glass(alpha: real): color {
        return Qt.rgba(root.themeBg.r, root.themeBg.g, root.themeBg.b, alpha);
    }
    function glassDeep(alpha: real): color {
        var c = Qt.darker(root.themeBg, 1.25);
        return Qt.rgba(c.r, c.g, c.b, alpha);
    }
    function surface(alpha: real): color {
        return Qt.rgba(root.themeSurface.r, root.themeSurface.g, root.themeSurface.b, alpha);
    }
    function accent(alpha: real): color {
        return Qt.rgba(root.themeAccent.r, root.themeAccent.g, root.themeAccent.b, alpha);
    }
    // Text drawn on top of an accent-filled shape needs the opposite lightness
    // from the accent, not from the theme.
    function onAccent(): color {
        return root.themeAccent.hslLightness > 0.6 ? "#101014" : "#FFFFFF";
    }

    // ── Panel design tokens ────────────────────────────────────────
    // One vocabulary for every overlay (launcher, control center, cheatsheet).
    // Surfaces are translucent glass tinted with the theme's own colours, so a
    // theme switch repaints the whole shell instead of just the accent.
    // Body text is Google Sans Flex, mono is reserved for glyphs.
    readonly property color uiFg: themeFg
    readonly property color uiFgDim: Qt.rgba(themeFg.r, themeFg.g, themeFg.b, 0.66)
    readonly property color uiFgFaint: Qt.rgba(themeFg.r, themeFg.g, themeFg.b, 0.40)
    readonly property color uiCard: Qt.rgba(themeSurface.r, themeSurface.g, themeSurface.b, 0.55)
    readonly property color uiCardHover: Qt.rgba(themeSurface.r, themeSurface.g, themeSurface.b, 0.78)
    readonly property color uiBorder: Qt.rgba(themeFg.r, themeFg.g, themeFg.b, 0.16)
    readonly property color uiBorderStrong: Qt.rgba(themeFg.r, themeFg.g, themeFg.b, 0.30)
    readonly property color uiGlass: themeBg
    readonly property color uiGlassSoft: Qt.rgba(themeBg.r, themeBg.g, themeBg.b, 0.90)
    readonly property color uiSheen: Qt.rgba(themeFg.r, themeFg.g, themeFg.b, 0.09)
    readonly property int uiRadiusLg: Math.max(12, themeRounding + 12)
    readonly property int uiRadiusMd: Math.max(6, themeRounding + 2)
    readonly property int uiRadiusSm: Math.max(3, themeRounding - 3)
    readonly property bool panelOpen: displayState === 3 || displayState === 13 || displayState === 16 || displayState === 23 || displayState === 24
    readonly property bool compactMenu: displayState === 4 || displayState === 11 || displayState === 12 || displayState === 14 || displayState === 15

    // ── DESIGN.md token layer ─────────────────────────────────────
    // The component-level vocabulary. Every value here is derived from the
    // active Hyprland theme palette, so switching themes repaints panels,
    // controls and status colours together instead of only the accent.
    // Components should reach for these tokens, never for raw literals.
    readonly property color cBgPrimary: themeBg
    readonly property color cBgSecondary: themeSurface
    readonly property color cBgTertiary: themeDark ? Qt.lighter(themeSurface, 1.16) : Qt.darker(themeSurface, 1.04)
    readonly property color cBgElevated: themeDark ? Qt.lighter(themeSurface, 1.32) : Qt.darker(themeSurface, 1.08)
    readonly property color cFgPrimary: themeFg
    readonly property color cFgSecondary: Qt.rgba(themeFg.r, themeFg.g, themeFg.b, 0.76)
    readonly property color cFgMuted: Qt.rgba(themeFg.r, themeFg.g, themeFg.b, 0.54)
    readonly property color cAccent: themeAccent
    readonly property color cAccentStrong: themeAccent.hslLightness > 0.55 ? Qt.darker(themeAccent, 1.18) : Qt.lighter(themeAccent, 1.18)
    readonly property color cBorderSubtle: Qt.rgba(themeFg.r, themeFg.g, themeFg.b, 0.08)
    readonly property color cBorderDefault: Qt.rgba(themeFg.r, themeFg.g, themeFg.b, 0.16)
    readonly property color cBorderStrong: Qt.rgba(themeFg.r, themeFg.g, themeFg.b, 0.28)
    readonly property color cSuccess: "#a6e3a1"
    readonly property color cWarning: "#f9e2af"
    readonly property color cDanger: "#f38ba8"
    readonly property color cInfo: "#89dceb"

    // 4px base spacing scale — 2px for hairline gaps, 64px for page inset.
    readonly property int s0: 0
    readonly property int s1: 2
    readonly property int s2: 4
    readonly property int s3: 8
    readonly property int s4: 12
    readonly property int s5: 16
    readonly property int s6: 24
    readonly property int s7: 32
    readonly property int s8: 48
    readonly property int s9: 64

    readonly property int rNone: 0
    readonly property int rSm: uiRadiusSm
    readonly property int rMd: uiRadiusMd
    readonly property int rLg: uiRadiusLg
    readonly property int rXl: uiRadiusLg + 4
    readonly property int rFull: 9999

    readonly property string fontSans: uiFont
    readonly property string fontMono: font
    readonly property string fontDisplay: uiFont

    // [pixelSize, lineHeight, weight, letterSpacing]
    readonly property var tDisplay: [26, 1.15, 600, -0.02]
    readonly property var tH1: [21, 1.2, 600, -0.015]
    readonly property var tH2: [17, 1.2, 600, -0.01]
    readonly property var tH3: [14, 1.25, 600, -0.005]
    readonly property var tBodyLg: [14, 1.45, 400, 0]
    readonly property var tBody: [13, 1.45, 400, 0]
    readonly property var tBodySm: [12, 1.4, 400, 0]
    readonly property var tCaption: [11, 1.35, 500, 0.02]
    readonly property var tMono: [12, 1.35, 400, 0]
    readonly property var tMonoSm: [11, 1.35, 400, 0]

    readonly property int dInstant: 0
    readonly property int dMicro: Math.round(120 * motionScale)
    readonly property int dFast: Math.round(180 * motionScale)
    readonly property int dNormal: Math.round(240 * motionScale)
    readonly property int dSlow: Math.round(320 * motionScale)
    readonly property int dPage: Math.round(480 * motionScale)
    readonly property int dHero: Math.round(800 * motionScale)

    // ── Motion tokens ─────────────────────────────────────────────
    // One rhythm for the whole shell: surfaces arrive on a long decelerating
    // curve, leave on a quicker one, and the island's geometry leads the
    // content by a few milliseconds. Lists cascade inside their panel.
    // Motion presets scale the whole rhythm at once, so "snappy" tightens the
    // panel, the exit and the cascades together instead of one of them.
    property string motionPreset: "normal"
    readonly property real motionScale: motionPreset === "snappy" ? 0.65
                                       : motionPreset === "relaxed" ? 1.5 : 1.0
    readonly property int motionBase: Math.round(220 * motionScale)
    readonly property int motionPanel: Math.round(300 * motionScale)
    readonly property int motionExit: Math.round(150 * motionScale)
    
    // --- State ---
    // 0 idle · 1 now-playing · 2 volume · 3 launcher · 4 wallpapers · 6 weather
    // 8 battery · 9 bluetooth · 10 notifications · 11 themes · 12 power
    // 13 control center · 14 power profile · 15 clipboard · 16 profiles
    // 23 keybind cheatsheet
    property int displayState: 0
    property string islandTheme: "dark"

    // ── Depth ─────────────────────────────────────────────────────
    // The island is a pane floating over the wallpaper, not a rectangle
    // painted onto it. One soft shadow below it plus a top-lit rim gives it
    // thickness; larger panels sit higher and cast a wider shadow.
    readonly property bool islandRaised: panelOpen || compactMenu || displayState !== 0
    readonly property color islandShadowColor: islandTheme === "liquid"
        ? "#60000000"
        : (islandRaised ? "#61000000" : "#57000000")
    readonly property int islandShadowBlur: islandRaised ? 42 : 28
    readonly property int islandShadowOffsetY: islandRaised ? 14 : 8
    // Liquid keeps more tint than the old 21% fill so it can cross the
    // compositor's blur threshold while the softer shadow stays below it.
    readonly property color liquidSurface: "#6E000000"

    // ── Shell profiles ────────────────────────────────────────────
    // Profile 01 is the island + dock + desktop widgets. Profile 02 is a
    // command bar. Both live in this Quickshell process, so switching only
    // changes visibility and geometry — no restart, no lost notifications.
    property string activeProfile: "island"
    property string barStyle: "floating"
    property string barPosition: "top"
    property var barWidgets: ["workspaces", "window", "media", "clock", "weather", "system"]
    readonly property var barWidgetIds: ["workspaces", "window", "media", "clock", "weather", "system"]
    readonly property int barHeight: barStyle === "floating" ? 46 : 40
    readonly property int barGap: barStyle === "floating" ? 10 : 0
    readonly property int barReservedHeight: barHeight + (barStyle === "floating" ? barGap * 2 : 0)
    readonly property bool barActive: activeProfile === "bar"
    readonly property bool islandOverlay: [2, 3, 4, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 23].indexOf(displayState) !== -1
    readonly property string activeProfileLabel: activeProfile === "bar" ? "02" : "01"

    // ── Settings store ────────────────────────────────────────────
    // One map holds every user-facing setting in the shell. The settings
    // window edits this map, and loadSettings() folds the persisted JSON
    // back into it, so a change made by hand, by another process or by a
    // keybind shows up live without a shell restart. Reassigning the map
    // (rather than mutating it) is what notifies the UI that something moved.
    property var values: ({
        island_theme: "dark",
        profile: "island",
        bar_style: "floating",
        bar_position: "top",
        bar_widgets: ["workspaces", "window", "media", "clock", "weather", "system"],
        dock_theme: "liquid",
        dock_auto_hide: true,
        dock_transparency: 0.5,
        dock_frost: 0.5,
        ui_scale: 1.25,
        motion: "normal",
        lyrics_mode: true,
        dnd: false,
        widgets_visible: true,
        power_profile: "balanced",
        night_light: false,
        caffeine: false,
        camera_output: "1280x720@30"
    })

    // The settings window is its own layer-shell surface, so it can be a
    // full modal over the desktop without disturbing the island's state
    // machine or its displayState numbering.
    property bool settingsWindowOpen: false
    property string settingsPage: "wallpaper"

    // The one way the shell opens the settings window: from a button in
    // the bar, from the control centre, or from a keybind. The page is
    // optional — without it the window opens on whatever page was last
    // used.
    function openSettings(pageId) {
        if (pageId) root.settingsPage = pageId;
        root.settingsWindowOpen = true;
    }

    FileView {
        id: settingsFile
        path: Quickshell.env("HOME") + "/.config/quickshell/shell_settings.json"
        watchChanges: true
        onFileChanged: reload()
        onTextChanged: root.loadSettings(text())
    }

    function loadSettings(raw) {
        var next = Object.assign({}, root.values);
        try {
            var settings = JSON.parse(raw);
            if (settings.island_theme === "dark" || settings.island_theme === "liquid") {
                next.island_theme = settings.island_theme;
                root.islandTheme = settings.island_theme;
            }
            if (settings.profile === "island" || settings.profile === "bar") {
                next.profile = settings.profile;
                root.activeProfile = settings.profile;
            }
            if (settings.bar_style === "floating" || settings.bar_style === "edge") {
                next.bar_style = settings.bar_style;
                root.barStyle = settings.bar_style;
            }
            if (settings.bar_position === "top" || settings.bar_position === "bottom") {
                next.bar_position = settings.bar_position;
                root.barPosition = settings.bar_position;
            }
            if (Array.isArray(settings.bar_widgets)) {
                var valid = [];
                for (var i = 0; i < settings.bar_widgets.length; i++) {
                    var widgetId = settings.bar_widgets[i];
                    if (root.barWidgetIds.indexOf(widgetId) !== -1 && valid.indexOf(widgetId) === -1) {
                        valid.push(widgetId);
                    }
                }
                next.bar_widgets = valid;
                root.barWidgets = valid;
            }
            if (settings.dock_theme === "liquid" || settings.dock_theme === "solid") {
                next.dock_theme = settings.dock_theme;
            }
            if (typeof settings.dock_auto_hide === "boolean") {
                next.dock_auto_hide = settings.dock_auto_hide;
            }
            if (typeof settings.ui_scale === "number" && settings.ui_scale >= 0.85 && settings.ui_scale <= 1.6) {
                next.ui_scale = settings.ui_scale;
                root.uiScale = settings.ui_scale;
            }
            if (settings.motion === "snappy" || settings.motion === "normal" || settings.motion === "relaxed") {
                next.motion = settings.motion;
                root.motionPreset = settings.motion;
            }
            if (typeof settings.lyrics_mode === "boolean") {
                next.lyrics_mode = settings.lyrics_mode;
                root.lyricsMode = settings.lyrics_mode;
            }
            if (typeof settings.dnd === "boolean") {
                next.dnd = settings.dnd;
                root.dndEnabled = settings.dnd;
            }
            if (typeof settings.widgets_visible === "boolean") {
                next.widgets_visible = settings.widgets_visible;
            }
            if (typeof settings.dock_transparency === "number" && settings.dock_transparency >= 0.0 && settings.dock_transparency <= 1.0) {
                next.dock_transparency = settings.dock_transparency;
            }
            if (typeof settings.dock_frost === "number" && settings.dock_frost >= 0.0 && settings.dock_frost <= 1.0) {
                next.dock_frost = settings.dock_frost;
            }
            if (settings.power_profile === "performance" || settings.power_profile === "balanced" || settings.power_profile === "power-saver") {
                next.power_profile = settings.power_profile;
            }
            if (typeof settings.night_light === "boolean") next.night_light = settings.night_light;
            if (typeof settings.caffeine === "boolean") next.caffeine = settings.caffeine;
            if (typeof settings.camera_output === "string") next.camera_output = settings.camera_output;
        } catch(e) {}
        root.values = next;
        root.syncSessionToggles();
    }

    // Settings are written through a small queue. The old code reused one
    // Process and killed it on every call, so two changes made in quick
    // succession silently dropped the first one — which the settings menu
    // triggers constantly.
    property var pendingWrites: []
    property bool writingSetting: false

    function saveSetting(key, value) {
        var queue = root.pendingWrites.slice();
        var replaced = false;
        for (var i = 0; i < queue.length; i++) {
            if (queue[i][0] === key) {
                queue[i] = [key, value];
                replaced = true;
                break;
            }
        }
        if (!replaced) queue.push([key, value]);
        root.pendingWrites = queue;
        root.flushSettings();
    }

    function flushSettings() {
        if (root.writingSetting || root.pendingWrites.length === 0) return;
        var job = root.pendingWrites[0];
        root.pendingWrites = root.pendingWrites.slice(1);
        root.writingSetting = true;
        saveSettingProcess.running = false;
        saveSettingProcess.command = [
            "python3",
            Quickshell.shellDir + "/scripts/set_setting.py",
            job[0],
            JSON.stringify(job[1])
        ];
        saveSettingProcess.running = true;
    }

    Process {
        id: saveSettingProcess
        command: []
        onExited: {
            root.writingSetting = false;
            Qt.callLater(root.flushSettings);
        }
    }

    // ── Settings API ──────────────────────────────────────────────
    // setValue() is the single entry point the settings window uses. It
    // updates the store, then hands the value to applySetting() which owns
    // the live effect and the persistence.
    function setValue(id, value) {
        var next = Object.assign({}, root.values);
        next[id] = value;
        root.values = next;
        root.applySetting(id, value);
    }

    function applySetting(id, value) {
        switch (id) {
            case "island_theme":
                root.islandTheme = value;
                root.saveSetting("island_theme", value);
                break;
            case "profile":
                root.setProfile(value);
                break;
            case "bar_style":
                root.setBarStyle(value);
                break;
            case "bar_position":
                root.setBarPosition(value);
                break;
            case "bar_widgets":
                root.barWidgets = value.slice();
                root.saveSetting("bar_widgets", value);
                break;
            case "dock_theme":
                // The dock is its own process but it watches the same file,
                // so writing the key is enough to restyle it.
                root.saveSetting("dock_theme", value);
                break;
            case "dock_auto_hide":
                root.saveSetting("dock_auto_hide", value);
                break;
            case "ui_scale":
                root.uiScale = value;
                root.saveSetting("ui_scale", value);
                break;
            case "motion":
                root.motionPreset = value;
                root.saveSetting("motion", value);
                break;
            case "lyrics_mode":
                root.lyricsMode = value;
                root.saveSetting("lyrics_mode", value);
                break;
            case "dnd":
                root.dndEnabled = value;
                root.saveSetting("dnd", value);
                break;
            case "widgets_visible":
                root.saveSetting("widgets_visible", value);
                break;
            case "dock_transparency":
                root.saveSetting("dock_transparency", value);
                break;
            case "dock_frost":
                root.saveSetting("dock_frost", value);
                break;
            case "power_profile":
                root.setPowerProfile(value);
                break;
            case "night_light":
                root.setNightLight(value);
                break;
            case "caffeine":
                root.setCaffeine(value);
                break;
            case "camera_output":
                root.saveSetting("camera_output", value);
                root.applyCameraOutput(value);
                break;
        }
    }

    // The virtual camera's resolution is not a shell setting — the daemon
    // owns it and rewrites its own config file on every change. So the
    // picker has to drive the daemon, otherwise the daemon's config is read
    // back over the choice and the dropdown snaps straight back to what the
    // camera was already doing.
    function applyCameraOutput(spec) {
        var parts = String(spec).split("@");
        var size = parts[0].split("x");
        var width = parseInt(size[0], 10);
        var height = parseInt(size[1], 10);
        var fps = parts.length > 1 ? parseInt(parts[1], 10) : 30;
        if (isNaN(width) || isNaN(height) || width <= 0 || height <= 0) return;
        if (root.cameraService) root.cameraService.applyOutput(width, height, isNaN(fps) ? 30 : fps);
    }

    // ── Session toggles ───────────────────────────────────────────
    // Night light and caffeine are daemon-level switches, not shell state.
    // They are reconciled against what is actually running so a reboot or a
    // manual pkill cannot leave the toggle lying about the world.
    function applyNightLight(enabled) {
        nightLightProc.command = ["bash", "-c", enabled
            ? "pgrep -x hyprsunset >/dev/null 2>&1 || (nohup hyprsunset -t 4500 >/dev/null 2>&1 &)"
            : "pkill -x hyprsunset >/dev/null 2>&1 || true"];
        nightLightProc.running = true;
    }

    function setNightLight(enabled) {
        root.applyNightLight(enabled);
        root.saveSetting("night_light", enabled);
    }

    // Caffeine works by stopping the idle daemon, so the command is
    // inverted with respect to the toggle.
    function applyCaffeine(enabled) {
        caffeineProc.command = ["bash", "-c", enabled
            ? "pkill -x hypridle >/dev/null 2>&1 || true"
            : "pgrep -x hypridle >/dev/null 2>&1 || (nohup hypridle >/dev/null 2>&1 &)"];
        caffeineProc.running = true;
    }

    function setCaffeine(enabled) {
        root.applyCaffeine(enabled);
        root.saveSetting("caffeine", enabled);
    }

    function syncSessionToggles() {
        nightLightStateProc.command = ["bash", "-c", "pgrep -x hyprsunset >/dev/null 2>&1 && echo on || echo off"];
        nightLightStateProc.running = true;
        caffeineStateProc.command = ["bash", "-c", "pgrep -x hypridle >/dev/null 2>&1 && echo idle || echo busy"];
        caffeineStateProc.running = true;
    }

    Process {
        id: nightLightProc
        command: []
    }

    Process {
        id: caffeineProc
        command: []
    }

    Process {
        id: nightLightStateProc
        command: []
        stdout: SplitParser {
            onRead: data => {
                var actual = data.trim() === "on";
                if (actual !== root.values.night_light) root.applyNightLight(root.values.night_light);
            }
        }
    }

    Process {
        id: caffeineStateProc
        command: []
        stdout: SplitParser {
            onRead: data => {
                // The idle daemon running means caffeine is off.
                var actual = data.trim() !== "idle";
                if (actual !== root.values.caffeine) root.applyCaffeine(root.values.caffeine);
            }
        }
    }

    // ── Power profile ─────────────────────────────────────────────
    function setPowerProfile(profile) {
        if (profile !== "performance" && profile !== "balanced" && profile !== "power-saver") return;
        var home = Quickshell.env("HOME");
        var gm = home + "/scripts/dell-gmode.sh";
        var cmd = "powerprofilesctl set " + profile;
        if (profile === "performance") {
            cmd = "[ -x " + gm + " ] && " + gm + " set-perf || powerprofilesctl set performance";
        } else if (profile === "power-saver") {
            cmd = "[ -x " + gm + " ] && " + gm + " set-quiet || powerprofilesctl set power-saver";
        } else {
            cmd = "[ -x " + gm + " ] && " + gm + " set-balanced || powerprofilesctl set balanced";
        }
        powerProfileProc.running = false;
        powerProfileProc.command = ["bash", "-c", cmd];
        powerProfileProc.running = true;
        root.saveSetting("power_profile", profile);
    }

    Process {
        id: powerProfileProc
        command: []
    }

    // The compositor is the source of truth for the power profile, so the
    // stored preference is only a starting point — read the live one back.
    Process {
        id: powerProfileRead
        command: ["bash", "-c", "powerprofilesctl get 2>/dev/null"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                var live = String(text).trim();
                if (live === "performance" || live === "balanced" || live === "power-saver") {
                    var next = Object.assign({}, root.values);
                    next.power_profile = live;
                    root.values = next;
                }
            }
        }
    }

    // The camera daemon stores its own output size, and it rewrites that
    // file whenever the daemon restarts. Reading it keeps the settings
    // window honest about what apps are actually receiving.
    FileView {
        id: cameraOutputFile
        path: Quickshell.env("HOME") + "/.config/camera-effects/config.json"
        watchChanges: true
        onFileChanged: reload()
        onTextChanged: {
            try {
                var cfg = JSON.parse(text());
                if (cfg.output && cfg.output.width && cfg.output.height) {
                    var next = Object.assign({}, root.values);
                    next.camera_output = cfg.output.width + "x" + cfg.output.height + "@" + (cfg.output.fps || 30);
                    root.values = next;
                }
            } catch (e) {}
        }
    }

    function setProfile(profile) {
        if (profile !== "island" && profile !== "bar") return;
        root.activeProfile = profile;
        root.saveSetting("profile", profile);
        root.displayState = 0;
        if (profile === "island") root.updateState();
    }

    function setBarStyle(style) {
        if (style !== "floating" && style !== "edge") return;
        root.barStyle = style;
        root.saveSetting("bar_style", style);
    }

    function setBarPosition(position) {
        if (position !== "top" && position !== "bottom") return;
        root.barPosition = position;
        root.saveSetting("bar_position", position);
    }

    function hasBarWidget(widgetId) {
        return root.barWidgets.indexOf(widgetId) !== -1;
    }

    function toggleBarWidget(widgetId) {
        if (root.barWidgetIds.indexOf(widgetId) === -1) return;
        var next = root.barWidgets.slice();
        var index = next.indexOf(widgetId);
        if (index === -1) next.push(widgetId);
        else next.splice(index, 1);
        root.barWidgets = next;
        root.saveSetting("bar_widgets", next);
    }

    function setBarWidgets(widgets) {
        var valid = [];
        for (var i = 0; i < widgets.length; i++) {
            var widgetId = widgets[i];
            if (root.barWidgetIds.indexOf(widgetId) !== -1 && valid.indexOf(widgetId) === -1) {
                valid.push(widgetId);
            }
        }
        root.barWidgets = valid;
        root.saveSetting("bar_widgets", valid);
    }

    // The settings window lives on one screen only — the one the user is
    // actually looking at. Without a compositor hint, fall back to the
    // first screen so the window still appears somewhere.
    function settingsScreenMatches(screenInfo) {
        if (!root.settingsWindowOpen) return false;
        var focused = Hyprland.focusedMonitor;
        if (focused && focused.name) return focused.name === screenInfo.name;
        return Quickshell.screens.length > 0 && Quickshell.screens[0].name === screenInfo.name;
    }

    IpcHandler {
      target: "qs-island"
      function updateTheme(themeName: string): void {
        root.islandTheme = themeName;
      }
    }

    IpcHandler {
      target: "settings"
      function open(): void {
        root.openSettings();
      }
      function close(): void {
        root.settingsWindowOpen = false;
      }
      function toggle(): void {
        root.settingsWindowOpen = !root.settingsWindowOpen;
      }
      function page(pageId: string): void {
        root.openSettings(pageId);
      }
    }

    IpcHandler {
      target: "profile"
      function menu(): void {
        root.displayState = root.displayState === 16 ? 0 : 16;
        if (root.displayState === 0) root.updateState();
      }
      function settings(): void {
        root.openSettings("profile");
      }
      function switchTo(profile: string): void {
        root.setProfile(profile);
      }
      function toggle(): void {
        root.setProfile(root.activeProfile === "bar" ? "island" : "bar");
      }
      function setStyle(style: string): void {
        root.setBarStyle(style);
      }
      function setPosition(position: string): void {
        root.setBarPosition(position);
      }
    }

    // --- Theme Switcher ---
    property var themesList: []
    property string currentThemeId: ""
    property string currentThemeName: ""
    property string currentThemeAccent: "#838996"

    // The accent as a real colour. currentThemeAccent is a string (it is
    // assigned straight out of the manifest JSON), and a string has no .r/.g/.b
    // — every Qt.rgba(currentThemeAccent.r, …) call silently produced
    // transparent black. Components must use this property instead.
    readonly property color themeAccent: currentThemeAccent

    // --- Camera Effects ---
    // The daemon half of the ported camera-effects plugin. It lives in the
    // island process so the panel in the notification center can talk to it
    // directly; the daemon itself is a separate process it supervises.
    CameraService { id: cameraServiceObj }
    readonly property var cameraService: cameraServiceObj

    // Pull the whole palette for the active theme out of the manifest. Every
    // colour the shell paints comes from here, so switching themes repaints
    // surfaces, text and borders — not just the accent.
    function updateThemePalette() {
        for (var i = 0; i < root.themesList.length; i++) {
            var t = root.themesList[i];
            if (t.id === root.currentThemeId) {
                root.currentThemeName = t.name;
                root.currentThemeAccent = t.accent || "#838996";
                if (t.bg) root.themeBg = t.bg;
                if (t.surface) root.themeSurface = t.surface;
                if (t.fg) root.themeFg = t.fg;
                if (t.extra) root.themeExtra = t.extra;
                if (t.dark !== undefined) root.themeDark = !!t.dark;
                if (t.rounding !== undefined) root.themeRounding = t.rounding;
                break;
            }
        }
    }

    function applyTheme(themeId) {
        root.currentThemeId = themeId;
        updateThemePalette();
        applyThemeProcess.command = ["bash", Quickshell.env("HOME") + "/scripts/theme-switch.sh", themeId];
        applyThemeProcess.running = true;
        root.displayState = 0;
        root.updateState();
    }

    Process {
        id: applyThemeProcess
        command: []
    }

    // The theme manifest is regenerated by gen-themes.py whenever a
    // wallpaper-derived theme is repainted. Watch the live copy under
    // ~/.config/hypr/themes — the bundled one next to this config is only a
    // snapshot from install time, so accents drifted from the actual palette.
    FileView {
        id: fetchThemes
        path: Quickshell.env("HOME") + "/.config/hypr/themes/themes.json"
        watchChanges: true
        onFileChanged: reload()
        onTextChanged: {
            try {
                root.themesList = JSON.parse(text());
                root.updateThemePalette();
            } catch (e) {}
        }
    }

    // The active theme is written by theme-switch.sh / wallpaper-selector.sh.
    // FileView watches the file natively, so a switch from a keybind, the CLI
    // or a wallpaper change updates the island accent without a shell restart.
    // (The old one-shot `cat` only read it at startup.)
    FileView {
        id: fetchCurrentTheme
        path: Quickshell.env("HOME") + "/.config/hypr/themes/current_theme.conf"
        watchChanges: true
        onFileChanged: reload()
        onTextChanged: {
            // e.g. "source = ~/.config/hypr/themes/catppuccin.conf"
            var match = text().match(/themes\/([^\.]+)\.conf/);
            if (match) {
                root.currentThemeId = match[1];
                root.updateThemePalette();
            }
        }
    }
    property bool isExpanded: false
    property bool isHovered: false
    property bool islandVisible: true
    property var lastNotification: null

    // The now-playing pill is a transient state; never reopen it pre-expanded.
    onDisplayStateChanged: {
        if (root.displayState !== 1) {
            root.isExpanded = false
        }
    }

    property var allApps: []
    property var allWallpapers: []
    property var allClipboardItems: []

    function filterApps(query) {
        appsModel.clear();
        query = query.toLowerCase();
        for (var i = 0; i < root.allApps.length; i++) {
            var app = root.allApps[i];
            if (query === "" || app.name.toLowerCase().indexOf(query) !== -1 || (app.exec && app.exec.toLowerCase().indexOf(query) !== -1)) {
                appsModel.append(app);
            }
        }
    }

    function filterWallpapers(query) {
        wallpapersModel.clear();
        query = query.toLowerCase();
        for (var i = 0; i < root.allWallpapers.length; i++) {
            var wp = root.allWallpapers[i];
            // `name` was missing from get_wallpapers.py, so this threw a
            // TypeError on the first keystroke. Guard anyway — an entry with
            // no label should degrade to "shown unfiltered", not crash the shell.
            var label = (wp && wp.name) ? wp.name : "";
            if (query === "" || label.toLowerCase().indexOf(query) !== -1) {
                wallpapersModel.append(wp);
            }
        }
    }

    function filterClipboard(query) {
        clipboardModel.clear();
        query = query.toLowerCase();
        for (var i = 0; i < root.allClipboardItems.length; i++) {
            var item = root.allClipboardItems[i];
            if (query === "" || (item.content && item.content.toLowerCase().indexOf(query) !== -1)) {
                clipboardModel.append(item);
            }
        }
    }

    // --- Media ---
    property var activePlayer: null
    property bool isPlaying: false
    property string trackTitle: ""
    property string trackArtist: ""
    property string artUrl: ""
    property real trackPosition: 0
    property real trackLength: 0
    property real lastFetchedPosition: 0
    property real lastFetchTime: 0

    // --- OSD State ---
    property string osdType: "volume"
    property real osdValue: 0
    property string osdIcon: "\uf028"

    property string weatherTemp: "--°C"
    property string weatherDesc: "Loading..."
    property string weatherIcon: "\ue312"

    // Keep weather as a monochrome Nerd Font glyph. wttr.in's emoji icon varies
    // by condition, platform and Qt fallback font, which is what made the
    // weather glance jitter in both surfaces.
    function weatherGlyph(description) {
        var d = String(description || "").toLowerCase();
        if (d.indexOf("thunder") !== -1 || d.indexOf("storm") !== -1) return "\ue315";
        if (d.indexOf("snow") !== -1 || d.indexOf("sleet") !== -1 || d.indexOf("ice") !== -1) return "\ue31b";
        if (d.indexOf("rain") !== -1 || d.indexOf("drizzle") !== -1 || d.indexOf("shower") !== -1) return "\ue316";
        if (d.indexOf("fog") !== -1 || d.indexOf("mist") !== -1 || d.indexOf("haze") !== -1) return "\ue320";
        if (d.indexOf("partly") !== -1) return "\ue302";
        if (d.indexOf("cloud") !== -1 || d.indexOf("overcast") !== -1) return "\ue312";
        if (d.indexOf("sun") !== -1 || d.indexOf("clear") !== -1) return "\ue30d";
        return "\ue312";
    }

    Process {
        id: weatherProcess
        command: ["curl", "-sSf", "--max-time", "12", "https://wttr.in/?format=%t|%C"]
        stdout: SplitParser {
            onRead: data => {
                var parts = data.trim().split("|");
                if (parts.length >= 2) {
                    var temp = parts[0].replace("+", "").trim();
                    var desc = parts[1].trim();
                    if (temp !== "") root.weatherTemp = temp;
                    if (desc !== "") {
                        root.weatherDesc = desc;
                        root.weatherIcon = root.weatherGlyph(desc);
                    }
                }
            }
        }
    }

    Timer {
        interval: 15 * 60 * 1000 // 15 mins
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: weatherProcess.running = true
    }

    Timer {
        id: weatherCloseTimer
        interval: 5000 // Close after 5 seconds
        onTriggered: {
            if (root.displayState === 6) {
                root.displayState = 0;
                root.updateState();
            }
        }
    }

    // --- Phase 2: Live Timer ---
    property int timerSecondsTotal: 0
    property int timerSecondsRemaining: 0
    property string timerString: "00:00"

    Timer {
        id: countdownTimer
        interval: 1000
        repeat: true
        running: false
        onTriggered: {
            if (root.timerSecondsRemaining > 0) {
                root.timerSecondsRemaining--;
                var m = Math.floor(root.timerSecondsRemaining / 60);
                var s = root.timerSecondsRemaining % 60;
                root.timerString = (m < 10 ? "0" + m : m) + ":" + (s < 10 ? "0" + s : s);
            } else {
                running = false;
                root.displayState = 0;
                root.updateState();
            }
        }
    }

    IpcHandler {
        target: "timer"
        function start(minutes: string) {
            var mins = parseInt(minutes);
            root.timerSecondsTotal = mins * 60;
            root.timerSecondsRemaining = root.timerSecondsTotal;
            root.timerString = (mins < 10 ? "0" + mins : mins) + ":00";
            root.displayState = 7;
            countdownTimer.start();
        }
        function stop() {
            countdownTimer.stop();
            root.displayState = 0;
            root.updateState();
        }
    }

    // --- Phase 3: Battery & Charging ---
    property int batteryPercent: 0
    property bool batteryCharging: false

    Timer {
        id: batteryCloseTimer
        interval: 7000
        onTriggered: {
            if (root.displayState === 8) {
                root.displayState = 0;
                root.updateState();
            }
        }
    }

    IpcHandler {
        target: "battery"
        function showBattery(capacity: string, charging: string) {
            root.batteryPercent = parseInt(capacity);
            root.batteryCharging = (charging === "true");
            root.displayState = 8;
            batteryCloseTimer.restart();
        }
    }

    // --- Phase 4: Bluetooth ---
    property string bluetoothDeviceName: ""

    Timer {
        id: bluetoothCloseTimer
        interval: 3500
        onTriggered: {
            if (root.displayState === 9) {
                root.displayState = 0;
                root.updateState();
            }
        }
    }

    IpcHandler {
        target: "bluetooth"
        function showDevice(deviceName: string) {
            root.bluetoothDeviceName = deviceName;
            root.displayState = 9;
            bluetoothCloseTimer.restart();
        }
    }

    // --- Phase 6: Notifications ---
    property string notifyAppName: ""
    property string notifySummary: ""
    property string notifyBody: ""
    property var notificationList: []
    property bool dndEnabled: false

    function addToNotificationHistory(appName, summary, body) {
        var notif = {
            id: Date.now() + Math.random(),
            app: appName,
            summary: summary,
            body: body,
            time: new Date()
        };
        var list = root.notificationList.slice();
        list.unshift(notif);
        if (list.length > 25) list.pop();
        root.notificationList = list;
    }

    function clearNotification(notifId) {
        var list = root.notificationList.slice();
        for (var i = 0; i < list.length; i++) {
            if (list[i].id === notifId) {
                list.splice(i, 1);
                break;
            }
        }
        root.notificationList = list;
    }

    function clearAllNotifications() {
        root.notificationList = [];
    }

    Timer {
        id: notificationCloseTimer
        interval: 4000
        onTriggered: {
            if (root.displayState === 10) {
                root.displayState = 0;
                root.updateState();
            }
        }
    }

    IpcHandler {
        target: "notification"
        function showNotification(appName: string, summary: string, body: string) {
            root.notifyAppName = appName;
            root.notifySummary = summary;
            root.notifyBody = body;
            
            // Also add to control panel notification history
            root.addToNotificationHistory(appName, summary, body);

            if (!root.dndEnabled) {
                root.displayState = 10;
                notificationCloseTimer.restart();
            }
        }
    }

    PwObjectTracker { objects: [Pipewire.defaultAudioSink, Pipewire.defaultAudioSource] }

    IpcHandler {
        target: "osd"
        function showVolume() {
            fetchVolume.running = true;
        }
        function showMic() {
            var muted = Pipewire.defaultAudioSource && Pipewire.defaultAudioSource.audio ? Pipewire.defaultAudioSource.audio.muted : false;
            root.osdType = "mic";
            root.osdValue = 0;
            root.osdIcon = muted ? "\uf131" : "\uf130";
            root.displayState = 2;
            osdTimer.restart();
        }
        function showBrightness() {
            brightnessProcess.running = true;
        }
    }

    Process {
        id: fetchVolume
        command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"]
        stdout: SplitParser {
            onRead: data => {
                // Output: "Volume: 0.65" or "Volume: 0.65 [MUTED]"
                var muted = data.indexOf("[MUTED]") !== -1;
                var parts = data.trim().split(" ");
                var vol = parts.length >= 2 ? parseFloat(parts[1]) * 100 : 0;
                vol = Math.min(vol, 100);

                root.osdType = "volume";
                root.osdValue = muted ? 0 : vol;
                if (muted) root.osdIcon = "\uf026";
                else if (vol < 30) root.osdIcon = "\uf027";
                else root.osdIcon = "\uf028";

                root.displayState = 2;
                osdTimer.restart();
            }
        }
    }

    Process {
        id: brightnessProcess
        command: ["sh", "-c", "echo $(brightnessctl g) $(brightnessctl m)"]
        stdout: SplitParser {
            onRead: data => {
                var parts = data.trim().split(" ");
                if (parts.length === 2) {
                    var cur = parseFloat(parts[0]);
                    var max = parseFloat(parts[1]);
                    root.osdType = "brightness";
                    root.osdValue = (cur / max) * 100;
                    root.osdIcon = "\uf185";
                    root.displayState = 2;
                    osdTimer.restart();
                }
            }
        }
    }

    Timer {
        id: osdTimer
        interval: 2000
        onTriggered: {
            if (root.displayState === 2) {
                root.displayState = 0;
                root.updateState();
            }
        }
    }

    // --- State Logic ---
    function updateState() {
        if (displayState === 3 || displayState === 4 || displayState === 2 || displayState === 8 || displayState === 9 || displayState === 10 || displayState === 11 || displayState === 12 || displayState === 13 || displayState === 14 || displayState === 15 || displayState === 16 || displayState === 23 || displayState === 24) return;
        if (isPlaying) displayState = 1;
        else displayState = 0;
    }



    property real lastToggleTime: 0

    IpcHandler {
        target: "island"
        function state() {
            return "" + root.displayState;
        }
        function showLauncher() {
            var now = Date.now();
            if (now - root.lastToggleTime < 350) return;
            root.lastToggleTime = now;
            root.displayState = root.displayState === 3 ? 0 : 3;
            if (root.displayState === 0) root.updateState();
        }
        function showWallpapers() {
            var now = Date.now();
            if (now - root.lastToggleTime < 350) return;
            root.lastToggleTime = now;
            root.displayState = root.displayState === 4 ? 0 : 4;
            if (root.displayState === 0) root.updateState();
        }
        function showThemes() {
            var now = Date.now();
            if (now - root.lastToggleTime < 350) return;
            root.lastToggleTime = now;
            root.displayState = root.displayState === 11 ? 0 : 11;
            if (root.displayState === 0) root.updateState();
        }
        function showPower() {
            var now = Date.now();
            if (now - root.lastToggleTime < 350) return;
            root.lastToggleTime = now;
            root.displayState = root.displayState === 12 ? 0 : 12;
            if (root.displayState === 0) root.updateState();
        }
        function showControlPanel() {
            var now = Date.now();
            if (now - root.lastToggleTime < 350) return;
            root.lastToggleTime = now;
            root.displayState = root.displayState === 13 ? 0 : 13;
            if (root.displayState === 0) root.updateState();
        }
        function showWeather() {
            var now = Date.now();
            if (now - root.lastToggleTime < 350) return;
            root.lastToggleTime = now;
            root.displayState = root.displayState === 6 ? 0 : 6;
            if (root.displayState === 6) weatherCloseTimer.restart();
            else root.updateState();
        }
        function showPowerProfile() {
            var now = Date.now();
            if (now - root.lastToggleTime < 350) return;
            root.lastToggleTime = now;
            root.displayState = root.displayState === 14 ? 0 : 14;
            if (root.displayState === 0) root.updateState();
        }
        function showClipboard() {
            var now = Date.now();
            if (now - root.lastToggleTime < 350) return;
            root.lastToggleTime = now;
            root.displayState = root.displayState === 15 ? 0 : 15;
            if (root.displayState === 15) {
                fetchClipboard.running = true;
            } else {
                if (root.displayState === 0) root.updateState();
            }
        }
        function showCheatsheet() {
            var now = Date.now();
            if (now - root.lastToggleTime < 350) return;
            root.lastToggleTime = now;
            root.displayState = root.displayState === 23 ? 0 : 23;
            if (root.displayState !== 23 && root.displayState === 0) {
                root.updateState();
            }
        }
        function showCamera() {
            var now = Date.now();
            if (now - root.lastToggleTime < 350) return;
            root.lastToggleTime = now;
            root.displayState = root.displayState === 24 ? 0 : 24;
            if (root.displayState === 0) root.updateState();
        }
        // Mic mute without opening the panel: the point of a virtual microphone
        // is that one switch covers every app.
        function micMute() {
            if (!root.cameraService) return;
            root.cameraService.setMicMuted(!root.cameraService.micMuted);
        }
        function cameraSnap() {
            if (root.cameraService) root.cameraService.snapshot();
        }
        // Change what apps get: width, height and fps. A size bigger than the
        // camera's own capture size is a real-time upscale.
        function setCameraOutput(width: int, height: int, fps: int): void {
            if (root.cameraService) root.cameraService.applyOutput(width, height, fps);
        }
        function toggleMusicExpanded() {
            if (root.displayState !== 1) root.displayState = 1;
            root.isExpanded = !root.isExpanded;
        }
    }

    // --- Format Time ---
    function formatTime(sec) {
        var m = Math.floor(sec / 60);
        var s = Math.floor(sec % 60);
        return m + ":" + (s < 10 ? "0" : "") + s;
    }

    // --- Media Player Logic ---
    function checkPlayers() {
        var players = Mpris.players.values;
        var preferred = null;
        var fallback = null;

        for (var i = 0; i < players.length; i++) {
            var p = players[i];
            if (!fallback) fallback = p;
            if (p.playbackState === MprisPlaybackState.Playing) {
                preferred = p;
                break;
            }
        }

        var chosen = preferred || fallback;
        if (chosen) {
            root.activePlayer = chosen;
            root.isPlaying = (chosen.playbackState === MprisPlaybackState.Playing);
            var trackChanged = (root.trackTitle !== (chosen.trackTitle || ""));
            root.trackTitle = chosen.trackTitle || "";
            root.trackArtist = chosen.trackArtist || "";
            root.artUrl = chosen.artUrl || "";
            if (chosen.length !== undefined && chosen.length > 0) root.trackLength = chosen.length / 1000000.0;
            
            if (trackChanged) {
                root.currentLyrics = [];
                root.currentLyricLine = "";
                fetchLyrics.running = false;
                fetchLyrics.command = ["python3", Quickshell.shellDir + "/scripts/get_lyrics.py", root.trackArtist, root.trackTitle];
                triggerLyrics.restart();
            }
        } else {
            root.activePlayer = null;
            root.isPlaying = false;
            root.trackTitle = "";
            root.trackArtist = "";
            root.artUrl = "";
            root.trackPosition = 0;
            root.trackLength = 0;
        }
    }

    // --- Data Models ---
    ListModel { id: appsModel }
    ListModel { id: wallpapersModel }
    ListModel { id: clipboardModel }

    Process {
        id: fetchApps
        command: ["python3", Quickshell.shellDir + "/scripts/get_apps.py"]
        running: true
        stdout: SplitParser {
            onRead: data => {
                try {
                    var apps = JSON.parse(data);
                    root.allApps = apps;
                    root.filterApps("");
                } catch(e) {}
            }
        }
    }

    Process {
        id: fetchWallpapers
        command: ["python3", Quickshell.shellDir + "/scripts/get_wallpapers.py"]
        running: true
        stdout: SplitParser {
            onRead: data => {
                try {
                    var wps = JSON.parse(data);
                    root.allWallpapers = wps;
                    root.filterWallpapers("");
                } catch(e) {}
            }
        }
    }

    Process {
        id: fetchClipboard
        command: ["python3", Quickshell.shellDir + "/scripts/get_clipboard.py"]
        stdout: SplitParser {
            onRead: data => {
                try {
                    var items = JSON.parse(data);
                    root.allClipboardItems = items;
                    root.filterClipboard("");
                } catch(e) {}
            }
        }
    }

    Process {
        id: runCmd
        command: []
    }

    // --- Fetch Processes ---
    Process {
        id: fetchArt
        command: ["bash", "-c", "playerctl metadata mpris:artUrl 2>/dev/null"]
        stdout: SplitParser {
            onRead: data => {
                var url = data.trim();
                if (url.startsWith("/")) url = "file://" + url;
                root.artUrl = url;
            }
        }
    }

    Process {
        id: fetchPos
        command: ["bash", "-c", "for p in $(playerctl -l 2>/dev/null); do if [ \"$(playerctl -p \"$p\" status 2>/dev/null)\" = \"Playing\" ]; then playerctl -p \"$p\" position 2>/dev/null; exit 0; fi; done; playerctl position 2>/dev/null || echo 0"]
        stdout: SplitParser {
            onRead: data => { 
                root.trackPosition = parseFloat(data.trim()) || 0; 
                root.lastFetchedPosition = root.trackPosition;
                root.lastFetchTime = Date.now();
            }
        }
    }

    Process {
        id: fetchLen
        command: ["bash", "-c", "playerctl metadata mpris:length 2>/dev/null | awk '{print $1/1000000}'"]
        stdout: SplitParser {
            onRead: data => {
                var l = parseFloat(data.trim());
                if (l > 0) root.trackLength = l;
            }
        }
    }
    
    // Command functions for interacting with MPRIS
    function playPause() { if (root.activePlayer) root.activePlayer.togglePlaying(); }
    function prevTrack() { if (root.activePlayer) root.activePlayer.previous(); }
    function nextTrack() { if (root.activePlayer) root.activePlayer.next(); }

    property string currentTime: "00:00"

    // --- Live Synced Lyrics ---
    property var currentLyrics: []
    property string currentLyricLine: ""
    property bool lyricsMode: true

    Timer {
        id: triggerLyrics
        interval: 100
        onTriggered: {
            fetchLyrics.running = true;
        }
    }

    function updateLyricLine() {
        if (!root.currentLyrics || root.currentLyrics.length === 0) {
            root.currentLyricLine = "";
            return;
        }
        var pos = root.trackPosition;
        var activeText = "";
        for (var i = 0; i < root.currentLyrics.length; i++) {
            if (root.currentLyrics[i].time <= pos) {
                activeText = root.currentLyrics[i].text;
            } else {
                break;
            }
        }
        root.currentLyricLine = activeText;
    }

    Process {
        id: fetchLyrics
        command: []
        stdout: SplitParser {
            onRead: data => {
                try {
                    root.currentLyrics = JSON.parse(data);
                    root.updateLyricLine();
                } catch(e) {
                    root.currentLyrics = [];
                    root.currentLyricLine = "";
                }
            }
        }
    }

    Timer {
        interval: 100
        running: root.isPlaying && root.activePlayer !== null
        repeat: true
        onTriggered: {
            if (!fetchPos.running) {
                fetchPos.running = true;
            }
            if (root.lastFetchTime > 0) {
                var elapsed = (Date.now() - root.lastFetchTime) / 1000.0;
                root.trackPosition = root.lastFetchedPosition + elapsed;
            }
            root.updateLyricLine();
        }
    }

    // --- Update Timer ---
    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            var d = new Date();
            var h = d.getHours();
            var m = d.getMinutes();
            root.currentTime = (h < 10 ? "0" : "") + h + ":" + (m < 10 ? "0" : "") + m;

            root.checkPlayers();
            if (root.activePlayer) {
                if (root.activePlayer.position === undefined) {
                    fetchPos.running = true;
                }
                if (root.artUrl === "") {
                    fetchArt.running = true;
                }
            }
            root.updateState();
        }
    }

    // =========================================================================
    // DYNAMIC ISLAND WINDOW
    // =========================================================================
    // DYNAMIC ISLAND WINDOW (Static Reserve)
    // =========================================================================
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: reserveWindow
            required property var modelData
            screen: modelData
            anchors { top: true; left: true; right: true }
            visible: root.activeProfile !== "bar"
            color: "transparent"
            exclusiveZone: 40 * root.uiScale
            implicitHeight: 40 * root.uiScale
            mask: Region {} // Empty region means clicks pass through to desktop
        }
    }

    // =========================================================================
    // PROFILE 02 — COMMAND BAR
    // =========================================================================
    ProfileBar {}

    // =========================================================================
    // DYNAMIC ISLAND OVERLAY (Full screen renderer)
    // =========================================================================
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: islandPanel
            required property var modelData
            screen: modelData

            visible: root.islandVisible && (root.activeProfile !== "bar" || root.islandOverlay)

            WlrLayershell.namespace: "qs-island"
            WlrLayershell.keyboardFocus: (root.displayState === 3 || root.displayState === 4 || root.displayState === 11 || root.displayState === 12 || root.displayState === 14 || root.displayState === 15 || root.displayState === 16 || root.displayState === 23 || root.displayState === 24) ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
            WlrLayershell.layer: WlrLayer.Top
            exclusionMode: ExclusionMode.Ignore

            anchors { top: true; left: true; right: true; bottom: true }
            color: "transparent"
            
            mask: (root.displayState === 3 || root.displayState === 4 || root.displayState === 6 || root.displayState === 11 || root.displayState === 12 || root.displayState === 13 || root.displayState === 14 || root.displayState === 15 || root.displayState === 16 || root.displayState === 23 || root.displayState === 24) ? fullScreenRegion : pillRegion

            Region {
                id: fullScreenRegion
                x: 0; y: 0
                width: islandPanel.width
                height: islandPanel.height
            }

            Region {
                id: pillRegion
                // The region must exactly match the scaled dimensions of the pill
                x: scaleWrapper.x - (scaleWrapper.width * root.uiScale - scaleWrapper.width) / 2
                y: scaleWrapper.y
                width: scaleWrapper.width * root.uiScale
                height: scaleWrapper.height * root.uiScale
            }

            // Click outside full-screen overlay (closes launcher / wallpaper selector)
            MouseArea {
                anchors.fill: parent
                enabled: root.displayState === 3 || root.displayState === 4 || root.displayState === 6 || root.displayState === 11 || root.displayState === 12 || root.displayState === 13 || root.displayState === 14 || root.displayState === 15 || root.displayState === 16 || root.displayState === 23 || root.displayState === 24
                onClicked: {
                    root.displayState = 0;
                    root.updateState();
                }
                z: -1
            }

            // Scale wrapper (now controls the animated size instead of Wayland)
            Item {
                id: scaleWrapper
                width: root.displayState === 23 ? 680 :
                       root.displayState === 24 ? 540 :
                       root.displayState === 16 ? 460 :
                       root.displayState === 15 ? 560 :
                       root.displayState === 14 ? 500 :
                       root.displayState === 13 ? 460 :
                       root.displayState === 12 ? 480 :
                       root.displayState === 11 ? 540 :
                       root.displayState === 10 ? 320 :
                       root.displayState === 9 ? 220 :
                       root.displayState === 8 ? 240 :
                       root.displayState === 7 ? 180 :
                       root.displayState === 6 ? 280 :
                       root.displayState === 4 ? 540 :
                       root.displayState === 3 ? 460 :
                       root.displayState === 2 ? 200 :
                       root.displayState === 1 ? (root.isExpanded ? 400 : (root.currentLyricLine !== "" ? Math.min(540, Math.max(340, lyricMeasure.implicitWidth + 90)) : Math.min(460, Math.max(280, titleMeasure.implicitWidth + 120)))) :
                       80

                height: root.displayState === 23 ? 600 :
                        root.displayState === 24 ? 660 :
                        root.displayState === 16 ? 260 :
                        root.displayState === 15 ? 288 :
                        root.displayState === 14 ? 168 :
                        root.displayState === 13 ? 620 :
                        root.displayState === 12 ? 308 :
                        root.displayState === 11 ? 320 :
                        root.displayState === 10 ? 80 :
                        root.displayState === 9 ? 48 :
                        root.displayState === 8 ? 48 :
                        root.displayState === 7 ? 40 :
                        root.displayState === 6 ? 80 :
                        root.displayState === 4 ? 220 :
                        root.displayState === 3 ? appLauncher.panelHeight :
                        root.displayState === 2 ? 48 :
                        root.displayState === 1 ? (root.isExpanded ? 190 : 44) :
                        32
                
                anchors.top: parent.top
                anchors.topMargin: 4 * root.uiScale + (root.activeProfile === "bar" && root.barPosition === "top" ? root.barReservedHeight + 6 : 0)
                anchors.horizontalCenter: parent.horizontalCenter
                
                scale: root.uiScale
                transformOrigin: Item.Top
                
                Behavior on width { NumberAnimation { duration: root.motionPanel; easing.type: Easing.OutExpo } }
                Behavior on height { NumberAnimation { duration: root.motionPanel; easing.type: Easing.OutExpo } }

                // Measure text width for dynamic pill width
                Text {
                    id: lyricMeasure
                    visible: false
                    text: root.currentLyricLine
                    font.family: root.uiFont
                    font.pixelSize: 14
                    font.weight: Font.DemiBold
                    font.letterSpacing: 0.2
                }

                Text {
                    id: titleMeasure
                    visible: false
                    text: root.trackTitle || "Nothing Playing"
                    font.family: root.uiFont
                    font.pixelSize: 14
                    font.weight: Font.DemiBold
                    font.letterSpacing: 0.2
                }

                // Elevation: ambient shadow, clipped only by the screen edge.
                RectangularShadow {
                    anchors.fill: pill
                    radius: pill.radius
                    color: root.islandShadowColor
                    blur: root.islandShadowBlur
                    spread: 1
                    offset: Qt.vector2d(0, root.islandShadowOffsetY)

                    Behavior on color { ColorAnimation { duration: 300 } }
                    Behavior on blur { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
                }

                // ==================== Pill ====================
                Rectangle {
                    id: pill
                    anchors.fill: parent
                    radius: root.displayState === 0 ? 16 : ((root.panelOpen || root.compactMenu) ? root.uiRadiusLg : 22)
                    color: root.islandTheme === "liquid" ? root.liquidSurface : ((root.panelOpen || root.compactMenu) ? "#E00C0C10" : "#E60D0D11")
                    border.color: root.islandTheme === "liquid" ? "#30FFFFFF" : ((root.panelOpen || root.compactMenu) ? "#2EFFFFFF" : (root.isHovered && root.displayState === 1 ? "#38FFFFFF" : "#28FFFFFF"))
                    border.width: 1
                    clip: true

                    Behavior on radius { NumberAnimation { duration: root.motionBase; easing.type: Easing.OutCubic } }
                    Behavior on color { ColorAnimation { duration: 300 } }

                    // Inner dark glass container
                    Rectangle {
                        anchors.fill: parent
                        radius: parent.radius
                        opacity: root.islandTheme === "liquid" ? 0 : ((root.panelOpen || root.compactMenu) ? 0.72 : (root.displayState !== 0 ? 1 : 0))
                        Behavior on opacity { NumberAnimation { duration: 300 } }
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: "#F01B1B21" }
                            GradientStop { position: 0.52; color: "#F00E0E12" }
                            GradientStop { position: 1.0; color: "#F0060609" }
                        }
                    }

                    // Inner sheen: light catches the top edge and the body
                    // darkens toward its bottom edge, so the pane reads as a
                    // slab rather than a flat fill.
                    Rectangle {
                        anchors.fill: parent
                        radius: parent.radius
                        opacity: root.islandTheme === "liquid" ? 1 : 0.72
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: "#12FFFFFF" }
                            GradientStop { position: 0.32; color: "#00FFFFFF" }
                            GradientStop { position: 0.68; color: "#00000000" }
                            GradientStop { position: 1.0; color: "#2C000000" }
                        }
                        Behavior on opacity { NumberAnimation { duration: 300 } }
                    }

                    // Top rim light
                    Rectangle {
                        width: parent.width
                        height: 1
                        anchors.top: parent.top
                        anchors.topMargin: 1
                        anchors.horizontalCenter: parent.horizontalCenter
                        opacity: root.displayState === 0 ? 0.45 : 1
                        Behavior on opacity { NumberAnimation { duration: 300 } }
                        gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop { position: 0.0; color: "transparent" }
                            GradientStop { position: 0.18; color: "#18FFFFFF" }
                            GradientStop { position: 0.5; color: "#3CFFFFFF" }
                            GradientStop { position: 0.82; color: "#18FFFFFF" }
                            GradientStop { position: 1.0; color: "transparent" }
                        }
                    }

                    // Components from the components directory
                    IdleClock {}
                    NowPlayingCompact {}
                    NowPlayingExpanded {}
                    OSD {}
                    AppLauncher { id: appLauncher }
                    WallpaperSelector {}
                    WeatherGlance {}
                    LiveTimer {}
                    BatteryAlert {}
                    BluetoothAlert {}
                    Notification {}
                    ThemeSwitcher {}
                    PowerMenu {}
                    ControlPanel {}
                    PowerProfileMenu {}
                    ClipboardManager {}
                    KeybindCheatsheet {}
                    ProfileSwitcher {}
                    CameraPanel {}

                // Global hover area for the island
                MouseArea {
                    anchors.fill: parent
                    enabled: root.displayState < 3
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    acceptedButtons: Qt.LeftButton | Qt.RightButton

                    onContainsMouseChanged: {
                        root.isHovered = containsMouse;
                    }

                    onClicked: {
                        if (root.displayState === 1) {
                            root.isExpanded = !root.isExpanded;
                        } else if (root.displayState === 0) {
                            root.displayState = 6;
                            weatherCloseTimer.restart();
                        }
                    }

                    z: root.isExpanded ? -1 : 0
                }
                } // Close Rectangle (pill)
            } // Close Item (scale wrapper)
        }
    }

    // =========================================================================
    // SETTINGS WINDOW
    // =========================================================================
    // A separate layer-shell surface on the overlay layer. Keeping it out of
    // the island's displayState machine means the settings window can be a
    // full modal dialog without renumbering every state the island
    // enumerates for geometry, keyboard focus and the click-away mask.
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: settingsPanel
            required property var modelData
            screen: modelData

            visible: root.settingsWindowOpen && root.settingsScreenMatches(modelData)

            WlrLayershell.namespace: "qs-settings"
            // Only the screen that actually shows the window may take the
            // keyboard. Asking every screen for exclusive focus leaves the
            // compositor with several surfaces fighting over the keyboard.
            WlrLayershell.keyboardFocus: (root.settingsWindowOpen && root.settingsScreenMatches(modelData)) ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
            WlrLayershell.layer: WlrLayer.Overlay
            exclusionMode: ExclusionMode.Ignore
            color: "transparent"

            anchors { top: true; left: true; right: true; bottom: true }

            SettingsWindow {
                id: settingsUi
                anchors.fill: parent
            }
        }
    }

}
