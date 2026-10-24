import QtQuick
import QtQuick.Layouts

// Profile picker for the two shell modes. Each mode is a card previewing what
// it keeps on the desktop; the footer states that switching is in-place so
// nobody expects a restart.
Item {
    id: profileSwitcher
    anchors.fill: parent
    property real reveal: root.displayState === 16 ? 1 : 0
    opacity: reveal
    visible: opacity > 0
    clip: true
    scale: 0.992 + reveal * 0.008
    transform: Translate { y: (1 - profileSwitcher.reveal) * 8 }

    Behavior on reveal {
        NumberAnimation {
            duration: root.displayState === 16 ? root.dPage : root.dFast
            easing.type: root.displayState === 16 ? Easing.OutExpo : Easing.OutCubic
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
            }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: root.s5
            spacing: 0

            MenuHeader {
                title: "Shell profile"
                hint: "1 / 2"
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
                    last: true
                    onActivated: root.setProfile("bar")
                }
            }

            Item { Layout.fillHeight: true }

            HintBar {
                hints: [
                    { key: "1 2", label: "switch" },
                    { key: "esc", label: "close" }
                ]
            }
        }
    }
}
