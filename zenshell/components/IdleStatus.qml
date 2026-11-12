import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland
import Quickshell.Services.UPower

// Profile 03 idle content: a minimal status row inside the same pill.
// Workspaces on the left, the time in the middle, battery on the right.
// It only owns the idle state (displayState 0) and only appears when the
// "status" profile is active; every panel still comes from the island itself.
RowLayout {
    id: statusRoot
    anchors.centerIn: parent
    spacing: 11

    // Sits above the island's global hover MouseArea so the workspace dots
    // and the battery read are clickable while the pill is idle.
    z: 2

    property bool idleReady: false
    property real reveal: (root.displayState === 0 && idleReady) ? 1 : 0
    opacity: reveal
    visible: opacity > 0 && root.activeProfile === "status"
    transform: Translate { y: (1 - statusRoot.reveal) * 3 }

    // Match IdleClock's re-entry delay so the time never ghosts through a
    // closing panel while the surface is still shrinking.
    Timer {
        id: idleDelay
        interval: 160
        onTriggered: statusRoot.idleReady = root.displayState === 0
    }

    Connections {
        target: root
        function onDisplayStateChanged() {
            if (root.displayState === 0) {
                idleDelay.restart();
            } else {
                idleDelay.stop();
                statusRoot.idleReady = false;
            }
        }
    }

    Component.onCompleted: {
        if (root.displayState === 0) idleDelay.start();
    }

    Behavior on reveal {
        NumberAnimation { duration: 90; easing.type: Easing.OutCubic }
    }

    // ── Battery (UPower) ─────────────────────────────────────────
    readonly property var battery: UPower.displayDevice
    readonly property bool batteryPresent: battery && battery.isPresent
    readonly property bool batteryCharging: battery && (
        battery.state === UPowerDeviceState.Charging ||
        battery.state === UPowerDeviceState.PendingCharge ||
        battery.state === UPowerDeviceState.FullyCharged
    )
    // Quickshell exposes UPower percentages as 0..1; normalize to 0..100.
    readonly property real batteryLevel: battery
        ? (battery.percentage <= 1 ? battery.percentage * 100 : battery.percentage)
        : 0

    function batteryGlyph() {
        if (batteryCharging) return "\uf0e7";
        if (batteryLevel > 90) return "\uf240";
        if (batteryLevel > 65) return "\uf241";
        if (batteryLevel > 40) return "\uf242";
        if (batteryLevel > 15) return "\uf243";
        return "\uf244";
    }

    // ── Workspaces ───────────────────────────────────────────────
    Row {
        Layout.alignment: Qt.AlignVCenter
        spacing: 4

        Repeater {
            id: workspaceRepeater
            model: Hyprland.workspaces
            delegate: Rectangle {
                required property var modelData
                required property int index

                // Keep the row minimal: the first five, plus wherever focus
                // actually is so a far-away workspace never disappears.
                visible: index < 5 || modelData.focused
                width: modelData.focused ? 14 : 5
                height: 5
                radius: 2.5
                color: modelData.focused
                    ? root.currentThemeAccent
                    : (workspaceMouse.containsMouse ? root.ink(0.45) : root.ink(0.18))

                Behavior on width { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
                Behavior on color { ColorAnimation { duration: 140 } }

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
        Layout.alignment: Qt.AlignVCenter
        width: 1
        height: 12
        color: root.ink(0.14)
        visible: workspaceRepeater.count > 0
    }

    // ── Clock ────────────────────────────────────────────────────
    Text {
        Layout.alignment: Qt.AlignVCenter
        text: root.currentTime
        color: root.themeFg
        font.family: root.fontSans
        font.pixelSize: 13
        font.bold: true
    }

    Rectangle {
        Layout.alignment: Qt.AlignVCenter
        width: 1
        height: 12
        color: root.ink(0.14)
        visible: statusRoot.batteryPresent
    }

    // ── Battery percentage ───────────────────────────────────────
    Item {
        Layout.alignment: Qt.AlignVCenter
        Layout.preferredWidth: batteryRow.implicitWidth
        Layout.preferredHeight: batteryRow.implicitHeight
        visible: statusRoot.batteryPresent

        RowLayout {
            id: batteryRow
            anchors.centerIn: parent
            spacing: 5

            Text {
                Layout.alignment: Qt.AlignVCenter
                text: statusRoot.batteryGlyph()
                color: statusRoot.batteryCharging
                    ? root.currentThemeAccent
                    : (statusRoot.batteryLevel <= 15 ? root.cDanger : root.cFgSecondary)
                font.family: root.fontMono
                font.pixelSize: 12
            }

            Text {
                Layout.alignment: Qt.AlignVCenter
                text: Math.round(statusRoot.batteryLevel) + "%"
                color: root.ink(0.62)
                font.family: root.fontSans
                font.pixelSize: 10
                font.weight: Font.Medium
            }
        }

        MouseArea {
            anchors.fill: parent
            anchors.margins: -4
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                root.displayState = 13;
                root.updateState();
            }
        }
    }
}
