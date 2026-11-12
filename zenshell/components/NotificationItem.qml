import QtQuick
import QtQuick.Layouts

// System-themed notification card.
// Derived strictly from active theme tokens: surface container elevation,
// theme accent monogram, clean typographic hierarchy, and quiet dismiss action.
Rectangle {
    id: notifItem

    property string appName: ""
    property string summary: ""
    property string body: ""
    property var time: new Date()
    property bool showDivider: false
    property real press: 1.0

    signal dismissed()

    Layout.fillWidth: true
    implicitHeight: bodyText.visible ? 82 : 64
    radius: root.themeRounding || 14

    color: notifItemMouse.containsMouse ? root.cSurfaceContainerHigh : root.cSurfaceContainerLow
    border.width: 1
    border.color: notifItemMouse.containsMouse ? root.cOutline : root.cOutlineVariant

    Behavior on color { ColorAnimation { duration: root.dMicro } }
    Behavior on border.color { ColorAnimation { duration: root.dMicro } }

    transform: Scale {
        origin.x: notifItem.width / 2
        origin.y: notifItem.height / 2
        xScale: notifItem.press
        yScale: notifItem.press
    }
    Behavior on press { NumberAnimation { duration: root.dMicro; easing.type: Easing.OutCubic } }

    function formatTime(date) {
        if (!date) return ""
        var d = new Date(date)
        var hh = (d.getHours() < 10 ? "0" : "") + d.getHours()
        var mm = (d.getMinutes() < 10 ? "0" : "") + d.getMinutes()
        return hh + ":" + mm
    }

    function monogram(name) {
        var s = String(name || "").trim()
        return s.length > 0 ? s.charAt(0).toUpperCase() : "\u2022"
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 12

        // Monogram squircle
        Rectangle {
            Layout.alignment: Qt.AlignTop
            Layout.preferredWidth: 32
            Layout.preferredHeight: 32
            radius: 10
            color: root.cSurfaceContainerHigh
            border.width: 1
            border.color: root.cOutlineVariant

            Text {
                anchors.centerIn: parent
                text: notifItem.monogram(notifItem.appName)
                color: root.themeAccent
                font.family: root.fontSans
                font.pixelSize: 13
                font.weight: Font.Bold
            }
        }

        // Notification Content
        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 2

            // App name + Timestamp
            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                Text {
                    Layout.fillWidth: true
                    text: notifItem.appName.toUpperCase()
                    color: root.cOnSurfaceVariant
                    font.family: root.fontSans
                    font.pixelSize: 10
                    font.weight: Font.Bold
                    font.letterSpacing: 0.6
                    elide: Text.ElideRight
                    maximumLineCount: 1
                }

                Text {
                    text: notifItem.formatTime(notifItem.time)
                    color: root.cOnSurfaceVariant
                    opacity: 0.60
                    font.family: root.fontMono
                    font.pixelSize: 10
                }
            }

            // Summary Title
            Text {
                Layout.fillWidth: true
                text: notifItem.summary
                color: root.cOnSurface
                font.family: root.fontSans
                font.pixelSize: 13
                font.weight: Font.DemiBold
                elide: Text.ElideRight
                maximumLineCount: 1
            }

            // Body
            Text {
                id: bodyText
                Layout.fillWidth: true
                visible: notifItem.body !== ""
                text: notifItem.body
                color: root.cOnSurfaceVariant
                font.family: root.fontSans
                font.pixelSize: 11
                lineHeight: 1.25
                elide: Text.ElideRight
                maximumLineCount: 2
            }
        }

        // Dismiss Button
        Item {
            id: dismissButton
            Layout.alignment: Qt.AlignTop
            Layout.preferredWidth: 24
            Layout.preferredHeight: 24

            Rectangle {
                anchors.fill: parent
                radius: 12
                color: dismissArea.containsMouse ? root.cSurfaceContainerHighest : root.cSurfaceContainer
                border.width: 1
                border.color: root.cOutlineVariant
                Behavior on color { ColorAnimation { duration: root.dMicro } }

                Text {
                    anchors.centerIn: parent
                    text: "×"
                    color: dismissArea.containsMouse ? root.cOnSurface : root.cOnSurfaceVariant
                    font.family: root.fontSans
                    font.pixelSize: 15
                    font.weight: Font.Medium
                }
            }

            MouseArea {
                id: dismissArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: notifItem.dismissed()
            }
        }
    }

    MouseArea {
        id: notifItemMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        z: -1
        onPressed: notifItem.press = 0.985
        onReleased: notifItem.press = 1.0
        onCanceled: notifItem.press = 1.0
    }
}
