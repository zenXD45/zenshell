import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Pipewire

RowLayout {
    anchors.centerIn: parent
    spacing: 6
    opacity: root.displayState === 0 ? 1 : 0
    visible: opacity > 0
    Behavior on opacity { NumberAnimation { duration: root.displayState === 0 ? 240 : 160; easing.type: Easing.OutCubic } }
    
    // Mic Indicator (Red Dot)
    Rectangle {
        id: micDot
        width: 6
        height: 6
        radius: 3
        color: "#FF3B30"
        Layout.alignment: Qt.AlignVCenter
        visible: Pipewire.defaultAudioSource && Pipewire.defaultAudioSource.state === 3 // PwNodeState.Running
        
        // Pulse animation for the glowing dot
        SequentialAnimation on opacity {
            loops: Animation.Infinite
            running: micDot.visible
            NumberAnimation { to: 0.4; duration: 800 }
            NumberAnimation { to: 1.0; duration: 800 }
        }
    }

    Text {
        text: root.currentTime
        color: "#FFFFFF"
        font.family: root.uiFont
        font.pixelSize: 13
        font.bold: true
        Layout.alignment: Qt.AlignVCenter
    }
}
