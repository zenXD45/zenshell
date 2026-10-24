import QtQuick
import QtQuick.Layouts

// One notification in the control-center shade. No card: the row sits on the
// panel surface, separated from its neighbour by a hairline. App and time share
// a baseline, the summary carries weight, the body is optional and clamped.
// Dismiss appears on hover so a quiet shade stays quiet.
Item {
    id: notifItem

    property string appName: ""
    property string summary: ""
    property string body: ""
    property var time: new Date()
    property color accentColor: root.currentThemeAccent || root.themeAccent
    property bool showDivider: false

    signal dismissed()

    Layout.fillWidth: true
    Layout.preferredHeight: 62

    function formatTime(date) {
        var d = new Date(date)
        var hh = (d.getHours() < 10 ? "0" : "") + d.getHours()
        var mm = (d.getMinutes() < 10 ? "0" : "") + d.getMinutes()
        return hh + ":" + mm
    }

    Rectangle {
        anchors.fill: parent
        radius: root.rSm
        color: notifItemMouse.containsMouse ? root.ink(0.04) : "transparent"
        Behavior on color { ColorAnimation { duration: root.dMicro } }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.topMargin: root.s2
        anchors.bottomMargin: root.s2
        anchors.leftMargin: root.s3
        anchors.rightMargin: root.s3
        spacing: 1

        RowLayout {
            Layout.fillWidth: true
            spacing: root.s3

            Text {
                Layout.fillWidth: true
                text: notifItem.appName
                color: root.cFgSecondary
                font.family: root.fontSans
                font.pixelSize: 11
                font.weight: Font.DemiBold
                elide: Text.ElideRight
            }

            Text {
                text: notifItem.formatTime(notifItem.time)
                color: root.ink(0.36)
                font.family: root.fontMono
                font.pixelSize: 10
            }
        }

        Text {
            Layout.fillWidth: true
            text: notifItem.summary
            color: root.cFgPrimary
            font.family: root.fontSans
            font.pixelSize: 13
            font.weight: Font.Medium
            elide: Text.ElideRight
            maximumLineCount: 1
        }

        Text {
            Layout.fillWidth: true
            visible: notifItem.body !== ""
            text: notifItem.body
            color: root.cFgMuted
            font.family: root.fontSans
            font.pixelSize: 12
            elide: Text.ElideRight
            maximumLineCount: 1
        }
    }

    Item {
        id: dismissButton
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: root.s1
        width: 22
        height: 22
        opacity: notifItemMouse.containsMouse ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: root.dMicro } }

        Rectangle {
            anchors.fill: parent
            radius: root.rSm
            color: dismissArea.containsMouse ? root.ink(0.08) : "transparent"
        }

        Text {
            anchors.centerIn: parent
            text: "\uf00d"
            color: dismissArea.containsMouse ? root.cFgPrimary : root.cFgMuted
            font.family: root.fontMono
            font.pixelSize: 10
        }

        MouseArea {
            id: dismissArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: notifItem.dismissed()
        }
    }

    Rectangle {
        visible: notifItem.showDivider
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: 1
        color: root.ink(0.055)
    }

    MouseArea {
        id: notifItemMouse
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
    }
}
