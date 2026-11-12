import QtQuick.Controls
import QtQuick
import QtQuick.Layouts
import Quickshell
import Qt5Compat.GraphicalEffects

Item {
    id: clipboardRoot
    anchors.fill: parent
    property bool entered: false
    property real reveal: (root.displayState === 15 && entered) ? 1 : 0
    opacity: reveal
    visible: opacity > 0
    transform: Translate { y: (1 - clipboardRoot.reveal) * 6 }

    Behavior on reveal {
        NumberAnimation {
            duration: root.displayState === 15 ? root.motionPanel : root.motionExit
            easing.type: Easing.OutCubic
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
            Layout.preferredHeight: 48
            spacing: root.s4

            Text {
                Layout.alignment: Qt.AlignVCenter
                text: "Clipboard"
                color: root.cOnSurface
                font.family: root.fontSans
                font.pixelSize: 16
                font.weight: Font.DemiBold
            }

            Item { Layout.fillWidth: true }

            Item {
                Layout.alignment: Qt.AlignVCenter
                Layout.preferredWidth: 268
                Layout.preferredHeight: 40

                Rectangle {
                    anchors.fill: parent
                    radius: 20
                    color: root.cSurfaceContainerHigh
                    border.width: clipSearchInput.activeFocus ? 2 : 0
                    border.color: root.cPrimary
                    Behavior on color { ColorAnimation { duration: root.dMicro } }
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 14
                    anchors.rightMargin: 8
                    spacing: root.s3

                    Text {
                        Layout.alignment: Qt.AlignVCenter
                        text: root.icoSearch
                        color: clipSearchInput.activeFocus ? root.cPrimary : root.cOnSurfaceVariant
                        font.family: root.fontIcon
                        font.pixelSize: 19
                        Behavior on color { ColorAnimation { duration: root.dMicro } }
                    }

                    TextInput {
                        id: clipSearchInput
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                        color: root.cOnSurface
                        font.family: root.fontSans
                        font.pixelSize: 13
                        verticalAlignment: TextInput.AlignVCenter
                        padding: 0
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
                            color: root.cOnSurfaceVariant
                            opacity: 0.72
                            font.family: root.fontSans
                            font.pixelSize: 13
                            visible: !clipSearchInput.text
                        }
                    }

                    Rectangle {
                        Layout.alignment: Qt.AlignVCenter
                        width: 28
                        height: 20
                        radius: 6
                        color: root.cSurfaceContainerHighest
                        border.width: 1
                        border.color: root.cOutlineVariant

                        Text {
                            anchors.centerIn: parent
                            text: "esc"
                            color: root.cOnSurfaceVariant
                            font.family: root.fontMono
                            font.pixelSize: 9
                        }
                    }
                }
            }

            Text {
                Layout.alignment: Qt.AlignVCenter
                text: clipboardModel.count + (clipboardModel.count === 1 ? " clip" : " clips")
                color: root.cOnSurfaceVariant
                font.family: root.fontSans
                font.pixelSize: 12
            }
        }

        Item { Layout.preferredHeight: root.s4 }

        // ── History: one inset group of rows ───────────────────────
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            Rectangle {
                anchors.fill: parent
                radius: root.rLg
                color: root.cSurfaceContainerLow
                border.width: 1
                border.color: root.cOutlineVariant
            }

            ListView {
                id: clipListView
                anchors.fill: parent
                anchors.margins: 4
                spacing: root.s1
                clip: true
                model: clipboardModel
                boundsBehavior: Flickable.StopAtBounds
                highlightMoveDuration: 0

                ScrollBar.vertical: ScrollBar {
                    policy: ScrollBar.AsNeeded
                    contentItem: Rectangle { implicitWidth: 2; radius: 1; color: root.cOutline }
                }

                delegate: Item {
                    id: clipRow
                    width: clipListView.width
                    height: model.type === "image" ? 68 : 52

                    required property var model
                    required property int index

                    property bool isSel: clipListView.currentIndex === index

                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: 2
                        radius: root.rMd
                        color: clipRow.isSel
                            ? root.cSecondaryContainer
                            : (rowHover.containsMouse ? root.cStateHover : "transparent")
                        Behavior on color { ColorAnimation { duration: root.dMicro } }
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 16
                        anchors.rightMargin: 16
                        spacing: root.s4

                        // Images get a real preview; text keeps a quiet glyph.
                        Item {
                            Layout.alignment: Qt.AlignVCenter
                            Layout.preferredWidth: model.type === "image" ? 52 : 18
                            Layout.preferredHeight: model.type === "image" ? 40 : 18

                            Rectangle {
                                anchors.fill: parent
                                radius: 8
                                clip: true
                                color: root.cSurfaceContainerHigh
                                border.width: 1
                                border.color: root.cOutlineVariant
                                visible: model.type === "image"

                                Image {
                                    id: thumb
                                    anchors.fill: parent
                                    source: model.image_path ? "file://" + model.image_path : ""
                                    sourceSize: Qt.size(208, 160)
                                    asynchronous: true
                                    cache: false
                                    fillMode: Image.PreserveAspectCrop
                                    visible: status === Image.Ready
                                }

                                Text {
                                    anchors.centerIn: parent
                                    visible: thumb.status !== Image.Ready
                                    text: "\uf03e"
                                    color: root.cOnSurfaceVariant
                                    font.family: root.fontMono
                                    font.pixelSize: 14
                                }
                            }

                            Text {
                                anchors.centerIn: parent
                                visible: model.type !== "image"
                                text: "\uf0c5"
                                color: clipRow.isSel ? root.cOnSecondaryContainer : root.cOnSurfaceVariant
                                font.family: root.fontMono
                                font.pixelSize: 14
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter
                            spacing: 1

                            Text {
                                Layout.fillWidth: true
                                text: model.type === "image" ? "Image" : model.content.replace(/\s+/g, " ").trim()
                                color: root.cOnSurface
                                font.family: root.fontSans
                                font.pixelSize: 14
                                font.weight: clipRow.isSel ? Font.DemiBold : Font.Medium
                                elide: Text.ElideRight
                                maximumLineCount: 1
                            }

                            Text {
                                Layout.fillWidth: true
                                visible: model.type === "image"
                                text: "Copy to clipboard"
                                color: root.cOnSurfaceVariant
                                font.family: root.fontSans
                                font.pixelSize: 12
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
                icon: clipSearchInput.text.length > 0 ? root.icoSearchOff : ""
                title: clipSearchInput.text.length > 0 ? "No matches" : "Nothing copied yet"
                detail: clipSearchInput.text.length > 0 ? "Try a shorter phrase" : "Clips appear here as you copy"
            }
        }
    }
}
