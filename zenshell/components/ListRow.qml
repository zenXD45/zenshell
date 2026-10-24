import QtQuick
import QtQuick.Layouts

// One line of a menu: glyph, label, optional live value, optional chevron.
// Rows are the only structural unit in ZenShell panels — a menu is a stack of
// rows over a hairline, never a field of cards. There is no border, no icon
// tile and no accent unless the row is the active selection or destructive.
Item {
    id: row

    property string icon: ""
    property string label: ""
    property string value: ""
    property string detail: ""
    property bool chevron: false
    property bool active: false
    property bool danger: false
    property bool interactive: true
    property bool showDivider: false
    property int rowHeight: 44
    property color accentColor: root.currentThemeAccent || root.themeAccent

    signal clicked()

    implicitHeight: rowHeight
    height: rowHeight
    Layout.fillWidth: true

    Rectangle {
        anchors.fill: parent
        radius: root.rSm
        color: row.active
            ? Qt.rgba(row.accentColor.r, row.accentColor.g, row.accentColor.b, 0.11)
            : (rowArea.containsMouse && row.interactive ? root.ink(0.05) : "transparent")
        Behavior on color { ColorAnimation { duration: root.dMicro } }
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: root.s3
        anchors.rightMargin: root.s3
        spacing: root.s4

        Text {
            Layout.alignment: Qt.AlignVCenter
            Layout.preferredWidth: 20
            horizontalAlignment: Text.AlignHCenter
            text: row.icon
            visible: row.icon !== ""
            color: row.danger
                ? root.cDanger
                : (row.active ? row.accentColor : root.cFgSecondary)
            font.family: root.fontMono
            font.pixelSize: 15
            Behavior on color { ColorAnimation { duration: root.dMicro } }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            Text {
                Layout.fillWidth: true
                text: row.label
                color: row.danger ? root.cDanger : root.cFgPrimary
                font.family: root.fontSans
                font.pixelSize: 13
                font.weight: Font.Medium
                elide: Text.ElideRight
                maximumLineCount: 1
            }

            Text {
                Layout.fillWidth: true
                visible: text !== ""
                text: row.detail || ""
                color: root.cFgMuted
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
            color: row.active ? row.accentColor : root.cFgMuted
            font.family: root.fontMono
            font.pixelSize: 11
            horizontalAlignment: Text.AlignRight
            Behavior on color { ColorAnimation { duration: root.dMicro } }
        }

        Text {
            Layout.alignment: Qt.AlignVCenter
            visible: row.chevron
            text: "\uf054"
            color: root.ink(rowArea.containsMouse ? 0.62 : 0.34)
            font.family: root.fontMono
            font.pixelSize: 10
            Behavior on color { ColorAnimation { duration: root.dMicro } }
        }
    }

    // Hairline belongs to the row above it in reading order.
    Rectangle {
        visible: row.showDivider
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.leftMargin: root.s3 + 20 + root.s4
        height: 1
        color: root.ink(0.055)
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
