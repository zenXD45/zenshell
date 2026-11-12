import QtQuick

// Material 3 icon button: a 40 px circular state layer, a 22 px glyph, no
// resting fill. Selection is a primary container, not a tinted outline.
Item {
    id: iconButton

    property string icon: ""
    property string iconFont: root.fontMono
    property bool selected: false
    property color accentColor: root.cPrimary
    property int buttonSize: 40

    signal clicked()

    implicitWidth: buttonSize
    implicitHeight: buttonSize
    width: buttonSize
    height: buttonSize

    Rectangle {
        anchors.fill: parent
        radius: width / 2
        color: iconButton.selected
            ? root.cPrimaryContainer
            : (buttonArea.pressed ? root.cStatePressed : (buttonArea.containsMouse ? root.cStateHover : "transparent"))
        Behavior on color { ColorAnimation { duration: root.dMicro } }
    }

    Text {
        anchors.centerIn: parent
        text: iconButton.icon
        color: iconButton.selected
            ? root.cOnPrimaryContainer
            : (buttonArea.containsMouse ? root.cOnSurface : root.cOnSurfaceVariant)
        font.family: iconButton.iconFont
        font.pixelSize: 22
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
