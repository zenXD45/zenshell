import QtQuick
import QtQuick.Layouts

RowLayout {
    anchors.fill: parent
    anchors.margins: 8
    spacing: 8
    opacity: (root.displayState === 1 && !root.isExpanded) ? 1 : 0
    visible: opacity > 0

    Behavior on opacity { NumberAnimation { duration: (root.displayState === 1 && !root.isExpanded) ? 240 : 160; easing.type: Easing.OutCubic } }

    // Before lyrics arrive (or when lyrics mode is off) keep the same
    // single-line, centered rhythm as the lyric itself. The old two-line
    // artwork + title + artist stack felt cramped inside a 44px pill.
    Text {
        Layout.fillWidth: true
        Layout.alignment: Qt.AlignVCenter
        text: root.trackTitle || "Nothing Playing"
        color: "#FFFFFF"
        font.family: root.uiFont
        font.pixelSize: 14
        font.bold: true
        elide: Text.ElideRight
        horizontalAlignment: Text.AlignHCenter
        visible: !root.lyricsMode || root.currentLyricLine === ""
    }

    Text {
        Layout.fillWidth: true
        Layout.alignment: Qt.AlignVCenter
        text: root.currentLyricLine
        color: "#FFFFFF"
        font.family: root.uiFont
        font.pixelSize: 14
        font.bold: true
        elide: Text.ElideRight
        horizontalAlignment: Text.AlignHCenter
        visible: root.lyricsMode && root.currentLyricLine !== ""
    }

    Row {
        spacing: 2
        visible: root.isPlaying

        Item {
            width: 3; height: 14
            Rectangle {
                width: parent.width; anchors.bottom: parent.bottom; radius: 1.5; color: "#B3FFFFFF"; height: 5
                SequentialAnimation on height {
                    loops: Animation.Infinite; running: root.isPlaying
                    NumberAnimation { to: 12; duration: 300; easing.type: Easing.InOutQuad }
                    NumberAnimation { to: 4; duration: 400; easing.type: Easing.InOutQuad }
                }
            }
        }
        Item {
            width: 3; height: 14
            Rectangle {
                width: parent.width; anchors.bottom: parent.bottom; radius: 1.5; color: "#B3FFFFFF"; height: 8
                SequentialAnimation on height {
                    loops: Animation.Infinite; running: root.isPlaying
                    NumberAnimation { to: 5; duration: 350; easing.type: Easing.InOutQuad }
                    NumberAnimation { to: 14; duration: 280; easing.type: Easing.InOutQuad }
                }
            }
        }
        Item {
            width: 3; height: 14
            Rectangle {
                width: parent.width; anchors.bottom: parent.bottom; radius: 1.5; color: "#B3FFFFFF"; height: 6
                SequentialAnimation on height {
                    loops: Animation.Infinite; running: root.isPlaying
                    NumberAnimation { to: 13; duration: 420; easing.type: Easing.InOutQuad }
                    NumberAnimation { to: 3; duration: 300; easing.type: Easing.InOutQuad }
                }
            }
        }
    }
}
