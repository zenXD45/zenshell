import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire

Item {
    id: controlPanel
    anchors.fill: parent
    property real reveal: root.displayState === 13 ? 1 : 0
    opacity: reveal
    visible: opacity > 0
    clip: true
    scale: 0.992 + reveal * 0.008
    transform: Translate { y: (1 - controlPanel.reveal) * 8 }

    Behavior on reveal {
        NumberAnimation {
            duration: root.displayState === 13 ? root.motionPanel : root.motionExit
            easing.type: root.displayState === 13 ? Easing.OutExpo : Easing.OutCubic
        }
    }

    // ── Dynamic Theme Accent ───────────────────────────────────────
    property color themeAccent: root.currentThemeAccent || root.themeAccent

    // ── View Navigation ────────────────────────────────────────────
    property string currentView: "main"

    // ── Header / meta ──────────────────────────────────────────────
    property string panelClock: ""

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
    }

    onVisibleChanged: {
        if (visible) {
            currentView = "main"
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
            } else {
                root.displayState = 0
                root.updateState()
            }
        }
    }

    // ════════════════════════════════════════════════════════════════
    // │ MAIN VIEW — inset groups, hairline rows, real switches
    // ════════════════════════════════════════════════════════════════
    ColumnLayout {
        id: mainView
        anchors.fill: parent
        anchors.margins: root.s5
        spacing: 0
        opacity: currentView === "main" ? 1 : 0
        visible: opacity > 0
        transform: Translate { y: currentView === "main" ? (1 - mainView.opacity) * 6 : -mainView.opacity * 6 }
        Behavior on opacity {
            NumberAnimation {
                duration: currentView === "main" ? root.motionBase : root.motionExit
                easing.type: Easing.OutCubic
            }
        }

        // ── Header ─────────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 34
            spacing: root.s2

            Text {
                Layout.alignment: Qt.AlignVCenter
                text: "Control Center"
                color: root.cFgPrimary
                font.family: root.fontSans
                font.pixelSize: 17
                font.weight: Font.DemiBold
                font.letterSpacing: -0.2
            }

            Item { Layout.fillWidth: true }

            Text {
                Layout.alignment: Qt.AlignVCenter
                text: panelClock
                color: root.ink(0.40)
                font.family: root.fontMono
                font.pixelSize: 11
            }

            IconButton {
                Layout.alignment: Qt.AlignVCenter
                icon: "\uf013"
                onClicked: {
                    root.displayState = 0;
                    root.updateState();
                    root.openSettings();
                }
            }
        }

        Item { Layout.preferredHeight: root.s3 }

        // ── Connections ────────────────────────────────────────────
        Group {
            GroupRow {
                icon: activeType === "wired" ? "\uf0a0" : "\uf1eb"
                label: "Network"
                value: activeType === "wired"
                    ? (wiredConn || "Wired")
                    : (wifiActive ? (wifiConn || "Wi-Fi") : "Offline")
                chevron: true
                onActivated: { currentView = "network"; refreshNetwork() }
            }

            GroupRow {
                icon: "\uf293"
                label: "Bluetooth"
                value: btPowered ? "On" : "Off"
                chevron: true
                onActivated: { currentView = "bt"; refreshBluetooth() }
            }

            GroupRow {
                icon: "\uf030"
                label: "Camera"
                value: !root.cameraService ? "Not installed"
                    : root.cameraService.block ? "Blocked"
                    : root.cameraService.consumers > 0 ? "In use"
                    : root.cameraService.running ? "Live"
                    : "Idle"
                chevron: true
                last: recorderMode === "none"
                onActivated: {
                    root.displayState = 24;
                    root.updateState();
                }
            }

            GroupRow {
                visible: recorderMode !== "none"
                icon: recordingActive ? "\uf111" : "\uf03d"
                label: "Screen recording"
                value: recordingActive ? "Recording" : "Idle"
                destructive: recordingActive
                last: true
                onActivated: toggleRecord()
            }
        }

        Item { Layout.preferredHeight: root.s3 }

        // ── Output ─────────────────────────────────────────────────
        Group {
            SliderRow {
                width: parent.width
                height: 40
                icon: "\uf185"
                value: brightnessValue
                min: 0
                max: 100
                accentColor: themeAccent
                valueSuffix: "%"
                onMoved: setBrightness(value)
            }

            SliderRow {
                width: parent.width
                height: 40
                icon: "\uf028"
                value: volumeValue
                min: 0
                max: 100
                accentColor: themeAccent
                valueSuffix: "%"
                onMoved: setVolume(value)
            }
        }

        Item { Layout.preferredHeight: root.s3 }

        // ── Quick switches ─────────────────────────────────────────
        Group {
            GroupRow {
                icon: "\uf0f4"
                label: "Caffeine"
                showSwitch: true
                switchOn: caffeineEnabled
                onToggled: toggleCaffeine()
            }

            GroupRow {
                icon: "\uf186"
                label: "Night light"
                showSwitch: true
                switchOn: nightLightEnabled
                onToggled: toggleNightLight()
            }

            GroupRow {
                icon: "\uf0f3"
                label: "Silence"
                showSwitch: true
                switchOn: root.dndEnabled
                onToggled: toggleDnd()
            }

            GroupRow {
                icon: micMuted ? "\uf131" : "\uf130"
                label: "Microphone"
                showSwitch: true
                switchOn: !micMuted
                last: true
                onToggled: toggleMic()
            }
        }

        Item { Layout.preferredHeight: root.s3 }

        // ── Notifications ──────────────────────────────────────────
        GroupHeader {
            title: "Notifications"
            action: root.notificationList.length > 0 ? "Clear" : ""
            onActionClicked: clearAllNotifications()
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            ListView {
                anchors.fill: parent
                clip: true
                spacing: 0
                boundsBehavior: Flickable.StopAtBounds
                model: root.notificationList

                delegate: NotificationItem {
                    width: ListView.view.width
                    height: 56
                    showDivider: index < ListView.view.count - 1
                    appName: modelData.app
                    summary: modelData.summary
                    body: modelData.body
                    time: modelData.time
                    accentColor: themeAccent
                    onDismissed: clearNotification(modelData.id)
                }
            }

            EmptyState {
                anchors.centerIn: parent
                width: parent.width - root.s6
                visible: root.notificationList.length === 0
                title: "No notifications"
                detail: root.dndEnabled ? "Do Not Disturb is on" : ""
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

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            ListRow {
                icon: "\uf1eb"
                label: "Wi-Fi"
                detail: wifiActive ? (wifiConn || "Connected") : (wifiRadio ? "Radio on" : "Radio off")
                value: wifiActive ? "Connected" : (wifiRadio ? "On" : "Off")
                active: wifiActive
                showDivider: true
                onClicked: wifiRadio ? switchWifi() : toggleWifiRadio()
            }

            ListRow {
                icon: "󰈀"
                label: "Wired"
                value: wiredActive ? "Connected" : "—"
                active: wiredActive
                showDivider: true
                onClicked: switchWired()
            }

            ListRow {
                icon: wifiRadio ? "\uf1eb" : "\uf072"
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
                spacing: 0
                boundsBehavior: Flickable.StopAtBounds
                model: wifiNetworks

                delegate: Item {
                    id: netRow
                    width: ListView.view.width
                    height: 52
                    property var net: wifiNetworks[index]
                    property int strength: net && net.signal !== undefined ? net.signal : 0

                    Rectangle {
                        anchors.fill: parent
                        radius: root.rSm
                        color: netRowArea.containsMouse ? root.ink(0.045) : "transparent"
                        Behavior on color { ColorAnimation { duration: root.dMicro } }
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: root.s3
                        anchors.rightMargin: root.s3
                        spacing: root.s3

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
                                        width: 2.5
                                        height: 4 + index * 3
                                        radius: 1
                                        anchors.bottom: parent.bottom
                                        color: index < netRow.strength ? themeAccent : root.ink(0.14)
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
                                color: root.cFgPrimary
                                font.family: root.fontSans
                                font.pixelSize: 13
                                font.weight: Font.Medium
                                elide: Text.ElideRight
                            }

                            Text {
                                Layout.fillWidth: true
                                text: netRow.net && netRow.net.security ? "Secured" : "Open"
                                color: root.cFgMuted
                                font.family: root.fontSans
                                font.pixelSize: 11
                            }
                        }

                        Text {
                            Layout.alignment: Qt.AlignVCenter
                            text: connectingSsid === (netRow.net ? netRow.net.ssid : "")
                                ? "Connecting…"
                                : (netRow.net && netRow.net.active ? "Connected" : "Connect")
                            color: connectingSsid === (netRow.net ? netRow.net.ssid : "") || (netRow.net && netRow.net.active)
                                ? themeAccent
                                : root.cFgMuted
                            font.family: root.fontSans
                            font.pixelSize: 12
                            font.weight: Font.Medium
                        }
                    }

                    Rectangle {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        height: 1
                        color: root.ink(0.055)
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
                    title: "No networks found"
                    detail: wifiRadio ? "Move closer to the router and scan again" : "Turn the Wi-Fi radio on"
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "Scan again"
                    color: scanArea.containsMouse ? root.cFgPrimary : themeAccent
                    font.family: root.fontSans
                    font.pixelSize: 12
                    font.weight: Font.Medium

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

        ListRow {
            icon: "\uf293"
            label: "Bluetooth"
            value: btPowered ? "On" : "Off"
            onClicked: toggleBluetooth()
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
                spacing: 0
                boundsBehavior: Flickable.StopAtBounds
                model: btDevices

                delegate: Item {
                    id: btRow
                    width: ListView.view.width
                    height: 54
                    property var device: btDevices[index]

                    Rectangle {
                        anchors.fill: parent
                        radius: root.rSm
                        color: btRowArea.containsMouse ? root.ink(0.045) : "transparent"
                        Behavior on color { ColorAnimation { duration: root.dMicro } }
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: root.s3
                        anchors.rightMargin: root.s3
                        spacing: root.s3

                        Text {
                            Layout.preferredWidth: 20
                            Layout.alignment: Qt.AlignVCenter
                            horizontalAlignment: Text.AlignHCenter
                            text: getDeviceIcon(btRow.device ? btRow.device.type : "")
                            color: btRow.device && btRow.device.connected ? themeAccent : root.cFgSecondary
                            font.family: root.fontMono
                            font.pixelSize: 15
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0

                            Text {
                                Layout.fillWidth: true
                                text: btRow.device && btRow.device.name ? btRow.device.name : "Unknown device"
                                color: root.cFgPrimary
                                font.family: root.fontSans
                                font.pixelSize: 13
                                font.weight: Font.Medium
                                elide: Text.ElideRight
                            }

                            Text {
                                Layout.fillWidth: true
                                text: btRow.device && btRow.device.connected ? "Connected"
                                    : (btRow.device && btRow.device.paired ? "Paired" : "Available")
                                color: btRow.device && btRow.device.connected ? themeAccent : root.cFgMuted
                                font.family: root.fontSans
                                font.pixelSize: 11
                            }
                        }

                        Text {
                            Layout.alignment: Qt.AlignVCenter
                            text: connectingMac !== "" && btRow.device && connectingMac === btRow.device.mac
                                ? "Connecting…"
                                : (btRow.device && btRow.device.connected ? "Disconnect" : "Connect")
                            color: root.cFgMuted
                            font.family: root.fontSans
                            font.pixelSize: 12
                            font.weight: Font.Medium
                            opacity: btRowArea.containsMouse ? 1 : 0.55
                            Behavior on opacity { NumberAnimation { duration: root.dMicro } }
                        }
                    }

                    Rectangle {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        height: 1
                        color: root.ink(0.055)
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
                title: btPowered ? "No devices found" : "Bluetooth is off"
                detail: btPowered ? "Put the device in pairing mode" : "Turn Bluetooth on to connect"
            }
        }
    }

    // ── Action toast ───────────────────────────────────────────────
    Item {
        id: actionToast
        anchors.bottom: parent.bottom
        anchors.bottomMargin: root.s5
        anchors.horizontalCenter: parent.horizontalCenter
        width: parent.width - root.s7
        height: 40
        opacity: actionVisible ? 1 : 0
        visible: opacity > 0
        transform: Translate { y: (1 - actionToast.opacity) * 8 }
        Behavior on opacity {
            NumberAnimation {
                duration: actionVisible ? root.motionBase : root.motionExit
                easing.type: actionVisible ? Easing.OutExpo : Easing.OutCubic
            }
        }

        Rectangle {
            anchors.fill: parent
            radius: root.rMd
            color: Qt.rgba(root.cBgElevated.r, root.cBgElevated.g, root.cBgElevated.b, 0.96)
            border.width: 1
            border.color: root.ink(0.08)

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: root.s4
                anchors.rightMargin: root.s4
                spacing: root.s3

                Text {
                    text: actionTitle
                    color: root.cFgPrimary
                    font.family: root.fontSans
                    font.pixelSize: 13
                    font.weight: Font.DemiBold
                }

                Text {
                    Layout.fillWidth: true
                    text: actionSub
                    color: root.cFgMuted
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
