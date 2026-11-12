import QtQuick
import QtQuick.Layouts

// Shared header for island menus. A 20 px title, a 32 px back target, and at
// most one piece of quiet metadata. The back glyph is Material Symbols; any
// leading icon stays in the caller's font so app-specific glyphs still work.
RowLayout {
    id: header

    property string title: ""
    property string icon: ""
    property string iconFont: root.fontMono
    property string hint: ""
    property string meta: ""
    property bool back: false
    property color accent: root.currentThemeAccent || root.themeAccent

    signal backClicked()

    Layout.fillWidth: true
    Layout.preferredHeight: 40
    spacing: root.s3

    Item {
        Layout.alignment: Qt.AlignVCenter
        Layout.preferredWidth: header.back ? 32 : 0
        Layout.preferredHeight: 32
        visible: header.back

        Rectangle {
            anchors.fill: parent
            radius: root.rFull
            color: backArea.containsMouse ? root.cStateHover : "transparent"
            Behavior on color { ColorAnimation { duration: root.dMicro } }
        }

        Text {
            anchors.centerIn: parent
            text: root.icoChevronLeft
            color: backArea.containsMouse ? root.cOnSurface : root.cOnSurfaceVariant
            font.family: root.fontIcon
            font.pixelSize: 20
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
        color: root.cOnSurfaceVariant
        font.family: header.iconFont
        font.pixelSize: 16
    }

    Text {
        Layout.alignment: Qt.AlignVCenter
        text: header.title
        color: root.cOnSurface
        font.family: root.fontSans
        font.pixelSize: 20
        font.weight: Font.DemiBold
        font.letterSpacing: -0.3
    }

    Item { Layout.fillWidth: true }

    Text {
        Layout.alignment: Qt.AlignVCenter
        visible: header.meta !== ""
        text: header.meta
        color: root.cOnSurfaceVariant
        font.family: root.fontMono
        font.pixelSize: 11
    }

    Text {
        Layout.alignment: Qt.AlignVCenter
        visible: header.hint !== ""
        Layout.leftMargin: 12
        text: header.hint
        color: root.cOnSurfaceVariant
        opacity: 0.72
        font.family: root.fontMono
        font.pixelSize: 11
    }
}
