import QtQuick
import QtQuick.Layouts
import Quickshell

Item {
    anchors.fill: parent
    opacity: root.displayState === 4 ? 1 : 0
    visible: opacity > 0
    clip: true
    Behavior on opacity {
        NumberAnimation { duration: root.displayState === 4 ? 240 : 160; easing.type: Easing.OutCubic }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 6

        // Wallpaper Carousel
        ListView {
            id: wpListView
            property string hoveredWpName: ""
            property real scrollAcc: 0
            currentIndex: 0
            Layout.fillWidth: true
            Layout.fillHeight: true
            orientation: ListView.Horizontal
            spacing: 12
            clip: true
            model: wallpapersModel
            header: Item { width: 32; height: 1 }
            footer: Item { width: 32; height: 1 }
            preferredHighlightBegin: width / 2 - 80
            preferredHighlightEnd: width / 2 + 80
            highlightRangeMode: ListView.StrictlyEnforceRange

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
                width: (index === wpListView.currentIndex) ? 160 : 110
                height: ListView.view.height
                Behavior on width { NumberAnimation { duration: 250; easing.type: Easing.OutQuart } }

                property bool isSel: index === wpListView.currentIndex
                property bool isHov: wpArea.containsMouse

                Item {
                    anchors.centerIn: parent
                    width: parent.width
                    height: isSel ? parent.height - 20 : parent.height - 36
                    Behavior on height { NumberAnimation { duration: 250; easing.type: Easing.OutQuart } }

                    Rectangle {
                        id: wpCard
                        anchors.fill: parent
                        radius: 14
                        color: "#0F0F14"
                        clip: true

                        property real s: 1.0
                        transform: Scale { origin.x: wpCard.width/2; origin.y: wpCard.height/2; xScale: wpCard.s; yScale: wpCard.s }
                        Behavior on s { NumberAnimation { duration: 220; easing.type: Easing.OutBack } }

                        Image {
                            anchors.fill: parent
                            source: "file://" + model.path
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            cache: true
                            opacity: isSel ? 1.0 : (isHov ? 0.7 : 0.45)
                            Behavior on opacity { NumberAnimation { duration: 250 } }
                        }

                        // Bottom gradient for text
                        Rectangle {
                            anchors.bottom: parent.bottom
                            anchors.left: parent.left
                            anchors.right: parent.right
                            height: parent.height * 0.4
                            radius: 14
                            visible: isSel
                            gradient: Gradient {
                                GradientStop { position: 0.0; color: "transparent" }
                                GradientStop { position: 1.0; color: "#CC000000" }
                            }
                        }

                        // Selection glow border
                        Rectangle {
                            anchors.fill: parent
                            radius: 14
                            color: "transparent"
                            border.color: isSel ? "#55FFFFFF" : "transparent"
                            border.width: 1.5
                            Behavior on border.color { ColorAnimation { duration: 250 } }
                        }
                    }

                    // Accent underline
                    Rectangle {
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: -6
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: isSel ? 28 : 0
                        height: 2.5
                        radius: 1.25
                        color: "#3B82F6"
                        Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutQuart } }
                    }

                    MouseArea {
                        id: wpArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onPressed: wpCard.s = 0.92
                        onReleased: wpCard.s = 1.0
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

        // Filename label
        Text {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignHCenter
            horizontalAlignment: Text.AlignHCenter
            font.family: "Outfit"
            font.pixelSize: 11
            font.weight: Font.Medium
            color: "#888888"
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
