import Quickshell
import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import Quickshell.Services.Mpris
import Quickshell.Services.Pipewire
import Qt5Compat.GraphicalEffects
import Quickshell.Wayland
import "components"

Scope {
    id: root

    property string font: "JetBrainsMono Nerd Font"
    property real uiScale: 1.25
    
    // --- State ---
    property int displayState: 0 // 0=idle, 1=now-playing, 2=volume, 11=themes, 13=control-panel
    property string islandTheme: "dark"
    
    Process {
      command: ["cat", Quickshell.env("HOME") + "/.config/quickshell/shell_settings.json"]
      running: true
      stdout: SplitParser {
        onRead: (data) => {
          try {
            var settings = JSON.parse(data);
            if (settings.island_theme) root.islandTheme = settings.island_theme;
          } catch (e) {}
        }
      }
    }

    IpcHandler {
      target: "qs-island"
      function updateTheme(themeName: string): void {
        root.islandTheme = themeName;
      }
    }

    // --- Theme Switcher ---
    property var themesList: []
    property string currentThemeId: ""
    property string currentThemeName: ""
    property string currentThemeAccent: "#838996"

    function updateThemeAccent() {
        for (var i = 0; i < root.themesList.length; i++) {
            if (root.themesList[i].id === root.currentThemeId) {
                root.currentThemeName = root.themesList[i].name;
                root.currentThemeAccent = root.themesList[i].accent || "#838996";
                break;
            }
        }
    }

    function applyTheme(themeId) {
        root.currentThemeId = themeId;
        updateThemeAccent();
        applyThemeProcess.command = ["bash", Quickshell.env("HOME") + "/scripts/theme-switch.sh", themeId];
        applyThemeProcess.running = true;
        root.displayState = 0;
        root.updateState();
    }

    Process {
        id: applyThemeProcess
        command: []
    }

    Process {
        id: fetchThemes
        command: ["python3", Quickshell.shellDir + "/scripts/get_themes.py"]
        running: true
        stdout: SplitParser {
            onRead: data => {
                try {
                    root.themesList = JSON.parse(data);
                    root.updateThemeAccent();
                } catch(e) {}
            }
        }
    }

    Process {
        id: fetchCurrentTheme
        command: ["cat", Quickshell.env("HOME") + "/.config/hypr/themes/current_theme.conf"]
        running: true
        stdout: SplitParser {
            onRead: data => {
                // e.g. "source = ~/.config/hypr/themes/catppuccin.conf"
                var match = data.match(/themes\/([^\.]+)\.conf/);
                if (match) {
                    root.currentThemeId = match[1];
                    root.updateThemeAccent();
                }
            }
        }
    }
    property bool isExpanded: false
    property bool isHovered: false
    property bool islandVisible: true
    property bool mediaPopupVisible: false
    property var lastNotification: null

    property var allApps: []
    property var allWallpapers: []
    property var allClipboardItems: []

    function filterApps(query) {
        appsModel.clear();
        query = query.toLowerCase();
        for (var i = 0; i < root.allApps.length; i++) {
            var app = root.allApps[i];
            if (query === "" || app.name.toLowerCase().indexOf(query) !== -1 || (app.exec && app.exec.toLowerCase().indexOf(query) !== -1)) {
                appsModel.append(app);
            }
        }
    }

    function filterWallpapers(query) {
        wallpapersModel.clear();
        query = query.toLowerCase();
        for (var i = 0; i < root.allWallpapers.length; i++) {
            var wp = root.allWallpapers[i];
            // `name` was missing from get_wallpapers.py, so this threw a
            // TypeError on the first keystroke. Guard anyway — an entry with
            // no label should degrade to "shown unfiltered", not crash the shell.
            var label = (wp && wp.name) ? wp.name : "";
            if (query === "" || label.toLowerCase().indexOf(query) !== -1) {
                wallpapersModel.append(wp);
            }
        }
    }

    function filterClipboard(query) {
        clipboardModel.clear();
        query = query.toLowerCase();
        for (var i = 0; i < root.allClipboardItems.length; i++) {
            var item = root.allClipboardItems[i];
            if (query === "" || (item.content && item.content.toLowerCase().indexOf(query) !== -1)) {
                clipboardModel.append(item);
            }
        }
    }

    // --- Media ---
    property var activePlayer: null
    property bool isPlaying: false
    property string trackTitle: ""
    property string trackArtist: ""
    property string artUrl: ""
    property real trackPosition: 0
    property real trackLength: 0
    property real lastFetchedPosition: 0
    property real lastFetchTime: 0

    // --- OSD State ---
    property string osdType: "volume"
    property real osdValue: 0
    property string osdIcon: "\uf028"

    property string weatherTemp: "--°C"
    property string weatherDesc: "Loading..."
    property string weatherIcon: "☁️"

    Process {
        id: weatherProcess
        command: ["curl", "-s", "wttr.in/?format=%t|%C|%c"]
        stdout: SplitParser {
            onRead: data => {
                var parts = data.trim().split("|");
                if (parts.length >= 3) {
                    root.weatherTemp = parts[0].replace("+", "").trim();
                    root.weatherDesc = parts[1].trim();
                    root.weatherIcon = parts[2].trim();
                }
            }
        }
    }

    Timer {
        interval: 15 * 60 * 1000 // 15 mins
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: weatherProcess.running = true
    }

    Timer {
        id: weatherCloseTimer
        interval: 5000 // Close after 5 seconds
        onTriggered: {
            if (root.displayState === 6) {
                root.displayState = 0;
                root.updateState();
            }
        }
    }

    // --- Phase 2: Live Timer ---
    property int timerSecondsTotal: 0
    property int timerSecondsRemaining: 0
    property string timerString: "00:00"

    Timer {
        id: countdownTimer
        interval: 1000
        repeat: true
        running: false
        onTriggered: {
            if (root.timerSecondsRemaining > 0) {
                root.timerSecondsRemaining--;
                var m = Math.floor(root.timerSecondsRemaining / 60);
                var s = root.timerSecondsRemaining % 60;
                root.timerString = (m < 10 ? "0" + m : m) + ":" + (s < 10 ? "0" + s : s);
            } else {
                running = false;
                root.displayState = 0;
                root.updateState();
            }
        }
    }

    IpcHandler {
        target: "timer"
        function start(minutes: string) {
            var mins = parseInt(minutes);
            root.timerSecondsTotal = mins * 60;
            root.timerSecondsRemaining = root.timerSecondsTotal;
            root.timerString = (mins < 10 ? "0" + mins : mins) + ":00";
            root.displayState = 7;
            countdownTimer.start();
        }
        function stop() {
            countdownTimer.stop();
            root.displayState = 0;
            root.updateState();
        }
    }

    // --- Phase 3: Battery & Charging ---
    property int batteryPercent: 0
    property bool batteryCharging: false

    Timer {
        id: batteryCloseTimer
        interval: 7000
        onTriggered: {
            if (root.displayState === 8) {
                root.displayState = 0;
                root.updateState();
            }
        }
    }

    IpcHandler {
        target: "battery"
        function showBattery(capacity: string, charging: string) {
            root.batteryPercent = parseInt(capacity);
            root.batteryCharging = (charging === "true");
            root.displayState = 8;
            batteryCloseTimer.restart();
        }
    }

    // --- Phase 4: Bluetooth ---
    property string bluetoothDeviceName: ""

    Timer {
        id: bluetoothCloseTimer
        interval: 3500
        onTriggered: {
            if (root.displayState === 9) {
                root.displayState = 0;
                root.updateState();
            }
        }
    }

    IpcHandler {
        target: "bluetooth"
        function showDevice(deviceName: string) {
            root.bluetoothDeviceName = deviceName;
            root.displayState = 9;
            bluetoothCloseTimer.restart();
        }
    }

    // --- Phase 6: Notifications ---
    property string notifyAppName: ""
    property string notifySummary: ""
    property string notifyBody: ""
    property var notificationList: []
    property bool dndEnabled: false

    function addToNotificationHistory(appName, summary, body) {
        var notif = {
            id: Date.now() + Math.random(),
            app: appName,
            summary: summary,
            body: body,
            time: new Date()
        };
        var list = root.notificationList.slice();
        list.unshift(notif);
        if (list.length > 25) list.pop();
        root.notificationList = list;
    }

    function clearNotification(notifId) {
        var list = root.notificationList.slice();
        for (var i = 0; i < list.length; i++) {
            if (list[i].id === notifId) {
                list.splice(i, 1);
                break;
            }
        }
        root.notificationList = list;
    }

    function clearAllNotifications() {
        root.notificationList = [];
    }

    Timer {
        id: notificationCloseTimer
        interval: 4000
        onTriggered: {
            if (root.displayState === 10) {
                root.displayState = 0;
                root.updateState();
            }
        }
    }

    IpcHandler {
        target: "notification"
        function showNotification(appName: string, summary: string, body: string) {
            root.notifyAppName = appName;
            root.notifySummary = summary;
            root.notifyBody = body;
            
            // Also add to control panel notification history
            root.addToNotificationHistory(appName, summary, body);

            if (!root.dndEnabled) {
                root.displayState = 10;
                notificationCloseTimer.restart();
            }
        }
    }

    PwObjectTracker { objects: [Pipewire.defaultAudioSink, Pipewire.defaultAudioSource] }

    IpcHandler {
        target: "osd"
        function showVolume() {
            fetchVolume.running = true;
        }
        function showMic() {
            var muted = Pipewire.defaultAudioSource && Pipewire.defaultAudioSource.audio ? Pipewire.defaultAudioSource.audio.muted : false;
            root.osdType = "mic";
            root.osdValue = 0;
            root.osdIcon = muted ? "\uf131" : "\uf130";
            root.displayState = 2;
            osdTimer.restart();
        }
        function showBrightness() {
            brightnessProcess.running = true;
        }
    }

    Process {
        id: fetchVolume
        command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"]
        stdout: SplitParser {
            onRead: data => {
                // Output: "Volume: 0.65" or "Volume: 0.65 [MUTED]"
                var muted = data.indexOf("[MUTED]") !== -1;
                var parts = data.trim().split(" ");
                var vol = parts.length >= 2 ? parseFloat(parts[1]) * 100 : 0;
                vol = Math.min(vol, 100);

                root.osdType = "volume";
                root.osdValue = muted ? 0 : vol;
                if (muted) root.osdIcon = "\uf026";
                else if (vol < 30) root.osdIcon = "\uf027";
                else root.osdIcon = "\uf028";

                root.displayState = 2;
                osdTimer.restart();
            }
        }
    }

    Process {
        id: brightnessProcess
        command: ["sh", "-c", "echo $(brightnessctl g) $(brightnessctl m)"]
        stdout: SplitParser {
            onRead: data => {
                var parts = data.trim().split(" ");
                if (parts.length === 2) {
                    var cur = parseFloat(parts[0]);
                    var max = parseFloat(parts[1]);
                    root.osdType = "brightness";
                    root.osdValue = (cur / max) * 100;
                    root.osdIcon = "\uf185";
                    root.displayState = 2;
                    osdTimer.restart();
                }
            }
        }
    }

    Timer {
        id: osdTimer
        interval: 2000
        onTriggered: {
            if (root.displayState === 2) {
                root.displayState = 0;
                root.updateState();
            }
        }
    }

    // --- State Logic ---
    function updateState() {
        if (displayState === 3 || displayState === 4 || displayState === 2 || displayState === 8 || displayState === 9 || displayState === 10 || displayState === 11 || displayState === 12 || displayState === 13 || displayState === 14 || displayState === 15 || displayState === 23) return;
        if (isPlaying) displayState = 1;
        else displayState = 0;
    }



    property real lastToggleTime: 0

    IpcHandler {
        target: "island"
        function showLauncher() {
            var now = Date.now();
            if (now - root.lastToggleTime < 350) return;
            root.lastToggleTime = now;
            root.displayState = root.displayState === 3 ? 0 : 3;
            if (root.displayState === 0) root.updateState();
        }
        function showWallpapers() {
            var now = Date.now();
            if (now - root.lastToggleTime < 350) return;
            root.lastToggleTime = now;
            root.displayState = root.displayState === 4 ? 0 : 4;
            if (root.displayState === 0) root.updateState();
        }
        function showThemes() {
            var now = Date.now();
            if (now - root.lastToggleTime < 350) return;
            root.lastToggleTime = now;
            root.displayState = root.displayState === 11 ? 0 : 11;
            if (root.displayState === 0) root.updateState();
        }
        function showPower() {
            var now = Date.now();
            if (now - root.lastToggleTime < 350) return;
            root.lastToggleTime = now;
            root.displayState = root.displayState === 12 ? 0 : 12;
            if (root.displayState === 0) root.updateState();
        }
        function showControlPanel() {
            var now = Date.now();
            if (now - root.lastToggleTime < 350) return;
            root.lastToggleTime = now;
            root.displayState = root.displayState === 13 ? 0 : 13;
            if (root.displayState === 0) root.updateState();
        }
        function showPowerProfile() {
            var now = Date.now();
            if (now - root.lastToggleTime < 350) return;
            root.lastToggleTime = now;
            root.displayState = root.displayState === 14 ? 0 : 14;
            if (root.displayState === 0) root.updateState();
        }
        function showClipboard() {
            var now = Date.now();
            if (now - root.lastToggleTime < 350) return;
            root.lastToggleTime = now;
            root.displayState = root.displayState === 15 ? 0 : 15;
            if (root.displayState === 15) {
                fetchClipboard.running = true;
            } else {
                if (root.displayState === 0) root.updateState();
            }
        }
        function showCheatsheet() {
            var now = Date.now();
            if (now - root.lastToggleTime < 350) return;
            root.lastToggleTime = now;
            root.displayState = root.displayState === 23 ? 0 : 23;
            if (root.displayState !== 23 && root.displayState === 0) {
                root.updateState();
            }
        }
    }

    // --- Format Time ---
    function formatTime(sec) {
        var m = Math.floor(sec / 60);
        var s = Math.floor(sec % 60);
        return m + ":" + (s < 10 ? "0" : "") + s;
    }

    // --- Media Player Logic ---
    function checkPlayers() {
        var players = Mpris.players.values;
        var preferred = null;
        var fallback = null;

        for (var i = 0; i < players.length; i++) {
            var p = players[i];
            if (!fallback) fallback = p;
            if (p.playbackState === MprisPlaybackState.Playing) {
                preferred = p;
                break;
            }
        }

        var chosen = preferred || fallback;
        if (chosen) {
            root.activePlayer = chosen;
            root.isPlaying = (chosen.playbackState === MprisPlaybackState.Playing);
            var trackChanged = (root.trackTitle !== (chosen.trackTitle || ""));
            root.trackTitle = chosen.trackTitle || "";
            root.trackArtist = chosen.trackArtist || "";
            root.artUrl = chosen.artUrl || "";
            if (chosen.length !== undefined && chosen.length > 0) root.trackLength = chosen.length / 1000000.0;
            
            if (trackChanged) {
                root.currentLyrics = [];
                root.currentLyricLine = "";
                fetchLyrics.running = false;
                fetchLyrics.command = ["python3", Quickshell.shellDir + "/scripts/get_lyrics.py", root.trackArtist, root.trackTitle];
                triggerLyrics.restart();
            }
        } else {
            root.activePlayer = null;
            root.isPlaying = false;
            root.trackTitle = "";
            root.trackArtist = "";
            root.artUrl = "";
            root.trackPosition = 0;
            root.trackLength = 0;
        }
    }

    // --- Data Models ---
    ListModel { id: appsModel }
    ListModel { id: wallpapersModel }
    ListModel { id: clipboardModel }

    Process {
        id: fetchApps
        command: ["python3", Quickshell.shellDir + "/scripts/get_apps.py"]
        running: true
        stdout: SplitParser {
            onRead: data => {
                try {
                    var apps = JSON.parse(data);
                    root.allApps = apps;
                    root.filterApps("");
                } catch(e) {}
            }
        }
    }

    Process {
        id: fetchWallpapers
        command: ["python3", Quickshell.shellDir + "/scripts/get_wallpapers.py"]
        running: true
        stdout: SplitParser {
            onRead: data => {
                try {
                    var wps = JSON.parse(data);
                    root.allWallpapers = wps;
                    root.filterWallpapers("");
                } catch(e) {}
            }
        }
    }

    Process {
        id: fetchClipboard
        command: ["python3", Quickshell.shellDir + "/scripts/get_clipboard.py"]
        stdout: SplitParser {
            onRead: data => {
                try {
                    var items = JSON.parse(data);
                    root.allClipboardItems = items;
                    root.filterClipboard("");
                } catch(e) {}
            }
        }
    }

    Process {
        id: runCmd
        command: []
    }

    // --- Fetch Processes ---
    Process {
        id: fetchArt
        command: ["bash", "-c", "playerctl metadata mpris:artUrl 2>/dev/null"]
        stdout: SplitParser {
            onRead: data => {
                var url = data.trim();
                if (url.startsWith("/")) url = "file://" + url;
                root.artUrl = url;
            }
        }
    }

    Process {
        id: fetchPos
        command: ["bash", "-c", "for p in $(playerctl -l 2>/dev/null); do if [ \"$(playerctl -p \"$p\" status 2>/dev/null)\" = \"Playing\" ]; then playerctl -p \"$p\" position 2>/dev/null; exit 0; fi; done; playerctl position 2>/dev/null || echo 0"]
        stdout: SplitParser {
            onRead: data => { 
                root.trackPosition = parseFloat(data.trim()) || 0; 
                root.lastFetchedPosition = root.trackPosition;
                root.lastFetchTime = Date.now();
            }
        }
    }

    Process {
        id: fetchLen
        command: ["bash", "-c", "playerctl metadata mpris:length 2>/dev/null | awk '{print $1/1000000}'"]
        stdout: SplitParser {
            onRead: data => {
                var l = parseFloat(data.trim());
                if (l > 0) root.trackLength = l;
            }
        }
    }
    
    // Command functions for interacting with MPRIS
    function playPause() { if (root.activePlayer) root.activePlayer.togglePlaying(); }
    function prevTrack() { if (root.activePlayer) root.activePlayer.previous(); }
    function nextTrack() { if (root.activePlayer) root.activePlayer.next(); }

    property string currentTime: "00:00"

    // --- Live Synced Lyrics ---
    property var currentLyrics: []
    property string currentLyricLine: ""
    property bool lyricsMode: true

    Timer {
        id: triggerLyrics
        interval: 100
        onTriggered: {
            fetchLyrics.running = true;
        }
    }

    function updateLyricLine() {
        if (!root.currentLyrics || root.currentLyrics.length === 0) {
            root.currentLyricLine = "";
            return;
        }
        var pos = root.trackPosition;
        var activeText = "";
        for (var i = 0; i < root.currentLyrics.length; i++) {
            if (root.currentLyrics[i].time <= pos) {
                activeText = root.currentLyrics[i].text;
            } else {
                break;
            }
        }
        root.currentLyricLine = activeText;
    }

    Process {
        id: fetchLyrics
        command: []
        stdout: SplitParser {
            onRead: data => {
                try {
                    root.currentLyrics = JSON.parse(data);
                    root.updateLyricLine();
                } catch(e) {
                    root.currentLyrics = [];
                    root.currentLyricLine = "";
                }
            }
        }
    }

    Timer {
        interval: 100
        running: root.isPlaying && root.activePlayer !== null
        repeat: true
        onTriggered: {
            if (!fetchPos.running) {
                fetchPos.running = true;
            }
            if (root.lastFetchTime > 0) {
                var elapsed = (Date.now() - root.lastFetchTime) / 1000.0;
                root.trackPosition = root.lastFetchedPosition + elapsed;
            }
            root.updateLyricLine();
        }
    }

    // --- Update Timer ---
    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            var d = new Date();
            var h = d.getHours();
            var m = d.getMinutes();
            root.currentTime = (h < 10 ? "0" : "") + h + ":" + (m < 10 ? "0" : "") + m;

            root.checkPlayers();
            if (root.activePlayer) {
                if (root.activePlayer.position === undefined) {
                    fetchPos.running = true;
                }
                if (root.artUrl === "") {
                    fetchArt.running = true;
                }
            }
            root.updateState();
        }
    }

    // =========================================================================
    // DYNAMIC ISLAND WINDOW
    // =========================================================================
    // DYNAMIC ISLAND WINDOW (Static Reserve)
    // =========================================================================
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: reserveWindow
            required property var modelData
            screen: modelData
            anchors { top: true; left: true; right: true }
            color: "transparent"
            exclusiveZone: 40 * root.uiScale
            implicitHeight: 40 * root.uiScale
            mask: Region {} // Empty region means clicks pass through to desktop
        }
    }

    // =========================================================================
    // DYNAMIC ISLAND OVERLAY (Full screen renderer)
    // =========================================================================
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: islandPanel
            required property var modelData
            screen: modelData

            visible: root.islandVisible

            WlrLayershell.namespace: "qs-island"
            WlrLayershell.keyboardFocus: (root.displayState === 3 || root.displayState === 4 || root.displayState === 11 || root.displayState === 12 || root.displayState === 14 || root.displayState === 15 || root.displayState === 23) ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
            WlrLayershell.layer: WlrLayer.Top
            exclusionMode: ExclusionMode.Ignore

            anchors { top: true; left: true; right: true; bottom: true }
            color: "transparent"
            
            mask: (root.displayState === 3 || root.displayState === 4 || root.displayState === 6 || root.displayState === 11 || root.displayState === 12 || root.displayState === 13 || root.displayState === 14 || root.displayState === 15 || root.displayState === 23) ? fullScreenRegion : pillRegion

            Region {
                id: fullScreenRegion
                x: 0; y: 0
                width: islandPanel.width
                height: islandPanel.height
            }

            Region {
                id: pillRegion
                // The region must exactly match the scaled dimensions of the pill
                x: scaleWrapper.x - (scaleWrapper.width * root.uiScale - scaleWrapper.width) / 2
                y: scaleWrapper.y
                width: scaleWrapper.width * root.uiScale
                height: scaleWrapper.height * root.uiScale
            }

            // Click outside full-screen overlay (closes launcher / wallpaper selector)
            MouseArea {
                anchors.fill: parent
                enabled: root.displayState === 3 || root.displayState === 4 || root.displayState === 6 || root.displayState === 11 || root.displayState === 12 || root.displayState === 13 || root.displayState === 14 || root.displayState === 15 || root.displayState === 23
                onClicked: {
                    root.displayState = 0;
                    root.updateState();
                }
                z: -1
            }

            // Scale wrapper (now controls the animated size instead of Wayland)
            Item {
                id: scaleWrapper
                width: root.displayState === 23 ? 780 :
                       root.displayState === 15 ? 780 :
                       root.displayState === 14 ? 500 :
                       root.displayState === 13 ? 560 :
                       root.displayState === 12 ? 480 :
                       root.displayState === 11 ? 540 :
                       root.displayState === 10 ? 320 :
                       root.displayState === 9 ? 220 :
                       root.displayState === 8 ? 240 :
                       root.displayState === 7 ? 180 :
                       root.displayState === 6 ? 280 :
                       root.displayState === 4 ? 540 :
                       root.displayState === 3 ? 780 :
                       root.displayState === 2 ? 200 :
                       root.displayState === 1 ? (root.isExpanded ? 360 : (root.currentLyricLine !== "" ? Math.min(540, Math.max(340, lyricMeasure.implicitWidth + 90)) : Math.min(460, Math.max(280, titleMeasure.implicitWidth + 120)))) :
                       80

                height: root.displayState === 23 ? 600 :
                        root.displayState === 15 ? 196 :
                        root.displayState === 14 ? 130 :
                        root.displayState === 13 ? 440 :
                        root.displayState === 12 ? 130 :
                        root.displayState === 11 ? 140 :
                        root.displayState === 10 ? 80 :
                        root.displayState === 9 ? 48 :
                        root.displayState === 8 ? 48 :
                        root.displayState === 7 ? 40 :
                        root.displayState === 6 ? 80 :
                        root.displayState === 4 ? 150 :
                        root.displayState === 3 ? 440 :
                        root.displayState === 2 ? 48 :
                        root.displayState === 1 ? (root.isExpanded ? 190 : 44) :
                        32
                
                anchors.top: parent.top
                anchors.topMargin: 4 * root.uiScale
                anchors.horizontalCenter: parent.horizontalCenter
                
                scale: root.uiScale
                transformOrigin: Item.Top
                
                Behavior on width { NumberAnimation { duration: 320; easing.type: Easing.OutCubic } }
                Behavior on height { NumberAnimation { duration: 320; easing.type: Easing.OutCubic } }

                // Measure text width for dynamic pill width
                Text {
                    id: lyricMeasure
                    visible: false
                    text: root.currentLyricLine
                    font.family: "Outfit"
                    font.pixelSize: 13
                    font.weight: Font.Medium
                }
                
                Text {
                    id: titleMeasure
                    visible: false
                    text: root.trackTitle || "Nothing Playing"
                    font.family: "Outfit"
                    font.pixelSize: 14
                    font.bold: true
                }

                // ==================== Pill ====================
                Rectangle {
                    id: pill
                    anchors.fill: parent
                    radius: root.displayState === 0 ? 16 : 22
                    color: root.islandTheme === "liquid" ? "#35000000" : "#E60D0D11"
                    border.color: root.islandTheme === "liquid" ? "#30FFFFFF" : "#28FFFFFF"
                    border.width: 1
                    clip: true

                    Behavior on radius { NumberAnimation { duration: 300 } }
                    Behavior on color { ColorAnimation { duration: 300 } }

                    // Inner dark glass container
                    Rectangle {
                        anchors.fill: parent
                        radius: parent.radius
                        opacity: root.islandTheme === "liquid" ? 0 : (root.displayState !== 0 ? 1 : 0)
                        Behavior on opacity { NumberAnimation { duration: 300 } }
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: "#F0161619" }
                            GradientStop { position: 1.0; color: "#F00A0A0D" }
                        }
                    }

                    // Top highlight shimmer
                    Rectangle {
                        width: parent.width * 0.5
                        height: 1
                        anchors.top: parent.top
                        anchors.topMargin: 1
                        anchors.horizontalCenter: parent.horizontalCenter
                        visible: root.displayState !== 0
                        gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop { position: 0.0; color: "transparent" }
                            GradientStop { position: 0.5; color: "#25FFFFFF" }
                            GradientStop { position: 1.0; color: "transparent" }
                        }
                    }

                    // Components from the components directory
                    IdleClock {}
                    NowPlayingCompact {}
                    NowPlayingExpanded {}
                    OSD {}
                    AppLauncher {}
                    WallpaperSelector {}
                    WeatherGlance {}
                    LiveTimer {}
                    BatteryAlert {}
                    BluetoothAlert {}
                    Notification {}
                    ThemeSwitcher {}
                    PowerMenu {}
                    ControlPanel {}
                    PowerProfileMenu {}
                    ClipboardManager {}
                    KeybindCheatsheet {}

                // Global hover area for the island
                MouseArea {
                    anchors.fill: parent
                    enabled: root.displayState < 3
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    acceptedButtons: Qt.LeftButton | Qt.RightButton

                    onContainsMouseChanged: {
                        root.isHovered = containsMouse;
                        // root.isExpanded = (containsMouse && root.displayState === 1 && !root.mediaPopupVisible);
                    }

                    onClicked: {
                        if (root.displayState === 1) {
                            root.mediaPopupVisible = !root.mediaPopupVisible;
                            if (root.mediaPopupVisible) root.isExpanded = false;
                        } else if (root.displayState === 0) {
                            root.displayState = 6;
                            weatherCloseTimer.restart();
                        }
                    }

                    z: root.isExpanded ? -1 : 0
                }
                } // Close Rectangle (pill)
            } // Close Item (scale wrapper)
        }
    }

    // =========================================================================
    // MEDIA POPUP WINDOW
    // =========================================================================
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: popupWindow
            required property var modelData
            screen: modelData

            anchors { top: true }
            margins { top: 72 * root.uiScale } // Below the dynamic island
            exclusiveZone: 0
            color: "transparent"
            visible: root.mediaPopupVisible

            implicitWidth: 400 * root.uiScale
            implicitHeight: 185 * root.uiScale

            Item {
                width: 400
                height: 185
                anchors.top: parent.top
                anchors.horizontalCenter: parent.horizontalCenter
                
                scale: root.mediaPopupVisible ? root.uiScale : (0.92 * root.uiScale)
                opacity: root.mediaPopupVisible ? 1 : 0
                transformOrigin: Item.Top
                Behavior on opacity { NumberAnimation { duration: 300; easing.type: Easing.OutQuart } }
                Behavior on scale { NumberAnimation { duration: 350; easing.type: Easing.OutBack } }

                // Shadow
                RectangularGlow {
                    anchors.fill: popupCard
                    glowRadius: 32
                    spread: 0.1
                    color: Qt.rgba(0,0,0, 0.5)
                    cornerRadius: popupCard.radius + glowRadius
                }

                Rectangle {
                    id: popupCard
                    anchors.fill: parent
                    radius: 24
                    color: "#F00A0A0D"
                    border.color: "#33FFFFFF"
                    border.width: 1
                    clip: true

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 20
                        spacing: 20

                        // ==================== Vinyl Disc ====================
                        Item {
                            Layout.preferredWidth: 145
                            Layout.preferredHeight: 145
                            Layout.alignment: Qt.AlignVCenter

                            // Spinning rotation
                            NumberAnimation on rotation {
                                from: 0; to: 360; duration: 8000
                                loops: Animation.Infinite
                                running: root.isPlaying && root.mediaPopupVisible
                            }

                            // Base record body
                            Rectangle {
                                anchors.fill: parent
                                radius: width / 2
                                color: "#111111"
                                border.color: "#222222"
                                border.width: 1
                            }

                            // Grooves
                            Repeater {
                                model: 12
                                Rectangle {
                                    anchors.centerIn: parent
                                    width: parent.width * (0.15 + (index * 0.055))
                                    height: width
                                    radius: width / 2
                                    color: "transparent"
                                    border.color: "#1AFFFFFF"
                                    border.width: 1
                                }
                            }

                            // Album Art Label
                            Rectangle {
                                id: artMask
                                anchors.centerIn: parent
                                width: parent.width * 0.4
                                height: width
                                radius: width / 2
                                visible: false
                            }

                            Image {
                                id: popupArtImg
                                anchors.fill: artMask
                                source: root.artUrl
                                fillMode: Image.PreserveAspectCrop
                                visible: false
                            }

                            OpacityMask {
                                anchors.fill: artMask
                                source: popupArtImg
                                maskSource: artMask
                            }

                            // Center Spindle Hole
                            Rectangle {
                                anchors.centerIn: parent
                                width: 8; height: 8
                                radius: 4
                                color: "#000000"
                            }
                        }

                        // ==================== Info & Controls ====================
                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter
                            spacing: 12

                            ColumnLayout {
                                spacing: 4
                                Text {
                                    Layout.fillWidth: true
                                    text: root.trackTitle || "Nothing Playing"
                                    color: "#FFFFFF"
                                    font.family: "Outfit"
                                    font.pixelSize: 18
                                    font.bold: true
                                    elide: Text.ElideRight
                                    wrapMode: Text.NoWrap
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: root.trackArtist || "Unknown"
                                    color: "#99FFFFFF"
                                    font.family: "Outfit"
                                    font.pixelSize: 14
                                    elide: Text.ElideRight
                                }
                            }

                            // Controls Row
                            RowLayout {
                                Layout.fillWidth: true
                                Layout.topMargin: 8
                                spacing: 16

                                Rectangle {
                                    id: pPrevBtn
                                    width: 38; height: 38; radius: 19
                                    color: pPrevArea.containsMouse ? "#22FFFFFF" : "transparent"
                                    property real btnScale: 1.0
                                    transform: Scale { origin.x: 19; origin.y: 19; xScale: pPrevBtn.btnScale; yScale: pPrevBtn.btnScale }
                                    Behavior on btnScale { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }
                                    Text { anchors.centerIn: parent; text: "\uf04a"; color: "#FFFFFF"; font.family: root.font; font.pixelSize: 18 }
                                    MouseArea {
                                        id: pPrevArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                        onPressed: pPrevBtn.btnScale = 0.88; onReleased: pPrevBtn.btnScale = 1.0; onClicked: root.prevTrack()
                                    }
                                }
                                Rectangle {
                                    id: pPlayBtn
                                    width: 48; height: 48; radius: 24
                                    color: "#FFFFFF"
                                    property real btnScale: 1.0
                                    transform: Scale { origin.x: 24; origin.y: 24; xScale: pPlayBtn.btnScale; yScale: pPlayBtn.btnScale }
                                    Behavior on btnScale { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }
                                    Text { anchors.centerIn: parent; text: root.isPlaying ? "\uf04c" : "\uf04b"; color: "#0D0D11"; font.family: root.font; font.pixelSize: 20 }
                                    MouseArea {
                                        anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                        onPressed: pPlayBtn.btnScale = 0.88; onReleased: pPlayBtn.btnScale = 1.0; onClicked: root.playPause()
                                    }
                                }
                                Rectangle {
                                    id: pNextBtn
                                    width: 38; height: 38; radius: 19
                                    color: pNextArea.containsMouse ? "#22FFFFFF" : "transparent"
                                    property real btnScale: 1.0
                                    transform: Scale { origin.x: 19; origin.y: 19; xScale: pNextBtn.btnScale; yScale: pNextBtn.btnScale }
                                    Behavior on btnScale { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }
                                    Text { anchors.centerIn: parent; text: "\uf04e"; color: "#FFFFFF"; font.family: root.font; font.pixelSize: 18 }
                                    MouseArea {
                                        id: pNextArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                        onPressed: pNextBtn.btnScale = 0.88; onReleased: pNextBtn.btnScale = 1.0; onClicked: root.nextTrack()
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
