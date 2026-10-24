import QtQuick
import QtQuick.Layouts

// Idle island weather glance. The condition glyph leads, the temperature is
// the one large number, the description sits under it — no card, no border.
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
            duration: root.displayState === 6 ? root.dNormal : root.dFast
            easing.type: root.displayState === 6 ? Easing.OutExpo : Easing.OutCubic
        }
    }

    RowLayout {
        anchors.centerIn: parent
        spacing: root.s4

        Text {
            text: root.weatherIcon
            color: root.cAccent
            font.family: root.fontMono
            font.pixelSize: 26
            Layout.preferredWidth: 40
            horizontalAlignment: Text.AlignHCenter
            Layout.alignment: Qt.AlignVCenter
        }

        ColumnLayout {
            Layout.alignment: Qt.AlignVCenter
            spacing: 0

            Text {
                text: root.weatherTemp
                color: root.cFgPrimary
                font.family: root.fontSans
                font.pixelSize: root.tH1[0]
                font.weight: root.tH1[2]
                font.letterSpacing: root.tH1[3]
            }
            Text {
                text: root.weatherDesc
                color: root.cFgMuted
                font.family: root.fontSans
                font.pixelSize: root.tBodySm[0]
                font.weight: Font.Medium
                Layout.maximumWidth: 180
                elide: Text.ElideRight
            }
        }
    }
}
