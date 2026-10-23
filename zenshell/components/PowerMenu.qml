import QtQuick
import QtQuick.Layouts
import Quickshell.Io

Item {
    id: powerRoot
    anchors.fill: parent
    property real reveal: root.displayState === 12 ? 1 : 0
    opacity: reveal
    visible: opacity > 0
    clip: true
    scale: 0.992 + reveal * 0.008
    transform: Translate { y: (1 - powerRoot.reveal) * 8 }

    Behavior on reveal {
        NumberAnimation {
            duration: root.displayState === 12 ? root.motionPanel : root.motionExit
            easing.type: root.displayState === 12 ? Easing.OutExpo : Easing.OutCubic
        }
    }

    property int selectedIndex: 0

    Process {
        id: powerCmd
        command: []
    }

    function executeAction(idx) {
        var cmds = [
            "hyprlock",
            "systemctl suspend",
            "hyprctl dispatch exit",
            "systemctl reboot",
            "systemctl poweroff"
        ];
        if (idx >= 0 && idx < cmds.length) {
            root.displayState = 0;
            root.updateState();
            powerCmd.command = ["bash", "-c", cmds[idx]];
            powerCmd.running = true;
        }
    }

    FocusScope {
        anchors.fill: parent
        focus: root.displayState === 12
        Keys.onEscapePressed: { root.displayState = 0; root.updateState(); }
        Keys.onLeftPressed: (event) => { if (selectedIndex > 0) selectedIndex--; event.accepted = true; }
        Keys.onRightPressed: (event) => { if (selectedIndex < 4) selectedIndex++; event.accepted = true; }
        Keys.onReturnPressed: executeAction(selectedIndex)
        Keys.onPressed: (event) => {
            var keys = {"L": 0, "U": 1, "E": 2, "R": 3, "S": 4};
            var k = event.text.toUpperCase();
            if (k in keys) { selectedIndex = keys[k]; executeAction(keys[k]); event.accepted = true; }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 12

        MenuHeader {
            title: "Power Menu"
            icon: "\uf011"
            hint: "esc to close"
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 12

            Repeater {
                model: [
                    { icon: "\uf023", label: "Lock",     key: "L", accent: "#5B9CF8" },
                    { icon: "\uf186", label: "Suspend",  key: "U", accent: "#A78BFA" },
                    { icon: "\uf2f5", label: "Logout",   key: "E", accent: "#F5C451" },
                    { icon: "\uf01e", label: "Reboot",   key: "R", accent: "#4ADE80" },
                    { icon: "\uf011", label: "Shutdown", key: "S", accent: "#F87171" }
                ]

                Item {
                    id: actionCard
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.minimumWidth: 64
                    opacity: Math.max(0, Math.min(1, (powerRoot.reveal - 0.04 - index * 0.05) / 0.65))
                    transform: Translate { y: (1 - actionCard.opacity) * 8 }

                    property bool isSel: index === selectedIndex
                    property bool isHov: btnArea.containsMouse
                    property color itemAccent: modelData.accent

                    Rectangle {
                        id: card
                        anchors.fill: parent
                        radius: 16
                        color: actionCard.isSel
                            ? Qt.rgba(actionCard.itemAccent.r, actionCard.itemAccent.g, actionCard.itemAccent.b, 0.11)
                            : (actionCard.isHov ? root.ink(0.039) : root.ink(0.02))
                        border.width: actionCard.isSel ? 1.2 : 1
                        border.color: actionCard.isSel
                            ? Qt.rgba(actionCard.itemAccent.r, actionCard.itemAccent.g, actionCard.itemAccent.b, 0.42)
                            : (actionCard.isHov ? root.ink(0.11) : root.ink(0.055))

                        Behavior on color { ColorAnimation { duration: 150 } }
                        Behavior on border.color { ColorAnimation { duration: 150 } }

                        property real press: 1.0
                        transform: Scale {
                            origin.x: card.width / 2
                            origin.y: card.height / 2
                            xScale: card.press
                            yScale: card.press
                        }
                        Behavior on press { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }

                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 8

                            Item {
                                Layout.preferredWidth: 36
                                Layout.preferredHeight: 36
                                Layout.alignment: Qt.AlignHCenter

                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.icon
                                    color: actionCard.isSel
                                        ? actionCard.itemAccent
                                        : Qt.rgba(actionCard.itemAccent.r, actionCard.itemAccent.g, actionCard.itemAccent.b, actionCard.isHov ? 0.85 : 0.55)
                                    font.family: root.font
                                    font.pixelSize: 20
                                    Behavior on color { ColorAnimation { duration: 150 } }
                                }
                            }

                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: modelData.label
                                color: actionCard.isSel || actionCard.isHov ? root.uiFg : root.uiFgDim
                                font.family: root.uiFont
                                font.pixelSize: 12
                                font.weight: actionCard.isSel ? Font.DemiBold : Font.Medium
                                Behavior on color { ColorAnimation { duration: 150 } }
                            }
                        }

                        // Keyboard shortcut hint, kept quiet until the card is engaged.
                        Rectangle {
                            anchors.top: parent.top
                            anchors.right: parent.right
                            anchors.margins: 7
                            width: 15
                            height: 15
                            radius: 4
                            color: actionCard.isSel ? Qt.rgba(actionCard.itemAccent.r, actionCard.itemAccent.g, actionCard.itemAccent.b, 0.08) : root.ink(0.024)
                            border.width: 1
                            border.color: actionCard.isSel
                                ? Qt.rgba(actionCard.itemAccent.r, actionCard.itemAccent.g, actionCard.itemAccent.b, 0.28)
                                : root.ink(0.063)

                            Text {
                                anchors.centerIn: parent
                                text: modelData.key
                                color: actionCard.isSel ? actionCard.itemAccent : root.ink(0.439)
                                font.family: root.font
                                font.pixelSize: 8
                                font.weight: Font.Medium
                            }
                        }

                        Rectangle {
                            anchors.bottom: parent.bottom
                            anchors.bottomMargin: 6
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: actionCard.isSel ? 20 : 0
                            height: 2
                            radius: 1
                            color: actionCard.itemAccent
                            Behavior on width { NumberAnimation { duration: 220; easing.type: Easing.OutQuart } }
                        }

                        MouseArea {
                            id: btnArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onPressed: card.press = 0.94
                            onReleased: card.press = 1.0
                            onClicked: executeAction(index)
                            onEntered: selectedIndex = index
                        }
                    }
                }
            }
        }
    }
}
