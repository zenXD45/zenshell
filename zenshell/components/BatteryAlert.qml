import QtQuick
import QtQuick.Layouts

Item {
    id: batteryRoot
    anchors.fill: parent
    property bool entered: false
    property real reveal: (root.displayState === 8 && entered) ? 1 : 0
    opacity: reveal
    visible: opacity > 0
    transform: Translate { y: (1 - batteryRoot.reveal) * 4 }

    Behavior on reveal {
        NumberAnimation {
            duration: root.displayState === 8 ? root.motionBase : root.motionExit
            easing.type: Easing.OutCubic
        }
    }

    RowLayout {
        anchors.centerIn: parent
        spacing: 10

        // iOS Battery Icon
        Item {
            width: 32
            height: 14
            Layout.alignment: Qt.AlignVCenter

            // Main battery body
            Rectangle {
                id: batteryBody
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                width: 28
                height: 14
                radius: 4
                color: "transparent"
                border.color: root.ink(0.45)
                border.width: 1.5

                // Battery fill
                Rectangle {
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    anchors.margins: 2
                    width: Math.max(0, (parent.width - 4) * (root.batteryPercent / 100))
                    radius: 2
                    color: root.batteryCharging ? root.cSuccess : (root.batteryPercent <= 20 ? root.cDanger : root.themeFg)
                    
                    // Charging lightning bolt overlay
                    Text {
                        anchors.centerIn: parent
                        text: "⚡"
                        font.pixelSize: 8
                        color: "#000000"
                        visible: root.batteryCharging
                    }
                }
            }

            // Battery terminal (nub)
            Rectangle {
                anchors.left: batteryBody.right
                anchors.leftMargin: 1
                anchors.verticalCenter: parent.verticalCenter
                width: 2
                height: 6
                radius: 1
                color: root.ink(0.45)
            }
        }

        Text {
            text: root.batteryPercent + "%"
            color: root.batteryCharging ? root.cSuccess : (root.batteryPercent <= 20 ? root.cDanger : root.themeFg)
            font.family: root.fontSans
            font.pixelSize: 15
            font.weight: Font.Bold
            Layout.alignment: Qt.AlignVCenter
        }

        Text {
            text: root.batteryCharging ? "Charging" : (root.batteryPercent <= 20 ? "Low Battery" : "Battery")
            color: root.ink(0.65)
            font.family: root.fontSans
            font.pixelSize: 13
            font.weight: Font.Medium
            Layout.alignment: Qt.AlignVCenter
        }
    }
}
