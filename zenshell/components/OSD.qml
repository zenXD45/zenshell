import QtQuick
import QtQuick.Layouts

Item {
    anchors.fill: parent
    opacity: root.displayState === 2 ? 1 : 0
    visible: opacity > 0
    clip: true
    Behavior on opacity { NumberAnimation { duration: root.displayState === 2 ? 240 : 160; easing.type: Easing.OutCubic } }

    RowLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 12

        Text {
            text: root.osdIcon
            color: root.currentThemeAccent
            font.family: root.font
            font.pixelSize: 16
            Layout.alignment: Qt.AlignVCenter
            Layout.preferredWidth: 20
            horizontalAlignment: Text.AlignHCenter
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 6
            Layout.alignment: Qt.AlignVCenter
            radius: 3
            color: Qt.rgba(1, 1, 1, 0.15)

            Rectangle {
                width: parent.width * (Math.min(root.osdValue, 100) / 100.0)
                height: parent.height
                radius: 3
                color: root.currentThemeAccent
                Behavior on width { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
            }
        }
    }
}
