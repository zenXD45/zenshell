import QtQuick
import QtQuick.Layouts

// A profile is chosen by recognizing its silhouette, not by reading a feature
// list. The miniature surface is the primary information; the labels confirm it.
Item {
    id: card

    property string profileId: "island"
    property string title: ""
    property string description: ""
    property bool active: false

    signal activated()

    Layout.fillWidth: true
    Layout.preferredHeight: 160

    scale: pointer.containsMouse ? 1.012 : 1.0
    transformOrigin: Item.Center
    Behavior on scale { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }

    Rectangle {
        anchors.fill: parent
        radius: root.uiRadiusMd
        color: card.active
            ? Qt.rgba(root.themeAccent.r, root.themeAccent.g, root.themeAccent.b, 0.09)
            : (pointer.containsMouse ? root.ink(0.055) : root.ink(0.027))
        border.width: 1
        border.color: card.active
            ? Qt.rgba(root.themeAccent.r, root.themeAccent.g, root.themeAccent.b, 0.42)
            : (pointer.containsMouse ? root.ink(0.141) : root.ink(0.071))
        Behavior on color { ColorAnimation { duration: 160 } }
        Behavior on border.color { ColorAnimation { duration: 160 } }
    }

    Rectangle {
        id: preview
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 10
        height: 92
        radius: 12
        color: "#06000000"
        border.width: 1
        border.color: root.ink(0.063)
        clip: true

        Rectangle {
            width: 118
            height: 118
            radius: width / 2
            x: parent.width - 66
            y: -42
            color: root.currentThemeAccent
            opacity: 0.07
        }

        Text {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.margins: 9
            text: card.profileId === "island" ? "01" : "02"
            color: root.uiFgDim
            font.family: root.font
            font.pixelSize: 8
            font.weight: Font.Medium
            font.letterSpacing: 0.8
        }

        // 01 — the island over a dock.
        Item {
            anchors.fill: parent
            visible: card.profileId === "island"

            Rectangle {
                width: 76
                height: 16
                radius: 8
                anchors.horizontalCenter: parent.horizontalCenter
                y: 17
                color: root.glass(0.9)
                border.width: 1
                border.color: root.ink(0.173)

                Rectangle {
                    width: 3
                    height: 3
                    radius: 1.5
                    anchors.left: parent.left
                    anchors.leftMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    color: root.currentThemeAccent
                }

                Rectangle {
                    width: 25
                    height: 2
                    radius: 1
                    anchors.centerIn: parent
                    color: root.ink(0.471)
                }
            }

            Rectangle {
                width: 94
                height: 22
                radius: 11
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 10
                color: "#3A000000"
                border.width: 1
                border.color: root.ink(0.141)

                Row {
                    anchors.centerIn: parent
                    spacing: 5

                    Repeater {
                        model: 4
                        delegate: Rectangle {
                            required property int index
                            width: 10
                            height: 10
                            radius: 3
                            color: index === 0 ? root.currentThemeAccent : root.ink(0.22)
                            opacity: index === 0 ? 0.9 : 1
                        }
                    }
                }
            }
        }

        // 02 — the command rail, rendered in the style currently chosen.
        Item {
            anchors.fill: parent
            visible: card.profileId === "bar"

            Rectangle {
                width: root.barStyle === "edge" ? parent.width - 18 : 118
                height: 16
                radius: root.barStyle === "edge" ? 2 : 6
                anchors.horizontalCenter: parent.horizontalCenter
                y: 22
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: root.glass(0.94) }
                    GradientStop { position: 1.0; color: root.glass(0.94) }
                }
                border.width: 1
                border.color: root.ink(0.173)

                Row {
                    anchors.fill: parent
                    anchors.leftMargin: 6
                    anchors.rightMargin: 6
                    spacing: 4

                    Rectangle {
                        width: 8
                        height: 8
                        radius: 2.5
                        anchors.verticalCenter: parent.verticalCenter
                        color: root.currentThemeAccent
                        opacity: 0.85
                    }

                    Rectangle {
                        width: 15
                        height: 2
                        radius: 1
                        anchors.verticalCenter: parent.verticalCenter
                        color: root.ink(0.345)
                    }

                    Item { width: 18; height: 1 }

                    Rectangle {
                        width: 18
                        height: 2
                        radius: 1
                        anchors.verticalCenter: parent.verticalCenter
                        color: root.ink(0.471)
                    }

                    Rectangle {
                        width: 12
                        height: 2
                        radius: 1
                        anchors.verticalCenter: parent.verticalCenter
                        color: root.ink(0.22)
                    }
                }
            }

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                y: 54
                spacing: 5

                Repeater {
                    model: [18, 31, 24, 14]
                    delegate: Rectangle {
                        required property int modelData
                        required property int index
                        width: modelData
                        height: 5
                        radius: 2.5
                        color: index === 0 ? root.currentThemeAccent : root.ink(0.133)
                        opacity: index === 0 ? 0.55 : 1
                    }
                }
            }
        }

        Rectangle {
            visible: card.active
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.margins: 8
            height: 17
            implicitWidth: activeText.implicitWidth + 12
            radius: 8.5
            color: root.glass(0.8)
            border.width: 1
            border.color: Qt.rgba(root.themeAccent.r, root.themeAccent.g, root.themeAccent.b, 0.38)

            Text {
                id: activeText
                anchors.centerIn: parent
                text: "LIVE"
                color: root.currentThemeAccent
                font.family: root.uiFont
                font.pixelSize: 7
                font.weight: Font.Bold
                font.letterSpacing: 0.8
            }
        }
    }

    Column {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        anchors.bottomMargin: 12
        spacing: 2

        Text {
            width: parent.width
            text: card.title
            color: root.uiFg
            font.family: root.uiFont
            font.pixelSize: 13
            font.weight: Font.DemiBold
            elide: Text.ElideRight
        }

        Text {
            width: parent.width
            text: card.description
            color: root.uiFgDim
            font.family: root.uiFont
            font.pixelSize: 9
            font.weight: Font.Medium
            elide: Text.ElideRight
        }
    }

    MouseArea {
        id: pointer
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: card.activated()
    }
}
