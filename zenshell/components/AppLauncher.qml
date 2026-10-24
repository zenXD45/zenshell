import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io

Item {
    id: launcherRoot
    anchors.fill: parent
    property real reveal: root.displayState === 3 ? 1 : 0
    opacity: reveal
    visible: opacity > 0
    clip: true
    scale: 0.992 + reveal * 0.008
    transform: Translate { y: (1 - launcherRoot.reveal) * 8 }

    Behavior on reveal {
        NumberAnimation {
            duration: root.displayState === 3 ? root.motionPanel : root.motionExit
            easing.type: root.displayState === 3 ? Easing.OutExpo : Easing.OutCubic
        }
    }

    // ── Selection copy ───────────────────────────────────────────
    property string selectedAction: "open"

    readonly property int maxVisibleRows: 6
    readonly property int visibleRows: searchModel.count === 0 ? 3 : Math.min(maxVisibleRows, searchModel.count)
    // 16 top + 40 field + 12 + (rows * 44 + 8) + 8 + 18 footer + 16 bottom
    readonly property int panelHeight: 118 + visibleRows * 44

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
        anchors.margins: root.s5
        spacing: 0

        // ── Search field: one inset rounded field ──────────────────
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 40

            Rectangle {
                anchors.fill: parent
                radius: 12
                color: root.ink(0.055)
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: root.s4
                anchors.rightMargin: root.s4
                spacing: root.s3

                Text {
                    Layout.alignment: Qt.AlignVCenter
                    text: "\uf002"
                    color: searchInput.activeFocus ? root.currentThemeAccent : root.ink(0.45)
                    font.family: root.fontMono
                    font.pixelSize: 13
                    Behavior on color { ColorAnimation { duration: root.dMicro } }
                }

                TextInput {
                    id: searchInput
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    color: root.cFgPrimary
                    font.family: root.fontSans
                    font.pixelSize: 14
                    verticalAlignment: TextInput.AlignVCenter
                    padding: 0
                    clip: true
                    focus: root.displayState === 3
                    focusPolicy: Qt.StrongFocus
                    selectByMouse: true
                    selectionColor: Qt.rgba(root.currentThemeAccent.r, root.currentThemeAccent.g, root.currentThemeAccent.b, 0.28)
                    cursorDelegate: Rectangle {
                        width: 1.5
                        height: 16
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
                        text: "Search apps or calculate"
                        color: root.ink(0.32)
                        font.family: root.fontSans
                        font.pixelSize: 14
                        visible: searchInput.text.length === 0
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

        Item { Layout.preferredHeight: root.s4 }

        // ── Results: one inset group ───────────────────────────────
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            Rectangle {
                anchors.fill: parent
                radius: 14
                color: root.ink(0.055)
            }

            ListView {
                id: resultList
                anchors.fill: parent
                anchors.margins: 4
                spacing: 0
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
                        color: root.ink(0.16)
                    }
                }

                delegate: Item {
                    id: resultRow
                    width: resultList.width
                    height: 44
                    opacity: Math.max(0, Math.min(1, (launcherRoot.reveal - 0.05 - index * 0.03) / 0.72))

                    required property int index
                    required property var model

                    property bool isSel: index === resultList.currentIndex
                    property color accent: root.currentThemeAccent

                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: 2
                        radius: 10
                        color: isSel
                            ? root.ink(0.065)
                            : (rowArea.containsMouse ? root.ink(0.04) : "transparent")
                        Behavior on color { ColorAnimation { duration: root.dMicro } }
                    }

                    Rectangle {
                        visible: index < resultList.count - 1
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        anchors.leftMargin: 46
                        anchors.rightMargin: 12
                        height: 1
                        color: root.ink(0.07)
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: root.s3
                        anchors.rightMargin: root.s4
                        spacing: root.s4

                        Item {
                            Layout.alignment: Qt.AlignVCenter
                            Layout.preferredWidth: 22
                            Layout.preferredHeight: 22

                            Image {
                                id: rowIcon
                                anchors.centerIn: parent
                                width: 20
                                height: 20
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
                                color: root.cFgMuted
                                font.family: root.fontMono
                                font.pixelSize: model.kind === "app" ? 12 : 13
                                font.weight: Font.Medium
                                visible: model.kind === "calc" || model.icon === ""
                                    || rowIcon.status === Image.Error
                            }
                        }

                        Text {
                            Layout.fillWidth: true
                            text: model.name
                            color: root.cFgPrimary
                            font.family: root.fontSans
                            font.pixelSize: 14
                            font.weight: resultRow.isSel ? Font.DemiBold : Font.Normal
                            elide: Text.ElideRight
                            maximumLineCount: 1
                        }

                        Text {
                            Layout.alignment: Qt.AlignVCenter
                            visible: resultRow.isSel || model.kind === "calc"
                            text: model.kind === "calc" ? "copy result" : "\u21b5"
                            color: model.kind === "calc" ? root.ink(0.50) : root.ink(0.30)
                            font.family: model.kind === "calc" ? root.fontSans : root.fontMono
                            font.pixelSize: 11
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

            EmptyState {
                anchors.centerIn: parent
                width: parent.width - root.s6
                visible: searchModel.count === 0
                title: "No matches"
                detail: "Try an app name or 12*8"
            }
        }

        Item { Layout.preferredHeight: root.s3 }

        // ── Footer: one quiet line ─────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 18
            spacing: root.s4

            Text {
                Layout.fillWidth: true
                text: searchModel.count + (searchModel.count === 1 ? " result" : " results")
                color: root.ink(0.34)
                font.family: root.fontSans
                font.pixelSize: 11
                elide: Text.ElideRight
            }

            Text {
                Layout.alignment: Qt.AlignVCenter
                text: "\u2191\u2193 move   \u21b5 " + selectedAction + "   esc close"
                color: root.ink(0.30)
                font.family: root.fontMono
                font.pixelSize: 10
            }
        }
    }
}
