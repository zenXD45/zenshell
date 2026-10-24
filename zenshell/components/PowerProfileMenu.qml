import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

// Power profile as a list of three rows. The active profile is the only one
// with colour; the others are quiet text. No cards, no keycap boxes.
Item {
    id: powerProfileMenu
    anchors.fill: parent
    property real reveal: root.displayState === 14 ? 1 : 0
    opacity: reveal
    visible: opacity > 0
    clip: true
    scale: 0.992 + reveal * 0.008
    transform: Translate { y: (1 - powerProfileMenu.reveal) * 8 }

    Behavior on reveal {
        NumberAnimation {
            duration: root.displayState === 14 ? root.motionPanel : root.motionExit
            easing.type: root.displayState === 14 ? Easing.OutExpo : Easing.OutCubic
        }
    }

    property color themeAccent: root.currentThemeAccent || root.themeAccent
    property string activeProfile: "balanced"
    property int selectedIndex: 1

    readonly property var profiles: [
        { id: "performance", icon: "\uf135", label: "Performance", sub: "G-Mode · maximum clocks", key: "1" },
        { id: "balanced",    icon: "\uf240", label: "Balanced",    sub: "Automatic fans · normal", key: "2" },
        { id: "power-saver", icon: "\uf06c", label: "Power saver", sub: "Quiet · battery first",   key: "3" }
    ]

    function accentFor(id) {
        if (id === "performance") return root.cWarning
        if (id === "power-saver") return root.cSuccess
        return themeAccent
    }

    Process {
        id: profileProc
        command: []
    }

    function setProfile(profile) {
        activeProfile = profile
        var home = Quickshell.env("HOME")
        var gm = home + "/scripts/dell-gmode.sh"
        var cmd = "powerprofilesctl set " + profile
        if (profile === "performance") {
            cmd = "[ -x " + gm + " ] && " + gm + " set-perf || powerprofilesctl set performance"
        } else if (profile === "power-saver") {
            cmd = "[ -x " + gm + " ] && " + gm + " set-quiet || powerprofilesctl set power-saver"
        } else {
            cmd = "[ -x " + gm + " ] && " + gm + " set-balanced || powerprofilesctl set balanced"
        }
        profileProc.running = false
        profileProc.command = ["bash", "-c", cmd]
        profileProc.running = true
        root.displayState = 0
        root.updateState()
    }

    Process {
        id: fetchActiveProfile
        command: ["powerprofilesctl", "get"]
        stdout: SplitParser {
            onRead: data => {
                var p = data.trim()
                if (p) {
                    activeProfile = p
                    if (p === "performance") selectedIndex = 0
                    else if (p === "balanced") selectedIndex = 1
                    else if (p === "power-saver") selectedIndex = 2
                }
            }
        }
    }

    onVisibleChanged: {
        if (visible) fetchActiveProfile.running = true
    }

    FocusScope {
        anchors.fill: parent
        focus: root.displayState === 14
        Keys.onEscapePressed: { root.displayState = 0; root.updateState(); }
        Keys.onUpPressed: (event) => { if (selectedIndex > 0) selectedIndex--; event.accepted = true; }
        Keys.onDownPressed: (event) => { if (selectedIndex < 2) selectedIndex++; event.accepted = true; }
        Keys.onLeftPressed: (event) => { if (selectedIndex > 0) selectedIndex--; event.accepted = true; }
        Keys.onRightPressed: (event) => { if (selectedIndex < 2) selectedIndex++; event.accepted = true; }
        Keys.onReturnPressed: setProfile(profiles[selectedIndex].id)
        Keys.onPressed: (event) => {
            if (event.key === Qt.Key_1) { selectedIndex = 0; setProfile("performance"); event.accepted = true; }
            else if (event.key === Qt.Key_2) { selectedIndex = 1; setProfile("balanced"); event.accepted = true; }
            else if (event.key === Qt.Key_3) { selectedIndex = 2; setProfile("power-saver"); event.accepted = true; }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: root.s5
        spacing: 0

        MenuHeader {
            title: "Power profile"
        }

        Item { Layout.preferredHeight: root.s2 }

        Repeater {
            model: powerProfileMenu.profiles

            Item {
                id: profileRow
                required property int index
                required property var modelData

                Layout.fillWidth: true
                Layout.preferredHeight: 54

                readonly property bool isTarget: profileRow.index === powerProfileMenu.selectedIndex
                readonly property bool isActive: powerProfileMenu.activeProfile === profileRow.modelData.id
                readonly property color tone: powerProfileMenu.accentFor(profileRow.modelData.id)

                Rectangle {
                    anchors.fill: parent
                    radius: root.rSm
                    color: profileRow.isTarget ? root.ink(0.055)
                        : (rowArea.containsMouse ? root.ink(0.04) : "transparent")
                    Behavior on color { ColorAnimation { duration: root.dMicro } }
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: root.s3
                    anchors.rightMargin: root.s3
                    spacing: root.s4

                    Text {
                        Layout.alignment: Qt.AlignVCenter
                        Layout.preferredWidth: 20
                        horizontalAlignment: Text.AlignHCenter
                        text: profileRow.modelData.icon
                        color: profileRow.isActive ? profileRow.tone : root.cFgMuted
                        font.family: root.fontMono
                        font.pixelSize: 16
                        Behavior on color { ColorAnimation { duration: root.dMicro } }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0

                        Text {
                            Layout.fillWidth: true
                            text: profileRow.modelData.label
                            color: root.cFgPrimary
                            font.family: root.fontSans
                            font.pixelSize: 13
                            font.weight: profileRow.isActive ? Font.DemiBold : Font.Medium
                            elide: Text.ElideRight
                        }

                        Text {
                            Layout.fillWidth: true
                            text: profileRow.modelData.sub
                            color: root.cFgMuted
                            font.family: root.fontSans
                            font.pixelSize: 11
                            elide: Text.ElideRight
                        }
                    }

                    Text {
                        Layout.alignment: Qt.AlignVCenter
                        text: profileRow.isActive ? "In use" : profileRow.modelData.key
                        color: profileRow.isActive ? profileRow.tone : root.ink(0.32)
                        font.family: profileRow.isActive ? root.fontSans : root.fontMono
                        font.pixelSize: 11
                        font.weight: profileRow.isActive ? Font.Medium : Font.Normal
                    }
                }

                MouseArea {
                    id: rowArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onEntered: powerProfileMenu.selectedIndex = profileRow.index
                    onClicked: powerProfileMenu.setProfile(profileRow.modelData.id)
                }
            }
        }

        Item { Layout.fillHeight: true }
    }
}
