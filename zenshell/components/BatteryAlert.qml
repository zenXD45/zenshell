import QtQuick
import QtQuick.Layouts

Item {
    anchors.fill: parent
    opacity: root.displayState === 8 ? 1 : 0
    visible: opacity > 0
    clip: true
    Behavior on opacity { NumberAnimation { duration: root.displayState === 8 ? 240 : 160; easing.type: Easing.OutCubic } }

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
                border.color: "#666666"
                border.width: 1.5

                // Battery fill
                Rectangle {
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    anchors.margins: 2
                    width: Math.max(0, (parent.width - 4) * (root.batteryPercent / 100))
                    radius: 2
                    color: root.batteryCharging ? "#34C759" : (root.batteryPercent <= 20 ? "#FF3B30" : "#FFFFFF")
                    
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
                color: "#666666"
            }
        }

        Text {
            text: root.batteryPercent + "%"
            color: root.batteryCharging ? "#34C759" : (root.batteryPercent <= 20 ? "#FF3B30" : "#FFFFFF")
            font.family: root.uiFont
            font.pixelSize: 15
            font.weight: Font.Bold
            Layout.alignment: Qt.AlignVCenter
        }

        Text {
            text: root.batteryCharging ? "Charging" : (root.batteryPercent <= 20 ? "Low Battery" : "Battery")
            color: "#A0A0A0"
            font.family: root.uiFont
            font.pixelSize: 13
            font.weight: Font.Medium
            Layout.alignment: Qt.AlignVCenter
        }
    }
}
