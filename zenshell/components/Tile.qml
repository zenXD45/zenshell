import QtQuick
import QtQuick.Layouts

// A tonal drill-in card: identity, live state, and a chevron. At rest it sits
// one surface step above the panel; hover raises it one more step. Selection is
// a secondary container, not an underline.
Rectangle {
    id: tile

    property string title: ""
    property string subtitle: ""
    property string icon: ""
    property string iconFont: root.fontIcon
    property color iconColor: root.cOnSurfaceVariant
    property color accentColor: root.cPrimary
    property bool selected: false
    property real press: 1.0
    property real pressScale: 0.98

    signal clicked()

    radius: root.rLg
    color: tile.selected
        ? root.cSecondaryContainer
        : (tileMouse.containsMouse ? root.cSurfaceContainerHigh : root.cSurfaceContainerLow)
    border.width: 1
    border.color: root.cOutlineVariant

    Behavior on color { ColorAnimation { duration: root.dMicro } }

    transform: Scale {
        origin.x: tile.width / 2
        origin.y: tile.height / 2
        xScale: tile.press
        yScale: tile.press
    }
    Behavior on press { NumberAnimation { duration: root.dMicro; easing.type: Easing.OutCubic } }

    RowLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: root.s4

        Rectangle {
            Layout.alignment: Qt.AlignVCenter
            width: 36
            height: 36
            radius: root.rMd
            color: tile.selected ? root.cPrimaryContainer : root.cSurfaceContainerHighest

            Text {
                anchors.centerIn: parent
                text: tile.icon
                color: tile.selected ? root.cOnPrimaryContainer : tile.iconColor
                font.family: tile.iconFont
                font.pixelSize: 20
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 1

            Text {
                Layout.fillWidth: true
                text: tile.title
                color: tile.selected ? root.cOnSecondaryContainer : root.cOnSurface
                font.family: root.fontSans
                font.pixelSize: 14
                font.weight: Font.Medium
                elide: Text.ElideRight
            }

            Text {
                Layout.fillWidth: true
                text: tile.subtitle
                color: root.cOnSurfaceVariant
                font.family: root.fontSans
                font.pixelSize: 12
                elide: Text.ElideRight
            }
        }

        Text {
            text: root.icoChevronRight
            color: root.cOnSurfaceVariant
            font.family: root.fontIcon
            font.pixelSize: 20
            opacity: tileMouse.containsMouse ? 1 : 0.64
            Behavior on opacity { NumberAnimation { duration: root.dMicro } }
        }
    }

    MouseArea {
        id: tileMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onPressed: tile.press = tile.pressScale
        onReleased: tile.press = 1.0
        onClicked: tile.clicked()
    }
}
