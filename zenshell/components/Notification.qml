import QtQuick
import QtQuick.Layouts

// Transient notification pill. The icon tile is the anchor, the app name is
// the quiet line, the summary is the loud one, the body is optional. No emoji:
// the glyph comes from the same Nerd Font set as the rest of the shell.
RowLayout {
    id: notificationRoot
    anchors.fill: parent
    anchors.margins: root.s4
    spacing: root.s4
    property real reveal: root.displayState === 10 ? 1 : 0
    opacity: reveal
    visible: opacity > 0
    clip: true
    transform: Translate { y: (1 - notificationRoot.reveal) * 5 }

    Behavior on reveal {
        NumberAnimation {
            duration: root.displayState === 10 ? root.dNormal : root.dFast
            easing.type: root.displayState === 10 ? Easing.OutExpo : Easing.OutCubic
        }
    }

    Rectangle {
        width: 44
        height: 44
        radius: root.rMd
        color: Qt.rgba(root.cAccent.r, root.cAccent.g, root.cAccent.b, 0.14)
        border.width: 1
        border.color: Qt.rgba(root.cAccent.r, root.cAccent.g, root.cAccent.b, 0.24)
        Layout.alignment: Qt.AlignVCenter

        Text {
            anchors.centerIn: parent
            text: "\uf0f3"
            color: root.cAccent
            font.family: root.fontMono
            font.pixelSize: 16
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        Layout.alignment: Qt.AlignVCenter
        spacing: 1

        Text {
            Layout.fillWidth: true
            text: root.notifyAppName
            color: root.cFgMuted
            font.family: root.fontSans
            font.pixelSize: root.tCaption[0]
            font.weight: Font.Medium
            font.letterSpacing: 0.4
            elide: Text.ElideRight
        }

        Text {
            Layout.fillWidth: true
            text: root.notifySummary
            color: root.cFgPrimary
            font.family: root.fontSans
            font.pixelSize: root.tBody[0]
            font.weight: Font.DemiBold
            elide: Text.ElideRight
        }

        Text {
            Layout.fillWidth: true
            visible: text.length > 0
            text: root.notifyBody
            color: root.cFgSecondary
            font.family: root.fontSans
            font.pixelSize: root.tBodySm[0]
            elide: Text.ElideRight
            maximumLineCount: 1
        }
    }
}
