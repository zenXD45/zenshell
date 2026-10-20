import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects

Item {
    anchors.fill: parent
    opacity: (root.displayState === 1 && root.isExpanded) ? 1 : 0
    visible: opacity > 0

    Behavior on opacity { NumberAnimation { duration: (root.displayState === 1 && root.isExpanded) ? 240 : 160; easing.type: Easing.OutCubic } }

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
        anchors.margins: 18
        spacing: 18

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
                color: "#101012"
                border.color: "#26FFFFFF"
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
                    border.color: "#1AFFFFFF"
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
                color: "#66FFFFFF"
                font.family: root.font
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
                color: "#FFFFFF"
                font.family: root.uiFont
                font.pixelSize: 18
                font.bold: true
                elide: Text.ElideRight
            }

            Text {
                Layout.fillWidth: true
                text: root.trackArtist || "Unknown"
                color: "#99FFFFFF"
                font.family: root.uiFont
                font.pixelSize: 14
                elide: Text.ElideRight
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: 14
                spacing: 16

                Rectangle {
                    id: prevBtn
                    width: 38; height: 38; radius: 19
                    color: prevArea.containsMouse ? "#22FFFFFF" : "transparent"
                    property real btnScale: 1.0
                    transform: Scale { origin.x: 19; origin.y: 19; xScale: prevBtn.btnScale; yScale: prevBtn.btnScale }
                    Behavior on btnScale { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }
                    Text { anchors.centerIn: parent; text: "\uf04a"; color: "#FFFFFF"; font.family: root.font; font.pixelSize: 18 }
                    MouseArea {
                        id: prevArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onPressed: prevBtn.btnScale = 0.88; onReleased: prevBtn.btnScale = 1.0; onClicked: root.prevTrack()
                    }
                }

                Rectangle {
                    id: playBtn
                    width: 48; height: 48; radius: 24
                    color: "#FFFFFF"
                    property real btnScale: 1.0
                    transform: Scale { origin.x: 24; origin.y: 24; xScale: playBtn.btnScale; yScale: playBtn.btnScale }
                    Behavior on btnScale { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }
                    Text { anchors.centerIn: parent; text: root.isPlaying ? "\uf04c" : "\uf04b"; color: "#0D0D11"; font.family: root.font; font.pixelSize: 20 }
                    MouseArea {
                        anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onPressed: playBtn.btnScale = 0.88; onReleased: playBtn.btnScale = 1.0; onClicked: root.playPause()
                    }
                }

                Rectangle {
                    id: nextBtn
                    width: 38; height: 38; radius: 19
                    color: nextArea.containsMouse ? "#22FFFFFF" : "transparent"
                    property real btnScale: 1.0
                    transform: Scale { origin.x: 19; origin.y: 19; xScale: nextBtn.btnScale; yScale: nextBtn.btnScale }
                    Behavior on btnScale { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }
                    Text { anchors.centerIn: parent; text: "\uf04e"; color: "#FFFFFF"; font.family: root.font; font.pixelSize: 18 }
                    MouseArea {
                        id: nextArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onPressed: nextBtn.btnScale = 0.88; onReleased: nextBtn.btnScale = 1.0; onClicked: root.nextTrack()
                    }
                }
            }
        }
    }
}
