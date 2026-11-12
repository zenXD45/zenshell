import QtQuick
import QtQuick.Layouts

// System-themed container for grouped list rows.
// Follows DESIGN.md: one rounded block (radius 14), subtle surface container fill,
// and single hairline outline. Rows inside are separated by inset hairlines.
Item {
    id: group

    default property alias content: col.data
    property int groupRadius: root.themeRounding || 14
    property color fill: root.cSurfaceContainerLow

    Layout.fillWidth: true
    implicitWidth: 0
    implicitHeight: col.height

    Rectangle {
        anchors.fill: parent
        radius: group.groupRadius
        color: group.fill
        border.width: 1
        border.color: root.cOutlineVariant
        antialiasing: true
    }

    Column {
        id: col
        width: parent.width
        spacing: 0
        topPadding: 2
        bottomPadding: 2
    }
}
