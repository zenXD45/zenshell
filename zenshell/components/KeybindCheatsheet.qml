import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io

Item {
    id: cheatsheetRoot
    anchors.fill: parent
    opacity: root.displayState === 23 ? 1 : 0
    visible: opacity > 0
    clip: true

    Behavior on opacity {
        NumberAnimation { duration: root.displayState === 23 ? 220 : 150; easing.type: Easing.OutCubic }
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
        anchors.margins: 18
        spacing: 14

        // ── Header ───────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 40
            spacing: 14

            ColumnLayout {
                Layout.alignment: Qt.AlignVCenter
                spacing: 1

                Text {
                    text: "Keybinds"
                    color: root.uiFg
                    font.family: root.uiFont
                    font.pixelSize: 18
                    font.weight: Font.DemiBold
                }
                Text {
                    text: visibleCount + (visibleCount === 1 ? " shortcut" : " shortcuts")
                    color: root.uiFgFaint
                    font.family: root.uiFont
                    font.pixelSize: 11
                }
            }

            Item { Layout.fillWidth: true }

            Rectangle {
                Layout.alignment: Qt.AlignVCenter
                Layout.preferredWidth: 250
                Layout.preferredHeight: 38
                radius: 12
                color: root.uiCard
                border.width: 1
                border.color: searchInput.activeFocus
                    ? Qt.rgba(root.currentThemeAccent.r, root.currentThemeAccent.g, root.currentThemeAccent.b, 0.42)
                    : root.uiBorder
                Behavior on border.color { ColorAnimation { duration: 140 } }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 8
                    spacing: 8

                    Text {
                        text: "\uf002"
                        color: searchInput.activeFocus ? root.currentThemeAccent : root.uiFgFaint
                        font.family: root.font
                        font.pixelSize: 12
                        Behavior on color { ColorAnimation { duration: 140 } }
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
                        focus: root.displayState === 23
                        focusPolicy: Qt.StrongFocus
                        selectByMouse: true
                        selectionColor: Qt.rgba(root.currentThemeAccent.r, root.currentThemeAccent.g, root.currentThemeAccent.b, 0.30)

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
                            text: "Filter shortcuts\u2026"
                            color: root.uiFgFaint
                            font.family: root.uiFont
                            font.pixelSize: 13
                            visible: searchInput.text.length === 0
                        }
                    }

                    Rectangle {
                        Layout.alignment: Qt.AlignVCenter
                        width: 26; height: 18; radius: 5
                        color: "#12FFFFFF"
                        border.color: "#1AFFFFFF"
                        border.width: 1
                        Text {
                            anchors.centerIn: parent
                            text: "esc"
                            color: root.uiFgFaint
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 8
                        }
                    }
                }
            }
        }

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
                        implicitWidth: 3
                        radius: 1.5
                        color: "#30FFFFFF"
                    }
                }

                RowLayout {
                    id: cols
                    width: flick.width
                    spacing: 12

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignTop
                        spacing: 12

                        Repeater {
                            model: leftCats
                            delegate: categoryCard
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignTop
                        spacing: 12

                        Repeater {
                            model: rightCats
                            delegate: categoryCard
                        }
                    }
                }
            }

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 5
                visible: visibleCount === 0

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "\uf002"
                    color: "#22FFFFFF"
                    font.family: root.font
                    font.pixelSize: 20
                }
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "No shortcuts match"
                    color: root.uiFgDim
                    font.family: root.uiFont
                    font.pixelSize: 13
                    font.weight: Font.Medium
                }
            }
        }
    }

    // ── Category card (shared delegate) ──────────────────────────
    Component {
        id: categoryCard

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: cardCol.implicitHeight + 28
            radius: root.uiRadiusMd
            color: "#08FFFFFF"
            border.width: 1
            border.color: root.uiBorder

            Column {
                id: cardCol
                anchors.fill: parent
                anchors.margins: 14
                spacing: 6

                RowLayout {
                    width: parent.width
                    height: 18
                    spacing: 7

                    Rectangle {
                        Layout.alignment: Qt.AlignVCenter
                        width: 5; height: 5; radius: 2.5
                        color: root.currentThemeAccent
                    }

                    Text {
                        Layout.alignment: Qt.AlignVCenter
                        text: modelData.name
                        color: root.uiFgFaint
                        font.family: root.uiFont
                        font.pixelSize: 10
                        font.weight: Font.DemiBold
                        font.letterSpacing: 1.1
                        font.capitalization: Font.AllUppercase
                    }

                    Item { Layout.fillWidth: true }

                    Text {
                        Layout.alignment: Qt.AlignVCenter
                        text: modelData.binds.length
                        color: "#3DFFFFFF"
                        font.family: root.uiFont
                        font.pixelSize: 10
                    }
                }

                Repeater {
                    model: modelData.binds

                    delegate: RowLayout {
                        width: cardCol.width
                        height: 28
                        spacing: 8

                        Rectangle {
                            Layout.alignment: Qt.AlignVCenter
                            height: 21
                            width: keyLabel.implicitWidth + 14
                            radius: 6
                            color: "#10FFFFFF"
                            border.width: 1
                            border.color: "#1CFFFFFF"

                            Text {
                                id: keyLabel
                                anchors.centerIn: parent
                                text: modelData.key
                                color: "#D9FFFFFF"
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 10
                                font.weight: Font.Medium
                            }
                        }

                        Text {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter
                            text: modelData.action
                            color: root.uiFgDim
                            font.family: root.uiFont
                            font.pixelSize: 12
                            elide: Text.ElideRight
                            maximumLineCount: 1
                        }
                    }
                }
            }
        }
    }
}
