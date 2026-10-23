import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

// The ZenShell settings window.
//
// It is a full modal dialog rather than another island state, so it lives
// in its own overlay surface and can be as large as the desktop needs. The
// left column is a searchable tree of pages; the right column renders the
// active page. Every control writes through root.setValue(), which keeps the
// store, the live shell and the persisted file in step.
Item {
    id: win

    anchors.fill: parent

    readonly property color accent: root.currentThemeAccent
    readonly property string uiFont: root.uiFont
    readonly property string iconFont: root.font

    // The window scales with the interface scale, exactly like the island
    // and every panel. The card is laid out in unscaled units and then
    // scaled, so the content keeps its proportions while the whole surface
    // grows and shrinks with the rest of the shell.
    readonly property real uiScale: root.uiScale ? root.uiScale : 1

    // The window fills most of the screen but keeps a margin so the
    // wallpaper still frames it, and can be expanded to fill completely.
    property bool expanded: false
    property string query: ""
    readonly property string activePage: root.settingsPage
    property var expandedCategories: ({ personalization: true, shell: true, island: true, system: false })
    property var catalog: []
    property var filtered: []
    property var activePageModel: null

    // The card is sized in unscaled units; the scale below turns it into
    // its final size on screen. The margins are therefore measured in
    // scaled units too, which is why they are divided by uiScale. The base
    // width stays wide enough for the theme grid, and the grids themselves
    // reflow when the scale squeezes the content column.
    readonly property int cardWidth: expanded
        ? Math.floor((parent.width - 24) / uiScale)
        : Math.floor(Math.min(1160, (parent.width - 76) / uiScale))
    readonly property int cardHeight: expanded
        ? Math.floor((parent.height - 24) / uiScale)
        : Math.floor(Math.min(812, (parent.height - 76) / uiScale))

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
                                    { type: "slider", id: "ui_scale", label: "Interface scale", desc: "Scales the island, every panel and this window together", min: 0.9, max: 1.5, step: 0.05, unit: "×" }
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
                                    { type: "segment", id: "profile", label: "Active profile", desc: "The island with the dock, or the command bar", options: [ { value: "island", label: "Island" }, { value: "bar", label: "Command bar" } ] }
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
                        groups: [
                            {
                                title: "Dock",
                                rows: [
                                    { type: "toggle", id: "dock_auto_hide", label: "Auto-hide", desc: "Keep the dock out of the way until the pointer reaches the edge" },
                                    { type: "segment", id: "dock_theme", label: "Dock material", desc: "The same choice as the island", options: [ { value: "solid", label: "Solid" }, { value: "liquid", label: "Liquid" } ] }
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
    onActivePageChanged: win.refreshNav()

    // Escape closes the window from anywhere. The search field handles it
    // first — it clears the query when there is one — so this only sees the
    // key when the field does not hold the focus.
    focus: true
    Keys.onEscapePressed: {
        root.settingsWindowOpen = false;
        event.accepted = true;
    }

    // Opening the window puts the cursor in the search field, so the whole
    // app is reachable from the keyboard without a single click.
    Connections {
        target: root
        function onSettingsWindowOpenChanged() {
            if (root.settingsWindowOpen) {
                Qt.callLater(function() { searchInput.forceActiveFocus(); });
            }
        }
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
        }
    }

    Process {
        id: dockMenuProc
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

    // ── Backdrop ──────────────────────────────────────────────────
    Rectangle {
        anchors.fill: parent
        color: "#99000000"
        Behavior on color { ColorAnimation { duration: 200 } }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.settingsWindowOpen = false
    }

    // ── Card ──────────────────────────────────────────────────────
    Rectangle {
        id: card
        width: win.cardWidth
        height: win.cardHeight
        anchors.centerIn: parent
        radius: 18
        scale: win.uiScale
        transformOrigin: Item.Center
        color: root.islandTheme === "liquid" ? root.glass(0.94) : root.glass(0.95)
        border.width: 1
        border.color: Qt.rgba(win.accent.r, win.accent.g, win.accent.b, 0.28)
        clip: true

        Behavior on scale { NumberAnimation { duration: root.motionPanel; easing.type: Easing.OutExpo } }

        Behavior on width { NumberAnimation { duration: root.motionPanel; easing.type: Easing.OutExpo } }
        Behavior on height { NumberAnimation { duration: root.motionPanel; easing.type: Easing.OutExpo } }

        RectangularShadow {
            anchors.fill: card
            radius: card.radius
            color: "#70000000"
            blur: 60
            spread: 2
            offset: Qt.vector2d(0, 18)
        }

        // Top rim light, the same trick the island uses on its pill.
        Rectangle {
            width: parent.width
            height: 1
            anchors.top: parent.top
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: "transparent" }
                GradientStop { position: 0.5; color: root.ink(0.22) }
                GradientStop { position: 1.0; color: "transparent" }
            }
        }

        // ── Header ─────────────────────────────────────────────────
        Item {
            id: header
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: 22
            anchors.rightMargin: 18
            height: 60

            Row {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                spacing: 11

                Rectangle {
                    width: 30
                    height: 30
                    radius: 9
                    anchors.verticalCenter: parent.verticalCenter
                    color: Qt.rgba(win.accent.r, win.accent.g, win.accent.b, 0.14)
                    border.width: 1
                    border.color: Qt.rgba(win.accent.r, win.accent.g, win.accent.b, 0.28)

                    Text {
                        anchors.centerIn: parent
                        text: "\uf013"
                        color: win.accent
                        font.family: win.iconFont
                        font.pixelSize: 14
                    }
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Settings"
                    color: root.uiFg
                    font.family: win.uiFont
                    font.pixelSize: 19
                    font.weight: Font.DemiBold
                }
            }

            Row {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: 6

                Rectangle {
                    width: 32
                    height: 32
                    radius: 9
                    color: expandMouse.containsMouse ? root.ink(0.078) : "transparent"
                    border.width: 1
                    border.color: expandMouse.containsMouse ? root.ink(0.141) : "transparent"
                    Behavior on color { ColorAnimation { duration: 140 } }

                    Text {
                        anchors.centerIn: parent
                        text: win.expanded ? "\uf066" : "\uf065"
                        color: root.uiFgDim
                        font.family: win.iconFont
                        font.pixelSize: 12
                    }

                    MouseArea {
                        id: expandMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: win.expanded = !win.expanded
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
                        color: root.uiFgDim
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
                            color: root.uiFg
                            font.family: win.uiFont
                            font.pixelSize: 14
                            font.weight: Font.DemiBold
                        }

                        Text {
                            text: "ZenShell · " + Quickshell.env("USER")
                            color: root.uiFgFaint
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
                            color: root.uiFgFaint
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
                            color: root.uiFg
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
                                color: root.uiFgFaint
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
                                    color: root.uiFgFaint
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
                                    color: root.uiFgDim
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
                                    color: root.uiFgFaint
                                    font.family: win.iconFont
                                    font.pixelSize: 9
                                    rotation: win.expandedCategories[categoryItem.modelData.id] === false ? -90 : 0
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

                                    visible: win.expandedCategories[categoryItem.modelData.id] !== false

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
                                        color: pageItem.active ? win.accent : root.uiFgFaint
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
                                        color: pageItem.active ? win.accent : root.uiFgDim
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
                        color: root.uiFgFaint
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
                    contentWidth: width
                    contentHeight: pageColumn.implicitHeight
                    boundsBehavior: Flickable.StopAtBounds

                    Column {
                        id: pageColumn
                        width: content.width
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
                                    color: root.uiFg
                                    font.family: win.uiFont
                                    font.pixelSize: 17
                                    font.weight: Font.DemiBold
                                }

                                Text {
                                    text: {
                                        if (!win.activePageModel) return "";
                                        var cat = "";
                                        for (var i = 0; i < win.catalog.length; i++) {
                                            for (var j = 0; j < win.catalog[i].pages.length; j++) {
                                                if (win.catalog[i].pages[j].id === root.settingsPage) cat = win.catalog[i].label;
                                            }
                                        }
                                        return cat;
                                    }
                                    color: root.uiFgFaint
                                    font.family: win.uiFont
                                    font.pixelSize: 11
                                }
                            }

                            Item { width: parent.width; Layout.fillWidth: true }
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

                                // An open dropdown paints over the groups
                                // below it, so the card that owns it has to
                                // be lifted above its siblings. Without
                                // this the next group card painted over the
                                // list.
                                property int openDropdowns: 0
                                z: openDropdowns > 0 ? 10 : 0

                                Column {
                                    id: groupColumn
                                    x: 16
                                    y: 15
                                    width: parent.width - 32
                                    spacing: 0

                                    Text {
                                        text: groupCard.modelData.title ? groupCard.modelData.title : ""
                                        color: root.uiFgDim
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
                                        color: root.uiFg
                                        font.family: win.uiFont
                                        font.pixelSize: 13
                                        font.weight: Font.DemiBold
                                    }

                                    Text {
                                        width: parent.width
                                        visible: groupCard.modelData.intro !== undefined
                                        text: groupCard.modelData.intro ? groupCard.modelData.intro.desc : ""
                                        color: root.uiFgFaint
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
                                                value: root.values[rowHolder.modelData.id]
                                                accent: win.accent
                                                onPicked: (v) => win.handlePick(rowHolder.modelData, v)
                                                onDropdownOpenChanged: {
                                                    groupCard.openDropdowns = Math.max(0, groupCard.openDropdowns + (dropdownOpen ? 1 : -1));
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
