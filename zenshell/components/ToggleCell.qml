import QtQuick
import QtQuick.Layouts

// One segment of a quick-toggle strip. Icon and label sit inline on a 34px
// row; the strip is one surface, so a cell owns no border, no divider and no
// resting fill. Active is the only state that gets an accent surface.
Item {
    id: cell

    property string icon: ""
    property string label: ""
    property bool checked: false
    property color accentColor: root.currentThemeAccent || root.themeAccent

    signal toggled()

    implicitHeight: 34
    Layout.fillWidth: true
    Layout.fillHeight: true

    Rectangle {
        anchors.fill: parent
        radius: root.rSm
        color: cell.checked
            ? Qt.rgba(cell.accentColor.r, cell.accentColor.g, cell.accentColor.b, 0.16)
            : (cellArea.containsMouse ? root.ink(0.06) : "transparent")
        Behavior on color { ColorAnimation { duration: root.dMicro } }
    }

    RowLayout {
        anchors.centerIn: parent
        spacing: 6

        Text {
            text: cell.icon
            color: cell.checked ? cell.accentColor : root.cFgSecondary
            font.family: root.fontMono
            font.pixelSize: 13
            Behavior on color { ColorAnimation { duration: root.dMicro } }
        }

        Text {
            text: cell.label
            color: cell.checked ? root.cFgPrimary : root.cFgMuted
            font.family: root.fontSans
            font.pixelSize: 12
            font.weight: cell.checked ? Font.DemiBold : Font.Medium
            Behavior on color { ColorAnimation { duration: root.dMicro } }
        }
    }

    MouseArea {
        id: cellArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: cell.toggled()
    }
}
