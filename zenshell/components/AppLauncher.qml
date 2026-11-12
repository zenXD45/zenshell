import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io

Item {
    id: launcherRoot
    anchors.fill: parent
    property bool entered: false
    property real reveal: (root.displayState === 3 && entered) ? 1 : 0
    opacity: reveal
    visible: opacity > 0
    transform: Translate { y: (1 - launcherRoot.reveal) * 6 }

    Behavior on reveal {
        NumberAnimation {
            duration: root.displayState === 3 ? root.motionPanel : root.motionExit
            easing.type: Easing.OutCubic
        }
    }

    // ── Selection copy ───────────────────────────────────────────
    property string selectedAction: "open"

    readonly property int maxVisibleRows: 6
    readonly property int visibleRows: searchModel.count === 0 ? 3 : Math.min(maxVisibleRows, searchModel.count)
    // 16 top + 56 search bar + 12 + (rows * 52 + 8 group padding) + 8 + 18 footer + 16 bottom
    readonly property int panelHeight: 134 + visibleRows * 52

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

        // ── Search bar: M3 search, 56 px, full radius ──────────────
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 56

            Rectangle {
                anchors.fill: parent
                radius: height / 2
                color: searchInput.activeFocus ? root.cSurfaceContainerHighest : root.cSurfaceContainerHigh
                border.width: searchInput.activeFocus ? 2 : 0
                border.color: root.cPrimary
                Behavior on color { ColorAnimation { duration: root.dMicro } }
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 20
                anchors.rightMargin: 12
                spacing: root.s4

                Text {
                    Layout.alignment: Qt.AlignVCenter
                    text: root.icoSearch
                    color: searchInput.activeFocus ? root.cPrimary : root.cOnSurfaceVariant
                    font.family: root.fontIcon
                    font.pixelSize: 22
                    Behavior on color { ColorAnimation { duration: root.dMicro } }
                }

                TextInput {
                    id: searchInput
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    color: root.cOnSurface
                    font.family: root.fontSans
                    font.pixelSize: 15
                    verticalAlignment: TextInput.AlignVCenter
                    padding: 0
                    clip: true
                    focus: root.displayState === 3
                    focusPolicy: Qt.StrongFocus
                    selectByMouse: true
                    selectionColor: Qt.rgba(root.cPrimary.r, root.cPrimary.g, root.cPrimary.b, 0.28)
                    cursorDelegate: Rectangle {
                        width: 1.5
                        height: 18
                        radius: 0.75
                        color: root.cPrimary
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
                        color: root.cOnSurfaceVariant
                        opacity: 0.72
                        font.family: root.fontSans
                        font.pixelSize: 15
                        visible: searchInput.text.length === 0
                    }
                }

                Rectangle {
                    Layout.alignment: Qt.AlignVCenter
                    width: 32
                    height: 22
                    radius: 6
                    color: root.cSurfaceContainerHighest
                    border.width: 1
                    border.color: root.cOutlineVariant

                    Text {
                        anchors.centerIn: parent
                        text: "esc"
                        color: root.cOnSurfaceVariant
                        font.family: root.fontMono
                        font.pixelSize: 10
                    }
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
                radius: root.rLg
                color: root.cSurfaceContainerLow
                border.width: 1
                border.color: root.cOutlineVariant
            }

            ListView {
                id: resultList
                anchors.fill: parent
                anchors.margins: 4
                spacing: root.s1
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
                        color: root.cOutline
                    }
                }

                delegate: Item {
                    id: resultRow
                    width: resultList.width
                    height: 52
                    opacity: Math.max(0, Math.min(1, (launcherRoot.reveal - 0.05 - index * 0.03) / 0.72))

                    required property int index
                    required property var model

                    property bool isSel: index === resultList.currentIndex
                    property color accent: root.cPrimary

                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: 2
                        radius: root.rMd
                        color: isSel
                            ? root.cSecondaryContainer
                            : (rowArea.containsMouse ? root.cStateHover : "transparent")
                        Behavior on color { ColorAnimation { duration: root.dMicro } }
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 16
                        spacing: root.s4

                        Item {
                            Layout.alignment: Qt.AlignVCenter
                            Layout.preferredWidth: 24
                            Layout.preferredHeight: 24

                            Image {
                                id: rowIcon
                                anchors.centerIn: parent
                                width: 22
                                height: 22
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
                                color: root.cOnSurfaceVariant
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
                            color: root.cOnSurface
                            font.family: root.fontSans
                            font.pixelSize: 14
                            font.weight: resultRow.isSel ? Font.DemiBold : Font.Medium
                            elide: Text.ElideRight
                            maximumLineCount: 1
                        }

                        Rectangle {
                            Layout.alignment: Qt.AlignVCenter
                            visible: resultRow.isSel || model.kind === "calc"
                            implicitWidth: actionLabel.implicitWidth + 12
                            implicitHeight: 22
                            radius: 6
                            color: model.kind === "calc" ? root.cPrimaryContainer : root.cSurfaceContainerHighest
                            border.width: 1
                            border.color: root.cOutlineVariant

                            Text {
                                id: actionLabel
                                anchors.centerIn: parent
                                text: model.kind === "calc" ? "copy result" : "\u21b5"
                                color: model.kind === "calc" ? root.cOnPrimaryContainer : root.cOnSurfaceVariant
                                font.family: model.kind === "calc" ? root.fontSans : root.fontMono
                                font.pixelSize: 10
                                font.weight: Font.Medium
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

            EmptyState {
                anchors.centerIn: parent
                width: parent.width - root.s6
                visible: searchModel.count === 0
                icon: root.icoSearchOff
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
                color: root.cOnSurfaceVariant
                opacity: 0.72
                font.family: root.fontSans
                font.pixelSize: 11
                elide: Text.ElideRight
            }

            Text {
                Layout.alignment: Qt.AlignVCenter
                text: "\u2191\u2193 move   \u21b5 " + selectedAction + "   esc close"
                color: root.cOnSurfaceVariant
                opacity: 0.6
                font.family: root.fontMono
                font.pixelSize: 10
            }
        }
    }
}
