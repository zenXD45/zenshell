import QtQuick
import QtQuick.Layouts

Item {
    id: weatherRoot
    anchors.fill: parent
    property real reveal: root.displayState === 6 ? 1 : 0
    opacity: reveal
    visible: opacity > 0
    clip: true
    transform: Translate { y: (1 - weatherRoot.reveal) * 5 }

    Behavior on reveal {
        NumberAnimation {
            duration: root.displayState === 6 ? root.motionBase : root.motionExit
            easing.type: root.displayState === 6 ? Easing.OutExpo : Easing.OutCubic
        }
    }

    RowLayout {
        anchors.centerIn: parent
        spacing: 12

        Text {
            text: root.weatherIcon
            color: root.uiFg
            font.family: root.font
            font.pixelSize: 30
            Layout.preferredWidth: 40
            horizontalAlignment: Text.AlignHCenter
            Layout.alignment: Qt.AlignVCenter
        }

        ColumnLayout {
            Layout.alignment: Qt.AlignVCenter
            spacing: 2

            Text {
                text: root.weatherTemp
                color: root.uiFg
                font.family: root.uiFont
                font.pixelSize: 22
                font.weight: Font.Bold
            }
            Text {
                text: root.weatherDesc
                color: root.uiFgDim
                font.family: root.uiFont
                font.pixelSize: 13
                font.weight: Font.Medium
                Layout.maximumWidth: 180
                elide: Text.ElideRight
            }
        }
    }
}
