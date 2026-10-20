import QtQuick

// Quiet square action used across the Profile 02 bar. It only gains a surface
// on hover so the rail stays a single continuous object instead of a row of
// boxes.
Rectangle {
    id: button

    property string glyph: ""
    property string label: ""
    property color accent: root.currentThemeAccent || "#838996"
    property bool active: false

    signal clicked()

    width: 26
    height: 26
    radius: 8
    color: active
        ? Qt.rgba(accent.r, accent.g, accent.b, 0.14)
        : (pointer.containsMouse ? "#12FFFFFF" : "transparent")
    border.width: active ? 1 : 0
    border.color: Qt.rgba(accent.r, accent.g, accent.b, 0.24)

    Behavior on color { ColorAnimation { duration: 140 } }

    Text {
        anchors.centerIn: parent
        text: button.glyph
        color: button.active ? button.accent : (pointer.containsMouse ? root.uiFg : root.uiFgDim)
        font.family: root.font
        font.pixelSize: 12
    }

    MouseArea {
        id: pointer
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: button.clicked()
    }
}
