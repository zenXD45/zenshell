import QtQuick
import QtQuick.Layouts

RowLayout {
    id: bluetoothRoot
    anchors.fill: parent
    anchors.margins: 12
    spacing: 12
    property bool entered: false
    property real reveal: (root.displayState === 9 && entered) ? 1 : 0
    opacity: reveal
    visible: opacity > 0
    transform: Translate { y: (1 - bluetoothRoot.reveal) * 4 }

    Behavior on reveal {
        NumberAnimation {
            duration: root.displayState === 9 ? root.motionBase : root.motionExit
            easing.type: Easing.OutCubic
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
            color: root.cSuccess // iOS Green
            font.family: root.fontSans
            font.pixelSize: 13
            font.weight: Font.Medium
        }
        Text {
            text: root.bluetoothDeviceName
            color: root.themeFg
            font.family: root.fontSans
            font.pixelSize: 16
            font.weight: Font.Bold
            elide: Text.ElideRight
            Layout.fillWidth: true
        }
    }
}
