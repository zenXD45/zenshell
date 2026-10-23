import QtQuick
import QtQuick.Layouts

// Shared header for the compact island menus. Keeps the icon tile, title,
// keyboard hint and count badge on one baseline so every menu reads as part
// of the same surface rather than four separate widgets.
RowLayout {
    id: header
    property string title: ""
    property string icon: ""
    property string hint: ""
    property string meta: ""
    property color accent: root.currentThemeAccent || root.themeAccent

    Layout.fillWidth: true
    Layout.preferredHeight: 28
    spacing: 9

    Rectangle {
        Layout.alignment: Qt.AlignVCenter
        width: 28
        height: 28
        radius: 9
        visible: header.icon !== ""
        color: Qt.rgba(header.accent.r, header.accent.g, header.accent.b, 0.14)
        border.width: 1
        border.color: Qt.rgba(header.accent.r, header.accent.g, header.accent.b, 0.26)

        Text {
            anchors.centerIn: parent
            text: header.icon
            color: header.accent
            font.family: root.font
            font.pixelSize: 12
        }
    }

    Text {
        Layout.alignment: Qt.AlignVCenter
        text: header.title
        color: root.uiFg
        font.family: root.uiFont
        font.pixelSize: 15
        font.weight: Font.DemiBold
    }

    Item { Layout.fillWidth: true }

    Text {
        Layout.alignment: Qt.AlignVCenter
        visible: header.hint !== ""
        text: header.hint
        color: root.ink(0.6)
        font.family: root.uiFont
        font.pixelSize: 10
        font.weight: Font.Normal
    }

    Rectangle {
        Layout.alignment: Qt.AlignVCenter
        visible: header.meta !== ""
        height: 20
        implicitWidth: metaText.implicitWidth + 14
        radius: 10
        color: Qt.rgba(header.accent.r, header.accent.g, header.accent.b, 0.10)
        border.width: 1
        border.color: Qt.rgba(header.accent.r, header.accent.g, header.accent.b, 0.22)

        Text {
            id: metaText
            anchors.centerIn: parent
            text: header.meta
            color: root.uiFgDim
            font.family: root.uiFont
            font.pixelSize: 10
            font.weight: Font.Medium
        }
    }
}
