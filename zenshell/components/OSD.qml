import QtQuick
import QtQuick.Layouts

// Volume / brightness HUD. One icon, one track, one number. The track is 4px
// and the value is tabular mono so it does not jitter while the key repeats.
Item {
    id: osdRoot
    anchors.fill: parent
    property bool entered: false
    property real reveal: (root.displayState === 2 && entered) ? 1 : 0
    opacity: reveal
    visible: opacity > 0
    transform: Translate { y: (1 - osdRoot.reveal) * 4 }

    Behavior on reveal {
        NumberAnimation {
            duration: root.displayState === 2 ? root.motionBase : root.motionExit
            easing.type: Easing.OutCubic
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: root.s5
        anchors.rightMargin: root.s5
        spacing: root.s4

        Text {
            Layout.alignment: Qt.AlignVCenter
            Layout.preferredWidth: 20
            text: root.osdIcon
            color: root.cAccent
            font.family: root.fontMono
            font.pixelSize: 15
            horizontalAlignment: Text.AlignHCenter
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 4
            Layout.alignment: Qt.AlignVCenter
            radius: root.rFull
            color: root.ink(0.12)

            Rectangle {
                width: Math.max(0, parent.width * (Math.min(Math.max(root.osdValue, 0), 100) / 100.0))
                height: parent.height
                radius: parent.radius
                color: root.cAccent
                Behavior on width { NumberAnimation { duration: root.dFast; easing.type: Easing.OutCubic } }
            }
        }

        Text {
            Layout.alignment: Qt.AlignVCenter
            Layout.preferredWidth: 34
            text: Math.round(root.osdValue) + "%"
            color: root.cFgMuted
            font.family: root.fontMono
            font.pixelSize: root.tMonoSm[0]
            horizontalAlignment: Text.AlignRight
        }
    }
}
