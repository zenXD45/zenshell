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
    property string currentView: "main" // "main" | "network" | "bt"

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
    property string recorderMode: "none" // "ui" | "gsr" | "none"
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
    // ════════════════════════════════════════════════════════════════
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
    // Caffeine, night light and Do Not Disturb are settings, not panel-local
    // state. They go through root.setValue() so the store, the live effect
    // and the persisted file stay in step — the control centre and the
    // settings window are then two views of the same thing instead of two
    // switches that quietly undo each other.
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

    // hypridle absent/stopped == Caffeine is ON (no idle, dim or lock).
    Process {
        id: checkCaffeine
        command: ["bash", "-c", "pgrep -x hypridle >/dev/null 2>&1 && echo 0 || echo 1"]
        stdout: SplitParser { onRead: data => { caffeineEnabled = (data.trim() === "1") } }
    }

    // Toggle the mic and report the real resulting state, not an assumption.
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
    // │ MAIN VIEW
    // ════════════════════════════════════════════════════════════════
    ColumnLayout {
        id: mainView
        anchors.fill: parent
        anchors.margins: 18
        spacing: 10
        opacity: currentView === "main" ? 1 : 0
        visible: opacity > 0
        transform: Translate { y: currentView === "main" ? (1 - mainView.opacity) * 8 : -mainView.opacity * 8 }
        Behavior on opacity {
            NumberAnimation {
                duration: currentView === "main" ? root.motionBase : root.motionExit
                easing.type: Easing.OutCubic
            }
        }

        // ── Header (compact) ─────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 28
            spacing: 9

            Rectangle {
                width: 28; height: 28; radius: 9
                color: Qt.rgba(themeAccent.r, themeAccent.g, themeAccent.b, 0.14)
                border.width: 1
                border.color: Qt.rgba(themeAccent.r, themeAccent.g, themeAccent.b, 0.24)
                Text {
                    anchors.centerIn: parent
                    text: "\uf013"
                    color: themeAccent
                    font.family: root.font
                    font.pixelSize: 12
                }
            }

            Text {
                text: "Control Center"
                color: root.uiFg
                font.family: root.uiFont
                font.pixelSize: 15
                font.weight: Font.DemiBold
            }

            Item { Layout.fillWidth: true }

            Text {
                text: panelClock
                color: root.uiFgFaint
                font.family: root.uiFont
                font.pixelSize: 10
                font.weight: Font.Medium
            }

            // Settings. The full settings window lives on its own overlay
            // surface, so the panel closes first — two surfaces asking for
            // exclusive keyboard focus at once is how the compositor ends up
            // with a dead keyboard.
            Rectangle {
                id: settingsChip
                height: 22
                width: 22
                radius: 11
                color: settingsChipMouse.containsMouse
                    ? Qt.rgba(themeAccent.r, themeAccent.g, themeAccent.b, 0.18)
                    : "transparent"
                border.width: 1
                border.color: settingsChipMouse.containsMouse
                    ? Qt.rgba(themeAccent.r, themeAccent.g, themeAccent.b, 0.34)
                    : "transparent"
                Behavior on color { ColorAnimation { duration: 140 } }

                Text {
                    anchors.centerIn: parent
                    text: "\uf013"
                    color: settingsChipMouse.containsMouse ? themeAccent : root.uiFgDim
                    font.family: root.font
                    font.pixelSize: 11
                }

                MouseArea {
                    id: settingsChipMouse
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

            // Shell profile switcher. The 01/02 glyph reads as a miniature
            // island over a dock (01) or a single command rail (02).
            Rectangle {
                height: 22
                implicitWidth: profileChipRow.implicitWidth + 16
                radius: 11
                color: profileChipMouse.containsMouse ? root.ink(0.078) : root.ink(0.039)
                border.width: 1
                border.color: profileChipMouse.containsMouse ? root.ink(0.141) : root.ink(0.078)
                Behavior on color { ColorAnimation { duration: 140 } }
                Behavior on border.color { ColorAnimation { duration: 140 } }

                RowLayout {
                    id: profileChipRow
                    anchors.centerIn: parent
                    spacing: 5

                    Item {
                        width: 12
                        height: 10
                        Rectangle {
                            width: 8
                            height: 3
                            radius: 1.5
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.top: parent.top
                            color: themeAccent
                        }
                        Rectangle {
                            width: 12
                            height: 2
                            radius: 1
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.bottom: parent.bottom
                            color: root.uiFg
                            opacity: 0.5
                        }
                    }

                    Text {
                        text: "PROFILE " + root.activeProfileLabel
                        color: root.uiFgDim
                        font.family: root.uiFont
                        font.pixelSize: 8
                        font.weight: Font.DemiBold
                        font.letterSpacing: 0.7
                    }
                }

                MouseArea {
                    id: profileChipMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.displayState = 16
                }
            }

            Rectangle {
                height: 22
                implicitWidth: badgeRow.implicitWidth + 16
                radius: 11
                color: Qt.rgba(themeAccent.r, themeAccent.g, themeAccent.b, 0.12)
                border.width: 1
                border.color: Qt.rgba(themeAccent.r, themeAccent.g, themeAccent.b, 0.28)

                RowLayout {
                    id: badgeRow
                    anchors.centerIn: parent
                    spacing: 4
                    Text {
                        text: activeType === "wired" ? "󰈀" : (wifiActive ? "\uf1eb" : "\uf072")
                        color: themeAccent
                        font.family: root.font
                        font.pixelSize: 9
                    }
                    Text {
                        id: badgeText
                        text: activeType === "wired" ? "Wired" : (wifiActive ? (wifiConn || "Wi-Fi") : "Offline")
                        color: root.uiFg
                        font.family: root.uiFont
                        font.pixelSize: 9
                        font.weight: Font.Medium
                    }
                }
            }
        }

        // ── Connectivity (compact) ───────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 54
            Layout.minimumHeight: 54
            Layout.maximumHeight: 54
            spacing: 10

            // Network
            Rectangle {
                id: netTile
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: 14
                color: netArea.containsMouse ? root.ink(0.063) : root.uiCard
                border.width: 1
                border.color: netArea.containsMouse ? root.uiBorderStrong : root.uiBorder
                Behavior on color { ColorAnimation { duration: 130 } }

                property real press: 1.0
                transform: Scale { origin.x: width / 2; origin.y: height / 2; xScale: netTile.press; yScale: netTile.press }
                Behavior on press { NumberAnimation { duration: 110; easing.type: Easing.OutBack } }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 8
                    spacing: 9

                    Rectangle {
                        width: 30; height: 30; radius: 9
                        color: Qt.rgba(themeAccent.r, themeAccent.g, themeAccent.b, 0.13)
                        Text {
                            anchors.centerIn: parent
                            text: activeType === "wired" ? "󰈀" : "\uf1eb"
                            color: themeAccent
                            font.family: root.font
                            font.pixelSize: 13
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0

                        Text {
                            text: "Network"
                            color: root.uiFg
                            font.family: root.uiFont
                            font.pixelSize: 12
                            font.weight: Font.Medium
                        }
                        Text {
                            Layout.fillWidth: true
                            text: activeType === "wired"
                                ? (wiredConn || "Wired")
                                : (wifiActive ? (wifiConn || "Wi-Fi") : "Disconnected")
                            color: root.uiFgFaint
                            font.family: root.uiFont
                            font.pixelSize: 10
                            elide: Text.ElideRight
                        }
                    }

                    Text {
                        text: "\uf054"
                        color: root.uiFgFaint
                        font.family: root.font
                        font.pixelSize: 8
                    }
                }

                MouseArea {
                    id: netArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onPressed: parent.press = 0.98
                    onReleased: parent.press = 1.0
                    onClicked: { currentView = "network"; refreshNetwork() }
                }
            }

            // Bluetooth
            Rectangle {
                id: btTile
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: 14
                color: btArea.containsMouse ? root.ink(0.063) : root.uiCard
                border.width: 1
                border.color: btArea.containsMouse ? root.uiBorderStrong : root.uiBorder
                Behavior on color { ColorAnimation { duration: 130 } }

                property real press: 1.0
                transform: Scale { origin.x: width / 2; origin.y: height / 2; xScale: btTile.press; yScale: btTile.press }
                Behavior on press { NumberAnimation { duration: 110; easing.type: Easing.OutBack } }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 8
                    spacing: 9

                    Rectangle {
                        width: 30; height: 30; radius: 9
                        color: Qt.rgba(themeAccent.r, themeAccent.g, themeAccent.b, 0.13)
                        Text {
                            anchors.centerIn: parent
                            text: "\uf293"
                            color: themeAccent
                            font.family: root.font
                            font.pixelSize: 13
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0

                        Text {
                            text: "Bluetooth"
                            color: root.uiFg
                            font.family: root.uiFont
                            font.pixelSize: 12
                            font.weight: Font.Medium
                        }
                        Text {
                            text: btPowered ? "On" : "Off"
                            color: root.uiFgFaint
                            font.family: root.uiFont
                            font.pixelSize: 10
                        }
                    }

                    Text {
                        text: "\uf054"
                        color: root.uiFgFaint
                        font.family: root.font
                        font.pixelSize: 8
                    }
                }

                MouseArea {
                    id: btArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onPressed: parent.press = 0.98
                    onReleased: parent.press = 1.0
                    onClicked: { currentView = "bt"; refreshBluetooth() }
                }
            }

            // Camera — the ported camera-effects plugin. The tile is the
            // entry point; the panel itself lives in the island.
            Rectangle {
                id: camTile
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: 14
                color: camArea.containsMouse ? root.ink(0.063) : root.uiCard
                border.width: 1
                border.color: camArea.containsMouse ? root.uiBorderStrong : root.uiBorder
                Behavior on color { ColorAnimation { duration: 130 } }

                property real press: 1.0
                transform: Scale { origin.x: width / 2; origin.y: height / 2; xScale: camTile.press; yScale: camTile.press }
                Behavior on press { NumberAnimation { duration: 110; easing.type: Easing.OutBack } }

                readonly property var svc: root.cameraService
                readonly property bool live: svc ? (svc.consumers > 0 || svc.running) : false

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 8
                    spacing: 9

                    Rectangle {
                        width: 30; height: 30; radius: 9
                        color: Qt.rgba(themeAccent.r, themeAccent.g, themeAccent.b, camTile.live ? 0.24 : 0.13)
                        border.width: 1
                        border.color: Qt.rgba(themeAccent.r, themeAccent.g, themeAccent.b, camTile.live ? 0.5 : 0.24)
                        Text {
                            anchors.centerIn: parent
                            text: "󰄀"
                            color: themeAccent
                            font.family: root.font
                            font.pixelSize: 13
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0

                        Text {
                            text: "Camera"
                            color: root.uiFg
                            font.family: root.uiFont
                            font.pixelSize: 12
                            font.weight: Font.Medium
                        }
                        Text {
                            Layout.fillWidth: true
                            text: !camTile.svc ? "Not installed"
                                : camTile.svc.block ? "Blocked"
                                : camTile.svc.consumers > 0 ? "In use"
                                : camTile.svc.running ? "Live"
                                : "Idle"
                            color: camTile.live ? themeAccent : root.uiFgFaint
                            font.family: root.uiFont
                            font.pixelSize: 10
                            elide: Text.ElideRight
                        }
                    }

                    Text {
                        text: ""
                        color: root.uiFgFaint
                        font.family: root.font
                        font.pixelSize: 8
                    }
                }

                MouseArea {
                    id: camArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onPressed: parent.press = 0.98
                    onReleased: parent.press = 1.0
                    onClicked: {
                        root.displayState = 24;
                        root.updateState();
                    }
                }
            }
        }

        // ── Quick toggles (compact) ──────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 44
            Layout.minimumHeight: 44
            Layout.maximumHeight: 44
            spacing: 8

            // Caffeine
            Rectangle {
                id: caffeineTile
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: 12
                color: caffeineEnabled
                    ? Qt.rgba(themeAccent.r, themeAccent.g, themeAccent.b, 0.16)
                    : (caffArea.containsMouse ? root.ink(0.063) : root.uiCard)
                border.width: 1
                border.color: caffeineEnabled
                    ? Qt.rgba(themeAccent.r, themeAccent.g, themeAccent.b, 0.38)
                    : root.uiBorder
                Behavior on color { ColorAnimation { duration: 140 } }

                property real press: 1.0
                transform: Scale { origin.x: width / 2; origin.y: height / 2; xScale: caffeineTile.press; yScale: caffeineTile.press }
                Behavior on press { NumberAnimation { duration: 110; easing.type: Easing.OutBack } }

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 1
                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: "\uf0f4"
                        color: caffeineEnabled ? themeAccent : root.uiFgFaint
                        font.family: root.font
                        font.pixelSize: 13
                    }
                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: "Caffeine"
                        color: caffeineEnabled ? root.uiFg : root.uiFgDim
                        font.family: root.uiFont
                        font.pixelSize: 9
                        font.weight: caffeineEnabled ? Font.DemiBold : Font.Medium
                    }
                }

                MouseArea {
                    id: caffArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onPressed: parent.press = 0.96
                    onReleased: parent.press = 1.0
                    onClicked: toggleCaffeine()
                }
            }

            // Night Light
            Rectangle {
                id: nightLightTile
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: 12
                color: nightLightEnabled
                    ? Qt.rgba(themeAccent.r, themeAccent.g, themeAccent.b, 0.16)
                    : (nightArea.containsMouse ? root.ink(0.063) : root.uiCard)
                border.width: 1
                border.color: nightLightEnabled
                    ? Qt.rgba(themeAccent.r, themeAccent.g, themeAccent.b, 0.38)
                    : root.uiBorder
                Behavior on color { ColorAnimation { duration: 140 } }

                property real press: 1.0
                transform: Scale { origin.x: width / 2; origin.y: height / 2; xScale: nightLightTile.press; yScale: nightLightTile.press }
                Behavior on press { NumberAnimation { duration: 110; easing.type: Easing.OutBack } }

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 1
                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: "\uf186"
                        color: nightLightEnabled ? themeAccent : root.uiFgFaint
                        font.family: root.font
                        font.pixelSize: 13
                    }
                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: "Night Light"
                        color: nightLightEnabled ? root.uiFg : root.uiFgDim
                        font.family: root.uiFont
                        font.pixelSize: 9
                        font.weight: nightLightEnabled ? Font.DemiBold : Font.Medium
                    }
                }

                MouseArea {
                    id: nightArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onPressed: parent.press = 0.96
                    onReleased: parent.press = 1.0
                    onClicked: toggleNightLight()
                }
            }

            // Do Not Disturb
            Rectangle {
                id: dndTile
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: 12
                color: root.dndEnabled
                    ? Qt.rgba(themeAccent.r, themeAccent.g, themeAccent.b, 0.16)
                    : (dndArea.containsMouse ? root.ink(0.063) : root.uiCard)
                border.width: 1
                border.color: root.dndEnabled
                    ? Qt.rgba(themeAccent.r, themeAccent.g, themeAccent.b, 0.38)
                    : root.uiBorder
                Behavior on color { ColorAnimation { duration: 140 } }

                property real press: 1.0
                transform: Scale { origin.x: width / 2; origin.y: height / 2; xScale: dndTile.press; yScale: dndTile.press }
                Behavior on press { NumberAnimation { duration: 110; easing.type: Easing.OutBack } }

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 1
                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: "\uf0f3"
                        color: root.dndEnabled ? themeAccent : root.uiFgFaint
                        font.family: root.font
                        font.pixelSize: 13
                    }
                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: "Do Not Disturb"
                        color: root.dndEnabled ? root.uiFg : root.uiFgDim
                        font.family: root.uiFont
                        font.pixelSize: 9
                        font.weight: root.dndEnabled ? Font.DemiBold : Font.Medium
                    }
                }

                MouseArea {
                    id: dndArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onPressed: parent.press = 0.96
                    onReleased: parent.press = 1.0
                    onClicked: toggleDnd()
                }
            }

            // Mic
            Rectangle {
                id: micTile
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: 12
                color: micMuted
                    ? Qt.rgba(themeAccent.r, themeAccent.g, themeAccent.b, 0.16)
                    : (micArea.containsMouse ? root.ink(0.063) : root.uiCard)
                border.width: 1
                border.color: micMuted
                    ? Qt.rgba(themeAccent.r, themeAccent.g, themeAccent.b, 0.38)
                    : root.uiBorder
                Behavior on color { ColorAnimation { duration: 140 } }

                property real press: 1.0
                transform: Scale { origin.x: width / 2; origin.y: height / 2; xScale: micTile.press; yScale: micTile.press }
                Behavior on press { NumberAnimation { duration: 110; easing.type: Easing.OutBack } }

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 1
                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: micMuted ? "\uf131" : "\uf130"
                        color: micMuted ? themeAccent : root.uiFgFaint
                        font.family: root.font
                        font.pixelSize: 13
                    }
                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: micMuted ? "Muted" : "Mic"
                        color: micMuted ? root.uiFg : root.uiFgDim
                        font.family: root.uiFont
                        font.pixelSize: 9
                        font.weight: micMuted ? Font.DemiBold : Font.Medium
                    }
                }

                MouseArea {
                    id: micArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onPressed: parent.press = 0.96
                    onReleased: parent.press = 1.0
                    onClicked: toggleMic()
                }
            }
        }

        // ── Sliders (compact) ────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 76
            radius: 14
            color: root.uiCard
            border.width: 1
            border.color: root.uiBorder

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 8

                // Brightness
                RowLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 9

                    Text {
                        text: "\uf185"
                        color: root.uiFgDim
                        font.family: root.font
                        font.pixelSize: 12
                        Layout.preferredWidth: 14
                        horizontalAlignment: Text.AlignHCenter
                    }

                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width
                            height: 4; radius: 2
                            color: root.ink(0.102)
                        }

                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            height: 4; radius: 2
                            width: (parent.width - 12) * (brightnessValue / 100)
                            color: themeAccent
                        }

                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            x: Math.max(0, Math.min(parent.width - width, (parent.width - 12) * (brightnessValue / 100)))
                            width: brightDrag.pressed ? 14 : 12
                            height: width; radius: width / 2
                            color: root.themeFg
                            Behavior on width { NumberAnimation { duration: 100; easing.type: Easing.OutCubic } }
                        }

                        MouseArea {
                            id: brightDrag
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            property bool dragging: false
                            onPressed: (mouse) => { dragging = true; setBrightness((mouse.x / parent.width) * 100) }
                            onReleased: dragging = false
                            onPositionChanged: (mouse) => { if (dragging) setBrightness((mouse.x / parent.width) * 100) }
                        }
                    }

                    Rectangle {
                        width: 36; height: 20; radius: 6
                        color: root.ink(0.063)
                        border.width: 1
                        border.color: root.ink(0.094)
                        Text {
                            anchors.centerIn: parent
                            text: Math.round(brightnessValue) + "%"
                            color: root.uiFgDim
                            font.family: root.uiFont
                            font.pixelSize: 9
                            font.weight: Font.Medium
                        }
                    }
                }

                // Volume
                RowLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 9

                    Text {
                        text: "\uf028"
                        color: root.uiFgDim
                        font.family: root.font
                        font.pixelSize: 12
                        Layout.preferredWidth: 14
                        horizontalAlignment: Text.AlignHCenter
                    }

                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width
                            height: 4; radius: 2
                            color: root.ink(0.102)
                        }

                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            height: 4; radius: 2
                            width: (parent.width - 12) * (volumeValue / 100)
                            color: themeAccent
                        }

                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            x: Math.max(0, Math.min(parent.width - width, (parent.width - 12) * (volumeValue / 100)))
                            width: volDrag.pressed ? 14 : 12
                            height: width; radius: width / 2
                            color: root.themeFg
                            Behavior on width { NumberAnimation { duration: 100; easing.type: Easing.OutCubic } }
                        }

                        MouseArea {
                            id: volDrag
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            property bool dragging: false
                            onPressed: (mouse) => { dragging = true; setVolume((mouse.x / parent.width) * 100) }
                            onReleased: dragging = false
                            onPositionChanged: (mouse) => { if (dragging) setVolume((mouse.x / parent.width) * 100) }
                        }
                    }

                    Rectangle {
                        width: 36; height: 20; radius: 6
                        color: root.ink(0.063)
                        border.width: 1
                        border.color: root.ink(0.094)
                        Text {
                            anchors.centerIn: parent
                            text: Math.round(volumeValue) + "%"
                            color: root.uiFgDim
                            font.family: root.uiFont
                            font.pixelSize: 9
                            font.weight: Font.Medium
                        }
                    }
                }
            }
        }

        // ── Screen record (only while a recorder is available) ───
        Rectangle {
            id: recordTile
            Layout.fillWidth: true
            Layout.preferredHeight: 32
            radius: 11
            visible: recorderMode !== "none"
            color: recArea.containsMouse ? root.ink(0.063) : root.uiCard
            border.width: 1
            border.color: recordingActive
                ? Qt.rgba(themeAccent.r, themeAccent.g, themeAccent.b, 0.35)
                : root.uiBorder
            property real press: 1.0
            transform: Scale { origin.x: width / 2; origin.y: height / 2; xScale: recordTile.press; yScale: recordTile.press }
            Behavior on press { NumberAnimation { duration: 110; easing.type: Easing.OutBack } }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 10
                spacing: 8

                Text {
                    text: recordingActive ? "\uf111" : "\uf03d"
                    color: recordingActive ? "#EF4444" : root.uiFgFaint
                    font.family: root.font
                    font.pixelSize: 11
                }
                Text {
                    text: recordingActive ? "Recording in progress" : "Screen Record"
                    color: recordingActive ? root.uiFg : root.uiFgDim
                    font.family: root.uiFont
                    font.pixelSize: 10
                    font.weight: recordingActive ? Font.DemiBold : Font.Medium
                    Layout.fillWidth: true
                }
            }

            MouseArea {
                id: recArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onPressed: parent.press = 0.98
                onReleased: parent.press = 1.0
                onClicked: toggleRecord()
            }
        }

        // ── Notification shade (the main event) ──────────────────
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: root.uiRadiusMd
            color: root.ink(0.027)
            border.width: 1
            border.color: root.ink(0.071)

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 8

                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 20
                    spacing: 6

                    Text {
                        text: "\uf0f3"
                        color: themeAccent
                        font.family: root.font
                        font.pixelSize: 11
                    }
                    Text {
                        text: "Notifications"
                        color: root.uiFg
                        font.family: root.uiFont
                        font.pixelSize: 12
                        font.weight: Font.DemiBold
                    }

                    Rectangle {
                        visible: root.notificationList.length > 0
                        height: 16
                        implicitWidth: countText.implicitWidth + 10
                        radius: 8
                        color: Qt.rgba(themeAccent.r, themeAccent.g, themeAccent.b, 0.14)
                        Text {
                            id: countText
                            anchors.centerIn: parent
                            text: root.notificationList.length
                            color: themeAccent
                            font.family: root.uiFont
                            font.pixelSize: 9
                            font.weight: Font.DemiBold
                        }
                    }

                    Item { Layout.fillWidth: true }

                    Text {
                        visible: root.notificationList.length > 0
                        text: "Clear all"
                        color: clearArea.containsMouse ? "#FF8A8A" : root.uiFgFaint
                        font.family: root.uiFont
                        font.pixelSize: 10
                        font.weight: Font.Medium
                        Behavior on color { ColorAnimation { duration: 120 } }

                        MouseArea {
                            id: clearArea
                            anchors.fill: parent
                            anchors.margins: -4
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.clearAllNotifications()
                        }
                    }
                }

                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    // Empty state
                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 4
                        visible: root.notificationList.length === 0

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: "\uf0f3"
                            color: root.ink(0.125)
                            font.family: root.font
                            font.pixelSize: 18
                        }
                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: "You\u2019re all caught up"
                            color: root.uiFgDim
                            font.family: root.uiFont
                            font.pixelSize: 12
                            font.weight: Font.Medium
                        }
                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: "New notifications will appear here"
                            color: root.uiFgFaint
                            font.family: root.uiFont
                            font.pixelSize: 10
                        }
                    }

                    // The shade list: always fills the space it is given and
                    // scrolls once the history is longer than the viewport.
                    ListView {
                        id: notifList
                        anchors.fill: parent
                        anchors.rightMargin: 8
                        visible: root.notificationList.length > 0
                        model: root.notificationList.length
                        spacing: 6
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds

                        ScrollBar.vertical: ScrollBar {
                            // AsNeeded can leave a full-height thumb when the list
                            // happens to fit; drive visibility from the actual geometry.
                            policy: notifList.contentHeight > notifList.height + 1
                                    ? ScrollBar.AlwaysOn : ScrollBar.AlwaysOff
                            contentItem: Rectangle {
                                implicitWidth: 3
                                radius: 1.5
                                color: root.ink(0.251)
                            }
                        }

                        delegate: Rectangle {
                            width: ListView.view.width
                            height: 68
                            radius: 12
                            color: notifHover.hovered ? root.ink(0.071) : root.ink(0.039)
                            border.width: 1
                            border.color: notifHover.hovered ? root.ink(0.125) : root.ink(0.071)

                            property var notif: root.notificationList[index] || {}

                            HoverHandler { id: notifHover }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 10
                                anchors.rightMargin: 8
                                anchors.topMargin: 8
                                anchors.bottomMargin: 8
                                spacing: 10

                                Rectangle {
                                    width: 30; height: 30; radius: 9
                                    Layout.alignment: Qt.AlignTop
                                    color: Qt.rgba(themeAccent.r, themeAccent.g, themeAccent.b, 0.12)
                                    Text {
                                        anchors.centerIn: parent
                                        text: "\uf1d7"
                                        color: themeAccent
                                        font.family: root.font
                                        font.pixelSize: 12
                                    }
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 0

                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: 6

                                        Text {
                                            Layout.fillWidth: true
                                            text: notif.app || "Notification"
                                            color: themeAccent
                                            font.family: root.uiFont
                                            font.pixelSize: 9
                                            font.weight: Font.DemiBold
                                            elide: Text.ElideRight
                                        }
                                        Text {
                                            text: notif.time ? Qt.formatTime(notif.time, "HH:mm") : ""
                                            color: root.uiFgFaint
                                            font.family: root.uiFont
                                            font.pixelSize: 9
                                        }
                                    }

                                    Text {
                                        Layout.fillWidth: true
                                        text: notif.summary || ""
                                        color: root.uiFg
                                        font.family: root.uiFont
                                        font.pixelSize: 12
                                        font.weight: Font.DemiBold
                                        elide: Text.ElideRight
                                        maximumLineCount: 1
                                    }

                                    Text {
                                        Layout.fillWidth: true
                                        text: notif.body || ""
                                        color: root.uiFgDim
                                        font.family: root.uiFont
                                        font.pixelSize: 10
                                        wrapMode: Text.Wrap
                                        maximumLineCount: 2
                                        elide: Text.ElideRight
                                    }
                                }

                                Rectangle {
                                    width: 22; height: 22; radius: 7
                                    Layout.alignment: Qt.AlignTop
                                    color: dismissArea.containsMouse ? "#22EF4444" : "transparent"
                                    Behavior on color { ColorAnimation { duration: 120 } }
                                    Text {
                                        anchors.centerIn: parent
                                        text: "\uf00d"
                                        color: dismissArea.containsMouse ? "#EF4444" : root.uiFgFaint
                                        font.family: root.font
                                        font.pixelSize: 8
                                    }
                                    MouseArea {
                                        id: dismissArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.clearNotification(notif.id)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }


    // ════════════════════════════════════════════════════════════════
    // │ NETWORK & WI-FI SUB-VIEW
    // ════════════════════════════════════════════════════════════════
    ColumnLayout {
        id: networkView
        anchors.fill: parent
        anchors.margins: 16
        spacing: 8
        opacity: currentView === "network" ? 1 : 0
        visible: opacity > 0
        transform: Translate { y: currentView === "network" ? (1 - networkView.opacity) * 8 : -networkView.opacity * 8 }
        Behavior on opacity {
            NumberAnimation {
                duration: currentView === "network" ? root.motionBase : root.motionExit
                easing.type: Easing.OutCubic
            }
        }

        // Sub-view header
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Rectangle {
                width: 28; height: 28; radius: 10
                color: backNetArea.containsMouse ? root.ink(0.102) : root.ink(0.039)
                Text { anchors.centerIn: parent; text: "\uf060"; color: root.themeFg; font.family: root.font; font.pixelSize: 12 }
                MouseArea {
                    id: backNetArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: currentView = "main"
                }
            }

            Text { text: "Network & Wi-Fi"; color: root.themeFg; font.family: root.uiFont; font.pixelSize: 14; font.weight: Font.Bold }

            Item { Layout.fillWidth: true }

            Rectangle {
                width: 28; height: 28; radius: 10
                color: openNmArea.containsMouse ? root.ink(0.102) : root.ink(0.039)
                Text { anchors.centerIn: parent; text: "\uf013"; color: root.ink(0.52); font.family: root.font; font.pixelSize: 12 }
                MouseArea {
                    id: openNmArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: runShell("command -v nm-connection-editor >/dev/null 2>&1 && nm-connection-editor & || (command -v nmtui >/dev/null 2>&1 && kitty -e nmtui &)")
                }
            }

            Rectangle {
                width: 28; height: 28; radius: 10
                color: refNetArea.containsMouse ? root.ink(0.102) : root.ink(0.039)
                Text { anchors.centerIn: parent; text: "\uf021"; color: themeAccent; font.family: root.font; font.pixelSize: 12 }
                MouseArea {
                    id: refNetArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: refreshNetwork()
                }
            }
        }

        // Switchers: wired + wifi radio
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Rectangle {
id: wiredTile
                Layout.fillWidth: true
                Layout.preferredHeight: 52
                radius: 14
                color: wiredActive ? Qt.rgba(themeAccent.r, themeAccent.g, themeAccent.b, 0.14) : root.ink(0.031)
                border.color: wiredActive ? themeAccent : root.ink(0.063)
                border.width: 1
                property real press: 1.0
                transform: Scale { origin.x: width / 2; origin.y: height / 2; xScale: wiredTile.press; yScale: wiredTile.press }
                Behavior on press { NumberAnimation { duration: 110; easing.type: Easing.OutBack } }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 10

                    Text {
                        text: "󰈀"
                        color: wiredActive ? themeAccent : root.ink(0.45)
                        font.family: root.font
                        font.pixelSize: 16
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 1
                        Text {
                            text: "Ethernet"
                            color: root.themeFg
                            font.family: root.uiFont
                            font.pixelSize: 11
                            font.weight: Font.Bold
                        }
                        Text {
                            text: wiredActive ? (wiredConn || "Connected") : "Tap to connect"
                            color: wiredActive ? root.ink(0.55) : root.ink(0.45)
                            font.family: root.uiFont
                            font.pixelSize: 9
                        }
                    }

                    Rectangle {
                        width: 12; height: 12; radius: 6
                        color: wiredActive ? themeAccent : root.ink(0.24)
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onPressed: parent.press = 0.97
                    onReleased: parent.press = 1.0
                    onClicked: switchWired()
                }
            }

            Rectangle {
id: wifiTile
                Layout.fillWidth: true
                Layout.preferredHeight: 52
                radius: 14
                color: wifiRadio ? Qt.rgba(themeAccent.r, themeAccent.g, themeAccent.b, 0.14) : root.ink(0.031)
                border.color: wifiRadio ? themeAccent : root.ink(0.063)
                border.width: 1
                property real press: 1.0
                transform: Scale { origin.x: width / 2; origin.y: height / 2; xScale: wifiTile.press; yScale: wifiTile.press }
                Behavior on press { NumberAnimation { duration: 110; easing.type: Easing.OutBack } }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 10
                    spacing: 10

                    Text {
                        text: "\uf1eb"
                        color: wifiRadio ? themeAccent : root.ink(0.45)
                        font.family: root.font
                        font.pixelSize: 16
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 1
                        Text {
                            text: "Wi-Fi"
                            color: root.themeFg
                            font.family: root.uiFont
                            font.pixelSize: 11
                            font.weight: Font.Bold
                        }
                        Text {
                            text: wifiRadio ? "Radio on" : "Radio off"
                            color: wifiRadio ? root.ink(0.55) : root.ink(0.45)
                            font.family: root.uiFont
                            font.pixelSize: 9
                        }
                    }

                    // Toggle switch
                    Rectangle {
                        width: 34; height: 20; radius: 10
                        color: wifiRadio ? themeAccent : root.ink(0.17)
                        Behavior on color { ColorAnimation { duration: 150 } }
                        Rectangle {
                            width: 16; height: 16; radius: 8
                            x: wifiRadio ? 16 : 2
                            anchors.verticalCenter: parent.verticalCenter
                            color: root.themeFg
                            Behavior on x { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onPressed: parent.press = 0.97
                    onReleased: parent.press = 1.0
                    onClicked: toggleWifiRadio()
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Text {
                text: "AVAILABLE NETWORKS"
                color: root.ink(0.36)
                font.family: root.uiFont
                font.pixelSize: 9
                font.weight: Font.Bold
            }
            Item { Layout.fillWidth: true }
            Text {
                text: ipAddress || ""
                color: root.ink(0.45)
                font.family: root.uiFont
                font.pixelSize: 9
            }
        }

        ListView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            model: (wifiNetworks && wifiNetworks.length) ? wifiNetworks.length : 0
            spacing: 5
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            delegate: Rectangle {
                width: ListView.view.width
                height: 42
                radius: 12
                color: itemNet.in_use ? Qt.rgba(themeAccent.r, themeAccent.g, themeAccent.b, 0.14) : (netItemArea.containsMouse ? root.ink(0.063) : root.ink(0.024))
                border.color: itemNet.in_use ? Qt.rgba(themeAccent.r, themeAccent.g, themeAccent.b, 0.45) : root.ink(0.071)
                border.width: 1

                property var itemNet: wifiNetworks[index] || {}
                property bool isConnecting: connectingSsid === itemNet.ssid

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 10

                    Text {
                        text: "\uf1eb"
                        color: itemNet.in_use ? themeAccent : root.ink(0.6)
                        font.family: root.font
                        font.pixelSize: 13
                    }

                    Text {
                        text: itemNet.ssid || "Hidden Network"
                        color: itemNet.in_use ? root.themeFg : root.ink(0.85)
                        font.family: root.uiFont
                        font.pixelSize: 11
                        font.weight: itemNet.in_use ? Font.DemiBold : Font.Normal
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }

                    // Signal bars
                    Text {
                        text: itemNet.signal >= 75 ? "▂▄▆█" : (itemNet.signal >= 50 ? "▂▄▆" : "▂▄")
                        color: itemNet.in_use ? themeAccent : root.ink(0.45)
                        font.pixelSize: 9
                    }

                    Text {
                        text: isConnecting ? "Connecting…" : (itemNet.security ? "" : "Open")
                        color: isConnecting ? themeAccent : root.ink(0.3)
                        font.family: root.uiFont
                        font.pixelSize: 9
                    }

                    Text {
                        text: "\uf00c"
                        color: themeAccent
                        font.family: root.font
                        font.pixelSize: 11
                        visible: itemNet.in_use
                    }
                }

                MouseArea {
                    id: netItemArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: connectWifi(itemNet.ssid)
                }
            }
        }

        // Loading / empty footer for the list
        Text {
            Layout.alignment: Qt.AlignHCenter
            Layout.bottomMargin: 2
            text: wifiLoading ? "Scanning…" : (wifiNetworks.length === 0 ? "No networks found" : wifiNetworks.length + " networks")
            color: root.ink(0.36)
            font.family: root.uiFont
            font.pixelSize: 9
        }
    }

    // ════════════════════════════════════════════════════════════════
    // │ BLUETOOTH SUB-VIEW
    // ════════════════════════════════════════════════════════════════
    ColumnLayout {
        id: btView
        anchors.fill: parent
        anchors.margins: 16
        spacing: 8
        opacity: currentView === "bt" ? 1 : 0
        visible: opacity > 0
        transform: Translate { y: currentView === "bt" ? (1 - btView.opacity) * 8 : -btView.opacity * 8 }
        Behavior on opacity {
            NumberAnimation {
                duration: currentView === "bt" ? root.motionBase : root.motionExit
                easing.type: Easing.OutCubic
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Rectangle {
                width: 28; height: 28; radius: 10
                color: backBtArea.containsMouse ? root.ink(0.102) : root.ink(0.039)
                Text { anchors.centerIn: parent; text: "\uf060"; color: root.themeFg; font.family: root.font; font.pixelSize: 12 }
                MouseArea {
                    id: backBtArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: currentView = "main"
                }
            }

            Text { text: "Bluetooth Devices"; color: root.themeFg; font.family: root.uiFont; font.pixelSize: 14; font.weight: Font.Bold }

            Item { Layout.fillWidth: true }

            Rectangle {
                width: 28; height: 28; radius: 10
                color: openBtArea.containsMouse ? root.ink(0.102) : root.ink(0.039)
                Text { anchors.centerIn: parent; text: "\uf013"; color: root.ink(0.52); font.family: root.font; font.pixelSize: 12 }
                MouseArea {
                    id: openBtArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: runShell("blueman-manager &")
                }
            }

            Rectangle {
                width: 28; height: 28; radius: 10
                color: refBtArea.containsMouse ? root.ink(0.102) : root.ink(0.039)
                Text { anchors.centerIn: parent; text: "\uf021"; color: themeAccent; font.family: root.font; font.pixelSize: 12 }
                MouseArea {
                    id: refBtArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: refreshBluetooth()
                }
            }
        }

        // Power toggle card
        Rectangle {
id: powerTile
            Layout.fillWidth: true
            Layout.preferredHeight: 48
            radius: 14
            color: btPowered ? Qt.rgba(themeAccent.r, themeAccent.g, themeAccent.b, 0.14) : root.ink(0.031)
            border.color: btPowered ? themeAccent : root.ink(0.063)
            border.width: 1
            property real press: 1.0
            transform: Scale { origin.x: width / 2; origin.y: height / 2; xScale: powerTile.press; yScale: powerTile.press }
            Behavior on press { NumberAnimation { duration: 110; easing.type: Easing.OutBack } }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 10
                spacing: 10

                Text {
                    text: "\uf293"
                    color: btPowered ? themeAccent : root.ink(0.45)
                    font.family: root.font
                    font.pixelSize: 15
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 1
                    Text {
                        text: "Bluetooth Adapter"
                        color: root.themeFg
                        font.family: root.uiFont
                        font.pixelSize: 11
                        font.weight: Font.Bold
                    }
                    Text {
                        text: btPowered ? "On" : "Off"
                        color: btPowered ? root.ink(0.55) : root.ink(0.45)
                        font.family: root.uiFont
                        font.pixelSize: 9
                    }
                }

                Rectangle {
                    width: 36; height: 20; radius: 10
                    color: btPowered ? themeAccent : root.ink(0.17)
                    Behavior on color { ColorAnimation { duration: 150 } }
                    Rectangle {
                        width: 16; height: 16; radius: 8
                        x: btPowered ? 18 : 2
                        anchors.verticalCenter: parent.verticalCenter
                        color: root.themeFg
                        Behavior on x { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
                    }
                }
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onPressed: parent.press = 0.97
                onReleased: parent.press = 1.0
                onClicked: toggleBluetooth()
            }
        }

        Text {
            text: "DEVICES"
            color: root.ink(0.36)
            font.family: root.uiFont
            font.pixelSize: 9
            font.weight: Font.Bold
        }

        ListView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            model: (btDevices && btDevices.length) ? btDevices.length : 0
            spacing: 5
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            delegate: Rectangle {
                width: ListView.view.width
                height: 46
                radius: 12
                color: itemBt.connected ? Qt.rgba(themeAccent.r, themeAccent.g, themeAccent.b, 0.14) : (btItemArea.containsMouse ? root.ink(0.063) : root.ink(0.024))
                border.color: itemBt.connected ? Qt.rgba(themeAccent.r, themeAccent.g, themeAccent.b, 0.45) : root.ink(0.071)
                border.width: 1

                property var itemBt: btDevices[index] || {}
                property bool isConnecting: connectingMac === itemBt.mac

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 8
                    spacing: 10

                    Text {
                        text: itemBt.icon === "phone" ? "\uf10b" : (itemBt.icon === "audio-headset" ? "\uf025" : "\uf293")
                        color: itemBt.connected ? themeAccent : root.ink(0.6)
                        font.family: root.font
                        font.pixelSize: 14
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 1
                        Text {
                            text: itemBt.name || "Bluetooth Device"
                            color: itemBt.connected ? root.themeFg : root.ink(0.85)
                            font.family: root.uiFont
                            font.pixelSize: 11
                            font.weight: itemBt.connected ? Font.DemiBold : Font.Normal
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                        Text {
                            text: itemBt.paired ? "Paired" : "Not paired"
                            color: root.ink(0.45)
                            font.family: root.uiFont
                            font.pixelSize: 9
                        }
                    }

                    Rectangle {
                        height: 22
                        implicitWidth: btStateText.implicitWidth + 14
                        radius: 11
                        color: itemBt.connected ? Qt.rgba(themeAccent.r, themeAccent.g, themeAccent.b, 0.25) : root.ink(0.063)
                        border.color: itemBt.connected ? Qt.rgba(themeAccent.r, themeAccent.g, themeAccent.b, 0.4) : "transparent"
                        border.width: itemBt.connected ? 1 : 0
                        Text {
                            id: btStateText
                            anchors.centerIn: parent
                            text: isConnecting ? "Working…" : (itemBt.connected ? "Disconnect" : "Connect")
                            color: itemBt.connected ? root.themeFg : root.ink(0.7)
                            font.family: root.uiFont
                            font.pixelSize: 9
                            font.weight: itemBt.connected ? Font.Bold : Font.Medium
                        }
                    }
                }

                MouseArea {
                    id: btItemArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: connectBtDevice(itemBt.mac)
                }
            }
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            Layout.bottomMargin: 2
            text: btLoading ? "Scanning…" : (btPowered ? (btDevices.length + " devices") : "Bluetooth is off")
            color: root.ink(0.36)
            font.family: root.uiFont
            font.pixelSize: 9
        }
    }

    // ── In-island action confirmation ──────────────────────────
    // Stays inside the open control center (unlike the notification
    // toast, which would replace the panel), so multiple toggles can be
    // flipped without reopening the shade.
    Rectangle {
        id: actionToast
        z: 100
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 18
        width: actionRow.implicitWidth + 26
        height: 36
        radius: 12
        color: root.glass(0.95)
        border.width: 1
        border.color: Qt.rgba(themeAccent.r, themeAccent.g, themeAccent.b, 0.45)
        opacity: controlPanel.actionVisible ? 1 : 0
        visible: opacity > 0
        transform: Translate { y: (1 - actionToast.opacity) * 6 }
        Behavior on opacity { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }

        RowLayout {
            id: actionRow
            anchors.centerIn: parent
            spacing: 8

            Rectangle {
                width: 20; height: 20; radius: 7
                color: Qt.rgba(themeAccent.r, themeAccent.g, themeAccent.b, 0.16)
                Text {
                    anchors.centerIn: parent
                    text: "\uf00c"
                    color: themeAccent
                    font.family: root.font
                    font.pixelSize: 9
                }
            }

            ColumnLayout {
                spacing: 0

                Text {
                    text: controlPanel.actionTitle
                    color: root.uiFg
                    font.family: root.uiFont
                    font.pixelSize: 11
                    font.weight: Font.DemiBold
                }
                Text {
                    visible: text.length > 0
                    text: controlPanel.actionSub
                    color: root.uiFgFaint
                    font.family: root.uiFont
                    font.pixelSize: 9
                }
            }
        }
    }

    // Small IPC surface so scripts/keybinds can use the same toggles.
    IpcHandler {
        target: "control"

        function toggleCaffeine() { controlPanel.toggleCaffeine() }
        function toggleNightLight() { controlPanel.toggleNightLight() }
        function toggleDnd() { controlPanel.toggleDnd() }
        function toggleMic() { controlPanel.toggleMic() }
        function clearNotifications() { root.clearAllNotifications() }
        function showNetwork() { controlPanel.currentView = "network"; controlPanel.refreshNetwork() }
        function showBluetooth() { controlPanel.currentView = "bt"; controlPanel.refreshBluetooth() }
        function showMain() { controlPanel.currentView = "main" }
    }
}
