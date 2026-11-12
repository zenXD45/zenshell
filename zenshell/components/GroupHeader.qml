import QtQuick
import QtQuick.Layouts

// A quiet section marker: a 2 px accent rule, a 12 px label, and an optional
// text-button action. The rule is the only decorative mark in the menu system;
// it gives long panels a hand-set rhythm without adding a badge or an icon.
RowLayout {
    id: groupHeader

    property string title: ""
    property string action: ""

    signal actionClicked()

    Layout.fillWidth: true
    Layout.preferredHeight: 30
    spacing: root.s3

    Rectangle {
        Layout.alignment: Qt.AlignVCenter
        Layout.preferredWidth: 2
        Layout.preferredHeight: 12
        radius: 1
        color: root.cPrimary
        visible: groupHeader.title !== ""
    }

    Text {
        Layout.alignment: Qt.AlignVCenter
        text: groupHeader.title
        color: root.cOnSurfaceVariant
        font.family: root.fontSans
        font.pixelSize: 12
        font.weight: Font.DemiBold
        font.letterSpacing: 0.2
    }

    Item { Layout.fillWidth: true }

    Item {
        Layout.alignment: Qt.AlignVCenter
        Layout.preferredWidth: actionText.implicitWidth + 16
        Layout.preferredHeight: 28
        visible: groupHeader.action !== ""

        Rectangle {
            anchors.fill: parent
            radius: 14
            color: actionArea.containsMouse ? Qt.rgba(root.cPrimary.r, root.cPrimary.g, root.cPrimary.b, 0.08) : "transparent"
            Behavior on color { ColorAnimation { duration: root.dMicro } }
        }

        Text {
            id: actionText
            anchors.centerIn: parent
            text: groupHeader.action
            color: root.cPrimary
            font.family: root.fontSans
            font.pixelSize: 12
            font.weight: Font.DemiBold
        }

        MouseArea {
            id: actionArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: groupHeader.actionClicked()
        }
    }
}
