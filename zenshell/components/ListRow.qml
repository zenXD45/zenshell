import QtQuick
import QtQuick.Layouts

// A Material 3 list row for drill-in menus: leading glyph, label, optional
// live detail and value, optional chevron. Hover and selection are tonal state
// layers; there is no card border and no resting accent.
Item {
    id: row

    property string icon: ""
    property string iconFont: root.fontIcon
    property string label: ""
    property string value: ""
    property string detail: ""
    property bool chevron: false
    property string chevronGlyph: root.icoChevronRight
    property string chevronFont: root.fontIcon
    property bool active: false
    property bool danger: false
    property bool interactive: true
    property bool showDivider: false
    property int rowHeight: 48
    property color accentColor: root.cPrimary

    signal clicked()

    implicitHeight: rowHeight
    height: rowHeight
    Layout.fillWidth: true

    Rectangle {
        anchors.fill: parent
        anchors.margins: 4
        radius: root.rMd
        color: row.active
            ? root.cSecondaryContainer
            : (rowArea.containsMouse && row.interactive ? root.cStateHover : "transparent")
        Behavior on color { ColorAnimation { duration: root.dMicro } }
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        spacing: root.s4

        Text {
            Layout.alignment: Qt.AlignVCenter
            Layout.preferredWidth: 24
            horizontalAlignment: Text.AlignHCenter
            text: row.icon
            visible: row.icon !== ""
            color: row.danger
                ? root.cError
                : (row.active ? root.cOnSecondaryContainer : root.cOnSurfaceVariant)
            font.family: row.iconFont
            font.pixelSize: 19
            Behavior on color { ColorAnimation { duration: root.dMicro } }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            Text {
                Layout.fillWidth: true
                text: row.label
                color: row.danger ? root.cError : root.cOnSurface
                font.family: root.fontSans
                font.pixelSize: 14
                font.weight: Font.Medium
                elide: Text.ElideRight
                maximumLineCount: 1
            }

            Text {
                Layout.fillWidth: true
                visible: text !== ""
                text: row.detail || ""
                color: root.cOnSurfaceVariant
                font.family: root.fontSans
                font.pixelSize: 12
                elide: Text.ElideRight
                maximumLineCount: 1
            }
        }

        Text {
            Layout.alignment: Qt.AlignVCenter
            visible: text !== ""
            text: row.value
            color: row.active ? root.cOnSecondaryContainer : root.cOnSurfaceVariant
            font.family: root.fontMono
            font.pixelSize: 11
            horizontalAlignment: Text.AlignRight
            Behavior on color { ColorAnimation { duration: root.dMicro } }
        }

        Text {
            Layout.alignment: Qt.AlignVCenter
            visible: row.chevron
            text: row.chevronGlyph
            color: rowArea.containsMouse ? root.cOnSurface : root.cOnSurfaceVariant
            font.family: row.chevronFont
            font.pixelSize: 20
            Behavior on color { ColorAnimation { duration: root.dMicro } }
        }
    }

    Rectangle {
        visible: row.showDivider
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.leftMargin: 56
        anchors.rightMargin: 16
        height: 1
        color: root.cOutlineVariant
    }

    MouseArea {
        id: rowArea
        anchors.fill: parent
        enabled: row.interactive
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: row.clicked()
    }
}
