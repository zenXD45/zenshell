import QtQuick

// iOS-style switch: a 40x24 track and a 20 px knob. Motion is a single
// 160 ms cubic slide, nothing bounces.
Rectangle {
    id: sw
    property bool on: false

    implicitWidth: 40
    implicitHeight: 24
    radius: 12
    color: on ? root.currentThemeAccent : root.ink(0.18)
    Behavior on color { ColorAnimation { duration: 160; easing.type: Easing.OutCubic } }

    Rectangle {
        width: 20
        height: 20
        radius: 10
        y: 2
        x: sw.on ? 18 : 2
        color: sw.on ? root.onAccent() : "#F2F2F5"
        Behavior on x { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
    }
}
