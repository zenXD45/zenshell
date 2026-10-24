import QtQuick
import QtQuick.Layouts

// A group heading inside a menu: one label, optional right-side action.
// Used sparingly — a group whose rows already name themselves needs no label.
RowLayout {
    id: groupHeader

    property string title: ""
    property string action: ""

    signal actionClicked()

    Layout.fillWidth: true
    Layout.preferredHeight: 26
    spacing: root.s3

    Text {
        Layout.alignment: Qt.AlignVCenter
        text: groupHeader.title
        color: root.cFgSecondary
        font.family: root.fontSans
        font.pixelSize: 12
        font.weight: Font.DemiBold
    }

    Item { Layout.fillWidth: true }

    Text {
        Layout.alignment: Qt.AlignVCenter
        visible: groupHeader.action !== ""
        text: groupHeader.action
        color: actionArea.containsMouse ? root.cFgPrimary : root.cFgMuted
        font.family: root.fontSans
        font.pixelSize: 11
        Behavior on color { ColorAnimation { duration: root.dMicro } }

        MouseArea {
            id: actionArea
            anchors.fill: parent
            anchors.margins: -6
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: groupHeader.actionClicked()
        }
    }
}
