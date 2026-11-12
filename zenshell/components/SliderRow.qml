import QtQuick
import QtQuick.Layouts

// System-themed slider capsule.
// Uses theme tokens for background elevation, active track fill, and typography.
Rectangle {
    id: sliderCard

    property string icon: ""
    property string iconFont: root.fontIcon
    property real value: 50
    property real min: 0
    property real max: 100
    property string valueSuffix: "%"

    signal moved(real value)

    readonly property real ratio: Math.max(0, Math.min(1, (sliderCard.value - sliderCard.min) / Math.max(0.0001, sliderCard.max - sliderCard.min)))
    readonly property int thumbSize: dragArea.containsMouse || dragArea.dragging ? 18 : 15

    implicitHeight: 46
    radius: root.themeRounding || 14

    color: dragArea.containsMouse ? root.cSurfaceContainerHigh : root.cSurfaceContainerLow
    border.width: 1
    border.color: dragArea.containsMouse ? root.cOutline : root.cOutlineVariant

    Behavior on color { ColorAnimation { duration: root.dMicro } }
    Behavior on border.color { ColorAnimation { duration: root.dMicro } }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.rightMargin: 12
        spacing: 10

        // Leading icon container
        Rectangle {
            Layout.preferredWidth: 28
            Layout.preferredHeight: 28
            radius: 14
            color: root.cSurfaceContainer

            Text {
                anchors.centerIn: parent
                text: sliderCard.icon
                color: sliderCard.ratio > 0.05 ? root.themeAccent : root.cOnSurfaceVariant
                font.family: sliderCard.iconFont
                font.pixelSize: 15
                Behavior on color { ColorAnimation { duration: root.dMicro } }
            }
        }

        // Draggable Track Area
        Item {
            id: trackArea
            Layout.fillWidth: true
            Layout.fillHeight: true

            // Background Track
            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width
                height: 6
                radius: 3
                color: root.cSurfaceContainerHighest
            }

            // Active Track Fill
            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                height: 6
                radius: 3
                width: Math.max(6, trackArea.width * sliderCard.ratio)
                color: root.themeAccent

                Behavior on width {
                    enabled: !dragArea.dragging
                    NumberAnimation { duration: 90; easing.type: Easing.OutCubic }
                }
            }

            // Draggable Thumb
            Rectangle {
                id: handle
                anchors.verticalCenter: parent.verticalCenter
                x: sliderCard.ratio * Math.max(0, trackArea.width - width)
                width: sliderCard.thumbSize
                height: sliderCard.thumbSize
                radius: width / 2
                color: root.onAccent()
                border.width: 2
                border.color: root.themeAccent

                Behavior on width { NumberAnimation { duration: root.dMicro; easing.type: Easing.OutCubic } }
                Behavior on height { NumberAnimation { duration: root.dMicro; easing.type: Easing.OutCubic } }
                Behavior on x {
                    enabled: !dragArea.dragging
                    NumberAnimation { duration: 90; easing.type: Easing.OutCubic }
                }
            }

            MouseArea {
                id: dragArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                property bool dragging: false

                function emitAt(mouseX) {
                    var r = Math.max(0, Math.min(1, mouseX / Math.max(1, width)))
                    sliderCard.moved(sliderCard.min + r * (sliderCard.max - sliderCard.min))
                }

                onPressed: (mouse) => {
                    dragging = true
                    emitAt(mouse.x)
                }
                onReleased: dragging = false
                onCanceled: dragging = false
                onPositionChanged: (mouse) => {
                    if (dragging) emitAt(mouse.x)
                }
            }
        }

        // Trailing Readout Badge
        Rectangle {
            Layout.preferredWidth: 38
            Layout.preferredHeight: 22
            radius: 6
            color: root.cSurfaceContainer

            Text {
                anchors.centerIn: parent
                text: Math.round(sliderCard.value) + sliderCard.valueSuffix
                color: root.cOnSurface
                font.family: root.fontMono
                font.pixelSize: 10
                font.weight: Font.DemiBold
            }
        }
    }
}
