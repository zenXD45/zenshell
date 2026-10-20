import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Networking
import Quickshell.Services.Pipewire
import Quickshell.Services.SystemTray
import Quickshell.Services.UPower

// Profile 02: a single command rail. It shares the island's process, theme,
// launcher and notification overlays, so switching profiles never restarts the
// shell or loses a notification.
Scope {
    id: barScope

    readonly property color accent: root.currentThemeAccent || "#838996"

    // Live clock, updated only while the bar exists.
    property string clockTime: Qt.formatTime(new Date(), "HH:mm")
    property string clockDate: Qt.formatDate(new Date(), "ddd dd MMM")

    Timer {
        interval: 1000
        running: root.barActive
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            var now = new Date();
            barScope.clockTime = Qt.formatTime(now, "HH:mm");
            barScope.clockDate = Qt.formatDate(now, "ddd dd MMM");
        }
    }

    readonly property string windowTitle: {
        var client = Hyprland.focusedClient;
        if (client && client.title) return client.title;
        var toplevel = Hyprland.activeToplevel;
        return toplevel && toplevel.title ? toplevel.title : "";
    }

    readonly property var battery: UPower.displayDevice
    readonly property bool batteryPresent: battery && battery.isPresent
    readonly property bool batteryCharging: battery && (
        battery.state === UPowerDeviceState.Charging ||
        battery.state === UPowerDeviceState.PendingCharge ||
        battery.state === UPowerDeviceState.FullyCharged
    )
    // Quickshell exposes UPower percentages as 0..1, while the island and
    // prompt helpers use 0..100. Normalize once so both surfaces agree.
    readonly property real batteryLevel: battery
        ? (battery.percentage <= 1 ? battery.percentage * 100 : battery.percentage)
        : 0

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property bool sinkReady: sink && sink.audio
    readonly property bool muted: sinkReady ? sink.audio.muted : false
    readonly property int volume: sinkReady ? Math.round(sink.audio.volume * 100) : 0

    readonly property bool networkOnline:
        Networking.connectivity === NetworkConnectivity.Full ||
        Networking.connectivity === NetworkConnectivity.Limited ||
        Networking.connectivity === NetworkConnectivity.Portal

    readonly property bool hasMedia: root.activePlayer !== null && root.trackTitle !== ""

    function hasWidget(widgetId) {
        return root.hasBarWidget(widgetId);
    }

    function batteryGlyph() {
        if (barScope.batteryCharging) return "\uf0e7";
        var level = barScope.batteryLevel;
        if (level > 90) return "\uf240";
        if (level > 65) return "\uf241";
        if (level > 40) return "\uf242";
        if (level > 15) return "\uf243";
        return "\uf244";
    }

    function volumeGlyph() {
        if (barScope.muted || barScope.volume <= 0) return "\uf026";
        if (barScope.volume < 35) return "\uf027";
        return "\uf028";
    }

    function trayIcon(item) {
        if (!item || !item.icon) return "";
        var value = String(item.icon);
        if (value.indexOf("file:") === 0 || value.indexOf("image://") === 0 || value.indexOf("/") === 0) return value;
        return "image://icon/" + value;
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: barWindow
            required property var modelData
            screen: modelData

            readonly property int barWidth: root.barStyle === "edge"
                ? modelData.width
                : Math.min(1120, modelData.width - 32)

            anchors {
                top: root.barPosition === "top"
                bottom: root.barPosition === "bottom"
                left: true
                right: true
            }
            margins {
                left: root.barStyle === "edge" ? 0 : Math.round((modelData.width - barWidth) / 2)
                right: root.barStyle === "edge" ? 0 : Math.round((modelData.width - barWidth) / 2)
                top: root.barPosition === "top" ? root.barGap : 0
                bottom: root.barPosition === "bottom" ? root.barGap : 0
            }
            implicitWidth: barWidth
            implicitHeight: root.barHeight
            exclusiveZone: root.barActive ? root.barReservedHeight : 0
            visible: root.barActive || surface.opacity > 0.01

            color: "transparent"
            WlrLayershell.layer: WlrLayer.Top
            WlrLayershell.namespace: "qs-bar"

            Rectangle {
                id: surface
                anchors.fill: parent
                radius: root.barStyle === "floating" ? 18 : 0
                opacity: root.barActive ? 1 : 0
                border.width: 1
                border.color: root.islandTheme === "liquid" ? "#33FFFFFF" : "#28FFFFFF"
                clip: true

                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop {
                        position: 0.0
                        color: root.islandTheme === "liquid" ? "#D9191920" : "#F0161619"
                    }
                    GradientStop {
                        position: 0.48
                        color: root.islandTheme === "liquid" ? "#C20B0B0F" : "#F00C0C10"
                    }
                    GradientStop {
                        position: 1.0
                        color: root.islandTheme === "liquid" ? "#D918181F" : "#F009090C"
                    }
                }

                Behavior on opacity { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                Behavior on radius { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

                // A single authored light cue: the floating rail catches the
                // top edge; the edge-mounted rail gets a low accent seam.
                Rectangle {
                    width: parent.width * 0.42
                    height: 1
                    anchors.top: parent.top
                    anchors.topMargin: 1
                    anchors.horizontalCenter: parent.horizontalCenter
                    visible: root.barStyle === "floating"
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0.0; color: "transparent" }
                        GradientStop { position: 0.5; color: "#30FFFFFF" }
                        GradientStop { position: 1.0; color: "transparent" }
                    }
                }

                Rectangle {
                    width: parent.width * 0.34
                    height: 1
                    anchors.bottom: parent.bottom
                    anchors.horizontalCenter: parent.horizontalCenter
                    visible: root.barStyle === "edge"
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0.0; color: "transparent" }
                        GradientStop { position: 0.5; color: Qt.rgba(barScope.accent.r, barScope.accent.g, barScope.accent.b, 0.35) }
                        GradientStop { position: 1.0; color: "transparent" }
                    }
                }

                Item {
                    anchors.fill: parent
                    anchors.leftMargin: root.barStyle === "edge" ? 14 : 12
                    anchors.rightMargin: root.barStyle === "edge" ? 14 : 12

                    // ── Identity + navigation ─────────────────────────────
                    Row {
                        id: leftGroup
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 6

                        BarIconButton {
                            glyph: "\uf009"
                            label: "Applications"
                            onClicked: root.displayState = 3
                        }

                        Row {
                            id: workspaceRow
                            visible: barScope.hasWidget("workspaces")
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 2

                            Repeater {
                                model: Hyprland.workspaces
                                delegate: Rectangle {
                                    required property var modelData
                                    required property int index

                                    visible: index < 5 || modelData.focused || modelData.active
                                    width: 22
                                    height: 24
                                    radius: 7
                                    color: modelData.focused
                                        ? Qt.rgba(barScope.accent.r, barScope.accent.g, barScope.accent.b, 0.15)
                                        : (workspaceMouse.containsMouse ? "#10FFFFFF" : "transparent")
                                    border.width: modelData.focused ? 1 : 0
                                    border.color: Qt.rgba(barScope.accent.r, barScope.accent.g, barScope.accent.b, 0.30)

                                    Text {
                                        anchors.centerIn: parent
                                        text: modelData.name !== "" ? modelData.name : modelData.id
                                        color: modelData.focused ? barScope.accent : (workspaceMouse.containsMouse ? root.uiFg : root.uiFgDim)
                                        font.family: root.uiFont
                                        font.pixelSize: 9
                                        font.weight: Font.DemiBold
                                    }

                                    MouseArea {
                                        id: workspaceMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: modelData.activate()
                                    }
                                }
                            }
                        }

                        Rectangle {
                            width: 1
                            height: 14
                            radius: 0.5
                            color: "#18FFFFFF"
                            visible: barScope.hasWidget("window")
                                && barScope.windowTitle !== ""
                                && barWindow.barWidth >= 1040
                        }

                        Text {
                            visible: barScope.hasWidget("window")
                                && barScope.windowTitle !== ""
                                && barWindow.barWidth >= 1040
                            width: Math.min(176, implicitWidth)
                            anchors.verticalCenter: parent.verticalCenter
                            text: barScope.windowTitle
                            color: root.uiFgDim
                            font.family: root.uiFont
                            font.pixelSize: 11
                            font.weight: Font.Medium
                            elide: Text.ElideRight
                        }
                    }

                    // ── Clock + now playing ───────────────────────────────
                    Row {
                        id: centerGroup
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 8

                        Rectangle {
                            visible: barScope.hasWidget("media") && barScope.hasMedia
                            width: 218
                            height: 30
                            radius: 10
                            color: mediaMouse.containsMouse ? "#0EFFFFFF" : "transparent"
                            Behavior on color { ColorAnimation { duration: 140 } }

                            Row {
                                anchors.fill: parent
                                anchors.leftMargin: 9
                                anchors.rightMargin: 8
                                spacing: 8

                                Item {
                                    width: 13
                                    height: 14
                                    anchors.verticalCenter: parent.verticalCenter
                                    Row {
                                        anchors.centerIn: parent
                                        spacing: 2
                                        Repeater {
                                            model: 3
                                            delegate: Rectangle {
                                                required property int index
                                                width: 2
                                                height: root.isPlaying ? [4, 9, 6][index] : 3
                                                radius: 1
                                                color: root.isPlaying ? barScope.accent : root.uiFgFaint
                                            }
                                        }
                                    }
                                }

                                Column {
                                    width: 151
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: -1

                                    Text {
                                        width: parent.width
                                        text: root.trackTitle || "Now playing"
                                        color: root.uiFg
                                        font.family: root.uiFont
                                        font.pixelSize: 10
                                        font.weight: Font.DemiBold
                                        elide: Text.ElideRight
                                    }

                                    Text {
                                        width: parent.width
                                        text: root.trackArtist || "Unknown artist"
                                        color: root.uiFgFaint
                                        font.family: root.uiFont
                                        font.pixelSize: 9
                                        font.weight: Font.Medium
                                        elide: Text.ElideRight
                                    }
                                }

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: root.isPlaying ? "\uf04c" : "\uf04b"
                                    color: root.uiFgFaint
                                    font.family: root.font
                                    font.pixelSize: 8
                                }
                            }

                            MouseArea {
                                id: mediaMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.playPause()
                            }
                        }

                        Column {
                            visible: barScope.hasWidget("clock")
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: -2

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: barScope.clockTime
                                color: root.uiFg
                                font.family: root.uiFont
                                font.pixelSize: 14
                                font.weight: Font.DemiBold
                                font.letterSpacing: 0.1
                            }

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: barScope.clockDate
                                color: root.uiFgFaint
                                font.family: root.uiFont
                                font.pixelSize: 9
                                font.weight: Font.Medium
                                font.letterSpacing: 0.15
                            }
                        }
                    }

                    // ── Ambient status + shell controls ───────────────────
                    Row {
                        id: rightGroup
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 3

                        Rectangle {
                            visible: barScope.hasWidget("weather")
                            width: weatherRow.implicitWidth + 8
                            height: 26
                            radius: 8
                            color: weatherMouse.containsMouse ? "#0EFFFFFF" : "transparent"
                            Behavior on color { ColorAnimation { duration: 140 } }

                            Row {
                                id: weatherRow
                                anchors.centerIn: parent
                                spacing: 4

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 14
                                    horizontalAlignment: Text.AlignHCenter
                                    text: root.weatherIcon
                                    color: root.uiFgDim
                                    font.family: root.font
                                    font.pixelSize: 12
                                }

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: root.weatherTemp
                                    color: root.uiFgDim
                                    font.family: root.uiFont
                                    font.pixelSize: 10
                                    font.weight: Font.DemiBold
                                }
                            }

                            MouseArea {
                                id: weatherMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.displayState = 6;
                                    weatherCloseTimer.restart();
                                }
                            }
                        }

                        Rectangle {
                            width: 1
                            height: 14
                            color: "#18FFFFFF"
                            visible: barScope.hasWidget("weather") && barScope.hasWidget("system")
                        }

                        Row {
                            id: systemRow
                            visible: barScope.hasWidget("system")
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 9

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: barScope.networkOnline
                                    ? (Networking.wifiEnabled ? "\uf1eb" : "\uf0e8")
                                    : "\uf072"
                                color: barScope.networkOnline ? root.uiFgDim : root.uiFgFaint
                                font.family: root.font
                                font.pixelSize: 11
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: barScope.volumeGlyph()
                                color: barScope.muted ? root.uiFgFaint : root.uiFgDim
                                font.family: root.font
                                font.pixelSize: 11
                            }

                            Row {
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 3
                                visible: barScope.batteryPresent

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: barScope.batteryGlyph()
                                    color: barScope.batteryCharging ? barScope.accent : root.uiFgDim
                                    font.family: root.font
                                    font.pixelSize: 12
                                }

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: barScope.battery ? Math.round(barScope.batteryLevel) + "%" : ""
                                    color: root.uiFgFaint
                                    font.family: root.uiFont
                                    font.pixelSize: 9
                                    font.weight: Font.Medium
                                }
                            }

                            Item {
                                width: Math.min(trayRow.implicitWidth, 76)
                                height: 20
                                clip: true

                                Row {
                                    id: trayRow
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: 3

                                    Repeater {
                                        model: SystemTray.items
                                        delegate: Item {
                                            required property var modelData
                                            required property int index
                                            width: 18
                                            height: 18
                                            visible: index < 4

                                            Image {
                                                anchors.centerIn: parent
                                                width: 15
                                                height: 15
                                                source: barScope.trayIcon(modelData)
                                                smooth: true
                                            }

                                            MouseArea {
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                acceptedButtons: Qt.LeftButton | Qt.RightButton
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: (mouse) => {
                                                    var pos = mapToGlobal(mouse.x, mouse.y);
                                                    if (mouse.button === Qt.LeftButton) {
                                                        if (modelData.activate.length === 2) modelData.activate(pos.x, pos.y);
                                                        else modelData.activate();
                                                    } else if (menuAnchor.menu) {
                                                        menuAnchor.open();
                                                    } else if (modelData.secondaryActivate) {
                                                        modelData.secondaryActivate();
                                                    }
                                                }
                                            }

                                            QsMenuAnchor {
                                                id: menuAnchor
                                                menu: modelData.menu
                                                anchor.item: parent
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        Rectangle {
                            width: 1
                            height: 14
                            color: "#18FFFFFF"
                            visible: barScope.hasWidget("weather") || barScope.hasWidget("system")
                        }

                        BarIconButton {
                            glyph: "\uf1de"
                            label: "Control center"
                            onClicked: root.displayState = 13
                        }

                        BarIconButton {
                            glyph: "\uf013"
                            label: "Bar settings"
                            onClicked: root.displayState = 17
                        }
                    }
                }
            }
        }
    }
}
