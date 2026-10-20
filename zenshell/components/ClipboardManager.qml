import QtQuick
import QtQuick.Layouts
import Quickshell
import Qt5Compat.GraphicalEffects

Item {
    anchors.fill: parent
    opacity: root.displayState === 15 ? 1 : 0
    visible: opacity > 0
    clip: true
    Behavior on opacity {
        NumberAnimation { duration: root.displayState === 15 ? 240 : 160; easing.type: Easing.OutCubic }
    }

    property color accent: root.currentThemeAccent || "#838996"

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 12

        // ── Toolbar: identity, search, count ────────────────────────
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 32
            spacing: 9

            Rectangle {
                Layout.alignment: Qt.AlignVCenter
                width: 28
                height: 28
                radius: 9
                color: Qt.rgba(accent.r, accent.g, accent.b, 0.14)
                border.width: 1
                border.color: Qt.rgba(accent.r, accent.g, accent.b, 0.26)

                Text {
                    anchors.centerIn: parent
                    text: "\uf0c5"
                    color: accent
                    font.family: root.font
                    font.pixelSize: 12
                }
            }

            Text {
                Layout.alignment: Qt.AlignVCenter
                text: "Clipboard"
                color: root.uiFg
                font.family: root.uiFont
                font.pixelSize: 14
                font.weight: Font.DemiBold
                font.letterSpacing: 0.1
            }

            Item { Layout.fillWidth: true }

            Rectangle {
                Layout.alignment: Qt.AlignVCenter
                width: 320
                height: 32
                radius: 16
                color: "#0AFFFFFF"
                border.width: 1
                border.color: clipSearchInput.activeFocus
                    ? Qt.rgba(accent.r, accent.g, accent.b, 0.45)
                    : "#16FFFFFF"
                Behavior on border.color { ColorAnimation { duration: 150 } }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 13
                    anchors.rightMargin: 13
                    spacing: 8

                    Text {
                        text: "\uf002"
                        color: clipSearchInput.activeFocus ? accent : "#80FFFFFF"
                        font.family: root.font
                        font.pixelSize: 11
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }

                    TextInput {
                        id: clipSearchInput
                        Layout.fillWidth: true
                        color: root.uiFg
                        font.family: root.uiFont
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
                        Keys.onLeftPressed: (event) => {
                            if (clipListView.currentIndex > 0) {
                                clipListView.currentIndex--;
                                clipListView.positionViewAtIndex(clipListView.currentIndex, ListView.Contain);
                            }
                            event.accepted = true;
                        }
                        Keys.onRightPressed: (event) => {
                            if (clipListView.currentIndex < clipboardModel.count - 1) {
                                clipListView.currentIndex++;
                                clipListView.positionViewAtIndex(clipListView.currentIndex, ListView.Contain);
                            }
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
                            text: "Search clipboard"
                            color: "#80FFFFFF"
                            font.family: root.uiFont
                            font.pixelSize: 12
                            visible: !clipSearchInput.text
                        }
                    }
                }
            }

            Rectangle {
                Layout.alignment: Qt.AlignVCenter
                height: 20
                implicitWidth: clipCount.implicitWidth + 14
                radius: 10
                color: Qt.rgba(accent.r, accent.g, accent.b, 0.10)
                border.width: 1
                border.color: Qt.rgba(accent.r, accent.g, accent.b, 0.22)

                Text {
                    id: clipCount
                    anchors.centerIn: parent
                    text: clipboardModel.count + (clipboardModel.count === 1 ? " clip" : " clips")
                    color: root.uiFgDim
                    font.family: root.uiFont
                    font.pixelSize: 9
                    font.weight: Font.Medium
                }
            }

            Text {
                Layout.alignment: Qt.AlignVCenter
                text: "esc"
                color: "#80FFFFFF"
                font.family: root.uiFont
                font.pixelSize: 9
                font.weight: Font.Medium
            }
        }

        // ── Clipboard history ───────────────────────────────────────
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            ListView {
                id: clipListView
                anchors.fill: parent
                property string hoveredItemId: ""
                orientation: ListView.Horizontal
                spacing: 8
                clip: true
                model: clipboardModel
                highlightMoveDuration: 200

                delegate: Rectangle {
                    id: clipCard
                    width: 142
                    height: clipListView.height - 8
                    radius: 14
                    color: clipListView.currentIndex === index
                        ? Qt.rgba(accent.r, accent.g, accent.b, 0.10)
                        : (clipListView.hoveredItemId === model.id ? "#0AFFFFFF" : "#05FFFFFF")
                    border.color: clipListView.currentIndex === index
                        ? Qt.rgba(accent.r, accent.g, accent.b, 0.45)
                        : (clipListView.hoveredItemId === model.id ? "#1CFFFFFF" : "#0EFFFFFF")
                    border.width: 1
                    Behavior on color { ColorAnimation { duration: 150 } }
                    Behavior on border.color { ColorAnimation { duration: 150 } }

                    property bool isSel: clipListView.currentIndex === index
                    property bool isHov: clipListView.hoveredItemId === model.id

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 6

                        Item {
                            Layout.alignment: Qt.AlignHCenter
                            Layout.preferredWidth: model.type === "image" ? 64 : 36
                            Layout.preferredHeight: model.type === "image" ? 64 : 36

                            Rectangle {
                                anchors.fill: parent
                                radius: 18
                                color: clipCard.isSel
                                    ? Qt.rgba(accent.r, accent.g, accent.b, 0.14)
                                    : "#12FFFFFF"
                                visible: model.type !== "image"

                                Text {
                                    anchors.centerIn: parent
                                    text: "\uf0c5"
                                    color: clipCard.isSel ? accent : "#B0FFFFFF"
                                    font.family: root.font
                                    font.pixelSize: 16
                                }
                            }

                            Rectangle {
                                id: maskRect
                                anchors.fill: parent
                                radius: 8
                                visible: false
                            }

                            Image {
                                anchors.fill: parent
                                source: model.type === "image" ? ("file://" + model.image_path) : ""
                                fillMode: Image.PreserveAspectCrop
                                visible: model.type === "image"
                                layer.enabled: true
                                layer.effect: OpacityMask {
                                    maskSource: maskRect
                                }
                            }
                        }

                        Text {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            text: model.type === "image" ? "Image" : model.content
                            color: clipCard.isSel || clipCard.isHov ? root.uiFg : root.uiFgDim
                            font.family: root.uiFont
                            font.pixelSize: 12
                            font.weight: Font.Medium
                            horizontalAlignment: Text.AlignHCenter
                            wrapMode: Text.Wrap
                            elide: Text.ElideRight
                            maximumLineCount: model.type === "image" ? 1 : 3
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }
                    }

                    Rectangle {
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 6
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: clipCard.isSel ? 18 : 0
                        height: 2
                        radius: 1
                        color: accent
                        Behavior on width { NumberAnimation { duration: 220; easing.type: Easing.OutQuart } }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: clipListView.hoveredItemId = model.id
                        onExited: if (clipListView.hoveredItemId === model.id) clipListView.hoveredItemId = ""
                        onClicked: {
                            clipListView.currentIndex = index;
                            clipSearchInput.forceActiveFocus();
                            root.displayState = 0; root.updateState();
                            runCmd.command = ["python3", Quickshell.shellDir + "/scripts/get_clipboard.py", "decode", model.id];
                            runCmd.running = true;
                            clipSearchInput.text = "";
                        }
                    }
                }
            }

            Column {
                anchors.centerIn: parent
                spacing: 8
                visible: clipboardModel.count === 0

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "\uf0c5"
                    color: "#70FFFFFF"
                    font.family: root.font
                    font.pixelSize: 22
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: clipSearchInput.text.length > 0 ? "No matches" : "No clipboard history"
                    color: root.uiFgDim
                    font.family: root.uiFont
                    font.pixelSize: 11
                    font.weight: Font.Medium
                }
            }
        }
    }
}
