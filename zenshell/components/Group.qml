import QtQuick
import QtQuick.Layouts

// An inset group, the way iOS Settings does it: one rounded block, rows inside,
// hairlines between them. No borders, no nested cards.
Item {
    id: group

    default property alias content: col.data
    property int groupRadius: 14
    property color fill: root.ink(0.055)

    Layout.fillWidth: true
    implicitWidth: 0
    implicitHeight: col.height

    Rectangle {
        anchors.fill: parent
        radius: group.groupRadius
        color: group.fill
        antialiasing: true
    }

    Column {
        id: col
        width: parent.width
        spacing: 0
    }
}
