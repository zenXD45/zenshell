import QtQuick
import QtQuick.Layouts

// Shared header for island menus. Title carries the weight; everything else is
// quiet. No icon tile, no badge, no pill — a header is a title and at most one
// piece of right-aligned metadata.
RowLayout {
    id: header

    property string title: ""
    property string icon: ""
    property string hint: ""
    property string meta: ""
    property bool back: false
    property color accent: root.currentThemeAccent || root.themeAccent

    signal backClicked()

    Layout.fillWidth: true
    Layout.preferredHeight: 34
    spacing: root.s2

    Item {
        Layout.alignment: Qt.AlignVCenter
        Layout.preferredWidth: header.back ? 26 : 0
        Layout.preferredHeight: 26
        visible: header.back

        Rectangle {
            anchors.fill: parent
            radius: root.rSm
            color: backArea.containsMouse ? root.ink(0.06) : "transparent"
            Behavior on color { ColorAnimation { duration: root.dMicro } }
        }

        Text {
            anchors.centerIn: parent
            text: "\uf060"
            color: backArea.containsMouse ? root.cFgPrimary : root.cFgMuted
            font.family: root.fontMono
            font.pixelSize: 11
        }

        MouseArea {
            id: backArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: header.backClicked()
        }
    }

    Text {
        Layout.alignment: Qt.AlignVCenter
        visible: header.icon !== ""
        text: header.icon
        color: root.cFgMuted
        font.family: root.fontMono
        font.pixelSize: 14
    }

    Text {
        Layout.alignment: Qt.AlignVCenter
        text: header.title
        color: root.cFgPrimary
        font.family: root.fontSans
        font.pixelSize: 17
        font.weight: Font.DemiBold
        font.letterSpacing: -0.2
    }

    Item { Layout.fillWidth: true }

    Text {
        Layout.alignment: Qt.AlignVCenter
        visible: header.meta !== ""
        text: header.meta
        color: root.ink(0.50)
        font.family: root.fontMono
        font.pixelSize: 11
    }

    Text {
        Layout.alignment: Qt.AlignVCenter
        visible: header.hint !== ""
        Layout.leftMargin: 12
        text: header.hint
        color: root.ink(0.42)
        font.family: root.fontMono
        font.pixelSize: 11
    }
}
