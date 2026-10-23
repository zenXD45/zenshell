import QtQuick

// Quiet square action used across the Profile 02 bar. It only gains a surface
// on hover so the rail stays a single continuous object instead of a row of
// boxes.
Rectangle {
    id: button

    property string glyph: ""
    property string label: ""
    property color accent: root.currentThemeAccent || root.themeAccent
    property bool active: false

    signal clicked()

    width: 28
    height: 28
    radius: 9
    color: active
        ? Qt.rgba(accent.r, accent.g, accent.b, 0.14)
        : (pointer.containsMouse ? root.ink(0.071) : "transparent")
    border.width: active ? 1 : 0
    border.color: Qt.rgba(accent.r, accent.g, accent.b, 0.24)

    Behavior on color { ColorAnimation { duration: 140 } }

    Text {
        anchors.centerIn: parent
        text: button.glyph
        color: button.active ? button.accent : (pointer.containsMouse ? root.uiFg : root.uiFgDim)
        font.family: root.font
        font.pixelSize: 13
    }

    MouseArea {
        id: pointer
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: button.clicked()
    }
}
