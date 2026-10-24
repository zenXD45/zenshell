import QtQuick
import QtQuick.Layouts

// One cell inside a Group. Label left, optional value and chevron right, or an
// iOS switch. The hairline starts where the text starts, never at the edge.
Item {
    id: row

    property string icon: ""
    property string label: ""
    property string value: ""
    property bool chevron: false
    property bool showSwitch: false
    property bool switchOn: false
    property bool last: false
    property bool destructive: false
    property bool selected: false
    property int rowHeight: 42
    property int labelSize: 14
    property int valueSize: 13

    signal activated()
    signal toggled()
    signal entered()

    width: parent ? parent.width : 0
    height: rowHeight

    Rectangle {
        anchors.fill: parent
        anchors.margins: 2
        radius: 10
        color: row.selected
            ? root.ink(0.06)
            : (pointer.containsMouse ? root.ink(0.04) : "transparent")
        Behavior on color { ColorAnimation { duration: root.dMicro } }
    }

    Rectangle {
        visible: !row.last
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.leftMargin: row.icon !== "" ? 50 : 16
        anchors.rightMargin: 16
        height: 1
        color: root.ink(0.07)
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        spacing: root.s3

        Text {
            Layout.alignment: Qt.AlignVCenter
            Layout.preferredWidth: 22
            horizontalAlignment: Text.AlignHCenter
            visible: row.icon !== ""
            text: row.icon
            color: row.selected ? root.cFgSecondary : root.ink(0.55)
            font.family: root.fontMono
            font.pixelSize: 14
        }

        Text {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            text: row.label
            color: row.destructive ? root.cDanger : root.cFgPrimary
            font.family: root.fontSans
            font.pixelSize: row.labelSize
            elide: Text.ElideRight
            maximumLineCount: 1
        }

        Text {
            Layout.alignment: Qt.AlignVCenter
            visible: row.value !== ""
            text: row.value
            color: root.ink(0.46)
            font.family: root.fontSans
            font.pixelSize: row.valueSize
            elide: Text.ElideRight
            maximumLineCount: 1
        }

        Text {
            Layout.alignment: Qt.AlignVCenter
            visible: row.chevron
            text: "\u203a"
            color: root.ink(0.28)
            font.family: root.fontSans
            font.pixelSize: 17
            font.weight: Font.Light
        }

        SwitchControl {
            Layout.alignment: Qt.AlignVCenter
            visible: row.showSwitch
            on: row.switchOn
        }
    }

    MouseArea {
        id: pointer
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onEntered: row.entered()
        onClicked: {
            if (row.showSwitch) row.toggled();
            else row.activated();
        }
    }
}
