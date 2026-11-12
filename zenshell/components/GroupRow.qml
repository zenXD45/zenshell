import QtQuick
import QtQuick.Layouts

// System-themed grouped list item.
// Follows DESIGN.md: clean glyph, 14px label, 13px right-aligned value,
// quiet hover state layer, and internal hairline separator.
Item {
    id: row

    property string icon: ""
    property string iconFont: root.fontIcon
    property string label: ""
    property string value: ""
    property bool valueActive: false
    property bool valueKeycap: false
    property bool chevron: false
    property string chevronGlyph: root.icoChevronRight
    property string chevronFont: root.fontIcon
    property bool showSwitch: false
    property bool switchOn: false
    property bool last: false
    property bool showDivider: false
    property bool destructive: false
    property bool selected: false
    property bool interactive: true
    property int rowHeight: 46
    property int labelSize: 14
    property int valueSize: 13
    property real pressScale: 0.985
    property real press: 1.0

    signal activated()
    signal toggled()
    signal entered()

    width: parent ? parent.width : 0
    height: rowHeight

    transform: Scale {
        origin.x: row.width / 2
        origin.y: row.height / 2
        xScale: row.press
        yScale: row.press
    }
    Behavior on press { NumberAnimation { duration: root.dMicro; easing.type: Easing.OutCubic } }

    // Hover / selection state layer
    Rectangle {
        anchors.fill: parent
        anchors.margins: 2
        radius: (root.themeRounding || 14) - 2
        color: row.selected
            ? (row.destructive ? root.cErrorContainer : root.cSecondaryContainer)
            : (pointer.containsMouse && row.interactive ? root.cStateHover : "transparent")
        Behavior on color { ColorAnimation { duration: root.dMicro } }
    }

    // Hairline divider
    Rectangle {
        visible: row.showDivider && !row.last
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.leftMargin: row.icon !== "" ? 50 : 16
        anchors.rightMargin: 16
        height: 1
        color: root.cOutlineVariant
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 14
        anchors.rightMargin: 14
        spacing: 12

        // Leading icon glyph
        Item {
            Layout.alignment: Qt.AlignVCenter
            Layout.preferredWidth: 24
            Layout.preferredHeight: 24
            visible: row.icon !== ""

            Text {
                anchors.centerIn: parent
                text: row.icon
                color: row.destructive
                    ? (row.selected ? root.cOnErrorContainer : root.cError)
                    : (row.selected ? root.cOnSecondaryContainer
                        : (row.valueActive ? root.themeAccent : root.cOnSurfaceVariant))
                font.family: row.iconFont
                font.pixelSize: 18
            }
        }

        // Label
        Text {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            text: row.label
            color: row.destructive
                ? (row.selected ? root.cOnErrorContainer : root.cError)
                : (row.selected ? root.cOnSecondaryContainer : root.cOnSurface)
            font.family: root.fontSans
            font.pixelSize: row.labelSize
            font.weight: row.selected ? Font.DemiBold : Font.Medium
            elide: Text.ElideRight
            maximumLineCount: 1
        }

        // Value text or keycap badge
        Rectangle {
            Layout.alignment: Qt.AlignVCenter
            visible: row.value !== ""
            implicitWidth: valueText.implicitWidth + (row.valueKeycap ? 10 : 0)
            implicitHeight: row.valueKeycap ? 20 : valueText.implicitHeight
            radius: row.valueKeycap ? 6 : 0
            color: row.valueKeycap ? root.cSurfaceContainerHighest : "transparent"
            border.width: row.valueKeycap ? 1 : 0
            border.color: root.cOutlineVariant

            Text {
                id: valueText
                anchors.centerIn: parent
                text: row.value
                color: row.valueActive ? root.themeAccent : root.cOnSurfaceVariant
                opacity: row.valueActive ? 1.0 : 0.70
                font.family: row.valueKeycap ? root.fontMono : root.fontSans
                font.pixelSize: row.valueSize
                font.weight: row.valueActive ? Font.Medium : Font.Normal
                elide: Text.ElideRight
            }
        }

        // Optional Switch
        SwitchControl {
            Layout.alignment: Qt.AlignVCenter
            visible: row.showSwitch
            on: row.switchOn
        }

        // Chevron
        Text {
            Layout.alignment: Qt.AlignVCenter
            visible: row.chevron
            text: row.chevronGlyph
            color: pointer.containsMouse ? root.cOnSurface : root.cOnSurfaceVariant
            opacity: pointer.containsMouse ? 0.85 : 0.40
            font.family: row.chevronFont
            font.pixelSize: 14
            Behavior on opacity { NumberAnimation { duration: root.dMicro } }
        }
    }

    MouseArea {
        id: pointer
        anchors.fill: parent
        enabled: row.interactive
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onEntered: row.entered()
        onPressed: row.press = row.pressScale
        onReleased: row.press = 1.0
        onCanceled: row.press = 1.0
        onClicked: {
            if (row.showSwitch) row.toggled();
            else row.activated();
        }
    }
}
