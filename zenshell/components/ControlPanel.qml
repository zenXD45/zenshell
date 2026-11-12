import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire

Item {
    id: controlPanel
    anchors.fill: parent
    property bool entered: false
    property real reveal: (root.displayState === 13 && entered) ? 1 : 0
    opacity: reveal
    visible: opacity > 0
    transform: Translate { y: (1 - controlPanel.reveal) * 6 }

    Behavior on reveal {
        NumberAnimation {
            duration: root.displayState === 13 ? root.motionPanel : root.motionExit
            easing.type: Easing.OutCubic
        }
    }

    // ── Dynamic Theme Accent ───────────────────────────────────────
    property color themeAccent: root.currentThemeAccent || root.themeAccent

    // ── View Navigation ────────────────────────────────────────────
    property string currentView: "main"
    property string mainTab: "controls"

    // ── Header / meta ──────────────────────────────────────────────
    property string panelClock: ""
    property string panelDate: ""

    // ── Network state ──────────────────────────────────────────────
    property bool wifiRadio: true
    property bool wiredActive: false
    property bool wifiActive: false
    property string activeType: "none"
    property string wiredConn: ""
    property string wifiConn: ""
    property string ipAddress: ""
    property var wifiNetworks: []
    property bool wifiLoading: false
    property string connectingSsid: ""

    // ── Bluetooth state ────────────────────────────────────────────
    property bool btPowered: false
    property var btDevices: []
    property bool btLoading: false
    property string connectingMac: ""

    // ── Toggles ────────────────────────────────────────────────────
    property bool caffeineEnabled: false
    property bool nightLightEnabled: false
    property bool micMuted: false
    property string recorderMode: "none"
    property bool recordingActive: false

    // ── Sliders ────────────────────────────────────────────────────
    property real brightnessValue: 50
    property real volumeValue: 50

    // ── In-island action feedback ──────────────────────────────────
    property string actionTitle: ""
    property string actionSub: ""
    property bool actionVisible: false

    // ════════════════════════════════════════════════════════════════
    // │ Core process + action helpers
    // ═════════════════════════════════════════════════════════════════
    Process { id: execCmd; command: [] }

    function runShell(cmd) {
        execCmd.running = false
        execCmd.command = ["bash", "-c", cmd]
        execCmd.running = true
    }

    Timer {
        id: actionTimer
        interval: 1800
        onTriggered: actionVisible = false
    }

    function showAction(title, sub) {
        actionTitle = title
        actionSub = sub || ""
        actionVisible = true
        actionTimer.restart()
    }

    // ── Network ────────────────────────────────────────────────────
    Process {
        id: netProc
        command: []
        stdout: SplitParser {
            onRead: data => {
                connectingSsid = ""
                try {
                    var st = JSON.parse(data.trim())
                    if (st.wired_active !== undefined) {
                        wiredActive = st.wired_active
                        wifiActive = st.wifi_active
                        wifiRadio = st.wifi_radio
                        activeType = st.active_type
                        wiredConn = st.wired_conn
                        wifiConn = st.wifi_conn
                        ipAddress = st.ip
                    }
                } catch(e) {}
            }
        }
    }

    Process {
        id: wifiListProc
        command: ["python3", Quickshell.shellDir + "/scripts/network_ctl.py", "--wifi-list"]
        stdout: SplitParser {
            onRead: data => {
                wifiLoading = false
                try { wifiNetworks = JSON.parse(data.trim()) } catch(e) {}
            }
        }
    }

    function refreshNetwork() {
        if (!netProc.running) {
            netProc.command = ["python3", Quickshell.shellDir + "/scripts/network_ctl.py", "--status"]
            netProc.running = true
        }
        if (currentView === "network" && !wifiListProc.running) {
            wifiLoading = true
            wifiListProc.command = ["python3", Quickshell.shellDir + "/scripts/network_ctl.py", "--wifi-list"]
            wifiListProc.running = true
        }
    }

    function switchWired() {
        netProc.command = ["python3", Quickshell.shellDir + "/scripts/network_ctl.py", "--switch-wired"]
        netProc.running = true
    }

    function switchWifi() {
        netProc.command = ["python3", Quickshell.shellDir + "/scripts/network_ctl.py", "--switch-wifi"]
        netProc.running = true
    }

    function toggleWifiRadio() {
        netProc.command = ["python3", Quickshell.shellDir + "/scripts/network_ctl.py", "--toggle-wifi"]
        netProc.running = true
    }

    function connectWifi(ssid) {
        connectingSsid = ssid
        netProc.command = ["python3", Quickshell.shellDir + "/scripts/network_ctl.py", "--connect-wifi", ssid]
        netProc.running = true
    }

    // ── Bluetooth ──────────────────────────────────────────────────
    Process {
        id: btProc
        command: []
        stdout: SplitParser {
            onRead: data => {
                connectingMac = ""
                try {
                    var st = JSON.parse(data.trim())
                    if (st.powered !== undefined) btPowered = st.powered
                } catch(e) {}
            }
        }
    }

    Process {
        id: btDevProc
        command: ["python3", Quickshell.shellDir + "/scripts/bluetooth_ctl.py", "--devices"]
        stdout: SplitParser {
            onRead: data => {
                btLoading = false
                connectingMac = ""
                try { btDevices = JSON.parse(data.trim()) } catch(e) {}
            }
        }
    }

    function refreshBluetooth() {
        if (!btProc.running) {
            btProc.command = ["python3", Quickshell.shellDir + "/scripts/bluetooth_ctl.py", "--status"]
            btProc.running = true
        }
        if (currentView === "bt" && !btDevProc.running) {
            btLoading = true
            btDevProc.command = ["python3", Quickshell.shellDir + "/scripts/bluetooth_ctl.py", "--devices"]
            btDevProc.running = true
        }
    }

    function toggleBluetooth() {
        btProc.command = ["python3", Quickshell.shellDir + "/scripts/bluetooth_ctl.py", "--toggle"]
        btProc.running = true
    }

    function connectBtDevice(mac) {
        connectingMac = mac
        btDevProc.command = ["python3", Quickshell.shellDir + "/scripts/bluetooth_ctl.py", "--connect", mac]
        btDevProc.running = true
    }

    // ── Sliders ────────────────────────────────────────────────────
    function setBrightness(val) {
        brightnessValue = Math.max(0, Math.min(100, val))
        runShell("brightnessctl s " + Math.round(brightnessValue) + "%")
    }

    function setVolume(val) {
        volumeValue = Math.max(0, Math.min(100, val))
        runShell("wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ " + (volumeValue / 100).toFixed(2))
    }

    // ── Toggles ────────────────────────────────────────────────────
    function toggleCaffeine() {
        var next = !root.values.caffeine;
        root.setValue("caffeine", next);
        caffeineEnabled = next;
        showAction(next ? "Caffeine on" : "Caffeine off",
                   next ? "Idle and sleep are inhibited" : "Normal idle and lock restored");
        caffeineRefresh.restart();
    }

    function toggleNightLight() {
        var next = !root.values.night_light;
        root.setValue("night_light", next);
        nightLightEnabled = next;
        showAction(next ? "Night Light on" : "Night Light off",
                   next ? "Warm tint at 4500K" : "Display temperature restored");
        nightRefresh.restart();
    }

    function toggleMic() {
        micToggle.running = true
    }

    function toggleDnd() {
        var next = !root.values.dnd;
        root.setValue("dnd", next);
        showAction(next ? "Do Not Disturb on" : "Do Not Disturb off",
                   next ? "Alerts stay in the notification shade" : "Island alerts are back")
    }

    function toggleRecord() {
        runShell("if command -v gsr-ui >/dev/null 2>&1; then gsr-ui launch-show; elif command -v gpu-screen-recorder >/dev/null 2>&1; then mkdir -p \"$HOME/Videos\" && (gpu-screen-recorder -w monitor -c mp4 -q very_high -o \"$HOME/Videos/rec_$(date +%Y%m%d_%H%M%S).mp4\" >/dev/null 2>&1 &) ; fi")
        root.displayState = 0
        root.updateState()
    }

    // ════════════════════════════════════════════════════════════════
    // │ State refresh on open
    // ════════════════════════════════════════════════════════════════
    Timer {
        id: initTimer
        interval: 180
        onTriggered: {
            refreshNetwork()
            refreshBluetooth()
            fetchBrightness.running = true
            fetchVolume.running = true
            fetchMic.running = true
            checkNight.running = true
            checkCaffeine.running = true
            checkRecorder.running = true
            checkRecording.running = true
            tickClock()
            clockTimer.running = true
        }
    }

    Timer {
        id: clockTimer
        interval: 1000
        repeat: true
        onTriggered: tickClock()
    }

    function tickClock() {
        var d = new Date()
        var hh = (d.getHours() < 10 ? "0" : "") + d.getHours()
        var mm = (d.getMinutes() < 10 ? "0" : "") + d.getMinutes()
        panelClock = hh + ":" + mm

        var days = ["SUNDAY", "MONDAY", "TUESDAY", "WEDNESDAY", "THURSDAY", "FRIDAY", "SATURDAY"]
        var months = ["JAN", "FEB", "MAR", "APR", "MAY", "JUN", "JUL", "AUG", "SEP", "OCT", "NOV", "DEC"]
        panelDate = days[d.getDay()] + " · " + d.getDate() + " " + months[d.getMonth()]
    }

    onVisibleChanged: {
        if (visible) {
            currentView = "main"
            mainTab = "controls"
            tickClock()
            initTimer.restart()
        }
    }

    Timer {
        interval: 4000
        running: root.displayState === 13
        repeat: true
        onTriggered: {
            refreshNetwork()
            refreshBluetooth()
            checkRecording.running = true
            checkCaffeine.running = true
            checkNight.running = true
            fetchMic.running = true
        }
    }

    Process {
        id: fetchBrightness
        command: ["bash", "-c", "echo $(( $(brightnessctl g) * 100 / $(brightnessctl m) ))"]
        stdout: SplitParser { onRead: data => { brightnessValue = parseInt(data.trim()) || 50 } }
    }

    Process {
        id: fetchVolume
        command: ["bash", "-c", "wpctl get-volume @DEFAULT_AUDIO_SINK@ | awk '{print int($2*100)}'"]
        stdout: SplitParser { onRead: data => { volumeValue = parseInt(data.trim()) || 50 } }
    }

    Process {
        id: fetchMic
        command: ["bash", "-c", "wpctl get-volume @DEFAULT_AUDIO_SOURCE@ | grep -q MUTED && echo '1' || echo '0'"]
        stdout: SplitParser { onRead: data => { micMuted = (data.trim() === '1') } }
    }

    Process {
        id: checkNight
        command: ["bash", "-c", "pgrep -x hyprsunset >/dev/null 2>&1 && echo on || echo off"]
        stdout: SplitParser { onRead: data => { nightLightEnabled = (data.trim() === "on") } }
    }

    Process {
        id: checkRecorder
        command: ["bash", "-c", "command -v gsr-ui >/dev/null 2>&1 && echo ui || (command -v gpu-screen-recorder >/dev/null 2>&1 && echo gsr || echo none)"]
        stdout: SplitParser { onRead: data => { recorderMode = data.trim() } }
    }

    Process {
        id: checkRecording
        command: ["bash", "-c", "pgrep -x gpu-screen-recorder >/dev/null 2>&1 && echo 1 || echo 0"]
        stdout: SplitParser { onRead: data => { recordingActive = (data.trim() === "1") } }
    }

    Process {
        id: checkCaffeine
        command: ["bash", "-c", "pgrep -x hypridle >/dev/null 2>&1 && echo 0 || echo 1"]
        stdout: SplitParser { onRead: data => { caffeineEnabled = (data.trim() === "1") } }
    }

    Process {
        id: micToggle
        command: ["bash", "-c", "wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle; wpctl get-volume @DEFAULT_AUDIO_SOURCE@ | grep -q MUTED && echo muted || echo live"]
        stdout: SplitParser {
            onRead: data => {
                micMuted = (data.trim() === "muted")
                showAction(micMuted ? "Microphone muted" : "Microphone live",
                           micMuted ? "Apps cannot hear you" : "Input is active")
            }
        }
    }

    Timer {
        id: caffeineRefresh
        interval: 450
        onTriggered: checkCaffeine.running = true
    }

    Timer {
        id: nightRefresh
        interval: 600
        onTriggered: checkNight.running = true
    }

    // ── Key escape ─────────────────────────────────────────────────
    FocusScope {
        anchors.fill: parent
        focus: root.displayState === 13
        Keys.onEscapePressed: {
            if (currentView !== "main") {
                currentView = "main"
            } else if (mainTab !== "controls") {
                mainTab = "controls"
            } else {
                root.displayState = 0
                root.updateState()
            }
        }
    }

    // ════════════════════════════════════════════════════════════════
    // │ MAIN VIEW — tonal tabs, quick settings, M3 controls
    // ════════════════════════════════════════════════════════════════
    // ════════════════════════════════════════════════════════════════
    // │ MAIN VIEW — Glass Dark Control Center & Notifications
    // ════════════════════════════════════════════════════════════════
    ColumnLayout {
        id: mainView
        anchors.fill: parent
        anchors.margins: 18
        spacing: 12
        opacity: currentView === "main" ? 1 : 0
        visible: opacity > 0
        transform: Translate { y: currentView === "main" ? (1 - mainView.opacity) * 6 : -mainView.opacity * 6 }
        Behavior on opacity {
            NumberAnimation {
                duration: currentView === "main" ? root.motionBase : root.motionExit
                easing.type: Easing.OutCubic
            }
        }

        // ── Top Header: User Profile, Battery Pill & Quick Actions ─────
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 44
            spacing: 10

            // User Profile Chip (Avatar + Name + Subtitle)
            RowLayout {
                spacing: 10
                Layout.alignment: Qt.AlignVCenter

                // Avatar Squircle
                Rectangle {
                    width: 38
                    height: 38
                    radius: 12
                    color: root.cSurfaceContainerHigh
                    border.width: 1
                    border.color: root.cOutlineVariant

                    Text {
                        anchors.centerIn: parent
                        text: (Quickshell.env("USER") || "Z").charAt(0).toUpperCase()
                        color: root.themeAccent
                        font.family: root.fontSans
                        font.pixelSize: 16
                        font.weight: Font.Bold
                    }
                }

                ColumnLayout {
                    spacing: 0
                    Layout.alignment: Qt.AlignVCenter

                    Text {
                        text: (Quickshell.env("USER") || "zen").charAt(0).toUpperCase() + (Quickshell.env("USER") || "zen").slice(1)
                        color: root.cOnSurface
                        font.family: root.fontSans
                        font.pixelSize: 14
                        font.weight: Font.DemiBold
                    }

                    Text {
                        text: (Quickshell.env("USER") || "zen") + "@archlinux"
                        color: root.cOnSurfaceVariant
                        opacity: 0.60
                        font.family: root.fontMono
                        font.pixelSize: 10
                    }
                }
            }

            Item { Layout.fillWidth: true }

            // Battery Badge Pill
            Rectangle {
                Layout.alignment: Qt.AlignVCenter
                implicitHeight: 28
                implicitWidth: batteryLayout.implicitWidth + 18
                radius: 14
                color: root.batteryCharging
                    ? root.cPrimaryContainer
                    : root.cSurfaceContainer
                border.width: 1
                border.color: root.batteryCharging
                    ? Qt.rgba(root.themeAccent.r, root.themeAccent.g, root.themeAccent.b, 0.35)
                    : root.cOutlineVariant

                RowLayout {
                    id: batteryLayout
                    anchors.centerIn: parent
                    spacing: 5

                    Text {
                        text: root.batteryCharging ? "\uf0e7" : (root.batteryPercent > 20 ? "\uf240" : "\uf244")
                        color: root.batteryCharging ? root.themeAccent : (root.batteryPercent <= 20 ? root.cError : root.cOnSurfaceVariant)
                        font.family: root.fontMono
                        font.pixelSize: 11
                    }

                    Text {
                        text: (root.batteryPercent > 0 ? root.batteryPercent : 80) + "%"
                        color: root.batteryCharging ? root.themeAccent : root.cOnSurface
                        font.family: root.fontMono
                        font.pixelSize: 11
                        font.weight: Font.DemiBold
                    }
                }
            }

            // Quick Settings Action Button
            Rectangle {
                Layout.alignment: Qt.AlignVCenter
                width: 32
                height: 32
                radius: 16
                color: settingsBtnArea.containsMouse ? root.cSurfaceContainerHighest : root.cSurfaceContainer
                border.width: 1
                border.color: settingsBtnArea.containsMouse ? root.cOutline : root.cOutlineVariant
                Behavior on color { ColorAnimation { duration: root.dMicro } }

                Text {
                    anchors.centerIn: parent
                    text: root.icoSettings
                    color: settingsBtnArea.containsMouse ? root.cOnSurface : root.cOnSurfaceVariant
                    font.family: root.fontIcon
                    font.pixelSize: 17
                }

                MouseArea {
                    id: settingsBtnArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.displayState = 0;
                        root.updateState();
                        root.openSettings();
                    }
                }
            }

            // Power Action Button
            Rectangle {
                Layout.alignment: Qt.AlignVCenter
                width: 32
                height: 32
                radius: 16
                color: powerBtnArea.containsMouse ? root.cErrorContainer : root.cSurfaceContainer
                border.width: 1
                border.color: powerBtnArea.containsMouse ? Qt.rgba(root.cError.r, root.cError.g, root.cError.b, 0.40) : root.cOutlineVariant
                Behavior on color { ColorAnimation { duration: root.dMicro } }

                Text {
                    anchors.centerIn: parent
                    text: root.icoPower
                    color: powerBtnArea.containsMouse ? root.cOnErrorContainer : root.cOnSurfaceVariant
                    font.family: root.fontIcon
                    font.pixelSize: 16
                }

                MouseArea {
                    id: powerBtnArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.displayState = 12;
                        root.updateState();
                    }
                }
            }
        }

        // ── Segmented Glass Tab Switcher ───────────────────────────
        Rectangle {
            id: segmentedTabs
            Layout.fillWidth: true
            Layout.preferredHeight: 38
            radius: 19
            color: root.cSurfaceContainerLow
            border.width: 1
            border.color: root.cOutlineVariant

            // Animated Sliding Pill Indicator
            Rectangle {
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.topMargin: 3
                anchors.bottomMargin: 3
                x: mainTab === "controls" ? 3 : (parent.width / 2)
                width: (parent.width / 2) - 3
                radius: 16
                color: root.cSurfaceContainerHigh
                border.width: 1
                border.color: root.cOutline

                Behavior on x {
                    NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
                }
            }

            RowLayout {
                anchors.fill: parent
                spacing: 0

                // Controls Tab Button
                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 6

                        Text {
                            text: "Controls"
                            color: mainTab === "controls" ? root.cOnSurface : root.cOnSurfaceVariant
                            font.family: root.fontSans
                            font.pixelSize: 13
                            font.weight: mainTab === "controls" ? Font.Bold : Font.Medium
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: mainTab = "controls"
                    }
                }

                // Notifications Tab Button
                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 6

                        Text {
                            text: "Notifications"
                            color: mainTab === "notifications" ? root.cOnSurface : root.cOnSurfaceVariant
                            font.family: root.fontSans
                            font.pixelSize: 13
                            font.weight: mainTab === "notifications" ? Font.Bold : Font.Medium
                        }

                        // Badge Counter
                        Rectangle {
                            width: Math.max(18, notifCountText.implicitWidth + 8)
                            height: 18
                            radius: 9
                            color: root.notificationList.length > 0
                                ? (mainTab === "notifications" ? root.themeAccent : root.cSurfaceContainerHighest)
                                : root.cSurfaceContainer

                            Text {
                                id: notifCountText
                                anchors.centerIn: parent
                                text: root.notificationList.length
                                color: root.notificationList.length > 0 ? (mainTab === "notifications" ? root.onAccent() : root.cOnSurface) : root.cOnSurfaceVariant
                                font.family: root.fontMono
                                font.pixelSize: 10
                                font.weight: Font.Bold
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: mainTab = "notifications"
                    }
                }
            }
        }

        // ── Tab Content Container ──────────────────────────────────
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            // ── Controls View ──────────────────────────────────────
            ColumnLayout {
                anchors.fill: parent
                spacing: 12
                visible: mainTab === "controls"

                // 4 Quick Toggle Tiles
                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 74
                    spacing: 8

                    ToggleTile {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        title: "Caffeine"
                        subtitle: caffeineEnabled ? "Active" : "Off"
                        icon: "\uf0f4"
                        iconFont: root.fontMono
                        checked: caffeineEnabled
                        onToggled: toggleCaffeine()
                    }

                    ToggleTile {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        title: "Night light"
                        subtitle: nightLightEnabled ? "Warm" : "Off"
                        icon: root.icoNight
                        checked: nightLightEnabled
                        onToggled: toggleNightLight()
                    }

                    ToggleTile {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        title: "Silence"
                        subtitle: root.dndEnabled ? "Silent" : "Off"
                        icon: root.icoDnd
                        checked: root.dndEnabled
                        onToggled: toggleDnd()
                    }

                    ToggleTile {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        title: "Microphone"
                        subtitle: micMuted ? "Muted" : "Active"
                        icon: root.icoMic
                        checked: !micMuted
                        onToggled: toggleMic()
                    }
                }

                // 2 Sleek Capsule Sliders
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    SliderRow {
                        Layout.fillWidth: true
                        icon: root.icoBrightness
                        value: brightnessValue
                        min: 0
                        max: 100
                        valueSuffix: "%"
                        onMoved: setBrightness(value)
                    }

                    SliderRow {
                        Layout.fillWidth: true
                        icon: volumeValue <= 0 ? root.icoVolumeMute : root.icoVolume
                        value: volumeValue
                        min: 0
                        max: 100
                        valueSuffix: "%"
                        onMoved: setVolume(value)
                    }
                }

                // System Connectivity & Services Group
                Group {
                    GroupRow {
                        icon: activeType === "wired" ? "\uf0a0" : root.icoWifi
                        iconFont: activeType === "wired" ? root.fontMono : root.fontIcon
                        label: "Network"
                        value: activeType === "wired"
                            ? (wiredConn || "Wired")
                            : (wifiActive ? (wifiConn || "Wi-Fi") : "Offline")
                        valueActive: activeType === "wired" || wifiActive
                        chevron: true
                        showDivider: true
                        onActivated: { currentView = "network"; refreshNetwork() }
                    }

                    GroupRow {
                        icon: root.icoBluetooth
                        label: "Bluetooth"
                        value: btPowered ? "On" : "Off"
                        valueActive: btPowered
                        chevron: true
                        showDivider: true
                        onActivated: { currentView = "bt"; refreshBluetooth() }
                    }

                    GroupRow {
                        icon: "\uf030"
                        iconFont: root.fontMono
                        label: "Camera"
                        value: !root.cameraService ? "Not installed"
                            : root.cameraService.block ? "Blocked"
                            : root.cameraService.consumers > 0 ? "In use"
                            : root.cameraService.running ? "Live"
                            : "Idle"
                        valueActive: root.cameraService && (root.cameraService.consumers > 0 || root.cameraService.running)
                        chevron: true
                        showDivider: recorderMode !== "none"
                        onActivated: {
                            root.displayState = 24;
                            root.updateState();
                        }
                    }

                    GroupRow {
                        visible: recorderMode !== "none"
                        icon: recordingActive ? "\uf111" : "\uf03d"
                        iconFont: root.fontMono
                        label: "Screen recording"
                        value: recordingActive ? "Recording" : "Idle"
                        valueActive: recordingActive
                        destructive: recordingActive
                        onActivated: toggleRecord()
                    }
                }

                Item { Layout.fillHeight: true }

                // Footer Metadata
                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 18

                    Text {
                        text: "ZenShell"
                        color: root.cOnSurfaceVariant
                        opacity: 0.50
                        font.family: root.fontMono
                        font.pixelSize: 10
                        font.letterSpacing: 0.08
                    }

                    Item { Layout.fillWidth: true }

                    Text {
                        text: root.activeProfile === "bar" ? "Command bar" : (root.activeProfile === "status" ? "Status island" : "Dynamic island")
                        color: root.cOnSurfaceVariant
                        opacity: 0.50
                        font.family: root.fontMono
                        font.pixelSize: 10
                    }
                }
            }

            // ── Notifications View ─────────────────────────────────
            ColumnLayout {
                anchors.fill: parent
                spacing: 10
                visible: mainTab === "notifications"

                // Header with Count + Clear All Button
                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 28

                    Text {
                        text: root.notificationList.length > 0
                            ? (root.notificationList.length + " Notifications")
                            : "Recent"
                        color: root.cOnSurfaceVariant
                        font.family: root.fontSans
                        font.pixelSize: 12
                        font.weight: Font.DemiBold
                    }

                    Item { Layout.fillWidth: true }

                    // Clear All Glass Button
                    Rectangle {
                        visible: root.notificationList.length > 0
                        implicitWidth: clearText.implicitWidth + 18
                        implicitHeight: 24
                        radius: 12
                        color: clearArea.containsMouse ? root.cSurfaceContainerHighest : root.cSurfaceContainerHigh
                        border.width: 1
                        border.color: clearArea.containsMouse ? root.cOutline : root.cOutlineVariant

                        Text {
                            id: clearText
                            anchors.centerIn: parent
                            text: "Clear all"
                            color: clearArea.containsMouse ? root.cOnSurface : root.cOnSurfaceVariant
                            font.family: root.fontSans
                            font.pixelSize: 11
                            font.weight: Font.Medium
                        }

                        MouseArea {
                            id: clearArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: clearAllNotifications()
                        }
                    }
                }

                // Notification Cards List
                ListView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    visible: root.notificationList.length > 0
                    clip: true
                    spacing: 8
                    boundsBehavior: Flickable.StopAtBounds
                    model: root.notificationList

                    delegate: NotificationItem {
                        width: ListView.view.width
                        appName: modelData.app
                        summary: modelData.summary
                        body: modelData.body
                        time: modelData.time
                        onDismissed: clearNotification(modelData.id)
                    }
                }

                // Empty State
                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    visible: root.notificationList.length === 0

                    EmptyState {
                        anchors.centerIn: parent
                        icon: root.icoNotifications
                        title: "No Notifications"
                        detail: root.dndEnabled ? "Do Not Disturb is currently active" : "All caught up for now"
                    }
                }
            }
        }
    }

    // ════════════════════════════════════════════════════════════════
    // │ NETWORK VIEW
    // ════════════════════════════════════════════════════════════════
    ColumnLayout {
        id: networkView
        anchors.fill: parent
        anchors.margins: root.s5
        spacing: 0
        opacity: currentView === "network" ? 1 : 0
        visible: opacity > 0
        transform: Translate { y: currentView === "network" ? (1 - networkView.opacity) * 6 : -networkView.opacity * 6 }
        Behavior on opacity {
            NumberAnimation {
                duration: currentView === "network" ? root.motionBase : root.motionExit
                easing.type: Easing.OutCubic
            }
        }

        MenuHeader {
            title: "Network"
            meta: ipAddress
            back: true
            onBackClicked: currentView = "main"
        }

        Item { Layout.preferredHeight: root.s3 }

        Group {
            ListRow {
                icon: root.icoWifi
                label: "Wi-Fi"
                detail: wifiActive ? (wifiConn || "Connected") : (wifiRadio ? "Radio on" : "Radio off")
                value: wifiActive ? "Connected" : (wifiRadio ? "On" : "Off")
                active: wifiActive
                onClicked: wifiRadio ? switchWifi() : toggleWifiRadio()
            }

            ListRow {
                icon: "󰈀"
                iconFont: root.fontMono
                label: "Wired"
                value: wiredActive ? "Connected" : "—"
                active: wiredActive
                onClicked: switchWired()
            }

            ListRow {
                icon: root.icoWifi
                label: "Wi-Fi radio"
                value: wifiRadio ? "On" : "Off"
                chevron: false
                onClicked: toggleWifiRadio()
            }
        }

        Item { Layout.preferredHeight: root.s5 }

        GroupHeader {
            title: wifiLoading ? "Scanning…" : "Available networks"
            action: wifiLoading ? "" : "Scan"
            onActionClicked: refreshNetwork()
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            ListView {
                anchors.fill: parent
                visible: !wifiLoading
                clip: true
                spacing: root.s1
                boundsBehavior: Flickable.StopAtBounds
                model: wifiNetworks

                delegate: Item {
                    id: netRow
                    width: ListView.view.width
                    height: 56
                    property var net: wifiNetworks[index]
                    property int strength: net && net.signal !== undefined ? net.signal : 0

                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: 2
                        radius: root.rMd
                        color: netRowArea.containsMouse ? root.cStateHover : "transparent"
                        Behavior on color { ColorAnimation { duration: root.dMicro } }
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 16
                        anchors.rightMargin: 16
                        spacing: root.s4

                        Item {
                            Layout.preferredWidth: 18
                            Layout.preferredHeight: 14
                            Layout.alignment: Qt.AlignVCenter

                            Row {
                                anchors.right: parent.right
                                anchors.bottom: parent.bottom
                                spacing: 2

                                Repeater {
                                    model: 4

                                    Rectangle {
                                        width: 3
                                        height: 4 + index * 3
                                        radius: 1.5
                                        anchors.bottom: parent.bottom
                                        color: index < netRow.strength ? themeAccent : root.cOutlineVariant
                                    }
                                }
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0

                            Text {
                                Layout.fillWidth: true
                                text: netRow.net && netRow.net.ssid ? netRow.net.ssid : "Unknown"
                                color: root.cOnSurface
                                font.family: root.fontSans
                                font.pixelSize: 14
                                font.weight: Font.Medium
                                elide: Text.ElideRight
                            }

                            Text {
                                Layout.fillWidth: true
                                text: netRow.net && netRow.net.security ? "Secured" : "Open"
                                color: root.cOnSurfaceVariant
                                font.family: root.fontSans
                                font.pixelSize: 12
                            }
                        }

                        Text {
                            Layout.alignment: Qt.AlignVCenter
                            text: connectingSsid === (netRow.net ? netRow.net.ssid : "")
                                ? "Connecting…"
                                : (netRow.net && netRow.net.active ? "Connected" : "Connect")
                            color: connectingSsid === (netRow.net ? netRow.net.ssid : "") || (netRow.net && netRow.net.active)
                                ? themeAccent
                                : root.cOnSurfaceVariant
                            font.family: root.fontSans
                            font.pixelSize: 12
                            font.weight: Font.Medium
                        }
                    }

                    MouseArea {
                        id: netRowArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: connectWifi(netRow.net ? netRow.net.ssid : "")
                    }
                }
            }

            ColumnLayout {
                anchors.centerIn: parent
                spacing: root.s2
                visible: !wifiLoading && wifiNetworks.length === 0

                EmptyState {
                    Layout.alignment: Qt.AlignHCenter
                    icon: root.icoSearchOff
                    title: "No networks found"
                    detail: wifiRadio ? "Move closer to the router and scan again" : "Turn the Wi-Fi radio on"
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "Scan again"
                    color: root.cPrimary
                    font.family: root.fontSans
                    font.pixelSize: 12
                    font.weight: Font.DemiBold

                    MouseArea {
                        id: scanArea
                        anchors.fill: parent
                        anchors.margins: -8
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: refreshNetwork()
                    }
                }
            }
        }
    }

    // ════════════════════════════════════════════════════════════════
    // │ BLUETOOTH VIEW
    // ════════════════════════════════════════════════════════════════
    ColumnLayout {
        id: btView
        anchors.fill: parent
        anchors.margins: root.s5
        spacing: 0
        opacity: currentView === "bt" ? 1 : 0
        visible: opacity > 0
        transform: Translate { y: currentView === "bt" ? (1 - btView.opacity) * 6 : -btView.opacity * 6 }
        Behavior on opacity {
            NumberAnimation {
                duration: currentView === "bt" ? root.motionBase : root.motionExit
                easing.type: Easing.OutCubic
            }
        }

        MenuHeader {
            title: "Bluetooth"
            meta: btPowered ? btDevices.length + (btDevices.length === 1 ? " device" : " devices") : "Off"
            back: true
            onBackClicked: currentView = "main"
        }

        Item { Layout.preferredHeight: root.s3 }

        Group {
            ListRow {
                icon: root.icoBluetooth
                label: "Bluetooth"
                value: btPowered ? "On" : "Off"
                onClicked: toggleBluetooth()
            }
        }

        Item { Layout.preferredHeight: root.s5 }

        GroupHeader {
            title: btLoading ? "Searching…" : "Devices"
            action: btLoading ? "" : "Scan"
            onActionClicked: refreshBluetooth()
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            ListView {
                anchors.fill: parent
                visible: !btLoading
                clip: true
                spacing: root.s1
                boundsBehavior: Flickable.StopAtBounds
                model: btDevices

                delegate: Item {
                    id: btRow
                    width: ListView.view.width
                    height: 56
                    property var device: btDevices[index]

                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: 2
                        radius: root.rMd
                        color: btRowArea.containsMouse ? root.cStateHover : "transparent"
                        Behavior on color { ColorAnimation { duration: root.dMicro } }
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 16
                        anchors.rightMargin: 16
                        spacing: root.s4

                        Text {
                            Layout.preferredWidth: 24
                            Layout.alignment: Qt.AlignVCenter
                            horizontalAlignment: Text.AlignHCenter
                            text: getDeviceIcon(btRow.device ? btRow.device.type : "")
                            color: btRow.device && btRow.device.connected ? themeAccent : root.cOnSurfaceVariant
                            font.family: root.fontMono
                            font.pixelSize: 16
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 1

                            Text {
                                Layout.fillWidth: true
                                text: btRow.device && btRow.device.name ? btRow.device.name : "Unknown device"
                                color: root.cOnSurface
                                font.family: root.fontSans
                                font.pixelSize: 14
                                font.weight: Font.Medium
                                elide: Text.ElideRight
                            }

                            Text {
                                Layout.fillWidth: true
                                text: btRow.device && btRow.device.connected ? "Connected"
                                    : (btRow.device && btRow.device.paired ? "Paired" : "Available")
                                color: btRow.device && btRow.device.connected ? themeAccent : root.cOnSurfaceVariant
                                font.family: root.fontSans
                                font.pixelSize: 12
                            }
                        }

                        Text {
                            Layout.alignment: Qt.AlignVCenter
                            text: connectingMac !== "" && btRow.device && connectingMac === btRow.device.mac
                                ? "Connecting…"
                                : (btRow.device && btRow.device.connected ? "Disconnect" : "Connect")
                            color: btRow.device && btRow.device.connected ? root.cOnSurfaceVariant : root.cPrimary
                            font.family: root.fontSans
                            font.pixelSize: 12
                            font.weight: Font.Medium
                        }
                    }

                    MouseArea {
                        id: btRowArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: if (btRow.device && btRow.device.mac) connectBtDevice(btRow.device.mac)
                    }
                }
            }

            EmptyState {
                anchors.centerIn: parent
                width: parent.width - root.s6
                visible: !btLoading && btDevices.length === 0
                icon: root.icoBluetooth
                title: btPowered ? "No devices found" : "Bluetooth is off"
                detail: btPowered ? "Put the device in pairing mode" : "Turn Bluetooth on to connect"
            }
        }
    }

    // ── Action snackbar ────────────────────────────────────────────
    Item {
        id: actionToast
        anchors.bottom: parent.bottom
        anchors.bottomMargin: root.s5
        anchors.horizontalCenter: parent.horizontalCenter
        width: parent.width - root.s7
        height: 52
        opacity: actionVisible ? 1 : 0
        visible: opacity > 0
        transform: Translate { y: (1 - actionToast.opacity) * 8 }
        Behavior on opacity {
            NumberAnimation {
                duration: actionVisible ? root.motionBase : root.motionExit
                easing.type: Easing.OutCubic
            }
        }

        Rectangle {
            anchors.fill: parent
            radius: root.rSm
            color: root.cInverseSurface

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: root.s5
                anchors.rightMargin: root.s5
                spacing: root.s3

                Text {
                    text: actionTitle
                    color: root.cInverseOnSurface
                    font.family: root.fontSans
                    font.pixelSize: 13
                    font.weight: Font.DemiBold
                }

                Text {
                    Layout.fillWidth: true
                    text: actionSub
                    color: root.cInverseOnSurface
                    opacity: 0.72
                    font.family: root.fontSans
                    font.pixelSize: 12
                    elide: Text.ElideRight
                }
            }
        }
    }

    function getDeviceIcon(type) {
        switch (type) {
            case "headphones": return "\uf025"
            case "keyboard": return "\uf11c"
            case "mouse": return "\uf2c5"
            case "phone": return "\uf3e0"
            case "computer": return "\uf108"
            case "speaker": return "\uf028"
            default: return "\uf293"
        }
    }
}
