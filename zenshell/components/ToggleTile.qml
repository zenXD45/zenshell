import QtQuick
import QtQuick.Layouts

// System-themed quick-settings tile.
// Derived strictly from the active Hyprland/ZenShell theme palette tokens.
// Features Emil Kowalski tactile press feedback (0.96) and Material 3 tonal hierarchy.
Rectangle {
    id: toggleTile

    property string title: ""
    property string subtitle: ""
    property string icon: ""
    property string iconFont: root.fontIcon
    property bool checked: false
    property real press: 1.0
    property real pressScale: 0.96

    signal toggled()

    implicitHeight: 74
    radius: root.themeRounding || 14

    color: toggleTile.checked
        ? root.cPrimaryContainer
        : (toggleTileMouse.containsMouse ? root.cSurfaceContainerHighest : root.cSurfaceContainerHigh)

    border.width: 1
    border.color: toggleTile.checked
        ? Qt.rgba(root.themeAccent.r, root.themeAccent.g, root.themeAccent.b, 0.35)
        : root.cOutlineVariant

    Behavior on color { ColorAnimation { duration: root.dMicro; easing.type: Easing.OutCubic } }
    Behavior on border.color { ColorAnimation { duration: root.dMicro; easing.type: Easing.OutCubic } }

    transform: Scale {
        origin.x: toggleTile.width / 2
        origin.y: toggleTile.height / 2
        xScale: toggleTile.press
        yScale: toggleTile.press
    }
    Behavior on press { NumberAnimation { duration: root.dMicro; easing.type: Easing.OutCubic } }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 11
        spacing: 0

        // Top Row: Icon emblem + Status dot
        RowLayout {
            Layout.fillWidth: true
            spacing: 0

            Rectangle {
                Layout.preferredWidth: 32
                Layout.preferredHeight: 32
                radius: 16
                color: toggleTile.checked
                    ? root.themeAccent
                    : root.cSurfaceContainerHighest

                Behavior on color { ColorAnimation { duration: root.dMicro; easing.type: Easing.OutCubic } }

                Text {
                    anchors.centerIn: parent
                    text: toggleTile.icon
                    color: toggleTile.checked ? root.onAccent() : root.cOnSurfaceVariant
                    font.family: toggleTile.iconFont
                    font.pixelSize: 16
                }
            }

            Item { Layout.fillWidth: true }

            Rectangle {
                Layout.alignment: Qt.AlignVCenter
                width: 6
                height: 6
                radius: 3
                color: toggleTile.checked ? root.themeAccent : root.cOutlineVariant
                Behavior on color { ColorAnimation { duration: root.dMicro; easing.type: Easing.OutCubic } }
            }
        }

        Item { Layout.fillHeight: true }

        // Bottom Labels
        Text {
            Layout.fillWidth: true
            text: toggleTile.title
            color: root.cOnSurface
            font.family: root.fontSans
            font.pixelSize: 12
            font.weight: Font.DemiBold
            elide: Text.ElideRight
            maximumLineCount: 1
        }

        Text {
            Layout.fillWidth: true
            text: toggleTile.subtitle !== "" ? toggleTile.subtitle : (toggleTile.checked ? "On" : "Off")
            color: toggleTile.checked ? root.themeAccent : root.cOnSurfaceVariant
            opacity: toggleTile.checked ? 1.0 : 0.65
            font.family: root.fontSans
            font.pixelSize: 10
            font.weight: Font.Medium
            elide: Text.ElideRight
            maximumLineCount: 1
        }
    }

    MouseArea {
        id: toggleTileMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onPressed: toggleTile.press = toggleTile.pressScale
        onReleased: toggleTile.press = 1.0
        onCanceled: toggleTile.press = 1.0
        onClicked: toggleTile.toggled()
    }
}
