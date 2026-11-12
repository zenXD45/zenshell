import QtQuick
import QtQuick.Layouts

// Profile picker for the three shell modes. Each mode is a card previewing what
// it keeps on the desktop; the footer states that switching is in-place so
// nobody expects a restart.
Item {
    id: profileSwitcher
    anchors.fill: parent
    property bool entered: false
    property real reveal: (root.displayState === 16 && entered) ? 1 : 0
    opacity: reveal
    visible: opacity > 0
    transform: Translate { y: (1 - profileSwitcher.reveal) * 6 }

    Behavior on reveal {
        NumberAnimation {
            duration: root.displayState === 16 ? root.motionPanel : root.motionExit
            easing.type: Easing.OutCubic
        }
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
            } else if (event.key === Qt.Key_3) {
                root.setProfile("status");
                event.accepted = true;
            }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: root.s5
            spacing: 0

            MenuHeader {
                title: "Shell profile"
                hint: "1 / 3"
            }

            Item { Layout.preferredHeight: root.s4 }

            Group {
                ProfileRow {
                    profileId: "island"
                    title: "Island"
                    description: "Dynamic island \u00b7 dock"
                    active: root.activeProfile === "island"
                    onActivated: root.setProfile("island")
                }

                ProfileRow {
                    profileId: "bar"
                    title: "Bar"
                    description: "Command rail \u00b7 widgets"
                    active: root.activeProfile === "bar"
                    onActivated: root.setProfile("bar")
                }

                ProfileRow {
                    profileId: "status"
                    title: "Status"
                    description: "Island \u00b7 clock, battery, workspaces"
                    active: root.activeProfile === "status"
                    last: true
                    onActivated: root.setProfile("status")
                }
            }

            Item { Layout.fillHeight: true }

            HintBar {
                hints: [
                    { key: "1 2 3", label: "switch" },
                    { key: "esc", label: "close" }
                ]
            }
        }
    }
}
