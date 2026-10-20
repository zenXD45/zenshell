import QtQuick
import QtQuick.Layouts

Item {
    id: compact
    anchors.fill: parent
    opacity: (root.displayState === 1 && !root.isExpanded) ? 1 : 0
    visible: opacity > 0
    Behavior on opacity { NumberAnimation { duration: (root.displayState === 1 && !root.isExpanded) ? 240 : 160; easing.type: Easing.OutCubic } }

    readonly property bool hasLyric: root.lyricsMode && root.currentLyricLine !== ""

    // The lyric sits inside symmetric 30px gutters: the right gutter holds the
    // equalizer, the left gutter balances it, so the line is optically centred
    // in the pill instead of being pushed off-centre by the visualizer.
    Item {
        id: stage
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.leftMargin: 30
        anchors.rightMargin: 30

        property string primaryLine: ""
        property string secondaryLine: ""
        property bool showPrimary: true

        function setLine(line) {
            if (line === "") {
                primaryLine = ""
                secondaryLine = ""
                showPrimary = true
                return
            }
            if (showPrimary && line === primaryLine) return
            if (!showPrimary && line === secondaryLine) return
            if (showPrimary) secondaryLine = line
            else primaryLine = line
            showPrimary = !showPrimary
        }

        Component.onCompleted: {
            primaryLine = root.currentLyricLine
            showPrimary = true
        }

        Connections {
            target: root
            function onCurrentLyricLineChanged() { stage.setLine(root.currentLyricLine) }
            function onLyricsModeChanged() { stage.setLine(root.currentLyricLine) }
        }

        Text {
            id: titleText
            anchors.fill: parent
            text: root.trackTitle || "Nothing Playing"
            color: root.uiFg
            font.family: root.uiFont
            font.pixelSize: 14
            font.weight: Font.DemiBold
            font.letterSpacing: 0.2
            elide: Text.ElideRight
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            opacity: compact.hasLyric ? 0 : 1
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: 170; easing.type: Easing.OutCubic } }
        }

        Text {
            id: primaryText
            anchors.fill: parent
            text: stage.primaryLine
            color: root.uiFg
            font.family: root.uiFont
            font.pixelSize: 14
            font.weight: Font.DemiBold
            font.letterSpacing: 0.2
            elide: Text.ElideRight
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            opacity: compact.hasLyric && stage.showPrimary ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 170; easing.type: Easing.OutCubic } }
        }

        Text {
            id: secondaryText
            anchors.fill: parent
            text: stage.secondaryLine
            color: root.uiFg
            font.family: root.uiFont
            font.pixelSize: 14
            font.weight: Font.DemiBold
            font.letterSpacing: 0.2
            elide: Text.ElideRight
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            opacity: compact.hasLyric && !stage.showPrimary ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 170; easing.type: Easing.OutCubic } }
        }
    }

    // A little live signal on the right; it picks up the active theme accent
    // so the pill feels connected to the rest of the shell.
    Item {
        id: equalizer
        anchors.right: parent.right
        anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        width: 18
        height: 16
        visible: root.isPlaying
        opacity: root.isHovered ? 1 : 0.82
        Behavior on opacity { NumberAnimation { duration: 160 } }

        Row {
            anchors.centerIn: parent
            spacing: 2

            Repeater {
                model: 4

                Item {
                    width: 2
                    height: 16

                    Rectangle {
                        width: parent.width
                        anchors.bottom: parent.bottom
                        radius: 1
                        color: root.currentThemeAccent
                        opacity: 0.9
                        height: 4

                        SequentialAnimation on height {
                            loops: Animation.Infinite
                            running: root.isPlaying
                            NumberAnimation { to: 12 - index * 1.5; duration: 320 + index * 70; easing.type: Easing.InOutQuad }
                            NumberAnimation { to: 4 + index * 2; duration: 360 - index * 30; easing.type: Easing.InOutQuad }
                        }
                    }
                }
            }
        }
    }

    // Track progress, kept as a hairline so it never competes with the lyric.
    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.leftMargin: 14
        anchors.rightMargin: 14
        anchors.bottomMargin: 4
        height: 1.5
        radius: 0.75
        color: "#12FFFFFF"
        visible: root.trackLength > 0

        Rectangle {
            width: root.trackLength > 0
                ? parent.width * Math.min(1, Math.max(0, root.trackPosition / root.trackLength))
                : 0
            height: parent.height
            radius: parent.radius
            color: root.currentThemeAccent
            opacity: 0.55
        }
    }
}
