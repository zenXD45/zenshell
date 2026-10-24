import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Pipewire

RowLayout {
    id: idleClockRoot
    anchors.centerIn: parent
    spacing: 6
    property bool idleReady: false
    property real reveal: (root.displayState === 0 && idleReady) ? 1 : 0
    opacity: reveal
    visible: opacity > 0
    transform: Translate { y: (1 - idleClockRoot.reveal) * 3 }

    // Let a closing panel finish before the clock fades back in. Without this
    // delay the time ghosts through the shrinking surface for a few frames.
    Timer {
        id: idleDelay
        interval: 160
        onTriggered: idleClockRoot.idleReady = root.displayState === 0
    }

    Connections {
        target: root
        function onDisplayStateChanged() {
            if (root.displayState === 0) {
                idleDelay.restart();
            } else {
                idleDelay.stop();
                idleClockRoot.idleReady = false;
            }
        }
    }

    Component.onCompleted: {
        if (root.displayState === 0) idleDelay.start();
    }

    Behavior on reveal {
        NumberAnimation {
            // Constant and quick: the clock must never ghost through an
            // opening panel. The 160ms re-entry delay supplies the softness.
            duration: 90
            easing.type: Easing.OutCubic
        }
    }
    
    // Mic Indicator (Red Dot)
    Rectangle {
        id: micDot
        width: 6
        height: 6
        radius: 3
        color: root.cDanger
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
        color: root.themeFg
        font.family: root.fontSans
        font.pixelSize: 13
        font.bold: true
        Layout.alignment: Qt.AlignVCenter
    }
}
