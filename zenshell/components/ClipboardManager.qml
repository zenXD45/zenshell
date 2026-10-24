import QtQuick.Controls
import QtQuick
import QtQuick.Layouts
import Quickshell
import Qt5Compat.GraphicalEffects

Item {
    id: clipboardRoot
    anchors.fill: parent
    property real reveal: root.displayState === 15 ? 1 : 0
    opacity: reveal
    visible: opacity > 0
    clip: true
    scale: 0.992 + reveal * 0.008
    transform: Translate { y: (1 - clipboardRoot.reveal) * 8 }

    Behavior on reveal {
        NumberAnimation {
            duration: root.displayState === 15 ? root.motionPanel : root.motionExit
            easing.type: root.displayState === 15 ? Easing.OutExpo : Easing.OutCubic
        }
    }

    property color accent: root.currentThemeAccent || root.themeAccent

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: root.s5
        spacing: 0

        // ── Toolbar ────────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 34
            spacing: root.s4

            Text {
                Layout.alignment: Qt.AlignVCenter
                text: "Clipboard"
                color: root.cFgPrimary
                font.family: root.fontSans
                font.pixelSize: 17
                font.weight: Font.DemiBold
                font.letterSpacing: -0.2
            }

            Item { Layout.fillWidth: true }

            Item {
                Layout.alignment: Qt.AlignVCenter
                Layout.preferredWidth: 260
                Layout.preferredHeight: 30

                Rectangle {
                    anchors.fill: parent
                    radius: 10
                    color: root.ink(0.055)
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: root.s3
                    anchors.rightMargin: root.s3
                    spacing: root.s2

                    Text {
                        Layout.alignment: Qt.AlignVCenter
                        text: "\uf002"
                        color: clipSearchInput.activeFocus ? accent : root.ink(0.45)
                        font.family: root.fontMono
                        font.pixelSize: 12
                        Behavior on color { ColorAnimation { duration: root.dMicro } }
                    }

                    TextInput {
                        id: clipSearchInput
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                        color: root.cFgPrimary
                        font.family: root.fontSans
                        font.pixelSize: 12
                        verticalAlignment: TextInput.AlignVCenter
                        clip: true
                        focus: root.displayState === 15
                        focusPolicy: Qt.StrongFocus
                        onTextChanged: {
                            root.filterClipboard(text);
                            clipListView.currentIndex = 0;
                        }
                        Keys.onEscapePressed: {
                            root.displayState = 0; root.updateState(); text = "";
                        }
                        Keys.onDownPressed: (event) => {
                            if (clipListView.currentIndex < clipboardModel.count - 1)
                                clipListView.currentIndex++;
                            event.accepted = true;
                        }
                        Keys.onUpPressed: (event) => {
                            if (clipListView.currentIndex > 0)
                                clipListView.currentIndex--;
                            event.accepted = true;
                        }
                        Keys.onReturnPressed: {
                            if (clipboardModel.count > 0) {
                                var targetIdx = (clipListView.currentIndex >= 0 && clipListView.currentIndex < clipboardModel.count) ? clipListView.currentIndex : 0;
                                var selectedItem = clipboardModel.get(targetIdx);
                                root.displayState = 0; root.updateState();
                                runCmd.command = ["python3", Quickshell.shellDir + "/scripts/get_clipboard.py", "decode", selectedItem.id];
                                runCmd.running = true;
                                text = "";
                            }
                        }

                        Text {
                            anchors.fill: parent
                            verticalAlignment: Text.AlignVCenter
                            text: "Search"
                            color: root.ink(0.32)
                            font.family: root.fontSans
                            font.pixelSize: 12
                            visible: !clipSearchInput.text
                        }
                    }

                    Text {
                        Layout.alignment: Qt.AlignVCenter
                        text: "esc"
                        color: root.ink(0.30)
                        font.family: root.fontMono
                        font.pixelSize: 10
                    }
                }
            }

            Text {
                Layout.alignment: Qt.AlignVCenter
                text: clipboardModel.count + (clipboardModel.count === 1 ? " clip" : " clips")
                color: root.ink(0.36)
                font.family: root.fontSans
                font.pixelSize: 11
            }
        }

        Item { Layout.preferredHeight: root.s4 }

        // ── History: one inset group of rows ───────────────────────
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            Rectangle {
                anchors.fill: parent
                radius: 14
                color: root.ink(0.055)
            }

            ListView {
                id: clipListView
                anchors.fill: parent
                anchors.margins: 4
                spacing: 0
                clip: true
                model: clipboardModel
                boundsBehavior: Flickable.StopAtBounds
                highlightMoveDuration: 0

                ScrollBar.vertical: ScrollBar {
                    policy: ScrollBar.AsNeeded
                    contentItem: Rectangle { implicitWidth: 2; radius: 1; color: root.ink(0.16) }
                }

                delegate: Item {
                    id: clipRow
                    width: clipListView.width
                    height: model.type === "image" ? 64 : 48

                    required property var model
                    required property int index

                    property bool isSel: clipListView.currentIndex === index

                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: 2
                        radius: 10
                        color: clipRow.isSel
                            ? root.ink(0.065)
                            : (rowHover.containsMouse ? root.ink(0.04) : "transparent")
                        Behavior on color { ColorAnimation { duration: root.dMicro } }
                    }

                    Rectangle {
                        visible: index < clipListView.count - 1
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        anchors.leftMargin: model.type === "image" ? 80 : 50
                        anchors.rightMargin: 16
                        height: 1
                        color: root.ink(0.07)
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: root.s5
                        anchors.rightMargin: root.s5
                        spacing: root.s3

                        // Images get a real preview; text keeps a quiet glyph.
                        Item {
                            Layout.alignment: Qt.AlignVCenter
                            Layout.preferredWidth: model.type === "image" ? 52 : 18
                            Layout.preferredHeight: model.type === "image" ? 40 : 18

                            Rectangle {
                                anchors.fill: parent
                                radius: 8
                                clip: true
                                color: root.ink(0.06)
                                visible: model.type === "image"

                                Image {
                                    id: thumb
                                    anchors.fill: parent
                                    source: model.image_path ? "file://" + model.image_path : ""
                                    sourceSize: Qt.size(208, 160)
                                    asynchronous: true
                                    cache: true
                                    fillMode: Image.PreserveAspectCrop
                                    visible: status === Image.Ready
                                }

                                Text {
                                    anchors.centerIn: parent
                                    visible: thumb.status !== Image.Ready
                                    text: "\uf03e"
                                    color: root.ink(0.40)
                                    font.family: root.fontMono
                                    font.pixelSize: 14
                                }
                            }

                            Text {
                                anchors.centerIn: parent
                                visible: model.type !== "image"
                                text: "\uf0c5"
                                color: clipRow.isSel ? root.cFgSecondary : root.ink(0.48)
                                font.family: root.fontMono
                                font.pixelSize: 13
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter
                            spacing: 2

                            Text {
                                Layout.fillWidth: true
                                text: model.type === "image" ? "Image" : model.content.replace(/\s+/g, " ").trim()
                                color: root.cFgPrimary
                                font.family: root.fontSans
                                font.pixelSize: 13
                                elide: Text.ElideRight
                                maximumLineCount: 1
                            }

                            Text {
                                Layout.fillWidth: true
                                visible: model.type === "image"
                                text: "Copy to clipboard"
                                color: root.ink(0.38)
                                font.family: root.fontSans
                                font.pixelSize: 11
                            }
                        }
                    }

                    MouseArea {
                        id: rowHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: clipListView.currentIndex = index
                        onClicked: {
                            clipListView.currentIndex = index;
                            root.displayState = 0; root.updateState();
                            runCmd.command = ["python3", Quickshell.shellDir + "/scripts/get_clipboard.py", "decode", model.id];
                            runCmd.running = true;
                            clipSearchInput.text = "";
                        }
                    }
                }
            }

            EmptyState {
                anchors.centerIn: parent
                visible: clipboardModel.count === 0
                title: clipSearchInput.text.length > 0 ? "No matches" : "Nothing copied yet"
                detail: clipSearchInput.text.length > 0 ? "" : "Clips appear here as you copy"
            }
        }
    }
}
