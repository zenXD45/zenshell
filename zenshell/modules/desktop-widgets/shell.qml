import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects

Scope {
    id: root

    // ── Type ──────────────────────────────────────────────────────
    property string font: "JetBrainsMono Nerd Font"
    readonly property string uiFont: "Google Sans Flex"

    property bool widgetsVisible: true
    property string shellProfile: "island"
    property string islandTheme: "dark"

    // ── Palette ───────────────────────────────────────────────────
    // The cards borrow the island's smoked glass and the active wallpaper's
    // accent, so the desktop widgets belong to the same shell as the dock
    // instead of reading as generic white panels.
    property color themeBg: "#0f1715"
    property color themeSurface: "#18221f"
    property color themeFg: "#d3c6aa"
    property color themeExtra: "#e67e80"
    property bool themeDark: true
    property int themeRounding: 14
    property var themesList: []
    property string currentThemeId: ""
    property string currentThemeAccent: "#838996"
    readonly property color themeAccent: currentThemeAccent

    readonly property color ink: root.themeFg
    readonly property color inkDim: root.inkAlpha(0.72)
    readonly property color inkFaint: root.inkAlpha(0.50)
    readonly property color hairline: root.inkAlpha(0.14)
    readonly property bool liquid: root.islandTheme === "liquid"
    readonly property color cardFill: root.liquid
        ? (root.themeDark ? root.glass(0.44) : root.inkAlpha(0.30))
        : root.glass(0.76)
    readonly property int cardRadius: Math.max(12, root.themeRounding + 12)

    // Tinted overlays: the alpha stays as designed, the hue comes from the
    // theme, so a light theme shades its glass where a dark theme lifts it.
    function inkAlpha(alpha: real): color {
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
        return root.themeAccent.hslLightness > 0.6 ? root.themeBg : root.themeFg;
    }

    function accentAlpha(alpha) {
        return Qt.rgba(root.themeAccent.r, root.themeAccent.g, root.themeAccent.b, alpha)
    }

    function updateThemePalette() {
        for (var i = 0; i < root.themesList.length; i++) {
            var t = root.themesList[i];
            if (t.id === root.currentThemeId) {
                root.currentThemeAccent = t.accent || root.currentThemeAccent;
                if (t.bg) root.themeBg = t.bg;
                if (t.surface) root.themeSurface = t.surface;
                if (t.fg) root.themeFg = t.fg;
                if (t.extra) root.themeExtra = t.extra;
                if (t.dark !== undefined) root.themeDark = !!t.dark;
                if (t.rounding !== undefined) root.themeRounding = t.rounding;
                return;
            }
        }
    }

    // ── Settings + theme ──────────────────────────────────────────
    FileView {
        id: shellSettings
        path: Quickshell.env("HOME") + "/.config/quickshell/shell_settings.json"
        watchChanges: true
        onFileChanged: reload()
        onTextChanged: {
            try {
                var settings = JSON.parse(text());
                if (settings.profile === "island" || settings.profile === "bar") {
                    root.shellProfile = settings.profile;
                }
                if (settings.island_theme === "dark" || settings.island_theme === "liquid") {
                    root.islandTheme = settings.island_theme;
                }
                // The settings window edits the same file, so the widgets
                // follow the preference without an IPC round trip.
                if (typeof settings.widgets_visible === "boolean") {
                    root.widgetsVisible = settings.widgets_visible;
                }
            } catch (e) {}
        }
    }

    // Toggling the widgets from a keybind has to survive a restart, so the
    // state is written back to the same settings file.
    function setWidgetsVisible(visible) {
        root.widgetsVisible = visible;
        saveSettingProcess.running = false;
        saveSettingProcess.command = [
            "python3",
            Quickshell.shellDir + "/../../scripts/set_setting.py",
            "widgets_visible",
            JSON.stringify(visible)
        ];
        saveSettingProcess.running = true;
    }

    Process {
        id: saveSettingProcess
        command: []
    }

    FileView {
        id: themeManifest
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

    FileView {
        id: activeTheme
        path: Quickshell.env("HOME") + "/.config/hypr/themes/current_theme.conf"
        watchChanges: true
        onFileChanged: reload()
        onTextChanged: {
            var match = text().match(/themes\/([^\.]+)\.conf/);
            if (match) {
                root.currentThemeId = match[1];
                root.updateThemePalette();
            }
        }
    }

    // Clock State
    property string currentTime: "00:00"
    property string currentDate: "Monday, January 1"
    property string currentGreeting: "Good morning, Zen"

    // Weather State
    property string weatherTemp: "--°"
    property string weatherIcon: "󰖐"
    property string weatherDesc: "Loading..."
    property string weatherHigh: ""
    property string weatherLow: ""

    // ── Entrance ──────────────────────────────────────────────────
    // A single quiet reveal: the time lands first, the weather follows.
    property real clockReveal: 0
    property real weatherReveal: 0

    NumberAnimation on clockReveal {
        from: 0
        to: 1
        duration: 560
        easing.type: Easing.OutCubic
    }

    SequentialAnimation on weatherReveal {
        PauseAnimation { duration: 90 }
        NumberAnimation { from: 0; to: 1; duration: 560; easing.type: Easing.OutCubic }
    }

    Timer {
        id: clockTimer
        interval: 1000
        running: root.widgetsVisible && root.shellProfile !== "bar"
        repeat: true
        onTriggered: {
            var d = new Date()
            root.currentTime = d.toLocaleTimeString(Qt.locale(), "hh:mm")
            root.currentDate = d.toLocaleDateString(Qt.locale(), "dddd, MMMM d")
            var h = d.getHours()
            if (h < 6) root.currentGreeting = "Good night, Zen"
            else if (h < 12) root.currentGreeting = "Good morning, Zen"
            else if (h < 17) root.currentGreeting = "Good afternoon, Zen"
            else if (h < 21) root.currentGreeting = "Good evening, Zen"
            else root.currentGreeting = "Good night, Zen"
        }
        Component.onCompleted: triggered()
    }

    Timer {
        id: weatherTimer
        interval: 600000 // Every 10 mins
        running: root.widgetsVisible && root.shellProfile !== "bar"
        repeat: true
        onTriggered: weatherProcess.running = true
        Component.onCompleted: triggered()
    }

    Process {
        id: weatherProcess
        command: ["python3", Quickshell.shellDir + "/get_weather.py"]
        stdout: SplitParser {
            onRead: (data) => {
                try {
                    var w = JSON.parse(data)
                    root.weatherTemp = w.temp
                    root.weatherIcon = w.icon
                    root.weatherDesc = w.desc
                    root.weatherHigh = w.high
                    root.weatherLow = w.low
                } catch (e) {}
            }
        }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: widgetWindow
            required property var modelData
            screen: modelData

            color: "transparent"
            visible: root.shellProfile !== "bar" && root.widgetsVisible

            WlrLayershell.layer: WlrLayer.Bottom
            WlrLayershell.namespace: "qs-widgets"
            exclusionMode: ExclusionMode.Ignore

            anchors {
                top: true
                right: true
                bottom: true
                left: true
            }

            // Widget Container
            Column {
                opacity: root.widgetsVisible ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
                anchors.top: parent.top
                anchors.right: parent.right
                anchors.margins: 48
                spacing: 24

                // ── Clock ─────────────────────────────────────────
                Item {
                    width: 380
                    height: 180
                    opacity: root.clockReveal
                    transform: Translate { y: (1 - root.clockReveal) * 14 }

                    HoverHandler { id: clockHover }

                    RectangularShadow {
                        anchors.fill: clockCard
                        radius: clockCard.radius
                        color: clockHover.hovered ? "#70000000" : "#5A000000"
                        blur: clockHover.hovered ? 50 : 42
                        spread: 0
                        offset: Qt.vector2d(0, 16)
                        Behavior on blur { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }
                        Behavior on color { ColorAnimation { duration: 240 } }
                    }

                    Rectangle {
                        id: clockCard
                        anchors.fill: parent
                        radius: root.cardRadius
                        color: root.cardFill
                        border.width: 1
                        border.color: clockHover.hovered ? root.accentAlpha(0.36) : root.hairline
                        clip: true

                        Behavior on border.color { ColorAnimation { duration: 240 } }
                        Behavior on color { ColorAnimation { duration: 240 } }

                        // Inner sheen: top light, bottom shade. This is the
                        // same slab treatment the island and dock use.
                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: 1
                            radius: parent.radius - 1
                            gradient: Gradient {
                                GradientStop { position: 0.0; color: root.liquid ? root.inkAlpha(0.11) : root.inkAlpha(0.078) }
                                GradientStop { position: 0.34; color: root.inkAlpha(0.0) }
                                GradientStop { position: 0.68; color: "#00000000" }
                                GradientStop { position: 1.0; color: "#38000000" }
                            }
                        }

                        // Rim light along the top edge.
                        Rectangle {
                            width: parent.width - 76
                            height: 1
                            anchors.top: parent.top
                            anchors.topMargin: 1
                            anchors.horizontalCenter: parent.horizontalCenter
                            opacity: 0.9
                            gradient: Gradient {
                                orientation: Gradient.Horizontal
                                GradientStop { position: 0.0; color: "transparent" }
                                GradientStop { position: 0.5; color: root.inkAlpha(0.227) }
                                GradientStop { position: 1.0; color: "transparent" }
                            }
                        }

                        Column {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.leftMargin: 24
                            anchors.rightMargin: 24
                            spacing: 0

                            RowLayout {
                                spacing: 8

                                Rectangle {
                                    Layout.preferredWidth: 6
                                    Layout.preferredHeight: 6
                                    Layout.alignment: Qt.AlignVCenter
                                    radius: 3
                                    color: root.themeAccent
                                }

                                Text {
                                    text: root.currentGreeting
                                    font.family: root.uiFont
                                    font.pixelSize: 13
                                    font.weight: Font.Medium
                                    font.letterSpacing: 0.2
                                    color: root.inkDim
                                }
                            }

                            Text {
                                text: root.currentTime
                                width: parent.width
                                topPadding: 6
                                font.family: root.uiFont
                                font.pixelSize: 72
                                font.weight: Font.Bold
                                font.letterSpacing: -2
                                font.features: ({ "tnum": 1 })
                                color: root.ink
                            }

                            Text {
                                text: root.currentDate
                                width: parent.width
                                font.family: root.uiFont
                                font.pixelSize: 14
                                font.weight: Font.DemiBold
                                font.letterSpacing: 0.3
                                color: root.inkFaint
                                elide: Text.ElideRight
                            }
                        }
                    }
                }

                // ── Weather ───────────────────────────────────────
                Item {
                    width: 380
                    height: 140
                    opacity: root.weatherReveal
                    transform: Translate { y: (1 - root.weatherReveal) * 14 }

                    HoverHandler { id: weatherHover }

                    RectangularShadow {
                        anchors.fill: weatherCard
                        radius: weatherCard.radius
                        color: weatherHover.hovered ? "#70000000" : "#5A000000"
                        blur: weatherHover.hovered ? 50 : 42
                        spread: 0
                        offset: Qt.vector2d(0, 16)
                        Behavior on blur { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }
                        Behavior on color { ColorAnimation { duration: 240 } }
                    }

                    Rectangle {
                        id: weatherCard
                        anchors.fill: parent
                        radius: root.cardRadius
                        color: root.cardFill
                        border.width: 1
                        border.color: weatherHover.hovered ? root.accentAlpha(0.36) : root.hairline
                        clip: true

                        Behavior on border.color { ColorAnimation { duration: 240 } }
                        Behavior on color { ColorAnimation { duration: 240 } }

                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: 1
                            radius: parent.radius - 1
                            gradient: Gradient {
                                GradientStop { position: 0.0; color: root.liquid ? root.inkAlpha(0.11) : root.inkAlpha(0.078) }
                                GradientStop { position: 0.34; color: root.inkAlpha(0.0) }
                                GradientStop { position: 0.68; color: "#00000000" }
                                GradientStop { position: 1.0; color: "#38000000" }
                            }
                        }

                        Rectangle {
                            width: parent.width - 76
                            height: 1
                            anchors.top: parent.top
                            anchors.topMargin: 1
                            anchors.horizontalCenter: parent.horizontalCenter
                            opacity: 0.9
                            gradient: Gradient {
                                orientation: Gradient.Horizontal
                                GradientStop { position: 0.0; color: "transparent" }
                                GradientStop { position: 0.5; color: root.inkAlpha(0.227) }
                                GradientStop { position: 1.0; color: "transparent" }
                            }
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 22
                            anchors.rightMargin: 22
                            spacing: 18

                            // The condition glyph sits on an accent-washed
                            // plate so the weather card gets one point of
                            // colour without turning the whole card green.
                            Rectangle {
                                Layout.preferredWidth: 78
                                Layout.preferredHeight: 78
                                Layout.alignment: Qt.AlignVCenter
                                radius: 22
                                color: root.accentAlpha(0.10)
                                border.width: 1
                                border.color: weatherHover.hovered ? root.accentAlpha(0.34) : root.accentAlpha(0.22)

                                Behavior on border.color { ColorAnimation { duration: 240 } }

                                Rectangle {
                                    anchors.fill: parent
                                    anchors.margins: 1
                                    radius: parent.radius - 1
                                    gradient: Gradient {
                                        GradientStop { position: 0.0; color: root.accentAlpha(0.16) }
                                        GradientStop { position: 1.0; color: root.accentAlpha(0.02) }
                                    }
                                }

                                Text {
                                    id: weatherGlyph
                                    text: root.weatherIcon
                                    anchors.centerIn: parent
                                    font.family: root.font
                                    font.pixelSize: 40
                                    color: root.ink

                                    transform: Translate { id: weatherFloat }
                                }

                                SequentialAnimation {
                                    running: root.widgetsVisible && root.shellProfile !== "bar"
                                    loops: Animation.Infinite
                                    NumberAnimation {
                                        target: weatherFloat
                                        property: "y"
                                        from: -2
                                        to: 2
                                        duration: 2800
                                        easing.type: Easing.InOutSine
                                    }
                                    NumberAnimation {
                                        target: weatherFloat
                                        property: "y"
                                        from: 2
                                        to: -2
                                        duration: 2800
                                        easing.type: Easing.InOutSine
                                    }
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignVCenter
                                spacing: 0

                                Text {
                                    text: root.weatherTemp
                                    Layout.fillWidth: true
                                    font.family: root.uiFont
                                    font.pixelSize: 40
                                    font.weight: Font.Bold
                                    font.letterSpacing: -1
                                    font.features: ({ "tnum": 1 })
                                    color: root.ink
                                    elide: Text.ElideRight
                                }

                                Text {
                                    text: root.weatherDesc
                                    Layout.fillWidth: true
                                    font.family: root.uiFont
                                    font.pixelSize: 14
                                    font.weight: Font.Medium
                                    color: root.inkDim
                                    elide: Text.ElideRight
                                }

                                Item { Layout.preferredHeight: 9 }

                                Text {
                                    visible: root.weatherHigh !== ""
                                    text: "↑ " + root.weatherHigh + "     ↓ " + root.weatherLow
                                    Layout.fillWidth: true
                                    font.family: root.uiFont
                                    font.pixelSize: 13
                                    font.weight: Font.DemiBold
                                    font.letterSpacing: 0.4
                                    font.features: ({ "tnum": 1 })
                                    color: root.inkAlpha(0.6)
                                    elide: Text.ElideRight
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    IpcHandler {
        target: "widgets"
        function toggle(): void { root.setWidgetsVisible(!root.widgetsVisible) }
        function show(): void { root.setWidgetsVisible(true) }
        function hide(): void { root.setWidgetsVisible(false) }
    }
}
