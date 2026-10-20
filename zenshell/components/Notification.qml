import QtQuick
import QtQuick.Layouts

RowLayout {
    anchors.fill: parent
    anchors.margins: 12
    spacing: 12
    opacity: root.displayState === 10 ? 1 : 0
    visible: opacity > 0
    clip: true
    Behavior on opacity { NumberAnimation { duration: root.displayState === 10 ? 240 : 160; easing.type: Easing.OutCubic } }

    Rectangle {
        width: 44
        height: 44
        radius: 12
        color: "#20FFFFFF"
        Layout.alignment: Qt.AlignVCenter
        
        Text {
            anchors.centerIn: parent
            text: "💬"
            font.pixelSize: 22
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        Layout.alignment: Qt.AlignVCenter
        spacing: 2
        
        Text {
            text: root.notifyAppName
            color: "#A0A0A5"
            font.family: root.uiFont
            font.pixelSize: 11
            font.weight: Font.Medium
            elide: Text.ElideRight
            Layout.fillWidth: true
        }

        Text {
            text: root.notifySummary
            color: "#FFFFFF"
            font.family: root.uiFont
            font.pixelSize: 14
            font.weight: Font.Bold
            elide: Text.ElideRight
            Layout.fillWidth: true
        }
        
        Text {
            text: root.notifyBody
            color: "#C0C0C5"
            font.family: root.uiFont
            font.pixelSize: 12
            font.weight: Font.Normal
            elide: Text.ElideRight
            maximumLineCount: 1
            Layout.fillWidth: true
        }
    }
}
