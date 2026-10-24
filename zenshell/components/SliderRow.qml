import QtQuick
import QtQuick.Layouts

// Icon, track, value. The number sits on the baseline as plain tabular text —
// no value badge, no boxed readout. The whole row is the drag target.
RowLayout {
    id: sliderRow

    property string icon: ""
    property real value: 50
    property real min: 0
    property real max: 100
    property color accentColor: root.currentThemeAccent || root.themeAccent
    property string valueSuffix: ""

    signal moved(real value)

    spacing: root.s4

    Text {
        Layout.alignment: Qt.AlignVCenter
        Layout.preferredWidth: 20
        horizontalAlignment: Text.AlignHCenter
        text: sliderRow.icon
        visible: sliderRow.icon !== ""
        color: root.cFgSecondary
        font.family: root.fontMono
        font.pixelSize: 15
    }

    Item {
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.preferredHeight: 32

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width
            height: dragArea.pressed || dragArea.containsMouse ? 4 : 3
            radius: height / 2
            color: root.ink(0.10)
            Behavior on height { NumberAnimation { duration: root.dMicro; easing.type: Easing.OutCubic } }
        }

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            height: dragArea.pressed || dragArea.containsMouse ? 4 : 3
            radius: height / 2
            width: Math.max(0, (parent.width - 10) * ((sliderRow.value - sliderRow.min) / Math.max(0.0001, sliderRow.max - sliderRow.min)))
            color: sliderRow.accentColor
            Behavior on height { NumberAnimation { duration: root.dMicro; easing.type: Easing.OutCubic } }
        }

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            x: Math.max(0, Math.min(parent.width - width, (parent.width - 10) * ((sliderRow.value - sliderRow.min) / Math.max(0.0001, sliderRow.max - sliderRow.min))))
            width: dragArea.pressed ? 13 : 10
            height: width
            radius: width / 2
            color: root.cFgPrimary
            Behavior on width { NumberAnimation { duration: root.dMicro; easing.type: Easing.OutCubic } }
        }

        MouseArea {
            id: dragArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            property bool dragging: false
            function emitAt(x) {
                var ratio = Math.max(0, Math.min(1, x / Math.max(1, width)))
                sliderRow.moved(sliderRow.min + ratio * (sliderRow.max - sliderRow.min))
            }
            onPressed: (mouse) => { dragging = true; emitAt(mouse.x) }
            onReleased: dragging = false
            onPositionChanged: (mouse) => { if (dragging) emitAt(mouse.x) }
        }
    }

    Text {
        Layout.alignment: Qt.AlignVCenter
        Layout.preferredWidth: 34
        horizontalAlignment: Text.AlignRight
        text: Math.round(sliderRow.value) + sliderRow.valueSuffix
        color: root.cFgSecondary
        font.family: root.fontMono
        font.pixelSize: 11
    }
}
