import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

// The ZenShell settings window.
//
// It is a real toplevel window, not a full-screen layer surface, so the
// compositor can move, resize, minimise and maximise it like any other app.
// The card is inset inside a transparent frame that leaves room for the drop
// shadow and for the resize grips. The left column is a searchable tree of
// pages; the right column renders the active page. Every control writes
// through root.setValue(), which keeps the store, the live shell and the
// persisted file in step.
FloatingWindow {
    id: win

    visible: root.settingsWindowOpen
    title: "ZenShell Settings"
    color: "transparent"
    implicitWidth: 1040
    implicitHeight: 740
    minimumSize: Qt.size(840, 560)
    maximumSize: Qt.size(2400, 1600)

    readonly property int framePad: 24
    readonly property color accent: root.currentThemeAccent
    readonly property string uiFont: root.fontSans
    readonly property string iconFont: root.fontMono
    // Descriptions are deliberately quieter than labels, but the shell-wide
    // 54% muted token disappears on a dark glass card. Lift it for the
    // settings window so 11 px supporting text still clears 4.5:1.
    readonly property color textMuted: Qt.rgba(root.themeFg.r, root.themeFg.g, root.themeFg.b, 0.64)

    property string query: ""
    readonly property string activePage: root.settingsPage
    property var expandedCategories: ({ personalization: true, shell: true, island: true, system: false })
    property var catalog: []
    property var filtered: []
    property var activePageModel: null

    // Desktop applications for the Default Applications page. Quickshell
    // scans .desktop files asynchronously, so the list starts empty and is
    // rebuilt when the model announces new entries.
    property var desktopApps: []
    property var defaultApps: ({})
    property bool defaultAppsLoaded: false
    readonly property var appFilters: ({
        browser: ["webbrowser"],
        mail: ["email"],
        file_manager: ["filemanager"],
        text_editor: ["texteditor"],
        image_viewer: ["graphics", "viewer"],
        video_player: ["videoplayer", "player", "audiovideo"],
        audio_player: ["audioplayer", "player", "audio"],
        pdf_viewer: ["office", "viewer"]
    })

    // The card follows the real window size, so resizing the window reflows
    // the content instead of scaling a fixed canvas.
    readonly property int cardWidth: Math.max(0, win.width - win.framePad * 2)
    readonly property int cardHeight: Math.max(0, win.height - win.framePad * 2)

    // ── Catalog ───────────────────────────────────────────────────
    // The catalog describes every setting the shell exposes. Pages are
    // grouped into categories the way the sidebar presents them; each row
    // names a setting id, which is also the key it is stored under.
    function buildCatalog() {
        return [
            {
                id: "personalization",
                label: "Personalization",
                icon: "\uf1fc",
                pages: [
                    {
                        id: "wallpaper",
                        label: "Wallpaper",
                        icon: "\uf03e",
                        groups: [
                            {
                                title: "Wallpaper",
                                intro: { label: "Background", desc: "Pick the image behind the desktop. Themed wallpapers repaint the shell theme." },
                                grid: "wallpapers"
                            }
                        ]
                    },
                    {
                        id: "colors",
                        label: "Theme & Colors",
                        icon: "\uf1fc",
                        groups: [
                            {
                                title: "Color theme",
                                intro: { label: "Desktop theme", desc: "Repaints the compositor, the terminals and the apps" },
                                grid: "themes"
                            },
                            {
                                title: "Shell surfaces",
                                rows: [
                                    { type: "segment", id: "island_theme", label: "Island material", desc: "Liquid glass picks up what is behind it, solid stays opaque", options: [ { value: "dark", label: "Solid" }, { value: "liquid", label: "Liquid" } ] },
                                    { type: "segment", id: "dock_theme", label: "Dock material", desc: "The same choice for the dock", options: [ { value: "solid", label: "Solid" }, { value: "liquid", label: "Liquid" } ] }
                                ]
                            }
                        ]
                    },
                    {
                        id: "motion",
                        label: "Typography & Motion",
                        icon: "\uf1de",
                        groups: [
                            {
                                title: "Interface",
                                rows: [
                                    { type: "slider", id: "ui_scale", label: "Interface scale", desc: "Scales the island and every overlay panel; the settings window has its own size", min: 0.9, max: 1.5, step: 0.05, unit: "×" }
                                ]
                            },
                            {
                                title: "Motion",
                                rows: [
                                    { type: "segment", id: "motion", label: "Animation speed", desc: "How quickly panels open, close and cascade", options: [ { value: "snappy", label: "Snappy" }, { value: "normal", label: "Normal" }, { value: "relaxed", label: "Relaxed" } ] }
                                ]
                            }
                        ]
                    }
                ]
            },
            {
                id: "shell",
                label: "Shell",
                icon: "\uf0c9",
                pages: [
                    {
                        id: "profile",
                        label: "Profile & Bar",
                        icon: "\uf0c9",
                        groups: [
                            {
                                title: "Shell profile",
                                rows: [
                                    { type: "segment", id: "profile", label: "Active profile", desc: "The island with the dock, the command bar, or the status island", options: [ { value: "island", label: "Island" }, { value: "bar", label: "Command bar" }, { value: "status", label: "Status" } ] }
                                ]
                            },
                            {
                                title: "Command bar",
                                rows: [
                                    { type: "segment", id: "bar_style", label: "Bar layout", desc: "A detached bar or one that spans the screen", options: [ { value: "floating", label: "Floating" }, { value: "edge", label: "Edge" } ] },
                                    { type: "segment", id: "bar_position", label: "Bar position", desc: "Which edge the bar sits on", options: [ { value: "top", label: "Top" }, { value: "bottom", label: "Bottom" } ] }
                                ]
                            },
                            {
                                title: "Bar widgets",
                                rows: [
                                    { type: "checklist", id: "bar_widgets", label: "Visible widgets", desc: "The launcher, control center and settings button always stay", options: [ { value: "workspaces", label: "Workspaces" }, { value: "window", label: "Window title" }, { value: "media", label: "Now playing" }, { value: "clock", label: "Clock & date" }, { value: "weather", label: "Weather" }, { value: "system", label: "System tray" } ] }
                                ]
                            }
                        ]
                    },
                    {
                        id: "dock",
                        label: "Dock",
                        icon: "\uf1b3",
                        desc: "Where the dock sits, how it hides and how large its icons grow.",
                        groups: [
                            {
                                title: "Behaviour",
                                rows: [
                                    { type: "toggle", id: "dock_enabled", label: "Show the dock", desc: "Hide the dock and free up the screen edge" },
                                    { type: "toggle", id: "dock_auto_hide", label: "Auto-hide", desc: "Keep the dock out of the way until the pointer reaches the screen edge" },
                                    { type: "segment", id: "dock_position", label: "Dock position", desc: "Which screen edge the dock is attached to", options: [ { value: "bottom", label: "Bottom" }, { value: "top", label: "Top" } ] },
                                    { type: "segment", id: "dock_monitor", label: "Show on", desc: "One dock shared by every display, or only the primary display", options: [ { value: "all", label: "All displays" }, { value: "primary", label: "Primary" } ] },
                                    { type: "slider", id: "dock_hide_delay", label: "Hide delay", desc: "How long the dock waits before sliding away after the pointer leaves", min: 100, max: 900, step: 20, unit: " ms" }
                                ]
                            },
                            {
                                title: "Size & motion",
                                rows: [
                                    { type: "slider", id: "dock_icon_size", label: "Icon size", desc: "The artwork size inside each dock tile", min: 28, max: 48, step: 2, unit: " px" },
                                    { type: "slider", id: "dock_magnification", label: "Magnification", desc: "How large an icon grows when the pointer is over it", min: 1.0, max: 1.5, step: 0.02, unit: "×" },
                                    { type: "toggle", id: "dock_show_indicators", label: "Running indicators", desc: "Show the dots under applications that have open windows" }
                                ]
                            },
                            {
                                title: "Material",
                                rows: [
                                    { type: "segment", id: "dock_theme", label: "Dock material", desc: "The same choice as the island", options: [ { value: "solid", label: "Solid" }, { value: "liquid", label: "Liquid" } ] },
                                    { type: "slider", id: "dock_transparency", label: "Transparency", desc: "Background opacity of the dock surface", min: 0.0, max: 1.0, step: 0.05, unit: "" },
                                    { type: "slider", id: "dock_frost", label: "Frost", desc: "Milkiness of the liquid glass material", min: 0.0, max: 1.0, step: 0.05, unit: "" }
                                ]
                            },
                            {
                                title: "Applications",
                                rows: [
                                    { type: "action", id: "dock_pins", label: "Pinned applications", desc: "Choose which applications the dock keeps and in what order", actionLabel: "Manage" }
                                ]
                            }
                        ]
                    },
                    {
                        id: "widgets",
                        label: "Desktop Widgets",
                        icon: "\uf03d",
                        groups: [
                            {
                                title: "Desktop widgets",
                                rows: [
                                    { type: "toggle", id: "widgets_visible", label: "Show the widgets", desc: "Clock, date and weather cards floating on the desktop" }
                                ]
                            }
                        ]
                    }
                ]
            },
            {
                id: "island",
                label: "Island",
                icon: "\uf0f3",
                pages: [
                    {
                        id: "alerts",
                        label: "Alerts & Media",
                        icon: "\uf0f3",
                        groups: [
                            {
                                title: "Alerts",
                                rows: [
                                    { type: "toggle", id: "dnd", label: "Do Not Disturb", desc: "Keep the island quiet; notifications still land in the shade" }
                                ]
                            },
                            {
                                title: "Media",
                                rows: [
                                    { type: "toggle", id: "lyrics_mode", label: "Synced lyrics", desc: "Show the current lyric line under the track title" }
                                ]
                            },
                            {
                                title: "Clipboard",
                                rows: [
                                    { type: "action", id: "clipboard_open", label: "Clipboard history", desc: "Everything the clipboard manager has kept", actionLabel: "Open" }
                                ]
                            }
                        ]
                    }
                ]
            },
            {
                id: "system",
                label: "System",
                icon: "\uf0e4",
                pages: [
                    {
                        id: "power",
                        label: "Power & Performance",
                        icon: "\uf0e4",
                        groups: [
                            {
                                title: "Power profile",
                                rows: [
                                    { type: "segment", id: "power_profile", label: "Power profile", desc: "How hard the machine is allowed to work", options: [ { value: "performance", label: "Performance" }, { value: "balanced", label: "Balanced" }, { value: "power-saver", label: "Saver" } ] }
                                ]
                            },
                            {
                                title: "Display and session",
                                rows: [
                                    { type: "toggle", id: "night_light", label: "Night light", desc: "Warm the display to 4500K" },
                                    { type: "toggle", id: "caffeine", label: "Caffeine", desc: "Stop the idle daemon so the machine never sleeps" }
                                ]
                            }
                        ]
                    },
                    {
                        id: "camera",
                        label: "Camera",
                        icon: "\uf030",
                        groups: [
                            {
                                title: "Virtual camera output",
                                rows: [
                                    { type: "dropdown", id: "camera_output", label: "Resolution", desc: "What applications receive from the virtual camera", options: [ { value: "1280x720@30", label: "1280 × 720" }, { value: "1920x1080@30", label: "1920 × 1080" }, { value: "2560x1440@30", label: "2560 × 1440" }, { value: "3840x2160@30", label: "3840 × 2160" } ] }
                                ]
                            },
                            {
                                title: "Effects",
                                rows: [
                                    { type: "action", id: "camera_open", label: "Camera effects", desc: "Centre stage, background blur, filters and microphone effects", actionLabel: "Open" }
                                ]
                            }
                        ]
                    },
                    {
                        id: "default-apps",
                        label: "Default Applications",
                        icon: "\uf085",
                        desc: "Choose which application opens each kind of link, file and document.",
                        groups: [
                            {
                                title: "Web & mail",
                                rows: [
                                    { type: "dropdown", id: "default_browser", source: "default_apps", role: "browser", label: "Web browser", desc: "Opens links, HTML documents and authentication pages", options: win.appsFor("browser") },
                                    { type: "dropdown", id: "default_mail", source: "default_apps", role: "mail", label: "Email client", desc: "Handles mailto: links from every application", options: win.appsFor("mail") }
                                ]
                            },
                            {
                                title: "Files & media",
                                rows: [
                                    { type: "dropdown", id: "default_file_manager", source: "default_apps", role: "file_manager", label: "File manager", desc: "Opens folders and mounted drives", options: win.appsFor("file_manager") },
                                    { type: "dropdown", id: "default_text_editor", source: "default_apps", role: "text_editor", label: "Text editor", desc: "Opens plain text and configuration files", options: win.appsFor("text_editor") },
                                    { type: "dropdown", id: "default_image_viewer", source: "default_apps", role: "image_viewer", label: "Image viewer", desc: "Opens PNG, JPEG and WebP images", options: win.appsFor("image_viewer") },
                                    { type: "dropdown", id: "default_video_player", source: "default_apps", role: "video_player", label: "Video player", desc: "Opens local video files", options: win.appsFor("video_player") },
                                    { type: "dropdown", id: "default_audio_player", source: "default_apps", role: "audio_player", label: "Music player", desc: "Opens local audio files", options: win.appsFor("audio_player") },
                                    { type: "dropdown", id: "default_pdf_viewer", source: "default_apps", role: "pdf_viewer", label: "PDF viewer", desc: "Opens PDF documents", options: win.appsFor("pdf_viewer") }
                                ]
                            },
                            {
                                title: "Associations",
                                rows: [
                                    { type: "action", id: "default_apps_file", label: "Open mimeapps.list", desc: "Edit raw file associations for anything not listed here", actionLabel: "Open file" },
                                    { type: "action", id: "default_apps_refresh", label: "Refresh application list", desc: "Rescan .desktop files after installing or removing applications", actionLabel: "Rescan" }
                                ]
                            }
                        ]
                    },
                    {
                        id: "keyboard",
                        label: "Keyboard",
                        icon: "\uf11c",
                        groups: [
                            {
                                title: "Shortcuts",
                                rows: [
                                    { type: "action", id: "keybinds_open", label: "Keyboard shortcuts", desc: "Every Hyprland and ZenShell binding in one sheet", actionLabel: "View all" }
                                ]
                            }
                        ]
                    }
                ]
            }
        ];
    }

    // A page matches when its own name, one of its group titles, one of its
    // rows or — for the two grid pages — one of the items inside the grid
    // matches. Every group is probed defensively: a group describes either
    // a set of rows or a grid, and reading `rows.length` off a grid group
    // threw a TypeError that killed the whole filter on the first
    // keystroke.
    function pageMatches(page, q) {
        if (page.label.toLowerCase().indexOf(q) !== -1) return true;
        if (page.desc && page.desc.toLowerCase().indexOf(q) !== -1) return true;

        for (var i = 0; i < page.groups.length; i++) {
            var group = page.groups[i];
            if (!group) continue;

            if (group.title && group.title.toLowerCase().indexOf(q) !== -1) return true;

            if (group.intro) {
                if (group.intro.label && group.intro.label.toLowerCase().indexOf(q) !== -1) return true;
                if (group.intro.desc && group.intro.desc.toLowerCase().indexOf(q) !== -1) return true;
            }

            var rows = group.rows ? group.rows : [];
            for (var j = 0; j < rows.length; j++) {
                var row = rows[j];
                if (!row) continue;
                if (row.label && row.label.toLowerCase().indexOf(q) !== -1) return true;
                if (row.desc && row.desc.toLowerCase().indexOf(q) !== -1) return true;
                if (row.actionLabel && row.actionLabel.toLowerCase().indexOf(q) !== -1) return true;
                if (row.options) {
                    for (var k = 0; k < row.options.length; k++) {
                        if (row.options[k].label && row.options[k].label.toLowerCase().indexOf(q) !== -1) return true;
                    }
                }
            }

            if (group.grid === "themes") {
                var themes = root.themesList ? root.themesList : [];
                for (var t = 0; t < themes.length; t++) {
                    var theme = themes[t];
                    if (!theme) continue;
                    if (theme.name && theme.name.toLowerCase().indexOf(q) !== -1) return true;
                    if (theme.id && String(theme.id).toLowerCase().indexOf(q) !== -1) return true;
                }
            }

            if (group.grid === "wallpapers") {
                var papers = root.allWallpapers ? root.allWallpapers : [];
                for (var p = 0; p < papers.length; p++) {
                    var paper = papers[p];
                    if (!paper) continue;
                    var name = paper.filename || paper.name || "";
                    if (name.toLowerCase().indexOf(q) !== -1) return true;
                }
            }
        }
        return false;
    }

    function refreshNav() {
        var cat = win.buildCatalog();
        var q = win.query.trim().toLowerCase();
        var out = [];

        for (var i = 0; i < cat.length; i++) {
            var c = cat[i];
            var pages = [];
            for (var j = 0; j < c.pages.length; j++) {
                if (!q || win.pageMatches(c.pages[j], q)) pages.push(c.pages[j]);
            }
            if (pages.length > 0) out.push({ id: c.id, label: c.label, icon: c.icon, pages: pages });
        }

        win.catalog = cat;
        win.filtered = out;

        // Keep the active page pointing at something that still exists.
        var active = null;
        for (var k = 0; k < out.length; k++) {
            for (var m = 0; m < out[k].pages.length; m++) {
                if (out[k].pages[m].id === root.settingsPage) active = out[k].pages[m];
            }
        }
        if (!active && out.length > 0 && out[0].pages.length > 0) {
            active = out[0].pages[0];
            root.settingsPage = active.id;
        }
        win.activePageModel = active;
    }

    Component.onCompleted: win.refreshNav()

    // The page can also be switched from outside the window (a keybind or
    // the CLI), so follow the shell's state rather than only our own clicks.
    onActivePageChanged: {
        win.refreshNav();
        win.revealActiveCategory();
        // A new page starts at its top; carrying the previous page's scroll
        // offset made pages look like their first group was missing.
        if (content) content.contentY = 0;
    }

    // A page opened from a keybind or IPC can live in a collapsed category.
    // Expand it so the highlighted item is actually visible in the sidebar.
    function revealActiveCategory() {
        for (var i = 0; i < win.catalog.length; i++) {
            for (var j = 0; j < win.catalog[i].pages.length; j++) {
                if (win.catalog[i].pages[j].id === root.settingsPage) {
                    var id = win.catalog[i].id;
                    if (win.expandedCategories[id] === false) {
                        var next = Object.assign({}, win.expandedCategories);
                        next[id] = true;
                        win.expandedCategories = next;
                    }
                    // The category can be expanded but still below the fold
                    // in the sidebar, leaving the active page invisible.
                    var categoryIndex = i;
                    Qt.callLater(function() {
                        navList.positionViewAtIndex(categoryIndex, ListView.Beginning);
                    });
                    return;
                }
            }
        }
    }

    // Escape closes the window from anywhere. The search field handles it
    // first — it clears the query when there is one — so this only sees the
    // key when the field does not hold the focus.
    // Opening the window puts the cursor in the search field, so the whole
    // app is reachable from the keyboard without a single click. The small
    // delay lets the compositor hand keyboard focus to the new toplevel
    // before QML tries to move the active item.
    Timer {
        id: focusTimer
        interval: 90
        onTriggered: searchInput.forceActiveFocus()
    }

    onVisibleChanged: {
        if (visible) {
            // Re-read both lists on every open: applications can be installed
            // while the window is closed and the associations can change in
            // another settings tool.
            win.defaultAppsLoaded = false;
            win.refreshDesktopApps();
            win.refreshDefaultApps();
            win.revealActiveCategory();
            focusTimer.restart();
        }
    }

    // A compositor close (Alt+F4) and the in-window close button both have
    // to leave the shell's state pointing at a closed window.
    onClosed: root.settingsWindowOpen = false

    Connections {
        target: root
        function onSettingsWindowOpenChanged() {
            if (root.settingsWindowOpen) {
                win.refreshDefaultApps();
                focusTimer.restart();
            }
        }
    }

    Connections {
        target: DesktopEntries.applications
        function onValuesChanged() {
            win.refreshDesktopApps();
        }
    }

    // ── Desktop applications ──────────────────────────────────────
    // The launcher already reads .desktop files through Quickshell, so the
    // default-apps picker uses the same source instead of keeping a second
    // application list in sync by hand.
    function refreshDesktopApps() {
        var model = DesktopEntries.applications;
        var entries = model && model.values ? model.values : [];
        var list = [];
        for (var i = 0; i < entries.length; i++) {
            var entry = entries[i];
            if (!entry || entry.noDisplay) continue;
            if (!entry.id) continue;
            list.push({
                id: entry.id,
                name: entry.name || entry.id,
                categories: entry.categories || []
            });
        }
        list.sort(function(a, b) { return String(a.name).localeCompare(String(b.name)); });
        win.desktopApps = list;
        win.refreshNav();
    }

    // Role-filtered options for the default-apps dropdowns. Categories are
    // advisory, so when a machine has no application advertising a role the
    // picker falls back to the full list rather than showing an empty menu.
    function normalizeAppId(id) {
        var value = String(id || "").replace(/@.*$/, "").replace(/\.desktop$/, "");
        return value;
    }

    function desktopId(id) {
        var value = String(id || "");
        return value.indexOf(".desktop") === -1 ? value + ".desktop" : value;
    }

    function appsFor(role) {
        var filters = win.appFilters[role] || [];
        var matched = [];
        var seen = {};
        for (var i = 0; i < win.desktopApps.length; i++) {
            var app = win.desktopApps[i];
            var key = win.normalizeAppId(app.id);
            if (seen[key]) continue;

            var hit = filters.length === 0;
            var categories = app.categories || [];
            for (var c = 0; c < categories.length && !hit; c++) {
                var category = String(categories[c]).toLowerCase();
                for (var f = 0; f < filters.length; f++) {
                    if (category.indexOf(filters[f]) !== -1) {
                        hit = true;
                        break;
                    }
                }
            }
            if (hit) {
                seen[key] = true;
                matched.push(app);
            }
        }
        if (matched.length === 0) {
            // Categories are advisory: fall back to every application rather
            // than showing an empty menu on a machine that does not advertise
            // the role.
            for (var j = 0; j < win.desktopApps.length; j++) {
                var fallback = win.desktopApps[j];
                var fallbackKey = win.normalizeAppId(fallback.id);
                if (seen[fallbackKey]) continue;
                seen[fallbackKey] = true;
                matched.push(fallback);
            }
        }

        var options = [];
        for (var k = 0; k < matched.length; k++) {
            // DesktopEntries ids omit the .desktop suffix, while xdg-mime
            // reports and expects the full desktop file id. Normalise once so
            // the stored association matches the dropdown option exactly.
            options.push({ value: win.desktopId(matched[k].id), label: matched[k].name });
        }

        // The associated application can be outside the category filter (a
        // browser used for mail, for example). Keep it in the menu so the
        // trigger never shows an id that cannot be re-selected.
        var current = String(win.defaultApps[role] || "");
        if (current !== "") {
            var currentKey = win.normalizeAppId(current);
            var present = false;
            for (var m = 0; m < options.length; m++) {
                if (win.normalizeAppId(options[m].value) === currentKey) {
                    present = true;
                    break;
                }
            }
            if (!present) {
                var label = currentKey;
                for (var n = 0; n < win.desktopApps.length; n++) {
                    if (win.normalizeAppId(win.desktopApps[n].id) === currentKey) {
                        label = win.desktopApps[n].name;
                        break;
                    }
                }
                options.unshift({ value: win.desktopId(currentKey), label: label });
            }
        }
        return options;
    }

    function refreshDefaultApps() {
        if (!defaultAppsRead.running) defaultAppsRead.running = true;
    }

    function setDefaultApp(role, desktopId) {
        if (!role || !desktopId) return;
        var next = Object.assign({}, win.defaultApps);
        next[role] = desktopId;
        win.defaultApps = next;
        defaultAppsWrite.command = [
            "python3",
            Quickshell.shellDir + "/scripts/default_apps.py",
            "set",
            role,
            desktopId
        ];
        defaultAppsWrite.running = true;
    }

    Process {
        id: defaultAppsRead
        command: ["python3", Quickshell.shellDir + "/scripts/default_apps.py", "get"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var parsed = JSON.parse(text);
                    if (parsed && typeof parsed === "object") {
                        win.defaultApps = parsed;
                        // Rebuild once, on the first read, so a role whose
                        // current app is outside the category filter still
                        // appears in its dropdown options. Later writes do
                        // not need to tear down the page.
                        if (!win.defaultAppsLoaded) {
                            win.defaultAppsLoaded = true;
                            win.refreshNav();
                        }
                    }
                } catch (e) {}
            }
        }
    }

    Process {
        id: defaultAppsWrite
        command: []
        onExited: win.refreshDefaultApps()
    }

    // ── Actions ───────────────────────────────────────────────────
    // Some settings live in another surface. The settings window closes
    // first so the target is not hidden behind this one.
    function runAction(id) {
        switch (id) {
            case "dock_pins":
                root.settingsWindowOpen = false;
                dockMenuProc.command = ["quickshell", "ipc", "-p", Quickshell.shellDir + "/modules/dock", "call", "qs-dock", "showDockMenu"];
                dockMenuProc.running = true;
                break;
            case "clipboard_open":
                root.settingsWindowOpen = false;
                root.displayState = 15;
                root.updateState();
                break;
            case "camera_open":
                root.settingsWindowOpen = false;
                root.displayState = 24;
                root.updateState();
                break;
            case "keybinds_open":
                root.settingsWindowOpen = false;
                root.displayState = 23;
                root.updateState();
                break;
            case "default_apps_file":
                appsFileProc.command = ["bash", "-c", "touch \"$HOME/.config/mimeapps.list\"; xdg-open \"$HOME/.config/mimeapps.list\""];
                appsFileProc.running = true;
                break;
            case "default_apps_refresh":
                desktopRefreshProc.command = ["bash", "-c", "update-desktop-database \"$HOME/.local/share/applications\" >/dev/null 2>&1 || true"];
                desktopRefreshProc.running = true;
                win.refreshDesktopApps();
                win.refreshDefaultApps();
                break;
        }
    }

    Process {
        id: dockMenuProc
        command: []
    }

    Process {
        id: appsFileProc
        command: []
    }

    Process {
        id: desktopRefreshProc
        command: []
    }

    // Wallpapers go through the same script the island picker uses, so the
    // matugen theme and the hyprlock background follow the desktop.
    function applyWallpaper(path) {
        wallpaperProc.command = ["bash", Quickshell.env("HOME") + "/scripts/wallpaper-selector.sh", path];
        wallpaperProc.running = true;
    }

    Process {
        id: wallpaperProc
        command: []
    }

    function handlePick(spec, value) {
        if (value === "__action__") {
            win.runAction(spec.id);
            return;
        }
        root.setValue(spec.id, value);
    }

    // The shadow is a sibling of the card: the card clips its own content,
    // so a shadow parented inside it would be clipped away.
    RectangularShadow {
        anchors.fill: card
        radius: card.radius
        color: "#50000000"
        blur: 24
        spread: 0
        offset: Qt.vector2d(0, 8)
    }

    // ── Card ──────────────────────────────────────────────────────
    // The window is bigger than the visible card only by `framePad`, which
    // holds the shadow and the eight resize grips. The card is the visual
    // surface and owns keyboard focus for the window-level Escape shortcut.
    Rectangle {
        id: card
        x: win.framePad
        y: win.framePad
        width: win.cardWidth
        height: win.cardHeight
        radius: 20
        // A settings window is read for minutes at a time, so it is a solid
        // tonal surface, not glass. The hierarchy comes from the sidebar and
        // the group containers, not from a translucent sheen.
        color: root.cSurface
        border.width: 1
        border.color: root.ink(0.12)
        clip: true
        focus: true

        Keys.onEscapePressed: {
            root.settingsWindowOpen = false;
            event.accepted = true;
        }

        Behavior on color { ColorAnimation { duration: 200 } }

        // ── Header ─────────────────────────────────────────────────
        Item {
            id: header
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: 22
            anchors.rightMargin: 18
            height: 60

            // The header is the title bar. Pressing anywhere on it starts a
            // native compositor move, so the window follows the pointer with
            // the same physics as every other application.
            MouseArea {
                id: headerDrag
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton
                enabled: !win.maximized
                onPressed: win.startSystemMove()
            }

            Row {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                spacing: 11

                Rectangle {
                    width: 34
                    height: 34
                    radius: 10
                    anchors.verticalCenter: parent.verticalCenter
                    color: root.cSurfaceContainerHigh
                    border.width: 1
                    border.color: root.cOutlineVariant

                    Text {
                        anchors.centerIn: parent
                        text: root.icoSettings
                        color: root.cPrimary
                        font.family: root.fontIcon
                        font.pixelSize: 18
                    }
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Settings"
                    color: root.cOnSurface
                    font.family: win.uiFont
                    font.pixelSize: 20
                    font.weight: Font.Medium
                }
            }

            Row {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: 6

                Rectangle {
                    width: 34
                    height: 34
                    radius: 10
                    color: expandMouse.containsMouse ? root.cStateHover : "transparent"
                    Behavior on color { ColorAnimation { duration: 140 } }

                    Text {
                        anchors.centerIn: parent
                        text: win.maximized ? "\uf066" : "\uf065"
                        color: root.cOnSurfaceVariant
                        font.family: win.iconFont
                        font.pixelSize: 12
                    }

                    MouseArea {
                        id: expandMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: win.maximized = !win.maximized
                    }
                }

                Rectangle {
                    width: 32
                    height: 32
                    radius: 9
                    color: closeMouse.containsMouse ? Qt.rgba(win.accent.r, win.accent.g, win.accent.b, 0.18) : "transparent"
                    border.width: 1
                    border.color: closeMouse.containsMouse ? Qt.rgba(win.accent.r, win.accent.g, win.accent.b, 0.34) : "transparent"
                    Behavior on color { ColorAnimation { duration: 140 } }

                    Text {
                        anchors.centerIn: parent
                        text: "\uf00d"
                        color: root.cFgSecondary
                        font.family: win.iconFont
                        font.pixelSize: 12
                    }

                    MouseArea {
                        id: closeMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.settingsWindowOpen = false
                    }
                }
            }
        }

        Rectangle {
            id: headerDivider
            anchors.top: header.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            height: 1
            color: root.ink(0.078)
        }

        // ── Body ───────────────────────────────────────────────────
        RowLayout {
            anchors.top: headerDivider.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            spacing: 0

            // ── Sidebar ─────────────────────────────────────────────
            Item {
                Layout.preferredWidth: 288
                Layout.fillHeight: true

                Rectangle {
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: 1
                    color: root.ink(0.071)
                }

                // User card
                Item {
                    id: userCard
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.leftMargin: 20
                    anchors.rightMargin: 20
                    height: 84

                    Rectangle {
                        id: avatar
                        width: 46
                        height: 46
                        radius: 23
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: win.accent }
                            GradientStop { position: 1.0; color: Qt.rgba(win.accent.r, win.accent.g, win.accent.b, 0.35) }
                        }
                        border.width: 1
                        border.color: root.ink(0.227)

                        Text {
                            anchors.centerIn: parent
                            text: "Z"
                            color: root.onAccent()
                            font.family: win.uiFont
                            font.pixelSize: 19
                            font.weight: Font.Bold
                        }
                    }

                    Column {
                        anchors.left: avatar.right
                        anchors.leftMargin: 13
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 2

                        Text {
                            text: "Zen"
                            color: root.cFgPrimary
                            font.family: win.uiFont
                            font.pixelSize: 14
                            font.weight: Font.DemiBold
                        }

                        Text {
                            text: "ZenShell · " + Quickshell.env("USER")
                            color: win.textMuted
                            font.family: win.uiFont
                            font.pixelSize: 11
                        }
                    }
                }

                // Search field
                Item {
                    id: searchBox
                    anchors.top: userCard.bottom
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.leftMargin: 20
                    anchors.rightMargin: 20
                    height: 36

                    Rectangle {
                        anchors.fill: parent
                        radius: 10
                        color: root.ink(0.039)
                        border.width: 1
                        border.color: searchInput.activeFocus ? Qt.rgba(win.accent.r, win.accent.g, win.accent.b, 0.55) : root.ink(0.11)
                        Behavior on border.color { ColorAnimation { duration: 150 } }

                        Text {
                            id: searchIcon
                            anchors.left: parent.left
                            anchors.leftMargin: 11
                            anchors.verticalCenter: parent.verticalCenter
                            text: "\uf002"
                            color: win.textMuted
                            font.family: win.iconFont
                            font.pixelSize: 11
                        }

                        TextInput {
                            id: searchInput
                            anchors.left: searchIcon.right
                            anchors.leftMargin: 9
                            anchors.right: parent.right
                            anchors.rightMargin: 12
                            anchors.verticalCenter: parent.verticalCenter
                            clip: true
                            color: root.cFgPrimary
                            font.family: win.uiFont
                            font.pixelSize: 12
                            selectionColor: Qt.rgba(win.accent.r, win.accent.g, win.accent.b, 0.45)
                            selectedTextColor: root.onAccent()
                            selectByMouse: true

                            onTextChanged: {
                                win.query = text;
                                win.refreshNav();
                            }

                            Keys.onEscapePressed: {
                                if (text.length > 0) {
                                    text = "";
                                } else {
                                    root.settingsWindowOpen = false;
                                }
                                event.accepted = true;
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                visible: searchInput.text.length === 0
                                text: "Search settings"
                                color: win.textMuted
                                font.family: win.uiFont
                                font.pixelSize: 12
                            }
                        }
                    }
                }

                // Navigation
                ListView {
                    id: navList
                    anchors.top: searchBox.bottom
                    anchors.topMargin: 14
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    anchors.bottomMargin: 12
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    model: win.filtered
                    spacing: 4

                    Controls.ScrollBar.vertical: Controls.ScrollBar {
                        id: navScroll
                        width: 4
                        policy: Controls.ScrollBar.AsNeeded
                        background: Item {}
                        contentItem: Rectangle {
                            implicitWidth: 4
                            radius: 2
                            color: navScroll.pressed ? root.ink(0.34) : root.ink(0.18)
                            visible: navScroll.size < 1
                        }
                    }

                    delegate: Item {
                        id: categoryItem
                        required property var modelData

                        width: navList.width
                        height: categoryColumn.implicitHeight + 6

                        Column {
                            id: categoryColumn
                            width: parent.width
                            spacing: 2

                            // Category header
                            Item {
                                width: parent.width
                                height: 30

                                Text {
                                    anchors.left: parent.left
                                    anchors.leftMargin: 10
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: categoryItem.modelData.icon
                                    color: win.textMuted
                                    font.family: win.iconFont
                                    font.pixelSize: 11
                                }

                                Text {
                                    anchors.left: parent.left
                                    anchors.leftMargin: 30
                                    anchors.right: chevron.left
                                    anchors.rightMargin: 8
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: categoryItem.modelData.label
                                    color: root.cFgSecondary
                                    font.family: win.uiFont
                                    font.pixelSize: 11
                                    font.weight: Font.DemiBold
                                    font.letterSpacing: 0.6
                                    elide: Text.ElideRight
                                }

                                Text {
                                    id: chevron
                                    anchors.right: parent.right
                                    anchors.rightMargin: 10
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: "\uf078"
                                    color: win.textMuted
                                    font.family: win.iconFont
                                    font.pixelSize: 9
                                    rotation: win.query.trim() === "" && win.expandedCategories[categoryItem.modelData.id] === false ? -90 : 0
                                    Behavior on rotation { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        var next = Object.assign({}, win.expandedCategories);
                                        next[categoryItem.modelData.id] = next[categoryItem.modelData.id] === false;
                                        win.expandedCategories = next;
                                    }
                                }
                            }

                            // Pages
                            Repeater {
                                model: categoryItem.modelData.pages

                                delegate: Rectangle {
                                    id: pageItem
                                    required property var modelData

                                    readonly property bool active: root.settingsPage === modelData.id

                                    visible: win.query.trim() !== "" || win.expandedCategories[categoryItem.modelData.id] !== false

                                    width: categoryColumn.width
                                    height: 36
                                    radius: 10
                                    color: active
                                        ? Qt.rgba(win.accent.r, win.accent.g, win.accent.b, 0.16)
                                        : (pageMouse.containsMouse ? root.ink(0.047) : "transparent")
                                    Behavior on color { ColorAnimation { duration: 140 } }

                                    Text {
                                        anchors.left: parent.left
                                        anchors.leftMargin: 30
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: pageItem.modelData.icon
                                        color: pageItem.active ? win.accent : win.textMuted
                                        font.family: win.iconFont
                                        font.pixelSize: 11
                                    }

                                    Text {
                                        anchors.left: parent.left
                                        anchors.leftMargin: 50
                                        anchors.right: parent.right
                                        anchors.rightMargin: 10
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: pageItem.modelData.label
                                        color: pageItem.active ? win.accent : root.cFgSecondary
                                        font.family: win.uiFont
                                        font.pixelSize: 12
                                        font.weight: pageItem.active ? Font.DemiBold : Font.Normal
                                        elide: Text.ElideRight
                                    }

                                    MouseArea {
                                        id: pageMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            root.settingsPage = pageItem.modelData.id;
                                            win.refreshNav();
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Nothing matched: say so instead of showing an empty
                    // sidebar that looks broken.
                    Text {
                        anchors.top: navList.top
                        anchors.topMargin: 18
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.leftMargin: 30
                        anchors.rightMargin: 20
                        visible: win.filtered.length === 0
                        text: "No settings match \"" + win.query.trim() + "\""
                        color: win.textMuted
                        font.family: win.uiFont
                        font.pixelSize: 11
                        wrapMode: Text.WordWrap
                    }
                }
            }

            // ── Content ─────────────────────────────────────────────
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                Flickable {
                    id: content
                    anchors.fill: parent
                    anchors.leftMargin: 26
                    anchors.rightMargin: 26
                    anchors.topMargin: 24
                    anchors.bottomMargin: 20
                    clip: true
                    // Leave a narrow gutter at the right for the scroll bar so
                    // it never sits on top of a dropdown or a slider.
                    contentWidth: width - 8
                    contentHeight: pageColumn.implicitHeight
                    boundsBehavior: Flickable.StopAtBounds

                    Controls.ScrollBar.vertical: Controls.ScrollBar {
                        id: pageScroll
                        width: 8
                        policy: Controls.ScrollBar.AsNeeded
                        background: Item {}
                        contentItem: Rectangle {
                            implicitWidth: 8
                            radius: 4
                            color: pageScroll.pressed ? root.ink(0.40) : root.ink(0.24)
                            visible: pageScroll.size < 1
                            Behavior on color { ColorAnimation { duration: 120 } }
                        }
                    }

                    Column {
                        id: pageColumn
                        width: content.width - 8
                        spacing: 18

                        // Page header
                        Row {
                            width: parent.width
                            spacing: 12

                            Rectangle {
                                width: 34
                                height: 34
                                radius: 10
                                anchors.verticalCenter: parent.verticalCenter
                                color: Qt.rgba(win.accent.r, win.accent.g, win.accent.b, 0.14)
                                border.width: 1
                                border.color: Qt.rgba(win.accent.r, win.accent.g, win.accent.b, 0.26)

                                Text {
                                    anchors.centerIn: parent
                                    text: win.activePageModel ? win.activePageModel.icon : "\uf013"
                                    color: win.accent
                                    font.family: win.iconFont
                                    font.pixelSize: 14
                                }
                            }

                            Column {
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 1

                                Text {
                                    text: win.activePageModel ? win.activePageModel.label : "Settings"
                                    color: root.cFgPrimary
                                    font.family: win.uiFont
                                    font.pixelSize: 17
                                    font.weight: Font.DemiBold
                                }

                                Text {
                                    text: {
                                        if (!win.activePageModel) return "";
                                        if (win.activePageModel.desc) return win.activePageModel.desc;
                                        var cat = "";
                                        for (var i = 0; i < win.catalog.length; i++) {
                                            for (var j = 0; j < win.catalog[i].pages.length; j++) {
                                                if (win.catalog[i].pages[j].id === root.settingsPage) cat = win.catalog[i].label;
                                            }
                                        }
                                        return cat;
                                    }
                                    color: win.textMuted
                                    font.family: win.uiFont
                                    font.pixelSize: 11
                                }
                            }
                        }

                        // Groups
                        Repeater {
                            model: win.activePageModel ? win.activePageModel.groups : []

                            delegate: Rectangle {
                                id: groupCard
                                required property var modelData

                                width: pageColumn.width
                                height: groupColumn.implicitHeight + 30
                                radius: 14
                                color: root.ink(0.031)
                                border.width: 1
                                border.color: root.ink(0.071)

                                Column {
                                    id: groupColumn
                                    x: 16
                                    y: 15
                                    width: parent.width - 32
                                    spacing: 0

                                    Text {
                                        text: groupCard.modelData.title ? groupCard.modelData.title : ""
                                        color: root.cFgSecondary
                                        font.family: win.uiFont
                                        font.pixelSize: 11
                                        font.weight: Font.DemiBold
                                        font.letterSpacing: 0.4
                                        bottomPadding: 6
                                    }

                                    // A grid group leads with a sentence about
                                    // what it does, then the picker itself.
                                    Text {
                                        width: parent.width
                                        visible: groupCard.modelData.intro !== undefined
                                        text: groupCard.modelData.intro ? groupCard.modelData.intro.label : ""
                                        color: root.cFgPrimary
                                        font.family: win.uiFont
                                        font.pixelSize: 13
                                        font.weight: Font.DemiBold
                                    }

                                    Text {
                                        width: parent.width
                                        visible: groupCard.modelData.intro !== undefined
                                        text: groupCard.modelData.intro ? groupCard.modelData.intro.desc : ""
                                        color: win.textMuted
                                        font.family: win.uiFont
                                        font.pixelSize: 11
                                        wrapMode: Text.WordWrap
                                        topPadding: 2
                                    }

                                    Item {
                                        width: 1
                                        height: groupCard.modelData.intro !== undefined ? 12 : 0
                                    }

                                    SettingsThemeGrid {
                                        width: groupColumn.width
                                        visible: groupCard.modelData.grid === "themes"
                                        filter: win.query
                                        onPicked: (themeId) => root.applyTheme(themeId)
                                    }

                                    SettingsWallpaperGrid {
                                        width: groupColumn.width
                                        visible: groupCard.modelData.grid === "wallpapers"
                                        filter: win.query
                                        onPicked: (path) => win.applyWallpaper(path)
                                    }

                                    Repeater {
                                        model: groupCard.modelData.rows ? groupCard.modelData.rows : []

                                        delegate: Item {
                                            id: rowHolder
                                            required property var modelData
                                            required property int index

                                            width: groupColumn.width
                                            height: 58

                                            // Hairline between rows
                                            Rectangle {
                                                anchors.top: parent.top
                                                anchors.left: parent.left
                                                anchors.right: parent.right
                                                height: 1
                                                visible: rowHolder.index > 0
                                                color: root.ink(0.059)
                                            }

                                            SettingsRow {
                                                anchors.fill: parent
                                                anchors.topMargin: 1
                                                spec: rowHolder.modelData
                                                value: rowHolder.modelData.source === "default_apps"
                                                    ? (win.defaultApps[rowHolder.modelData.role] || "")
                                                    : root.values[rowHolder.modelData.id]
                                                accent: win.accent
                                                hostWindow: win
                                                onPicked: (v) => {
                                                    if (rowHolder.modelData.source === "default_apps") {
                                                        win.setDefaultApp(rowHolder.modelData.role, v);
                                                    } else {
                                                        win.handlePick(rowHolder.modelData, v);
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // ── Resize grips ──────────────────────────────────────────────
    // The transparent frame around the card is the only place the grips can
    // live without covering content. Each one starts a native compositor
    // resize from the edge it sits on, exactly like a window decoration.
    Component {
        id: resizeGrip

        MouseArea {
            property int edges: Qt.RightEdge

            width: 8
            height: 8
            acceptedButtons: Qt.LeftButton
            hoverEnabled: true
            visible: !win.maximized
            cursorShape: edges === Qt.LeftEdge || edges === Qt.RightEdge
                ? Qt.SizeHorCursor
                : (edges === Qt.TopEdge || edges === Qt.BottomEdge
                    ? Qt.SizeVerCursor
                    : ((edges === (Qt.LeftEdge | Qt.TopEdge) || edges === (Qt.RightEdge | Qt.BottomEdge))
                        ? Qt.SizeFDiagCursor
                        : Qt.SizeBDiagCursor))

            onPressed: win.startSystemResize(edges)
        }
    }

    Loader {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: win.framePad
        sourceComponent: resizeGrip
        onLoaded: item.edges = Qt.LeftEdge
        visible: !win.maximized
    }

    Loader {
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: win.framePad
        sourceComponent: resizeGrip
        onLoaded: item.edges = Qt.RightEdge
        visible: !win.maximized
    }

    Loader {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: win.framePad
        sourceComponent: resizeGrip
        onLoaded: item.edges = Qt.TopEdge
        visible: !win.maximized
    }

    Loader {
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: win.framePad
        sourceComponent: resizeGrip
        onLoaded: item.edges = Qt.BottomEdge
        visible: !win.maximized
    }

    Loader {
        anchors.left: parent.left
        anchors.top: parent.top
        width: win.framePad + 8
        height: win.framePad + 8
        sourceComponent: resizeGrip
        onLoaded: item.edges = Qt.LeftEdge | Qt.TopEdge
        visible: !win.maximized
    }

    Loader {
        anchors.right: parent.right
        anchors.top: parent.top
        width: win.framePad + 8
        height: win.framePad + 8
        sourceComponent: resizeGrip
        onLoaded: item.edges = Qt.RightEdge | Qt.TopEdge
        visible: !win.maximized
    }

    Loader {
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        width: win.framePad + 8
        height: win.framePad + 8
        sourceComponent: resizeGrip
        onLoaded: item.edges = Qt.LeftEdge | Qt.BottomEdge
        visible: !win.maximized
    }

    Loader {
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        width: win.framePad + 8
        height: win.framePad + 8
        sourceComponent: resizeGrip
        onLoaded: item.edges = Qt.RightEdge | Qt.BottomEdge
        visible: !win.maximized
    }
}
