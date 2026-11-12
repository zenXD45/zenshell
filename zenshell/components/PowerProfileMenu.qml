import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

// Power profile as a list of three rows. The active profile is the only one
// with colour; the others are quiet text. No cards, no keycap boxes.
Item {
    id: powerProfileMenu
    anchors.fill: parent
    property bool entered: false
    property real reveal: (root.displayState === 14 && entered) ? 1 : 0
    opacity: reveal
    visible: opacity > 0
    transform: Translate { y: (1 - powerProfileMenu.reveal) * 6 }

    Behavior on reveal {
        NumberAnimation {
            duration: root.displayState === 14 ? root.motionPanel : root.motionExit
            easing.type: Easing.OutCubic
        }
    }

    property color themeAccent: root.currentThemeAccent || root.themeAccent
    property string activeProfile: "balanced"
    property int selectedIndex: 1

    readonly property var profiles: [
        { id: "performance", icon: root.icoPower,   label: "Performance", sub: "G-Mode · maximum clocks", key: "1" },
        { id: "balanced",    icon: root.icoBattery, label: "Balanced",    sub: "Automatic fans · normal", key: "2" },
        { id: "power-saver", icon: root.icoBedtime, label: "Power saver", sub: "Quiet · battery first",   key: "3" }
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

        Item { Layout.preferredHeight: root.s3 }

        Group {
            Repeater {
                model: powerProfileMenu.profiles

                Item {
                    id: profileRow
                    required property int index
                    required property var modelData

                    width: parent ? parent.width : 0
                    height: 56

                    readonly property bool isTarget: profileRow.index === powerProfileMenu.selectedIndex
                    readonly property bool isActive: powerProfileMenu.activeProfile === profileRow.modelData.id
                    readonly property color tone: powerProfileMenu.accentFor(profileRow.modelData.id)

                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: 4
                        radius: root.rMd
                        color: profileRow.isTarget ? root.cSecondaryContainer
                            : (rowArea.containsMouse ? root.cStateHover : "transparent")
                        Behavior on color { ColorAnimation { duration: root.dMicro } }
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 16
                        anchors.rightMargin: 16
                        spacing: root.s4

                        Text {
                            Layout.alignment: Qt.AlignVCenter
                            Layout.preferredWidth: 24
                            horizontalAlignment: Text.AlignHCenter
                            text: profileRow.modelData.icon
                            color: profileRow.isActive ? profileRow.tone : root.cOnSurfaceVariant
                            font.family: root.fontIcon
                            font.pixelSize: 19
                            Behavior on color { ColorAnimation { duration: root.dMicro } }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 1

                            Text {
                                Layout.fillWidth: true
                                text: profileRow.modelData.label
                                color: root.cOnSurface
                                font.family: root.fontSans
                                font.pixelSize: 14
                                font.weight: profileRow.isActive ? Font.DemiBold : Font.Medium
                                elide: Text.ElideRight
                            }

                            Text {
                                Layout.fillWidth: true
                                text: profileRow.modelData.sub
                                color: profileRow.isActive ? profileRow.tone : root.cOnSurfaceVariant
                                font.family: root.fontSans
                                font.pixelSize: 12
                                elide: Text.ElideRight
                            }
                        }

                        Text {
                            Layout.alignment: Qt.AlignVCenter
                            visible: profileRow.isActive
                            text: "In use"
                            color: profileRow.tone
                            font.family: root.fontSans
                            font.pixelSize: 12
                            font.weight: Font.Medium
                        }

                        Rectangle {
                            Layout.alignment: Qt.AlignVCenter
                            visible: !profileRow.isActive
                            width: 20
                            height: 20
                            radius: 6
                            color: root.cSurfaceContainerHighest
                            border.width: 1
                            border.color: root.cOutlineVariant

                            Text {
                                anchors.centerIn: parent
                                text: profileRow.modelData.key
                                color: root.cOnSurfaceVariant
                                font.family: root.fontMono
                                font.pixelSize: 10
                            }
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
        }

        Item { Layout.fillHeight: true }
    }
}
