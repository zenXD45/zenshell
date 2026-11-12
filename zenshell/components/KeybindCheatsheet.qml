import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io

Item {
    id: cheatsheetRoot
    anchors.fill: parent
    property bool entered: false
    property real reveal: (root.displayState === 23 && entered) ? 1 : 0
    opacity: reveal
    visible: opacity > 0
    transform: Translate { y: (1 - cheatsheetRoot.reveal) * 6 }

    Behavior on reveal {
        NumberAnimation {
            duration: root.displayState === 23 ? root.motionPanel : root.motionExit
            easing.type: Easing.OutCubic
        }
    }

    property var allBinds: []
    property var leftCats: []
    property var rightCats: []
    property int visibleCount: 0

    // Split categories into two balanced columns. Greedy by row count gives a
    // much better result than chronological order, where "Apps" and "Focus"
    // used to leave a huge empty gutter under the short column.
    function rebuild() {
        flick.contentY = 0;
        var q = searchInput.text.trim().toLowerCase();
        var cats = [];
        var byName = {};
        for (var i = 0; i < allBinds.length; i++) {
            var b = allBinds[i];
            if (q && (b.key + " " + b.action + " " + b.category).toLowerCase().indexOf(q) === -1) continue;
            if (!byName[b.category]) {
                byName[b.category] = { name: b.category, binds: [] };
                cats.push(byName[b.category]);
            }
            byName[b.category].binds.push(b);
        }

        var left = [], right = [], leftRows = 0, rightRows = 0, count = 0;
        for (var j = 0; j < cats.length; j++) {
            var rows = cats[j].binds.length;
            count += rows;
            if (leftRows <= rightRows) {
                left.push(cats[j]);
                leftRows += rows + 2;
            } else {
                right.push(cats[j]);
                rightRows += rows + 2;
            }
        }
        leftCats = left;
        rightCats = right;
        visibleCount = count;
    }

    function filterBinds(query) {
        rebuild();
    }

    Process {
        id: fetchBinds
        command: [Quickshell.shellDir + "/scripts/get_keybinds.py"]
        stdout: SplitParser {
            onRead: data => {
                try {
                    allBinds = JSON.parse(data.trim());
                    rebuild();
                } catch(e) {}
            }
        }
    }

    onVisibleChanged: {
        if (visible) {
            fetchBinds.running = true;
            searchInput.text = "";
            rebuild();
            searchInput.forceActiveFocus();
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: root.s5
        spacing: 0

        // ── Header ───────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 48
            spacing: root.s2

            Text {
                Layout.alignment: Qt.AlignVCenter
                text: "Keybinds"
                color: root.cOnSurface
                font.family: root.fontSans
                font.pixelSize: 16
                font.weight: Font.DemiBold
            }

            Text {
                Layout.alignment: Qt.AlignVCenter
                Layout.leftMargin: root.s3
                text: visibleCount + (visibleCount === 1 ? " shortcut" : " shortcuts")
                color: root.cOnSurfaceVariant
                font.family: root.fontSans
                font.pixelSize: 12
            }

            Item { Layout.fillWidth: true }

            Item {
                Layout.alignment: Qt.AlignVCenter
                Layout.preferredWidth: 280
                Layout.preferredHeight: 40

                Rectangle {
                    anchors.fill: parent
                    radius: 20
                    color: root.cSurfaceContainerHigh
                    border.width: searchInput.activeFocus ? 2 : 0
                    border.color: root.cPrimary
                    Behavior on border.color { ColorAnimation { duration: root.dMicro } }
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 14
                    anchors.rightMargin: 8
                    spacing: root.s3

                    Text {
                        Layout.alignment: Qt.AlignVCenter
                        text: root.icoSearch
                        color: searchInput.activeFocus ? root.cPrimary : root.cOnSurfaceVariant
                        font.family: root.fontIcon
                        font.pixelSize: 19
                        Behavior on color { ColorAnimation { duration: root.dMicro } }
                    }

                    TextInput {
                        id: searchInput
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                        color: root.cOnSurface
                        font.family: root.fontSans
                        font.pixelSize: 13
                        verticalAlignment: TextInput.AlignVCenter
                        padding: 0
                        clip: true
                        focus: root.displayState === 23
                        focusPolicy: Qt.StrongFocus
                        selectByMouse: true
                        selectionColor: Qt.rgba(root.cPrimary.r, root.cPrimary.g, root.cPrimary.b, 0.30)

                        onTextChanged: filterBinds(text)

                        Keys.onEscapePressed: {
                            root.displayState = 0;
                            root.updateState();
                            text = "";
                        }
                        Keys.onDownPressed: (event) => {
                            if (flick.contentY < flick.contentHeight - flick.height)
                                flick.contentY = Math.min(flick.contentY + 48, flick.contentHeight - flick.height);
                            event.accepted = true;
                        }
                        Keys.onUpPressed: (event) => {
                            flick.contentY = Math.max(flick.contentY - 48, 0);
                            event.accepted = true;
                        }

                        Text {
                            anchors.fill: parent
                            verticalAlignment: Text.AlignVCenter
                            text: "Filter shortcuts"
                            color: root.cOnSurfaceVariant
                            opacity: 0.72
                            font.family: root.fontSans
                            font.pixelSize: 13
                            visible: searchInput.text.length === 0
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
        }

        Item { Layout.preferredHeight: root.s4 }

        // ── Two-column reference ─────────────────────────────────
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            Flickable {
                id: flick
                anchors.fill: parent
                clip: true
                contentWidth: width
                contentHeight: cols.implicitHeight
                boundsBehavior: Flickable.StopAtBounds
                ScrollBar.vertical: ScrollBar {
                    policy: ScrollBar.AsNeeded
                    contentItem: Rectangle {
                        implicitWidth: 2
                        radius: 1
                        color: root.ink(0.16)
                    }
                }

                RowLayout {
                    id: cols
                    width: flick.width
                    spacing: root.s8

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignTop
                        spacing: root.s5

                        Repeater {
                            model: leftCats
                            delegate: categoryCard
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignTop
                        spacing: root.s5

                        Repeater {
                            model: rightCats
                            delegate: categoryCard
                        }
                    }
                }
            }

            EmptyState {
                anchors.centerIn: parent
                visible: visibleCount === 0
                icon: root.icoSearchOff
                title: "No shortcuts match"
                detail: "Try another filter"
            }
        }
    }

    // ── Category card (shared delegate) ──────────────────────────
    Component {
        id: categoryCard

        ColumnLayout {
            id: categoryRoot
            Layout.fillWidth: true
            spacing: root.s2
            opacity: Math.max(0, Math.min(1, (cheatsheetRoot.reveal - 0.04 - Math.min(index, 5) * 0.045) / 0.68))

            SectionLabel {
                Layout.fillWidth: true
                text: modelData.name
                Layout.preferredHeight: 20
                bottomPadding: 2
            }

            Group {
                Repeater {
                    id: bindRepeater
                    model: modelData.binds

                    GroupRow {
                        required property int index
                        required property var modelData

                        rowHeight: 34
                        labelSize: 12
                        valueSize: 10
                        valueKeycap: true
                        label: modelData.action
                        value: modelData.key
                        last: index === bindRepeater.count - 1
                    }
                }
            }
        }
    }
}
