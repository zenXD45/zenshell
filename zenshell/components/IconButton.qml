import QtQuick

// Quiet icon button. No border, no resting fill: the glyph is the control and
// a soft ink wash appears under the pointer. 26px target, 13px glyph.
Item {
    id: iconButton

    property string icon: ""
    property bool selected: false
    property color accentColor: root.currentThemeAccent || root.themeAccent
    property int buttonSize: 26

    signal clicked()

    implicitWidth: buttonSize
    implicitHeight: buttonSize
    width: buttonSize
    height: buttonSize

    Rectangle {
        anchors.fill: parent
        radius: root.rSm
        color: iconButton.selected
            ? Qt.rgba(iconButton.accentColor.r, iconButton.accentColor.g, iconButton.accentColor.b, 0.14)
            : (buttonArea.containsMouse ? root.ink(0.07) : "transparent")
        Behavior on color { ColorAnimation { duration: root.dMicro } }
    }

    Text {
        anchors.centerIn: parent
        text: iconButton.icon
        color: iconButton.selected
            ? iconButton.accentColor
            : (buttonArea.containsMouse ? root.cFgPrimary : root.cFgMuted)
        font.family: root.fontMono
        font.pixelSize: 13
        Behavior on color { ColorAnimation { duration: root.dMicro } }
    }

    MouseArea {
        id: buttonArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: iconButton.clicked()
    }
}
