import QtQuick

// Material 3 switch. A 52x32 track, a 24 px handle, and a check that only
// appears when the switch is on. The handle slides on one 180 ms curve; the
// state layer is handled by the parent row, so this control stays passive.
Rectangle {
    id: sw

    property bool on: false
    property color accentColor: root.cPrimary
    property color onColor: root.cOnPrimary
    property color offHandleColor: root.cOnSurfaceVariant

    implicitWidth: 52
    implicitHeight: 32
    radius: 16

    color: sw.on ? sw.accentColor : root.cSurfaceContainerHighest
    border.width: sw.on ? 0 : 2
    border.color: root.cOutline

    Behavior on color { ColorAnimation { duration: 180; easing.type: Easing.OutCubic } }
    Behavior on border.width { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

    HoverHandler { id: hover }

    Rectangle {
        anchors.fill: parent
        radius: parent.radius
        color: hover.hovered ? root.cStateHover : "transparent"
        Behavior on color { ColorAnimation { duration: root.dMicro } }
    }

    Rectangle {
        id: handle

        width: 24
        height: 24
        radius: 12
        y: 4
        x: sw.on ? 24 : 4
        color: sw.on ? sw.onColor : sw.offHandleColor

        Behavior on x { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
        Behavior on color { ColorAnimation { duration: 180; easing.type: Easing.OutCubic } }

        Text {
            anchors.centerIn: parent
            visible: sw.on
            text: root.icoCheck
            color: sw.accentColor
            font.family: root.fontIcon
            font.pixelSize: 16
        }
    }
}
