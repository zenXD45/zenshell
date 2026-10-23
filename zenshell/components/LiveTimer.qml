import QtQuick
import QtQuick.Layouts

RowLayout {
    id: timerRoot
    anchors.fill: parent
    anchors.margins: 12
    spacing: 12
    property real reveal: root.displayState === 7 ? 1 : 0
    opacity: reveal
    visible: opacity > 0
    clip: true
    transform: Translate { y: (1 - timerRoot.reveal) * 5 }

    Behavior on reveal {
        NumberAnimation {
            duration: root.displayState === 7 ? root.motionBase : root.motionExit
            easing.type: root.displayState === 7 ? Easing.OutExpo : Easing.OutCubic
        }
    }

    Text {
        text: "⏱️"
        font.pixelSize: 18
        Layout.alignment: Qt.AlignVCenter
    }

    Text {
        text: root.timerString
        color: "#FF9F0A" // iOS Orange for timer
        font.family: root.uiFont
        font.pixelSize: 18
        font.weight: Font.Bold
        font.features: { "tnum": 1 } // Tabular numbers
        Layout.alignment: Qt.AlignVCenter
        Layout.fillWidth: true
    }
    
    // Close button
    MouseArea {
        Layout.preferredWidth: 20
        Layout.preferredHeight: 20
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            countdownTimer.stop();
            root.displayState = 0;
            root.updateState();
        }
        Text {
            anchors.centerIn: parent
            text: "×"
            color: root.ink(0.6)
            font.pixelSize: 20
            font.weight: Font.Bold
        }
    }
}
