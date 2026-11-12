import QtQuick
import QtQuick.Layouts
import Quickshell.Io

// Session actions as a list, not a row of cards. One line per action, the
// shortcut printed on the row instead of hidden in a footer, and a single
// destructive cue: Shutdown turns red only when it is the target.
Item {
    id: powerRoot
    anchors.fill: parent
    property bool entered: false
    property real reveal: (root.displayState === 12 && entered) ? 1 : 0
    opacity: reveal
    visible: opacity > 0
    transform: Translate { y: (1 - powerRoot.reveal) * 6 }

    Behavior on reveal {
        NumberAnimation {
            duration: root.displayState === 12 ? root.motionPanel : root.motionExit
            easing.type: Easing.OutCubic
        }
    }

    property int selectedIndex: 0

    readonly property var actions: [
        { icon: root.icoLock,     label: "Lock",      key: "L", decisive: false },
        { icon: root.icoBedtime,  label: "Suspend",   key: "U", decisive: false },
        { icon: root.icoLogout,   label: "Log out",   key: "E", decisive: false },
        { icon: root.icoRestart,  label: "Restart",   key: "R", decisive: false },
        { icon: root.icoPower,    label: "Shut down", key: "S", decisive: true }
    ]

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
        Keys.onUpPressed: (event) => { if (powerRoot.selectedIndex > 0) powerRoot.selectedIndex--; event.accepted = true; }
        Keys.onDownPressed: (event) => { if (powerRoot.selectedIndex < powerRoot.actions.length - 1) powerRoot.selectedIndex++; event.accepted = true; }
        Keys.onLeftPressed: (event) => { if (powerRoot.selectedIndex > 0) powerRoot.selectedIndex--; event.accepted = true; }
        Keys.onRightPressed: (event) => { if (powerRoot.selectedIndex < powerRoot.actions.length - 1) powerRoot.selectedIndex++; event.accepted = true; }
        Keys.onReturnPressed: powerRoot.executeAction(powerRoot.selectedIndex)
        Keys.onPressed: (event) => {
            var keys = {"L": 0, "U": 1, "E": 2, "R": 3, "S": 4};
            var k = event.text.toUpperCase();
            if (k in keys) { powerRoot.selectedIndex = keys[k]; powerRoot.executeAction(keys[k]); event.accepted = true; }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: root.s5
        spacing: 0

        MenuHeader {
            title: "Power"
        }

        Item { Layout.preferredHeight: root.s4 }

        Group {
            Repeater {
                model: powerRoot.actions

                GroupRow {
                    required property int index
                    required property var modelData

                    rowHeight: 48
                    icon: modelData.icon
                    label: modelData.label
                    value: modelData.key
                    valueKeycap: true
                    destructive: modelData.decisive
                    selected: index === powerRoot.selectedIndex
                    last: index === powerRoot.actions.length - 1
                    onActivated: powerRoot.executeAction(index)
                    onEntered: powerRoot.selectedIndex = index
                }
            }
        }

        Item { Layout.fillHeight: true }
    }
}
