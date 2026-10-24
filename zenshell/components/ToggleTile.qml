import QtQuick
import QtQuick.Layouts

// A switch rendered as a square tile. The active state is carried by a tinted
// surface plus an accent icon — not by a glow — so four of them in a row stay
// calm while still being scannable at a glance.
Rectangle {
    id: toggleTile

    property string title: ""
    property string icon: ""
    property bool checked: false
    property color accentColor: root.cAccent
    property real press: 1.0
    property real pressScale: 0.97

    signal toggled()

    radius: root.rMd
    color: toggleTile.checked
        ? Qt.rgba(toggleTile.accentColor.r, toggleTile.accentColor.g, toggleTile.accentColor.b, 0.14)
        : (toggleTileMouse.containsMouse ? root.ink(0.055) : root.cBgSecondary)
    border.width: 1
    border.color: toggleTile.checked
        ? Qt.rgba(toggleTile.accentColor.r, toggleTile.accentColor.g, toggleTile.accentColor.b, 0.32)
        : (toggleTileMouse.containsMouse ? root.cBorderDefault : root.cBorderSubtle)

    Behavior on color { ColorAnimation { duration: root.dMicro } }
    Behavior on border.color { ColorAnimation { duration: root.dMicro } }

    transform: Scale {
        origin.x: toggleTile.width / 2
        origin.y: toggleTile.height / 2
        xScale: toggleTile.press
        yScale: toggleTile.press
    }
    Behavior on press { NumberAnimation { duration: root.dMicro; easing.type: Easing.OutCubic } }

    ColumnLayout {
        anchors.centerIn: parent
        spacing: root.s1

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: toggleTile.icon
            color: toggleTile.checked ? toggleTile.accentColor : root.cFgMuted
            font.family: root.fontMono
            font.pixelSize: 14
        }
        Text {
            Layout.alignment: Qt.AlignHCenter
            text: toggleTile.title
            color: toggleTile.checked ? root.cFgPrimary : root.cFgMuted
            font.family: root.fontSans
            font.pixelSize: root.tCaption[0]
            font.weight: toggleTile.checked ? Font.DemiBold : Font.Medium
        }
    }

    MouseArea {
        id: toggleTileMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onPressed: toggleTile.press = toggleTile.pressScale
        onReleased: toggleTile.press = 1.0
        onClicked: toggleTile.toggled()
    }
}
