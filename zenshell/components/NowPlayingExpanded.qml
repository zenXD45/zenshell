import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects

Item {
    id: expandedRoot
    anchors.fill: parent
    property real reveal: (root.displayState === 1 && root.isExpanded) ? 1 : 0
    opacity: reveal
    visible: opacity > 0
    scale: 0.994 + reveal * 0.006
    transform: Translate { y: (1 - expandedRoot.reveal) * 6 }

    Behavior on reveal {
        NumberAnimation {
            duration: (root.displayState === 1 && root.isExpanded) ? root.motionPanel : root.motionExit
            easing.type: (root.displayState === 1 && root.isExpanded) ? Easing.OutExpo : Easing.OutCubic
        }
    }

    // Click anywhere that isn't a transport button to fold the player back
    // into the lyric pill.
    MouseArea {
        anchors.fill: parent
        z: -1
        cursorShape: Qt.PointingHandCursor
        onClicked: root.isExpanded = false
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: root.s5
        spacing: root.s5

        // ── Vinyl ────────────────────────────────────────────────
        Item {
            id: vinyl
            Layout.preferredWidth: 140
            Layout.preferredHeight: 140
            Layout.alignment: Qt.AlignVCenter

            NumberAnimation on rotation {
                from: 0; to: 360; duration: 8000
                loops: Animation.Infinite
                running: root.isPlaying && root.isExpanded
            }

            Rectangle {
                anchors.fill: parent
                radius: width / 2
                color: root.cBgPrimary
                border.color: root.ink(0.149)
                border.width: 1
            }

            Repeater {
                model: 12
                Rectangle {
                    anchors.centerIn: parent
                    width: parent.width * (0.15 + (index * 0.055))
                    height: width
                    radius: width / 2
                    color: "transparent"
                    border.color: root.ink(0.102)
                    border.width: 1
                }
            }

            // Circular album-art label. The mask is hidden; only its shape
            // is used to clip the artwork into the centre of the record.
            Rectangle {
                id: artMask
                anchors.centerIn: parent
                width: parent.width * 0.4
                height: width
                radius: width / 2
                visible: false
            }

            Image {
                id: artImg
                anchors.fill: artMask
                source: root.artUrl
                fillMode: Image.PreserveAspectCrop
                visible: false
            }

            OpacityMask {
                anchors.fill: artMask
                source: artImg
                maskSource: artMask
            }

            Text {
                anchors.centerIn: parent
                text: "\uf001"
                color: root.ink(0.4)
                font.family: root.fontMono
                font.pixelSize: 18
                visible: artImg.status !== Image.Ready
            }

            Rectangle {
                anchors.centerIn: parent
                width: 8; height: 8
                radius: 4
                color: "#000000"
            }
        }

        // ── Track + transport ────────────────────────────────────
        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 4

            Text {
                Layout.fillWidth: true
                text: root.trackTitle || "Nothing Playing"
                color: root.cFgPrimary
                font.family: root.fontSans
                font.pixelSize: root.tH2[0]
                font.weight: root.tH2[2]
                font.letterSpacing: root.tH2[3]
                elide: Text.ElideRight
            }

            Text {
                Layout.fillWidth: true
                text: root.trackArtist || "Unknown"
                color: root.cFgMuted
                font.family: root.fontSans
                font.pixelSize: root.tBody[0]
                elide: Text.ElideRight
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: root.s4
                spacing: root.s5

                Rectangle {
                    id: prevBtn
                    width: 38; height: 38; radius: 19
                    color: prevArea.containsMouse ? root.ink(0.08) : "transparent"
                    property real btnScale: 1.0
                    transform: Scale { origin.x: 19; origin.y: 19; xScale: prevBtn.btnScale; yScale: prevBtn.btnScale }
                    Behavior on btnScale { NumberAnimation { duration: root.dFast; easing.type: Easing.OutBack } }
                    Text { anchors.centerIn: parent; text: "\uf04a"; color: root.cFgPrimary; font.family: root.fontMono; font.pixelSize: 18 }
                    MouseArea {
                        id: prevArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onPressed: prevBtn.btnScale = 0.88; onReleased: prevBtn.btnScale = 1.0; onClicked: root.prevTrack()
                    }
                }

                Rectangle {
                    id: playBtn
                    width: 48; height: 48; radius: 24
                    color: root.cFgPrimary
                    property real btnScale: 1.0
                    transform: Scale { origin.x: 24; origin.y: 24; xScale: playBtn.btnScale; yScale: playBtn.btnScale }
                    Behavior on btnScale { NumberAnimation { duration: root.dFast; easing.type: Easing.OutBack } }
                    Text { anchors.centerIn: parent; text: root.isPlaying ? "\uf04c" : "\uf04b"; color: root.onAccent(); font.family: root.fontMono; font.pixelSize: 20 }
                    MouseArea {
                        anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onPressed: playBtn.btnScale = 0.88; onReleased: playBtn.btnScale = 1.0; onClicked: root.playPause()
                    }
                }

                Rectangle {
                    id: nextBtn
                    width: 38; height: 38; radius: 19
                    color: nextArea.containsMouse ? root.ink(0.08) : "transparent"
                    property real btnScale: 1.0
                    transform: Scale { origin.x: 19; origin.y: 19; xScale: nextBtn.btnScale; yScale: nextBtn.btnScale }
                    Behavior on btnScale { NumberAnimation { duration: root.dFast; easing.type: Easing.OutBack } }
                    Text { anchors.centerIn: parent; text: "\uf04e"; color: root.cFgPrimary; font.family: root.fontMono; font.pixelSize: 18 }
                    MouseArea {
                        id: nextArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onPressed: nextBtn.btnScale = 0.88; onReleased: nextBtn.btnScale = 1.0; onClicked: root.nextTrack()
                    }
                }
            }
        }
    }
}
