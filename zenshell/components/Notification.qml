import QtQuick
import QtQuick.Layouts

RowLayout {
    id: notificationRoot
    anchors.fill: parent
    anchors.margins: 12
    spacing: 12
    property real reveal: root.displayState === 10 ? 1 : 0
    opacity: reveal
    visible: opacity > 0
    clip: true
    transform: Translate { y: (1 - notificationRoot.reveal) * 5 }

    Behavior on reveal {
        NumberAnimation {
            duration: root.displayState === 10 ? root.motionBase : root.motionExit
            easing.type: root.displayState === 10 ? Easing.OutExpo : Easing.OutCubic
        }
    }

    Rectangle {
        width: 44
        height: 44
        radius: 12
        color: root.ink(0.125)
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
            color: root.ink(0.65)
            font.family: root.uiFont
            font.pixelSize: 11
            font.weight: Font.Medium
            elide: Text.ElideRight
            Layout.fillWidth: true
        }

        Text {
            text: root.notifySummary
            color: root.themeFg
            font.family: root.uiFont
            font.pixelSize: 14
            font.weight: Font.Bold
            elide: Text.ElideRight
            Layout.fillWidth: true
        }
        
        Text {
            text: root.notifyBody
            color: root.ink(0.8)
            font.family: root.uiFont
            font.pixelSize: 12
            font.weight: Font.Normal
            elide: Text.ElideRight
            maximumLineCount: 1
            Layout.fillWidth: true
        }
    }
}
