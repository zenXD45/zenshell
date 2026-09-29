import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

Item {
    anchors.fill: parent
    opacity: root.displayState === 3 ? 1 : 0
    visible: opacity > 0
    clip: true
    Behavior on opacity {
        NumberAnimation { duration: root.displayState === 3 ? 240 : 160; easing.type: Easing.OutCubic }
    }

    // ── Actions ─────────────────────────────────────────────────
    function runSearch() {
        searchProc.command = ["python3", Quickshell.env("HOME") + "/.config/quickshell/dynamic-island/scripts/get_search.py", searchInput.text.trim()];
        searchProc.running = true;
    }

    function shellQuote(s) {
        return "'" + String(s).replace(/'/g, "'\\''") + "'";
    }

    function launchEntry(modelItem) {
        root.displayState = 0; root.updateState();
        searchInput.text = "";
        if (modelItem.kind === "calc") {
            copyProc.command = ["bash", "-c", "printf %s " + shellQuote(modelItem.result) + " | wl-copy -n"];
            copyProc.running = true;
        } else if (modelItem.kind === "file") {
            runCmd.command = ["bash", "-c", "xdg-open " + shellQuote(modelItem.path) + " > /dev/null 2>&1 &"];
            runCmd.running = true;
        } else {
            runCmd.command = ["bash", "-c", "gtk-launch " + modelItem.exec + " > /dev/null 2>&1 || " + modelItem.exec + " > /dev/null 2>&1 &"];
            runCmd.running = true;
        }
    }

    // ── Search process (debounced) ───────────────────────────────
    ListModel { id: searchModel }

    Process {
        id: searchProc
        stdout: SplitParser {
            onRead: data => {
                try {
                    var results = JSON.parse(data);
                    searchModel.clear();
                    for (var i = 0; i < results.length; i++) searchModel.append(results[i]);
                    resultList.currentIndex = 0;
                } catch(e) {
                    searchModel.clear();
                }
            }
        }
    }

    Process {
        id: copyProc
    }

    Timer {
        id: debounce
        interval: 180
        onTriggered: runSearch()
    }

    Component.onCompleted: runSearch()

    // ── Layout ───────────────────────────────────────────────────
    ColumnLayout {
        width: 740
        height: parent.height - 8
        anchors.top: parent.top
        anchors.topMargin: 8
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 12

        // ── Search Bar ──
        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: 520
            Layout.preferredHeight: 32
            radius: 16
            color: "#0AFFFFFF"

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 14
                anchors.rightMargin: 14
                spacing: 8

                Text {
                    text: "\uf002"
                    color: "#44411"
                    font.family: root.font
                    font.pixelSize: 12
                }
                TextInput {
                    id: searchInput
                    Layout.fillWidth: true
                    color: "#EEEEF0"
                    font.family: "Outfit"
                    font.pixelSize: 12
                    verticalAlignment: TextInput.AlignVCenter
                    clip: true
                    focus: root.displayState === 3
                    focusPolicy: Qt.StrongFocus
                    selectByMouse: true
                    onTextChanged: {
                        debounce.restart();
                    }
                    Keys.onEscapePressed: {
                        root.displayState = 0; root.updateState(); text = "";
                    }
                    Keys.onReturnPressed: {
                        if (searchModel.count > 0) {
                            var targetIdx = (resultList.currentIndex >= 0 && resultList.currentIndex < searchModel.count) ? resultList.currentIndex : 0;
                            launchEntry(searchModel.get(targetIdx));
                        }
                    }
                    Keys.onUpPressed: (event) => {
                        if (resultList.currentIndex > 0) {
                            resultList.currentIndex--;
                            resultList.positionViewAtIndex(resultList.currentIndex, ListView.Contain);
                        }
                        event.accepted = true;
                    }
                    Keys.onDownPressed: (event) => {
                        if (resultList.currentIndex < searchModel.count - 1) {
                            resultList.currentIndex++;
                            resultList.positionViewAtIndex(resultList.currentIndex, ListView.Contain);
                        }
                        event.accepted = true;
                    }
                    Keys.onLeftPressed: (event) => {
                        if (resultList.currentIndex > 0) {
                            resultList.currentIndex--;
                            resultList.positionViewAtIndex(resultList.currentIndex, ListView.Contain);
                        }
                        event.accepted = true;
                    }
                    Keys.onRightPressed: (event) => {
                        if (resultList.currentIndex < searchModel.count - 1) {
                            resultList.currentIndex++;
                            resultList.positionViewAtIndex(resultList.currentIndex, ListView.Contain);
                        }
                        event.accepted = true;
                    }

                    Text {
                        anchors.fill: parent
                        verticalAlignment: Text.AlignVCenter
                        text: "Search apps, files, and solve math\u2026"
                        color: "#333338"
                        font.family: "Outfit"
                        font.pixelSize: 12
                        visible: !searchInput.text && !searchInput.activeFocus
                    }
                }
            }
        }

        // ── Results ──
        ListView {
            id: resultList
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 8
            clip: true
            model: searchModel
            boundsBehavior: Flickable.StopAtBounds

            delegate: Item {
                width: resultList.width
                height: 54

                property bool isSel: index === resultList.currentIndex
                property bool isHov: rowArea.containsMouse

                Rectangle {
                    anchors.fill: parent
                    radius: 16
                    color: isSel ? "#1AFFFFFF" : (isHov ? "#12FFFFFF" : "#0AFFFFFF")
                    border.color: isSel ? "#44FFFFFF" : "transparent"
                    border.width: 1
                    Behavior on color { ColorAnimation { duration: 150 } }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 16
                        spacing: 14

                        // Icon box
                        Rectangle {
                            Layout.preferredWidth: 44
                            Layout.preferredHeight: 44
                            Layout.alignment: Qt.AlignVCenter
                            radius: 14
                            color: "#15FFFFFF"

                            Image {
                                id: rowIcon
                                anchors.centerIn: parent
                                width: 26
                                height: 26
                                source: (model.icon && model.icon.startsWith("/")) ? "file://" + model.icon : (model.icon ? "image://icon/" + model.icon : "")
                                sourceSize: Qt.size(44, 44)
                                asynchronous: true
                                visible: model.kind !== "calc" && rowIcon.status !== Image.Error && model.name !== ""
                            }

                            Text {
                                anchors.centerIn: parent
                                text: model.kind === "calc" ? "\uf1ec" : (model.kind === "file" ? "\uf016" : "\uf061")
                                color: "#88888E"
                                font.family: root.font
                                font.pixelSize: 18
                                visible: model.kind === "calc" || model.kind === "file" || rowIcon.status !== Image.Ready || model.icon === ""
                            }
                        }

                        // Text
                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter
                            spacing: 2

                            Text {
                                Layout.fillWidth: true
                                text: model.name
                                color: isSel ? "#FFFFFF" : (isHov ? "#F0F0F2" : "#D8D8DC")
                                font.family: "Outfit"
                                font.pixelSize: 13
                                font.weight: isSel ? Font.DemiBold : Font.Normal
                                elide: Text.ElideRight
                                maximumLineCount: 1
                            }

                            Text {
                                Layout.fillWidth: true
                                text: model.sub || ""
                                color: "#8A8A90"
                                font.family: "Outfit"
                                font.pixelSize: 10
                                elide: Text.ElideRight
                                maximumLineCount: 1
                            }
                        }

                        // Kind tag
                        Text {
                            text: model.kind === "app" ? "\uf1c0" : (model.kind === "file" ? "\uf0c5" : "\uf1ec")
                            color: (isSel ? "#5A86F6" : "#4A4A50")
                            font.family: root.font
                            font.pixelSize: 11
                        }
                    }
                }

                MouseArea {
                    id: rowArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onEntered: resultList.currentIndex = index
                    onClicked: launchEntry(model)
                }
            }
        }
    }
}
