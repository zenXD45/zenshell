import QtQuick
import QtQuick.Layouts

RowLayout {
    anchors.fill: parent
    anchors.margins: 12
    spacing: 12
    opacity: root.displayState === 9 ? 1 : 0
    visible: opacity > 0
    clip: true
    Behavior on opacity { NumberAnimation { duration: root.displayState === 9 ? 240 : 160; easing.type: Easing.OutCubic } }

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
            color: "#FFFFFF"
            font.family: root.uiFont
            font.pixelSize: 16
            font.weight: Font.Bold
            elide: Text.ElideRight
            Layout.fillWidth: true
        }
    }
}
