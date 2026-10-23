import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

Item {
    id: wallpaperRoot
    anchors.fill: parent
    property real reveal: root.displayState === 4 ? 1 : 0
    opacity: reveal
    visible: opacity > 0
    clip: true
    scale: 0.992 + reveal * 0.008
    transform: Translate { y: (1 - wallpaperRoot.reveal) * 8 }

    Behavior on reveal {
        NumberAnimation {
            duration: root.displayState === 4 ? root.motionPanel : root.motionExit
            easing.type: root.displayState === 4 ? Easing.OutExpo : Easing.OutCubic
        }
    }

    property string currentWallpaperPath: ""

    function syncCurrentWallpaper() {
        if (!currentWallpaperPath || wallpapersModel.count === 0) return;
        for (var i = 0; i < wallpapersModel.count; i++) {
            var item = wallpapersModel.get(i);
            if (item && item.path === currentWallpaperPath) {
                wpListView.currentIndex = i;
                wpListView.positionViewAtIndex(i, ListView.Center);
                return;
            }
        }
    }

    Process {
        id: currentWallpaperProc
        command: ["bash", "-c", "readlink -f \"$HOME/wallpapers/current\" 2>/dev/null"]
        stdout: SplitParser {
            onRead: data => {
                currentWallpaperPath = data.trim();
                syncCurrentWallpaper();
            }
        }
    }

    onVisibleChanged: {
        if (visible) {
            currentWallpaperProc.running = true;
            syncCurrentWallpaper();
            Qt.callLater(syncCurrentWallpaper);
        }
    }

    Connections {
        target: wallpapersModel
        function onCountChanged() {
            if (visible) syncCurrentWallpaper();
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 8

        MenuHeader {
            title: "Wallpapers"
            icon: "\uf03e"
            hint: "← →  ·  ↵ set"
            meta: wallpapersModel.count > 0 ? (wpListView.currentIndex + 1) + " / " + wallpapersModel.count : ""
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            ListView {
                id: wpListView
                anchors.fill: parent
                property string hoveredWpName: ""
                property real scrollAcc: 0
                currentIndex: 0
                orientation: ListView.Horizontal
                spacing: 12
                clip: true
                model: wallpapersModel
                header: Item { width: Math.max(32, (wpListView.width - 180) / 2); height: 1 }
                footer: Item { width: Math.max(32, (wpListView.width - 180) / 2); height: 1 }
                preferredHighlightBegin: width / 2 - 90
                preferredHighlightEnd: width / 2 + 90
                highlightRangeMode: ListView.StrictlyEnforceRange
                highlightMoveDuration: 260

                focus: root.displayState === 4

                Timer {
                    interval: 50
                    running: root.displayState === 4
                    onTriggered: wpListView.forceActiveFocus()
                }

                Keys.onEscapePressed: { root.displayState = 0; root.updateState(); }
                Keys.onLeftPressed: (event) => {
                    if (wpListView.currentIndex > 0) { wpListView.currentIndex--; wpListView.positionViewAtIndex(wpListView.currentIndex, ListView.Center); }
                    event.accepted = true;
                }
                Keys.onRightPressed: (event) => {
                    if (wpListView.currentIndex < wallpapersModel.count - 1) { wpListView.currentIndex++; wpListView.positionViewAtIndex(wpListView.currentIndex, ListView.Center); }
                    event.accepted = true;
                }
                Keys.onReturnPressed: {
                    if (wallpapersModel.count > 0) {
                        var targetIdx = (wpListView.currentIndex >= 0 && wpListView.currentIndex < wallpapersModel.count) ? wpListView.currentIndex : 0;
                        var selectedWp = wallpapersModel.get(targetIdx);
                        root.displayState = 0; root.updateState();
                        // Go through wallpaper-selector.sh rather than calling awww
                        // directly, exactly like the click handler below. Calling awww
                        // raw skipped updating ~/wallpapers/current, so the matugen /
                        // pywal theming and the hyprlock background never picked up the
                        // change — Enter and click behaved differently.
                        runCmd.command = ["bash", Quickshell.env("HOME") + "/scripts/wallpaper-selector.sh", selectedWp.path];
                        runCmd.running = true;
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    propagateComposedEvents: true
                    onWheel: (wheel) => {
                        var delta = (wheel.angleDelta.y !== 0 ? wheel.angleDelta.y : wheel.angleDelta.x);
                        wpListView.scrollAcc += delta;
                        if (Math.abs(wpListView.scrollAcc) >= 60) {
                            if (wpListView.scrollAcc < 0 && wpListView.currentIndex < wallpapersModel.count - 1) wpListView.currentIndex++;
                            else if (wpListView.scrollAcc > 0 && wpListView.currentIndex > 0) wpListView.currentIndex--;
                            wpListView.positionViewAtIndex(wpListView.currentIndex, ListView.Center);
                            wpListView.scrollAcc = 0;
                        }
                    }
                }

                delegate: Item {
                    id: wpCardItem
                    width: (index === wpListView.currentIndex) ? 180 : 118
                    height: ListView.view.height
                    opacity: Math.max(0, Math.min(1, (wallpaperRoot.reveal - 0.05 - Math.min(index, 4) * 0.04) / 0.70))
                    transform: Translate { y: (1 - wpCardItem.opacity) * 10 }
                    Behavior on width { NumberAnimation { duration: 260; easing.type: Easing.OutQuart } }

                    property bool isSel: index === wpListView.currentIndex
                    property bool isHov: wpArea.containsMouse

                    Item {
                        anchors.centerIn: parent
                        width: parent.width
                        height: isSel ? parent.height - 8 : parent.height - 24
                        Behavior on height { NumberAnimation { duration: 260; easing.type: Easing.OutQuart } }

                        Rectangle {
                            id: wpCard
                            anchors.fill: parent
                            radius: 14
                            color: root.themeBg
                            clip: true
                            border.width: isSel ? 1.5 : 1
                            border.color: isSel
                                ? Qt.rgba(root.themeAccent.r, root.themeAccent.g, root.themeAccent.b, 0.55)
                                : (isHov ? root.ink(0.149) : root.ink(0.071))
                            Behavior on border.color { ColorAnimation { duration: 180 } }

                            property real press: 1.0
                            transform: Scale {
                                origin.x: wpCard.width / 2
                                origin.y: wpCard.height / 2
                                xScale: wpCard.press
                                yScale: wpCard.press
                            }
                            Behavior on press { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }

                            Image {
                                anchors.fill: parent
                                source: "file://" + model.path
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                                cache: true
                                opacity: isSel ? 1.0 : (isHov ? 0.78 : 0.48)
                                Behavior on opacity { NumberAnimation { duration: 200 } }
                            }

                            // A soft floor keeps the crop from ending abruptly
                            // against the rounded corners on bright images.
                            Rectangle {
                                anchors.bottom: parent.bottom
                                anchors.left: parent.left
                                anchors.right: parent.right
                                height: parent.height * 0.32
                                visible: isSel
                                gradient: Gradient {
                                    GradientStop { position: 0.0; color: "transparent" }
                                    GradientStop { position: 1.0; color: "#B3000000" }
                                }
                            }
                        }

                        MouseArea {
                            id: wpArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onPressed: wpCard.press = 0.95
                            onReleased: wpCard.press = 1.0
                            onEntered: wpListView.hoveredWpName = model.name || model.filename
                            onExited: { if (wpListView.hoveredWpName === (model.name || model.filename)) wpListView.hoveredWpName = "" }
                            onClicked: {
                                root.displayState = 0; root.updateState();
                                runCmd.command = ["bash", Quickshell.env("HOME") + "/scripts/wallpaper-selector.sh", model.path];
                                runCmd.running = true;
                            }
                        }
                    }
                }
            }

            Rectangle {
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: 18
                z: 2
                visible: wallpapersModel.count > 0
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: root.glass(0.9) }
                    GradientStop { position: 1.0; color: "transparent" }
                }
            }
            Rectangle {
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: 18
                z: 2
                visible: wallpapersModel.count > 0
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: "transparent" }
                    GradientStop { position: 1.0; color: root.glass(0.9) }
                }
            }

            Column {
                anchors.centerIn: parent
                spacing: 8
                visible: wallpapersModel.count === 0

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "\uf03e"
                    color: root.ink(0.439)
                    font.family: root.font
                    font.pixelSize: 22
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "No wallpapers found"
                    color: root.uiFgDim
                    font.family: root.uiFont
                    font.pixelSize: 11
                    font.weight: Font.Medium
                }
            }
        }

        Text {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredHeight: 14
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            font.family: root.uiFont
            font.pixelSize: 10
            font.weight: Font.Medium
            color: root.uiFgDim
            elide: Text.ElideMiddle
            text: {
                if (wpListView.hoveredWpName && wpListView.hoveredWpName !== "") return wpListView.hoveredWpName;
                if (wallpapersModel && wallpapersModel.count > 0) {
                    var idx = (wpListView.currentIndex >= 0 && wpListView.currentIndex < wallpapersModel.count) ? wpListView.currentIndex : 0;
                    var item = wallpapersModel.get(idx);
                    if (item && item.name) return item.name;
                    if (item && item.filename) return item.filename;
                }
                return "";
            }
        }
    }
}
