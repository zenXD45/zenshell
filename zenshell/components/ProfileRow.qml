import QtQuick
import QtQuick.Layouts

// One profile choice, as a row in a group: a small schematic of the chrome,
// the name, a one-line description, and a checkmark on the active one.
Item {
    id: row

    property string profileId: "island"
    property string title: ""
    property string description: ""
    property bool active: false
    property bool last: false

    signal activated()

    width: parent ? parent.width : 0
    height: 64

    Rectangle {
        anchors.fill: parent
        anchors.margins: 2
        radius: 10
        color: pointer.containsMouse ? root.ink(0.04) : "transparent"
        Behavior on color { ColorAnimation { duration: root.dMicro } }
    }

    Rectangle {
        visible: !row.last
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.leftMargin: 78
        anchors.rightMargin: 16
        height: 1
        color: root.ink(0.07)
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 14
        anchors.rightMargin: 14
        spacing: root.s4

        // Schematic of the profile: pill at the top, or a rail at the left.
        Item {
            Layout.alignment: Qt.AlignVCenter
            Layout.preferredWidth: 50
            Layout.preferredHeight: 36

            Rectangle {
                anchors.fill: parent
                radius: 8
                color: root.ink(0.05)
            }

            Rectangle {
                visible: row.profileId === "island"
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.topMargin: 8
                width: 26
                height: 8
                radius: 4
                color: row.active ? root.currentThemeAccent : root.ink(0.32)
            }

            Rectangle {
                visible: row.profileId === "island"
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.topMargin: 21
                width: 18
                height: 2
                radius: 1
                color: root.ink(0.20)
            }

            Rectangle {
                visible: row.profileId === "bar"
                anchors.left: parent.left
                anchors.leftMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                width: 3
                height: 20
                radius: 1.5
                color: row.active ? root.currentThemeAccent : root.ink(0.32)
            }

            Column {
                visible: row.profileId === "bar"
                anchors.left: parent.left
                anchors.leftMargin: 16
                anchors.verticalCenter: parent.verticalCenter
                spacing: 4

                Repeater {
                    model: 3
                    Rectangle {
                        width: 20
                        height: 2
                        radius: 1
                        color: root.ink(0.20)
                    }
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 2

            Text {
                Layout.fillWidth: true
                text: row.title
                color: root.cFgPrimary
                font.family: root.fontSans
                font.pixelSize: 14
                font.weight: row.active ? Font.DemiBold : Font.Normal
                elide: Text.ElideRight
            }

            Text {
                Layout.fillWidth: true
                text: row.description
                color: root.ink(0.40)
                font.family: root.fontSans
                font.pixelSize: 11
                elide: Text.ElideRight
            }
        }

        Text {
            Layout.alignment: Qt.AlignVCenter
            visible: row.active
            text: "\uf00c"
            color: root.currentThemeAccent
            font.family: root.fontMono
            font.pixelSize: 13
        }
    }

    MouseArea {
        id: pointer
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: row.activated()
    }
}
