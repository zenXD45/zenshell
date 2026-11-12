import QtQuick
import QtQuick.Layouts

// Quiet empty state styled with system theme tokens.
ColumnLayout {
    id: emptyState

    property string icon: ""
    property string iconFont: root.fontIcon
    property string title: ""
    property string detail: ""

    spacing: 8
    Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter

    // Muted icon container
    Rectangle {
        Layout.alignment: Qt.AlignHCenter
        Layout.preferredWidth: 44
        Layout.preferredHeight: 44
        radius: 22
        color: root.cSurfaceContainerHigh
        border.width: 1
        border.color: root.cOutlineVariant

        Text {
            anchors.centerIn: parent
            text: emptyState.icon
            color: root.cOnSurfaceVariant
            opacity: 0.80
            font.family: emptyState.iconFont
            font.pixelSize: 20
        }
    }

    Item { Layout.preferredHeight: 2 }

    Text {
        Layout.alignment: Qt.AlignHCenter
        text: emptyState.title
        color: root.cOnSurface
        font.family: root.fontSans
        font.pixelSize: 14
        font.weight: Font.DemiBold
    }

    Text {
        Layout.alignment: Qt.AlignHCenter
        visible: emptyState.detail !== ""
        text: emptyState.detail
        color: root.cOnSurfaceVariant
        opacity: 0.65
        font.family: root.fontSans
        font.pixelSize: 12
        horizontalAlignment: Text.AlignHCenter
    }
}
