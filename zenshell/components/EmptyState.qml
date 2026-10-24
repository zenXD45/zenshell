import QtQuick
import QtQuick.Layouts

// Empty state for menus. Two lines and an optional quiet glyph — never a
// centred illustration block with a title, a subtitle and a decorative icon.
ColumnLayout {
    id: emptyState

    property string icon: ""
    property string title: ""
    property string detail: ""

    spacing: root.s1

    Text {
        Layout.alignment: Qt.AlignHCenter
        visible: emptyState.icon !== ""
        text: emptyState.icon
        color: root.ink(0.22)
        font.family: root.fontMono
        font.pixelSize: 18
        Layout.bottomMargin: 2
    }

    Text {
        Layout.alignment: Qt.AlignHCenter
        text: emptyState.title
        color: root.cFgSecondary
        font.family: root.fontSans
        font.pixelSize: 12
        font.weight: Font.Medium
    }

    Text {
        Layout.alignment: Qt.AlignHCenter
        visible: emptyState.detail !== ""
        text: emptyState.detail
        color: root.ink(0.38)
        font.family: root.fontSans
        font.pixelSize: 11
    }
}
