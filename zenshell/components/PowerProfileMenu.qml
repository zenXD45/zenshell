import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

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
        if (visible) {
            fetchActiveProfile.running = true
        }
    }

    FocusScope {
        anchors.fill: parent
        focus: root.displayState === 14
        Keys.onEscapePressed: { root.displayState = 0; root.updateState(); }
        Keys.onLeftPressed: (event) => { if (selectedIndex > 0) selectedIndex--; event.accepted = true; }
        Keys.onRightPressed: (event) => { if (selectedIndex < 2) selectedIndex++; event.accepted = true; }
        Keys.onReturnPressed: {
            var profs = ["performance", "balanced", "power-saver"];
            setProfile(profs[selectedIndex]);
        }
        Keys.onPressed: (event) => {
            if (event.key === Qt.Key_1) { selectedIndex = 0; setProfile("performance"); event.accepted = true; }
            else if (event.key === Qt.Key_2) { selectedIndex = 1; setProfile("balanced"); event.accepted = true; }
            else if (event.key === Qt.Key_3) { selectedIndex = 2; setProfile("power-saver"); event.accepted = true; }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 12

        MenuHeader {
            title: "Power Profile"
            icon: "\uf0e4"
            hint: "esc"
            meta: activeProfile === "performance" ? "Performance" : (activeProfile === "power-saver" ? "Power Saver" : "Balanced")
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 12

            Repeater {
                model: [
                    { id: "performance", icon: "\uf135", label: "Performance", sub: "G-Mode • Max Speed", key: "1", accent: "#F59E0B" },
                    { id: "balanced",    icon: "\uf240", label: "Balanced",    sub: "Auto Fans • Normal", key: "2", accent: "#838996" },
                    { id: "power-saver", icon: "\uf06c", label: "Power Saver", sub: "Quiet • Battery",   key: "3", accent: "#34D399" }
                ]

                Item {
                    id: profileCard
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.minimumWidth: 120

                    property bool isSel: index === selectedIndex
                    property bool isActive: activeProfile === modelData.id
                    property bool isHov: btnArea.containsMouse
                    property color itemAccent: modelData.id === "balanced" ? powerProfileMenu.themeAccent : modelData.accent

                    Rectangle {
                        id: card
                        anchors.fill: parent
                        radius: 16
                        color: profileCard.isActive
                            ? Qt.rgba(profileCard.itemAccent.r, profileCard.itemAccent.g, profileCard.itemAccent.b, 0.12)
                            : (profileCard.isSel || profileCard.isHov ? root.ink(0.039) : root.ink(0.02))
                        border.width: profileCard.isActive ? 1.3 : 1
                        border.color: profileCard.isActive
                            ? Qt.rgba(profileCard.itemAccent.r, profileCard.itemAccent.g, profileCard.itemAccent.b, 0.45)
                            : (profileCard.isSel || profileCard.isHov ? root.ink(0.122) : root.ink(0.055))

                        Behavior on color { ColorAnimation { duration: 160 } }
                        Behavior on border.color { ColorAnimation { duration: 160 } }

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
                            spacing: 6

                            Item {
                                Layout.preferredWidth: 34
                                Layout.preferredHeight: 34
                                Layout.alignment: Qt.AlignHCenter

                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.icon
                                    color: profileCard.isActive
                                        ? profileCard.itemAccent
                                        : Qt.rgba(profileCard.itemAccent.r, profileCard.itemAccent.g, profileCard.itemAccent.b, profileCard.isSel || profileCard.isHov ? 0.85 : 0.55)
                                    font.family: root.font
                                    font.pixelSize: 18
                                    Behavior on color { ColorAnimation { duration: 160 } }
                                }
                            }

                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: modelData.label
                                color: profileCard.isActive ? root.uiFg : (profileCard.isSel || profileCard.isHov ? root.uiFg : root.uiFgDim)
                                font.family: root.uiFont
                                font.pixelSize: 12
                                font.weight: profileCard.isActive ? Font.DemiBold : Font.Medium
                                Behavior on color { ColorAnimation { duration: 160 } }
                            }

                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: modelData.sub
                                color: profileCard.isActive ? root.ink(0.651) : root.ink(0.502)
                                font.family: root.uiFont
                                font.pixelSize: 9
                                font.weight: Font.Medium
                                Behavior on color { ColorAnimation { duration: 160 } }
                            }
                        }

                        Rectangle {
                            anchors.top: parent.top
                            anchors.right: parent.right
                            anchors.margins: 7
                            width: 15
                            height: 15
                            radius: 4
                            color: profileCard.isSel || profileCard.isActive
                                ? Qt.rgba(profileCard.itemAccent.r, profileCard.itemAccent.g, profileCard.itemAccent.b, 0.08)
                                : root.ink(0.024)
                            border.width: 1
                            border.color: profileCard.isSel || profileCard.isActive
                                ? Qt.rgba(profileCard.itemAccent.r, profileCard.itemAccent.g, profileCard.itemAccent.b, 0.28)
                                : root.ink(0.063)

                            Text {
                                anchors.centerIn: parent
                                text: modelData.key
                                color: profileCard.isSel || profileCard.isActive ? profileCard.itemAccent : root.ink(0.439)
                                font.family: root.font
                                font.pixelSize: 8
                                font.weight: Font.Medium
                            }
                        }

                        Rectangle {
                            anchors.bottom: parent.bottom
                            anchors.bottomMargin: 6
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: profileCard.isActive ? 22 : (profileCard.isSel ? 10 : 0)
                            height: 2
                            radius: 1
                            color: profileCard.itemAccent
                            Behavior on width { NumberAnimation { duration: 220; easing.type: Easing.OutQuart } }
                        }

                        MouseArea {
                            id: btnArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onPressed: card.press = 0.94
                            onReleased: card.press = 1.0
                            onClicked: setProfile(modelData.id)
                            onEntered: selectedIndex = index
                        }
                    }
                }
            }
        }
    }
}
