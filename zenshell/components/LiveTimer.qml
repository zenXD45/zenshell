import QtQuick
import QtQuick.Layouts

RowLayout {
    anchors.fill: parent
    anchors.margins: 12
    spacing: 12
    opacity: root.displayState === 7 ? 1 : 0
    visible: opacity > 0
    clip: true
    Behavior on opacity { NumberAnimation { duration: root.displayState === 7 ? 240 : 160; easing.type: Easing.OutCubic } }

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
            color: "#808080"
            font.pixelSize: 20
            font.weight: Font.Bold
        }
    }
}
