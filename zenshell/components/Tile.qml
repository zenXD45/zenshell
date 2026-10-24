import QtQuick
import QtQuick.Layouts

// A drill-in card for the control center: one line of identity, one line of
// live state, and a chevron that promises the next screen. Surfaces stay flat
// at rest and lift only on hover, so a column of tiles reads as one group.
Rectangle {
    id: tile

    property string title: ""
    property string subtitle: ""
    property string icon: ""
    property color iconColor: root.cFgMuted
    property color accentColor: root.cAccent
    property bool selected: false
    property real press: 1.0
    property real pressScale: 0.98

    signal clicked()

    radius: root.rLg
    color: tileMouse.containsMouse ? root.cBgTertiary : root.cBgSecondary
    border.width: 1
    border.color: tileMouse.containsMouse ? root.cBorderDefault : root.cBorderSubtle

    Behavior on color { ColorAnimation { duration: root.dMicro } }
    Behavior on border.color { ColorAnimation { duration: root.dMicro } }

    transform: Scale {
        origin.x: tile.width / 2
        origin.y: tile.height / 2
        xScale: tile.press
        yScale: tile.press
    }
    Behavior on press { NumberAnimation { duration: root.dMicro; easing.type: Easing.OutCubic } }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: root.s3
        spacing: root.s1

        RowLayout {
            Layout.fillWidth: true
            spacing: root.s3

            Rectangle {
                width: 32
                height: 32
                radius: root.rSm
                color: Qt.rgba(tile.iconColor.r, tile.iconColor.g, tile.iconColor.b, 0.12)
                border.width: 1
                border.color: Qt.rgba(tile.iconColor.r, tile.iconColor.g, tile.iconColor.b, 0.2)

                Text {
                    anchors.centerIn: parent
                    text: tile.icon
                    color: tile.iconColor
                    font.family: root.fontMono
                    font.pixelSize: 13
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                Text {
                    Layout.fillWidth: true
                    text: tile.title
                    color: root.cFgPrimary
                    font.family: root.fontSans
                    font.pixelSize: root.tBody[0]
                    font.weight: Font.Medium
                    elide: Text.ElideRight
                }
                Text {
                    Layout.fillWidth: true
                    text: tile.subtitle
                    color: root.cFgMuted
                    font.family: root.fontSans
                    font.pixelSize: root.tCaption[0]
                    elide: Text.ElideRight
                }
            }

            Text {
                text: "\uf054"
                color: root.cFgMuted
                font.family: root.fontMono
                font.pixelSize: 9
                opacity: tileMouse.containsMouse ? 1 : 0.5
                Behavior on opacity { NumberAnimation { duration: root.dMicro } }
            }
        }

        Rectangle {
            visible: tile.selected
            Layout.alignment: Qt.AlignHCenter
            width: 24
            height: 2
            radius: 1
            color: tile.accentColor
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
