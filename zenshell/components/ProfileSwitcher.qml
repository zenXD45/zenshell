import QtQuick
import QtQuick.Layouts

Item {
    id: profileSwitcher
    anchors.fill: parent
    opacity: root.displayState === 16 ? 1 : 0
    visible: opacity > 0
    clip: true
    Behavior on opacity {
        NumberAnimation { duration: root.displayState === 16 ? 220 : 140; easing.type: Easing.OutCubic }
    }

    onVisibleChanged: {
        if (visible) focusScope.forceActiveFocus()
    }

    FocusScope {
        id: focusScope
        anchors.fill: parent
        focus: root.displayState === 16

        Keys.onEscapePressed: {
            root.displayState = 0;
            root.updateState();
        }

        Keys.onPressed: (event) => {
            if (event.key === Qt.Key_1) {
                root.setProfile("island");
                event.accepted = true;
            } else if (event.key === Qt.Key_2) {
                root.setProfile("bar");
                event.accepted = true;
            }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 10

            MenuHeader {
                title: "Shell profiles"
                icon: "\uf0c9"
                hint: "press 1 or 2"
                meta: "2 modes"
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 160
                spacing: 10

                ProfileCard {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    profileId: "island"
                    title: "Island"
                    description: "Dynamic island · dock"
                    active: root.activeProfile === "island"
                    onActivated: root.setProfile("island")
                }

                ProfileCard {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    profileId: "bar"
                    title: "Bar"
                    description: "Command rail · widgets"
                    active: root.activeProfile === "bar"
                    onActivated: root.setProfile("bar")
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 24
                spacing: 8

                Text {
                    Layout.fillWidth: true
                    text: "The whole shell changes in place — no restart."
                    color: root.uiFgDim
                    font.family: root.uiFont
                    font.pixelSize: 9
                    font.weight: Font.Medium
                    elide: Text.ElideRight
                }

                Text {
                    text: "1 / 2"
                    color: root.uiFgFaint
                    font.family: root.font
                    font.pixelSize: 8
                    font.weight: Font.Medium
                    font.letterSpacing: 0.4
                }

                Rectangle {
                    height: 20
                    implicitWidth: escapeText.implicitWidth + 14
                    radius: 7
                    color: "#0AFFFFFF"
                    border.width: 1
                    border.color: "#16FFFFFF"

                    Text {
                        id: escapeText
                        anchors.centerIn: parent
                        text: "esc"
                        color: root.uiFgFaint
                        font.family: root.font
                        font.pixelSize: 8
                        font.weight: Font.Medium
                    }
                }
            }
        }
    }
}
