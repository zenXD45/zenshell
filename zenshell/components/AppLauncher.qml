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

    // ── Selection copy ───────────────────────────────────────────
    // Enter opens an app, but copies a calculator result. Keep the footer
    // honest as the highlighted row changes.
    property string selectedAction: "open"

    // The palette sizes to its content: six rows is the ceiling, and a
    // single filtered result keeps the whole surface small.
    readonly property int maxVisibleRows: 6
    readonly property int visibleRows: searchModel.count === 0 ? 2 : Math.min(maxVisibleRows, searchModel.count)
    readonly property int panelHeight: 96 + visibleRows * 40 + (visibleRows - 1) * 2

    function syncSelectedAction() {
        if (resultList.currentIndex >= 0 && resultList.currentIndex < searchModel.count) {
            var item = searchModel.get(resultList.currentIndex);
            selectedAction = item && item.kind === "calc" ? "copy" : "open";
        } else {
            selectedAction = "open";
        }
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
                    resultList.currentIndex = 0;
                    searchModel.clear();
                    for (var i = 0; i < results.length; i++) searchModel.append(results[i]);
                    resultList.currentIndex = 0;
                    syncSelectedAction();
                } catch(e) {
                    searchModel.clear();
                    syncSelectedAction();
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
            syncSelectedAction();
        }
    }

    // ── Layout ───────────────────────────────────────────────────
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 8

        // ── Search strip ─────────────────────────────────────────
        Rectangle {
            id: searchShell
            Layout.fillWidth: true
            Layout.preferredHeight: 40
            radius: 12
            color: searchInput.activeFocus ? "#10FFFFFF" : "#08FFFFFF"
            clip: true

            Behavior on color { ColorAnimation { duration: 160 } }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 9
                spacing: 8

                Text {
                    text: "\uf002"
                    color: searchInput.activeFocus ? root.currentThemeAccent : root.uiFgDim
                    font.family: root.font
                    font.pixelSize: 13
                    Behavior on color { ColorAnimation { duration: 160 } }
                }

                TextInput {
                    id: searchInput
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    color: root.uiFg
                    font.family: root.uiFont
                    font.pixelSize: 13
                    font.weight: Font.Medium
                    verticalAlignment: TextInput.AlignVCenter
                    padding: 0
                    clip: true
                    focus: root.displayState === 3
                    focusPolicy: Qt.StrongFocus
                    selectByMouse: true
                    selectionColor: Qt.rgba(root.currentThemeAccent.r, root.currentThemeAccent.g, root.currentThemeAccent.b, 0.30)
                    cursorDelegate: Rectangle {
                        width: 1.5
                        height: 15
                        radius: 0.75
                        color: root.currentThemeAccent
                    }

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
                        text: "Search apps or calculate\u2026"
                        color: root.uiFgDim
                        font.family: root.uiFont
                        font.pixelSize: 13
                        font.weight: Font.Normal
                        visible: searchInput.text.length === 0
                    }
                }

                Rectangle {
                    Layout.alignment: Qt.AlignVCenter
                    width: 25; height: 17; radius: 5
                    color: "#10FFFFFF"
                    border.color: "#20FFFFFF"
                    border.width: 1
                    Text {
                        anchors.centerIn: parent
                        text: "esc"
                        color: root.uiFgDim
                        font.family: root.font
                        font.pixelSize: 8
                    }
                }
            }

            // The search field is borderless; focus is carried by this fine
            // accent line, the caret, and the search glyph.
            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                height: 1
                radius: 0.5
                color: searchInput.activeFocus ? root.currentThemeAccent : "#16FFFFFF"
                opacity: searchInput.activeFocus ? 0.62 : 0.55
                Behavior on color { ColorAnimation { duration: 160 } }
                Behavior on opacity { NumberAnimation { duration: 160 } }
            }
        }

        // ── Results ──────────────────────────────────────────────
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            ListView {
                id: resultList
                anchors.fill: parent
                spacing: 2
                clip: true
                model: searchModel
                boundsBehavior: Flickable.StopAtBounds
                highlightMoveDuration: 0
                onCurrentIndexChanged: syncSelectedAction()

                ScrollBar.vertical: ScrollBar {
                    policy: ScrollBar.AsNeeded
                    visible: resultList.contentHeight > resultList.height
                    contentItem: Rectangle {
                        implicitWidth: 2
                        radius: 1
                        color: "#3DFFFFFF"
                    }
                }

                delegate: Item {
                    width: resultList.width
                    height: 40

                    required property int index
                    required property var model

                    property bool isSel: index === resultList.currentIndex
                    property bool isHov: rowArea.containsMouse
                    property color accent: root.currentThemeAccent

                    Rectangle {
                        anchors.fill: parent
                        radius: 10
                        color: isSel
                            ? Qt.rgba(accent.r, accent.g, accent.b, 0.10)
                            : (isHov ? "#0EFFFFFF" : "transparent")
                        border.width: 1
                        border.color: isSel
                            ? Qt.rgba(accent.r, accent.g, accent.b, 0.30)
                            : "transparent"
                        Behavior on color { ColorAnimation { duration: 120 } }
                        Behavior on border.color { ColorAnimation { duration: 120 } }
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        spacing: 10

                        // Compact icon tile. The border carries selection; no
                        // heavy row chrome.
                        Rectangle {
                            Layout.alignment: Qt.AlignVCenter
                            width: 26; height: 26; radius: 8
                            color: isSel
                                ? Qt.rgba(accent.r, accent.g, accent.b, 0.12)
                                : "#0EFFFFFF"
                            border.width: 1
                            border.color: isSel
                                ? Qt.rgba(accent.r, accent.g, accent.b, 0.22)
                                : "transparent"
                            Behavior on color { ColorAnimation { duration: 120 } }

                            Image {
                                id: rowIcon
                                anchors.centerIn: parent
                                width: 18; height: 18
                                source: (model.icon && model.icon.startsWith("/"))
                                    ? "file://" + encodeURI(model.icon)
                                    : (model.icon ? "image://icon/" + model.icon : "")
                                sourceSize: Qt.size(96, 96)
                                asynchronous: true
                                fillMode: Image.PreserveAspectFit
                                visible: model.kind !== "calc" && model.icon !== ""
                                    && rowIcon.status !== Image.Error
                            }

                            Text {
                                anchors.centerIn: parent
                                text: model.kind === "calc"
                                    ? "\uf1ec"
                                    : (model.name ? model.name.charAt(0).toUpperCase() : "?")
                                color: isSel ? accent : root.uiFgDim
                                font.family: root.font
                                font.pixelSize: model.kind === "app" ? 12 : 13
                                font.weight: Font.DemiBold
                                visible: model.kind === "calc" || model.icon === ""
                                    || rowIcon.status === Image.Error
                            }
                        }

                        Text {
                            Layout.fillWidth: true
                            text: model.name
                            color: isSel ? "#FFFFFF" : root.uiFg
                            font.family: root.uiFont
                            font.pixelSize: 13
                            font.weight: isSel ? Font.DemiBold : Font.Medium
                            elide: Text.ElideRight
                            maximumLineCount: 1
                        }

                        // A quiet enter chip appears only on the active row.
                        Rectangle {
                            Layout.alignment: Qt.AlignVCenter
                            width: 18; height: 18; radius: 5
                            color: Qt.rgba(accent.r, accent.g, accent.b, 0.14)
                            border.width: 1
                            border.color: Qt.rgba(accent.r, accent.g, accent.b, 0.24)
                            opacity: isSel ? 1 : 0
                            scale: isSel ? 1 : 0.9
                            Behavior on opacity { NumberAnimation { duration: 120 } }
                            Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                            Text {
                                anchors.centerIn: parent
                                text: "\u21b5"
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
                width: parent.width - 36
                spacing: 4
                visible: searchModel.count === 0

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "\uf002"
                    color: "#22FFFFFF"
                    font.family: root.font
                    font.pixelSize: 18
                }
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "No matches"
                    color: root.uiFgDim
                    font.family: root.uiFont
                    font.pixelSize: 13
                    font.weight: Font.DemiBold
                }
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "Try an app name or 12*8"
                    color: root.uiFgDim
                    font.family: root.uiFont
                    font.pixelSize: 10
                }
            }
        }

        // ── Status footer ────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 16
            spacing: 6

            Rectangle {
                Layout.alignment: Qt.AlignVCenter
                width: 18; height: 14; radius: 4
                color: "#0CFFFFFF"
                border.color: "#18FFFFFF"
                border.width: 1
                Text {
                    anchors.centerIn: parent
                    text: "\u2191\u2193"
                    color: root.uiFgDim
                    font.family: root.font
                    font.pixelSize: 8
                }
            }

            Text {
                text: "move"
                color: root.uiFgDim
                font.family: root.uiFont
                font.pixelSize: 9
            }

            Item { Layout.preferredWidth: 4 }

            Rectangle {
                Layout.alignment: Qt.AlignVCenter
                width: 14; height: 14; radius: 4
                color: "#0CFFFFFF"
                border.color: "#18FFFFFF"
                border.width: 1
                Text {
                    anchors.centerIn: parent
                    text: "\u21b5"
                    color: root.uiFgDim
                    font.family: root.font
                    font.pixelSize: 8
                }
            }

            Text {
                text: selectedAction
                color: root.uiFgDim
                font.family: root.uiFont
                font.pixelSize: 9
            }

            Item { Layout.fillWidth: true }

            Text {
                text: searchModel.count + (searchModel.count === 1 ? " RESULT" : " RESULTS")
                color: root.uiFgDim
                font.family: root.uiFont
                font.pixelSize: 8
                font.weight: Font.DemiBold
                font.letterSpacing: 1.1
            }
        }
    }
}
