import QtQuick
import QtQuick.Layouts

RowLayout {
    id: bluetoothRoot
    anchors.fill: parent
    anchors.margins: 12
    spacing: 12
    property real reveal: root.displayState === 9 ? 1 : 0
    opacity: reveal
    visible: opacity > 0
    clip: true
    transform: Translate { y: (1 - bluetoothRoot.reveal) * 5 }

    Behavior on reveal {
        NumberAnimation {
            duration: root.displayState === 9 ? root.motionBase : root.motionExit
            easing.type: root.displayState === 9 ? Easing.OutExpo : Easing.OutCubic
        }
    }

    Text {
        text: "🎧"
        font.pixelSize: 22
        Layout.alignment: Qt.AlignVCenter
    }

    ColumnLayout {
        Layout.fillWidth: true
        Layout.alignment: Qt.AlignVCenter
        spacing: 2
        
        Text {
            text: "Connected"
            color: "#34C759" // iOS Green
            font.family: root.uiFont
            font.pixelSize: 13
            font.weight: Font.Medium
        }
        Text {
            text: root.bluetoothDeviceName
            color: root.themeFg
            font.family: root.uiFont
            font.pixelSize: 16
            font.weight: Font.Bold
            elide: Text.ElideRight
            Layout.fillWidth: true
        }
    }
}
