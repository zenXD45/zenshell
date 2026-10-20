import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io

Item {
    anchors.fill: parent
    opacity: root.displayState === 3 ? 1 : 0
    visible: opacity > 0
    clip: true

    Behavior on opacity {
        NumberAnimation { duration: root.displayState === 3 ? 220 : 150; easing.type: Easing.OutCubic }
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
        interval: 160
        onTriggered: runSearch()
    }

    Component.onCompleted: runSearch()

    onVisibleChanged: {
        if (visible) {
            searchInput.text = "";
            resultList.currentIndex = 0;
            runSearch();
            searchInput.forceActiveFocus();
        }
    }

    // ── Layout ───────────────────────────────────────────────────
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 18
        spacing: 0

        // ── Search field ─────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 44
            radius: 14
            color: root.uiCard
            border.width: 1
            border.color: searchInput.activeFocus
                ? Qt.rgba(root.currentThemeAccent.r, root.currentThemeAccent.g, root.currentThemeAccent.b, 0.42)
                : root.uiBorder
            Behavior on border.color { ColorAnimation { duration: 140 } }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 14
                anchors.rightMargin: 10
                spacing: 10

                Text {
                    text: "\uf002"
                    color: searchInput.activeFocus ? root.currentThemeAccent : root.uiFgFaint
                    font.family: root.font
                    font.pixelSize: 14
                    Behavior on color { ColorAnimation { duration: 140 } }
                }

                TextInput {
                    id: searchInput
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    color: root.uiFg
                    font.family: root.uiFont
                    font.pixelSize: 15
                    font.weight: Font.Medium
                    verticalAlignment: TextInput.AlignVCenter
                    padding: 0
                    clip: true
                    focus: root.displayState === 3
                    focusPolicy: Qt.StrongFocus
                    selectByMouse: true
                    selectionColor: Qt.rgba(root.currentThemeAccent.r, root.currentThemeAccent.g, root.currentThemeAccent.b, 0.30)

                    onTextChanged: debounce.restart()

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
                        text: "Search apps, files, or calculate\u2026"
                        color: root.uiFgFaint
                        font.family: root.uiFont
                        font.pixelSize: 15
                        font.weight: Font.Normal
                        visible: searchInput.text.length === 0
                    }
                }

                Rectangle {
                    Layout.alignment: Qt.AlignVCenter
                    width: 30; height: 20; radius: 6
                    color: "#12FFFFFF"
                    border.color: "#1AFFFFFF"
                    border.width: 1
                    Text {
                        anchors.centerIn: parent
                        text: "esc"
                        color: root.uiFgFaint
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 9
                    }
                }
            }
        }

        Item { Layout.preferredHeight: 14 }

        // ── Section label ────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 16
            spacing: 8

            Text {
                text: "APPLICATIONS"
                color: root.uiFgFaint
                font.family: root.uiFont
                font.pixelSize: 10
                font.weight: Font.DemiBold
                font.letterSpacing: 1.4
            }

            Item { Layout.fillWidth: true }

            Text {
                text: searchModel.count === 1 ? "1 result" : searchModel.count + " results"
                color: root.uiFgFaint
                font.family: root.uiFont
                font.pixelSize: 10
            }
        }

        Item { Layout.preferredHeight: 8 }

        // ── Results ──────────────────────────────────────────────
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            ListView {
                id: resultList
                anchors.fill: parent
                spacing: 4
                clip: true
                model: searchModel
                boundsBehavior: Flickable.StopAtBounds
                highlightMoveDuration: 0

                ScrollBar.vertical: ScrollBar {
                    policy: ScrollBar.AsNeeded
                    contentItem: Rectangle {
                        implicitWidth: 3
                        radius: 1.5
                        color: "#30FFFFFF"
                    }
                }

                delegate: Item {
                    width: resultList.width
                    height: 56

                    required property int index
                    required property var model

                    property bool isSel: index === resultList.currentIndex
                    property bool isHov: rowArea.containsMouse
                    property color accent: root.currentThemeAccent

                    Rectangle {
                        anchors.fill: parent
                        radius: root.uiRadiusSm
                        color: isSel
                            ? Qt.rgba(accent.r, accent.g, accent.b, 0.13)
                            : (isHov ? "#0EFFFFFF" : "transparent")
                        border.width: 1
                        border.color: isSel
                            ? Qt.rgba(accent.r, accent.g, accent.b, 0.38)
                            : "transparent"
                        Behavior on color { ColorAnimation { duration: 120 } }

                        // Selection marker
                        Rectangle {
                            visible: isSel
                            anchors.verticalCenter: parent.verticalCenter
                            width: 3; height: 20; radius: 1.5
                            color: accent
                        }
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 14
                        anchors.rightMargin: 12
                        spacing: 12

                        // Icon tile
                        Rectangle {
                            Layout.alignment: Qt.AlignVCenter
                            width: 36; height: 36; radius: 10
                            color: "#12FFFFFF"
                            border.color: isSel ? Qt.rgba(accent.r, accent.g, accent.b, 0.22) : "#0CFFFFFF"
                            border.width: 1

                            Image {
                                id: rowIcon
                                anchors.centerIn: parent
                                width: 22; height: 22
                                source: (model.icon && model.icon.startsWith("/")) ? "file://" + model.icon : (model.icon ? "image://icon/" + model.icon : "")
                                sourceSize: Qt.size(44, 44)
                                asynchronous: true
                                fillMode: Image.PreserveAspectFit
                                visible: model.kind !== "calc" && rowIcon.status !== Image.Error && model.icon !== ""
                            }

                            Text {
                                anchors.centerIn: parent
                                text: model.kind === "calc" ? "\uf1ec" : (model.kind === "file" ? "\uf016" : (model.name ? model.name.charAt(0).toUpperCase() : "?"))
                                color: isSel ? accent : root.uiFgDim
                                font.family: root.font
                                font.pixelSize: model.kind === "app" ? 14 : 16
                                font.weight: Font.DemiBold
                                visible: model.kind === "calc" || model.kind === "file"
                                    || rowIcon.status !== Image.Ready || model.icon === ""
                            }
                        }

                        // Name + description
                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter
                            spacing: 1

                            Text {
                                Layout.fillWidth: true
                                text: model.name
                                color: isSel ? "#FFFFFF" : root.uiFg
                                font.family: root.uiFont
                                font.pixelSize: 14
                                font.weight: isSel ? Font.DemiBold : Font.Medium
                                elide: Text.ElideRight
                                maximumLineCount: 1
                            }

                            Text {
                                Layout.fillWidth: true
                                text: model.sub || ""
                                color: isSel ? root.uiFgDim : root.uiFgFaint
                                font.family: root.uiFont
                                font.pixelSize: 11
                                elide: Text.ElideRight
                                maximumLineCount: 1
                                visible: text.length > 0
                            }
                        }

                        // Launch affordance, only on the active row
                        Rectangle {
                            Layout.alignment: Qt.AlignVCenter
                            visible: isSel
                            width: 22; height: 22; radius: 7
                            color: Qt.rgba(accent.r, accent.g, accent.b, 0.16)
                            Text {
                                anchors.centerIn: parent
                                text: "\uf3be"
                                color: accent
                                font.family: root.font
                                font.pixelSize: 9
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

            // Empty state
            ColumnLayout {
                anchors.centerIn: parent
                width: parent.width - 40
                spacing: 6
                visible: searchModel.count === 0

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "\uf002"
                    color: "#22FFFFFF"
                    font.family: root.font
                    font.pixelSize: 22
                }
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "No matches"
                    color: root.uiFgDim
                    font.family: root.uiFont
                    font.pixelSize: 14
                    font.weight: Font.Medium
                }
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "Try an app name, a file, or something like 12*8"
                    color: root.uiFgFaint
                    font.family: root.uiFont
                    font.pixelSize: 11
                }
            }
        }

        Item { Layout.preferredHeight: 10 }

        // ── Footer hints ─────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 18
            spacing: 14

            Text {
                text: "\u2191\u2193  navigate     \u21b5  open     esc  close"
                color: root.uiFgFaint
                font.family: root.uiFont
                font.pixelSize: 10
                font.letterSpacing: 0.2
            }

            Item { Layout.fillWidth: true }

            Text {
                text: "apps \u00b7 files \u00b7 math"
                color: "#3DFFFFFF"
                font.family: root.uiFont
                font.pixelSize: 10
            }
        }
    }
}
