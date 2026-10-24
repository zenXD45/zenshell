import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs

// Camera Effects — the Omarchy plugin, ported to ZenShell.
//
// The daemon half is upstream's (see CameraService.qml); this file is the
// panel: the same five tabs as the original (Video · Look · Fun · Mic ·
// Privacy), rebuilt with ZenShell's tokens so it belongs to the island
// instead of looking like a guest in it.
//
// The panel is hosted by the island (displayState 24) and opened from the
// Camera tile in the notification center.
Item {
    id: cameraPanel
    anchors.fill: parent
    clip: true

    property var svc: root.cameraService
    readonly property var s: svc ? svc.settings : ({})
    readonly property var m: svc ? svc.micSettings : ({})
    readonly property color accent: root.currentThemeAccent || root.themeAccent
    readonly property bool connected: svc ? svc.connected : false
    readonly property bool inUse: svc ? svc.running : false
    readonly property int appCount: svc ? svc.consumers : 0
    readonly property bool blocked: svc ? svc.block : false

    opacity: root.displayState === 24 ? 1 : 0
    visible: opacity > 0
    Behavior on opacity {
        NumberAnimation {
            duration: root.displayState === 24 ? root.motionPanel : root.motionExit
            easing.type: root.displayState === 24 ? Easing.OutExpo : Easing.OutCubic
        }
    }

    // ═══════════════════════════════════════════════════════════════
    // State
    // ═══════════════════════════════════════════════════════════════
    property var tabs: [
        { key: "video", label: "Video" },
        { key: "look", label: "Look" },
        { key: "fun", label: "Fun" },
        { key: "mic", label: "Mic" },
        { key: "privacy", label: "Privacy" }
    ]
    property string tab: "video"

    property int snapCount: 0
    readonly property bool multiCam: svc ? (svc.cameras || []).length > 1 : false
    property bool autoGainRunning: false
    property real autoGainPeak: 0
    property int autoGainLeft: 0
    readonly property real autoGainTarget: 0.6

    function accentA(a) {
        return Qt.rgba(accent.r, accent.g, accent.b, a)
    }

    function setCam(key, value) {
        if (!svc) return;
        var p = {};
        p[key] = value;
        svc.set(p);
    }

    function setMicSetting(key, value) {
        if (!svc) return;
        var p = {};
        p[key] = value;
        svc.setMic({ settings: p });
    }

    function camName(c) {
        if (!c || !c.name) return "no camera";
        var n = String(c.name);
        return n.indexOf("File: ") === 0 ? n.slice(6) : n;
    }

    function camLabel(c) {
        var n = camName(c);
        return n.length > 24 ? n.slice(0, 23) + "…" : n;
    }

    function micName(c) {
        if (!c) return "microphone";
        var n = String(c.description || c.name || "microphone");
        return n.length > 26 ? n.slice(0, 25) + "…" : n;
    }

    function statusLine() {
        if (!svc) return "Starting…";
        if (svc.setupBusy) return "Working…";
        if (!svc.installed) return "Daemon not installed";
        if (svc.daemonError && !connected) return svc.daemonError;
        if (!connected) return "Connecting…";
        if (svc.deviceMissing) return "Virtual camera missing";
        if (blocked) return "Camera blocked";
        var cam = camName(svc.camera);
        if (appCount > 0) return "In use · " + cam;
        if (inUse) return "Live · " + cam;
        return "Idle · " + cam;
    }

    function micFooter() {
        if (!svc || !connected) return "";
        if (svc.micMuted) return "Muted · apps hear silence";
        if (svc.micStatus !== "" && svc.micStatus !== "ok" && svc.micStatus !== "off")
            return "Microphone problem: " + svc.micStatus;
        if (svc.micConsumers > 0) return "In use by " + svc.micConsumers + " app" + (svc.micConsumers > 1 ? "s" : "");
        if (svc.micListening) return "Listening · playing through your speakers";
        return "Idle · pick “" + svc.micLabel + "” in your apps";
    }

    function footerLine() {
        if (!svc || !connected) return "";
        var res = svc.state.output ? " · " + svc.state.output.width + "×" + svc.state.output.height : "";
        var apps = svc.consumerApps || [];
        var named = apps.length > 1 ? apps.slice(0, 1).join(", ") + " +" + (apps.length - 1) : apps.join(", ");
        var who = appCount > 0 ? "In use by " + (named || (appCount + " app" + (appCount > 1 ? "s" : ""))) : "Idle";
        return who + res + perfLine();
    }

    // What the pipeline costs. The daemon measures itself and reports it;
    // without this, a slow preview has no explanation.
    function perfLine() {
        if (!svc || !connected) return "";
        if (!svc.procMs) return "";
        var out = " · " + svc.procMs + " ms";
        if (svc.fps) out += " · " + svc.fps + " fps";
        if (svc.tier) out += " · tier " + svc.tier;
        return out;
    }

    // Gesture reactions default to on in the daemon, so an empty state reads
    // as "on" rather than as "off".
    function reactionsEnabled() {
        return !!(svc && svc.settings && svc.settings.reactions !== false);
    }

    // The gesture the daemon sees right now, in words.
    function gestureLabel(g) {
        if (!g) return "";
        return ({
            peace: "✌ Peace sign",
            thumbsup: "👍 Thumbs up",
            thumbsdown: "👎 Thumbs down",
            horns: "🤘 Rock sign",
            hearts: "🫶 Heart hands"
        })[g] || g;
    }

    readonly property var outputSizes: [
        { value: "1280x720", label: "720p", w: 1280, h: 720 },
        { value: "1920x1080", label: "1080p", w: 1920, h: 1080 },
        { value: "2560x1440", label: "1440p", w: 2560, h: 1440 },
        { value: "3840x2160", label: "4K", w: 3840, h: 2160 }
    ]
    readonly property string currentOutput: svc && svc.output && svc.output.width
        ? svc.output.width + "x" + svc.output.height : ""
    readonly property int currentFps: svc && svc.output && svc.output.fps ? svc.output.fps : 30
    // The daemon captures at the smaller of its capture size and the output
    // size, so an output bigger than the capture is a real-time upscale.
    readonly property bool upscaling: !!(svc && svc.output && svc.state && svc.state.capture
        && (svc.output.width > svc.state.capture.width || svc.output.height > svc.state.capture.height))

    // ── Camera presets ──────────────────────────────────────────
    // The same idea as the microphone presets: one chip is a complete
    // answer, and the panel shows which preset the settings currently
    // are (or "Custom" the moment you change something by hand).
    //
    // An intensity only counts while the effect it belongs to is on, so
    // nudging Portrait's strength does not drop you to "Custom" for a
    // setting that is not even running.
    readonly property var camIntensityOwner: ({
        portraitIntensity: "portrait",
        studioLightIntensity: "studioLight",
        centerStageIntensity: "centerStage"
    })
    readonly property var camPresetList: [
        { key: "clean", label: "Clean", set: { centerStage: false, centerStageIntensity: 0.5, portrait: false, portraitIntensity: 0.6,
                                               studioLight: false, studioLightIntensity: 0.55, background: "none", filter: "none",
                                               fun: "none", ambience: "none", zoom: 1, fit: "cover", rotate: 0, mirror: false } },
        { key: "portrait", label: "Portrait", set: { centerStage: false, centerStageIntensity: 0.5, portrait: true, portraitIntensity: 0.65,
                                                     studioLight: false, studioLightIntensity: 0.55, background: "none", filter: "none",
                                                     fun: "none", ambience: "none", zoom: 1.15, fit: "cover", rotate: 0, mirror: false } },
        { key: "studio", label: "Studio", set: { centerStage: false, centerStageIntensity: 0.5, portrait: false, portraitIntensity: 0.6,
                                                  studioLight: true, studioLightIntensity: 0.55, background: "none", filter: "warm",
                                                  fun: "none", ambience: "none", zoom: 1, fit: "cover", rotate: 0, mirror: false } },
        { key: "call", label: "Call", set: { centerStage: true, centerStageIntensity: 0.6, portrait: true, portraitIntensity: 0.45,
                                              studioLight: false, studioLightIntensity: 0.55, background: "none", filter: "none",
                                              fun: "none", ambience: "none", zoom: 1, fit: "cover", rotate: 0, mirror: false } },
        { key: "gaming", label: "Gaming", set: { centerStage: false, centerStageIntensity: 0.5, portrait: false, portraitIntensity: 0.6,
                                                  studioLight: false, studioLightIntensity: 0.55, background: "none", filter: "vivid",
                                                  fun: "none", ambience: "none", zoom: 1, fit: "cover", rotate: 0, mirror: false } }
    ]
    readonly property string camSettingsKey: svc ? JSON.stringify(svc.settings) : ""
    property string activeCamPreset: "custom"
    onCamSettingsKeyChanged: activeCamPreset = matchCamPreset()
    function matchCamPreset() {
        if (!svc || !svc.settings) return "custom";
        for (var i = 0; i < camPresetList.length; i++) {
            var p = camPresetList[i];
            if (!p.set) continue;
            var hit = true;
            for (var k in p.set) {
                var a = svc.settings[k], b = p.set[k];
                if (typeof b === "number") {
                    var owner = camIntensityOwner[k];
                    if (owner && !svc.settings[owner]) continue;
                    if (Math.abs((a === undefined ? -1 : a) - b) > 0.02) { hit = false; break; }
                    continue;
                }
                if ((a === undefined ? false : a) !== b) { hit = false; break; }
            }
            if (hit) return p.key;
        }
        return "custom";
    }
    function applyCamPreset(key) {
        if (!svc) return;
        for (var i = 0; i < camPresetList.length; i++) {
            if (camPresetList[i].key !== key) continue;
            var patch = {};
            for (var k in camPresetList[i].set) patch[k] = camPresetList[i].set[k];
            svc.set(patch);
            return;
        }
    }

    // ── Microphone presets (upstream's bundles) ──────────────────
    readonly property var intensityOwner: ({
        voiceIsolationIntensity: "voiceIsolation",
        noiseGateIntensity: "noiseGate",
        autoLevelIntensity: "autoLevel",
        deEsserIntensity: "deEsser"
    })
    readonly property var presetList: [
        { key: "clean", label: "Clean", set: { voiceIsolation: false, noiseGate: false, autoLevel: false, deEsser: false, humFilter: false,
                                               highPass: true, tone: "none", voice: "none", space: "none" } },
        { key: "voice", label: "Voice", set: { voiceIsolation: true, voiceIsolationIntensity: 0.6, noiseGate: false, autoLevel: false,
                                               deEsser: false, humFilter: false, highPass: true, tone: "none", voice: "none", space: "none" } },
        { key: "meeting", label: "Meeting", set: { voiceIsolation: true, voiceIsolationIntensity: 0.7, noiseGate: true, noiseGateIntensity: 0.55,
                                                   autoLevel: true, autoLevelIntensity: 0.6, deEsser: true, deEsserIntensity: 0.5,
                                                   humFilter: false, highPass: true, tone: "clarity", voice: "none", space: "none" } },
        { key: "podcast", label: "Podcast", set: { voiceIsolation: true, voiceIsolationIntensity: 0.4, noiseGate: false, autoLevel: true,
                                                   autoLevelIntensity: 0.5, deEsser: true, deEsserIntensity: 0.6, humFilter: false,
                                                   highPass: true, tone: "podcast", voice: "none", space: "none" } }
    ]
    readonly property string micSettingsKey: svc ? JSON.stringify(svc.micSettings) : ""
    property string activePreset: "custom"
    onMicSettingsKeyChanged: activePreset = matchPreset()
    function matchPreset() {
        if (!svc || !svc.micSettings) return "custom";
        for (var i = 0; i < presetList.length; i++) {
            var p = presetList[i];
            if (!p.set) continue;
            var hit = true;
            for (var k in p.set) {
                var a = svc.micSettings[k], b = p.set[k];
                if (typeof b === "number") {
                    var owner = intensityOwner[k];
                    if (owner && !svc.micSettings[owner]) continue;
                    if (Math.abs((a === undefined ? -1 : a) - b) > 0.001) { hit = false; break; }
                    continue;
                }
                if ((a === undefined ? false : a) !== b) { hit = false; break; }
            }
            if (hit) return p.key;
        }
        return "custom";
    }
    function applyPreset(key) {
        if (!svc) return;
        for (var i = 0; i < presetList.length; i++) {
            if (presetList[i].key !== key) continue;
            var patch = {};
            for (var k in presetList[i].set) patch[k] = presetList[i].set[k];
            patch.enabled = true;
            svc.setMic({ settings: patch });
            return;
        }
    }

    // "Auto": watch the raw level for a few seconds and set the gain so the
    // loudest thing lands a little under the top of the meter.
    property string autoGainNote: ""
    Timer { id: autoGainNoteClear; interval: 2500; onTriggered: cameraPanel.autoGainNote = "" }
    function startAutoGain() {
        if (!svc || autoGainRunning) return;
        autoGainPeak = 0;
        autoGainNote = "";
        autoGainLeft = 4;
        autoGainRunning = true;
        autoGainTimer.start();
    }
    function finishAutoGain() {
        autoGainRunning = false;
        if (!svc) return;
        if (autoGainPeak < 0.01) {
            autoGainNote = "heard nothing";
            autoGainNoteClear.restart();
            return;
        }
        var gain = autoGainTarget / autoGainPeak;
        var v = 0.5 + (20 * Math.log(gain) / Math.LN10) / 36;
        svc.setMicSetting("volume", Math.max(0, Math.min(1, Math.round(v * 20) / 20)));
    }
    Timer {
        id: autoGainTimer
        interval: 1000
        repeat: true
        onTriggered: {
            cameraPanel.autoGainLeft -= 1;
            if (cameraPanel.autoGainLeft <= 0) { stop(); cameraPanel.finishAutoGain(); }
        }
    }
    Connections {
        target: cameraPanel.svc
        enabled: cameraPanel.autoGainRunning
        function onMicInChanged() {
            if (cameraPanel.svc && cameraPanel.svc.micIn > cameraPanel.autoGainPeak)
                cameraPanel.autoGainPeak = cameraPanel.svc.micIn;
        }
    }

    // ── Snapshot ─────────────────────────────────────────────────
    function snap() {
        if (!svc || snapCount > 0) return;
        snapCount = 3;
        snapTimer.restart();
    }
    Timer {
        id: snapTimer
        interval: 1000
        repeat: true
        onTriggered: {
            cameraPanel.snapCount--;
            if (cameraPanel.snapCount > 0) return;
            stop();
            if (cameraPanel.svc) cameraPanel.svc.snapshot();
        }
    }

    // ── The daemon holds the camera open only while something watches ──
    onVisibleChanged: {
        if (!svc) return;
        if (visible) { svc.setPreview(true); svc.refresh(); svc.rescan(); }
        else { svc.setPreview(false); svc.setMicPreview(false, cameraPanel); }
    }
    onTabChanged: {
        if (!svc) return;
        if (tab === "mic") svc.setMicPreview(true, cameraPanel);
        else svc.setMicPreview(false, cameraPanel);
    }

    // ═══════════════════════════════════════════════════════════════
    // Reusable pieces
    // ═══════════════════════════════════════════════════════════════

    component SectionLabel: Text {
        color: root.cFgMuted
        font.family: root.fontSans
        font.pixelSize: 9
        font.weight: Font.DemiBold
        font.letterSpacing: 1.1
        font.capitalization: Font.AllUppercase
    }

    component ToggleRow: Item {
        id: row
        property string label: ""
        property string summary: ""
        property bool checked: false
        property bool enabled: true
        property bool strong: false
        signal toggled()
        implicitHeight: 30
        // The layout owns the width: an inline component in a ColumnLayout
        // gets zero unless it asks to fill.
        Layout.fillWidth: true
        Layout.preferredHeight: 30
        opacity: enabled ? 1 : 0.45

        Rectangle {
            anchors.fill: parent
            radius: 9
            color: row.checked ? cameraPanel.accentA(0.13) : (row.strong ? root.ink(0.039) : "transparent")
            border.width: 1
            border.color: row.checked ? cameraPanel.accentA(0.32) : root.ink(0.071)
            Behavior on color { ColorAnimation { duration: 140 } }
            Behavior on border.color { ColorAnimation { duration: 140 } }
        }

        Text {
            id: rowLabel
            anchors.left: parent.left
            anchors.leftMargin: row.strong ? 10 : 2
            anchors.right: switchBox.left
            anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            text: row.label
            color: root.cFgPrimary
            font.family: root.fontSans
            font.pixelSize: 12
            font.weight: row.strong ? Font.DemiBold : Font.Medium
            elide: Text.ElideRight
        }

        // Switch
        Item {
            id: switchBox
            anchors.right: parent.right
            anchors.rightMargin: 2
            anchors.verticalCenter: parent.verticalCenter
            width: 34
            height: 19

            Rectangle {
                anchors.fill: parent
                radius: height / 2
                color: row.checked ? cameraPanel.accentA(0.85) : root.ink(0.102)
                border.width: 1
                border.color: row.checked ? cameraPanel.accentA(0.9) : root.ink(0.122)
                Behavior on color { ColorAnimation { duration: 150 } }
            }
            Rectangle {
                width: 13
                height: 13
                radius: 6.5
                y: 3
                x: row.checked ? parent.width - width - 3 : 3
                color: row.checked ? root.onAccent() : root.ink(0.71)
                Behavior on x { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
                Behavior on color { ColorAnimation { duration: 150 } }
            }
            MouseArea {
                anchors.fill: parent
                enabled: row.enabled
                cursorShape: Qt.PointingHandCursor
                onClicked: row.toggled()
            }
        }

        // The whole row is a target, like a real settings list.
        MouseArea {
            anchors.fill: parent
            anchors.rightMargin: switchBox.width + 4
            enabled: row.enabled
            cursorShape: Qt.PointingHandCursor
            onClicked: row.toggled()
        }
    }

    component SliderRow: Item {
        id: srow
        property string label: ""
        property real value: 0
        property real from: 0
        property real to: 1
        property bool enabled: true
        property string suffix: "%"
        signal moved(real v)
        implicitHeight: 28
        Layout.fillWidth: true
        Layout.preferredHeight: 28
        opacity: enabled ? 1 : 0.45

        Text {
            id: srowLabel
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            width: 96
            text: srow.label
            color: root.cFgSecondary
            font.family: root.fontSans
            font.pixelSize: 11
            elide: Text.ElideRight
        }

        Text {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            text: Math.round(srow.value * 100) + srow.suffix
            color: root.cFgMuted
            font.family: root.fontSans
            font.pixelSize: 10
            font.weight: Font.Medium
        }

        Item {
            id: srowTrack
            anchors.left: srowLabel.right
            anchors.leftMargin: 8
            anchors.right: parent.right
            anchors.rightMargin: 46
            anchors.verticalCenter: parent.verticalCenter
            height: 18

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width
                height: 3
                radius: 1.5
                color: root.ink(0.122)
            }
            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                height: 3
                radius: 1.5
                width: Math.max(0, (parent.width - 12) * ((srow.value - srow.from) / (srow.to - srow.from)))
                color: cameraPanel.accent
            }
            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                x: Math.max(0, Math.min(parent.width - width, (parent.width - 12) * ((srow.value - srow.from) / (srow.to - srow.from))))
                width: sliderDrag.pressed ? 13 : 11
                height: width
                radius: width / 2
                color: root.themeFg
                Behavior on width { NumberAnimation { duration: 100 } }
            }
            MouseArea {
                id: sliderDrag
                anchors.fill: parent
                enabled: srow.enabled
                cursorShape: Qt.PointingHandCursor
                function valueAt(x) {
                    var t = Math.max(0, Math.min(1, (x - 6) / Math.max(1, parent.width - 12)));
                    return srow.from + t * (srow.to - srow.from);
                }
                onPressed: (mouse) => srow.moved(valueAt(mouse.x))
                onPositionChanged: (mouse) => { if (pressed) srow.moved(valueAt(mouse.x)); }
            }
        }
    }

    component ChipGrid: Flow {
        id: grid
        property var options: []
        property string current: ""
        property bool enabled: true
        signal picked(string value)
        spacing: 6
        Layout.fillWidth: true

        Repeater {
            model: grid.options
            delegate: Rectangle {
                required property var modelData
                height: 26
                width: chipText.implicitWidth + 20
                radius: 13
                color: grid.current === String(modelData.value)
                       ? cameraPanel.accentA(0.22)
                       : (chipMouse.containsMouse ? root.ink(0.071) : root.ink(0.031))
                border.width: 1
                border.color: grid.current === String(modelData.value)
                              ? cameraPanel.accentA(0.45)
                              : root.ink(0.078)
                opacity: grid.enabled ? 1 : 0.45
                Behavior on color { ColorAnimation { duration: 130 } }

                Text {
                    id: chipText
                    anchors.centerIn: parent
                    text: modelData.label !== undefined ? modelData.label : String(modelData.value)
                    color: grid.current === String(modelData.value) ? root.cFgPrimary : root.cFgSecondary
                    font.family: root.fontSans
                    font.pixelSize: 11
                    font.weight: grid.current === String(modelData.value) ? Font.DemiBold : Font.Medium
                }
                MouseArea {
                    id: chipMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    enabled: grid.enabled
                    cursorShape: Qt.PointingHandCursor
                    onClicked: grid.picked(String(modelData.value))
                }
            }
        }
    }

    component MeterBar: Item {
        id: meter
        property real level: 0
        property color tone: cameraPanel.accent
        implicitHeight: 6
        Layout.preferredHeight: 6
        Rectangle {
            anchors.fill: parent
            radius: height / 2
            color: root.ink(0.078)
        }
        Rectangle {
            height: parent.height
            radius: height / 2
            width: Math.max(0, Math.min(1, meter.level)) * parent.width
            color: meter.tone
            Behavior on width { NumberAnimation { duration: 90 } }
        }
    }

    // ═══════════════════════════════════════════════════════════════
    // Layout
    // ═══════════════════════════════════════════════════════════════
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 10

        // ── Header ───────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: 9

            Rectangle {
                width: 28; height: 28; radius: 9
                color: cameraPanel.accentA(cameraPanel.appCount > 0 ? 0.26 : 0.14)
                border.width: 1
                border.color: cameraPanel.accentA(cameraPanel.appCount > 0 ? 0.5 : 0.24)
                Text {
                    anchors.centerIn: parent
                    text: "󰄀"
                    color: cameraPanel.accent
                    font.family: root.fontMono
                    font.pixelSize: 13
                }
            }

            ColumnLayout {
                spacing: 0
                Layout.fillWidth: true
                Text {
                    text: "Camera Effects"
                    color: root.cFgPrimary
                    font.family: root.fontSans
                    font.pixelSize: 15
                    font.weight: Font.DemiBold
                }
                Text {
                    Layout.fillWidth: true
                    text: cameraPanel.statusLine()
                    color: cameraPanel.appCount > 0 ? cameraPanel.accent : root.cFgMuted
                    font.family: root.fontSans
                    font.pixelSize: 10
                    elide: Text.ElideRight
                }
            }

            // Shutter
            Rectangle {
                width: 30; height: 30; radius: 10
                color: snapMouse.containsMouse ? root.ink(0.094) : root.ink(0.039)
                border.width: 1
                border.color: root.ink(0.094)
                Text {
                    anchors.centerIn: parent
                    text: "◉"
                    color: root.cFgSecondary
                    font.pixelSize: 13
                }
                MouseArea {
                    id: snapMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: cameraPanel.snap()
                }
            }
        }

        // ── Install / setup prompts ──────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            visible: cameraPanel.svc && !cameraPanel.svc.setupBusy
                     && (!cameraPanel.svc.installed || cameraPanel.svc.deviceMissing)
            implicitHeight: 34
            radius: 10
            color: cameraPanel.accentA(0.12)
            border.width: 1
            border.color: cameraPanel.accentA(0.3)

            Text {
                anchors.left: parent.left
                anchors.leftMargin: 11
                anchors.verticalCenter: parent.verticalCenter
                text: cameraPanel.svc && cameraPanel.svc.deviceMissing ? "Virtual camera not created yet" : "Daemon not installed"
                color: root.cFgPrimary
                font.family: root.fontSans
                font.pixelSize: 11
            }

            Rectangle {
                anchors.right: parent.right
                anchors.rightMargin: 7
                anchors.verticalCenter: parent.verticalCenter
                height: 22
                width: setupBtn.implicitWidth + 16
                radius: 11
                color: cameraPanel.accentA(0.28)
                Text {
                    id: setupBtn
                    anchors.centerIn: parent
                    text: cameraPanel.svc && cameraPanel.svc.deviceMissing ? "Set up" : "Install"
                    color: root.cFgPrimary
                    font.family: root.fontSans
                    font.pixelSize: 10
                    font.weight: Font.DemiBold
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (!cameraPanel.svc) return;
                        if (!cameraPanel.svc.installed) cameraPanel.svc.install();
                        else cameraPanel.svc.runSetup("install");
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            visible: cameraPanel.svc && (cameraPanel.svc.busyText !== "" || cameraPanel.svc.setupOutput !== "")
            implicitHeight: Math.max(18, busyText.implicitHeight + 8)
            radius: 8
            color: root.ink(0.031)
            border.width: 1
            border.color: root.ink(0.071)
            Text {
                id: busyText
                anchors.fill: parent
                anchors.margins: 6
                text: cameraPanel.svc ? (cameraPanel.svc.busyText !== "" ? cameraPanel.svc.busyText : cameraPanel.svc.setupOutput) : ""
                wrapMode: Text.WordWrap
                color: root.cFgSecondary
                font.family: root.fontSans
                font.pixelSize: 10
            }
        }

        // ── Preview / mic stage ──────────────────────────────────
        // One slot, two faces: the picture on every tab but Mic, the level
        // meters on Mic. The height never changes, so switching tabs does
        // not make the rows below jump.
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: Math.round(width * 9 / 16)

        Rectangle {
            id: previewBox
            anchors.fill: parent
            radius: 14
            color: "#000000"
            border.width: 1
            border.color: root.ink(0.102)
            clip: true

            CameraPreview {
                id: preview
                anchors.fill: parent
                visible: cameraPanel.tab !== "mic"
                active: cameraPanel.visible
                path: cameraPanel.svc ? cameraPanel.svc.previewPath : ""
                mirror: cameraPanel.blocked ? false : (cameraPanel.svc ? cameraPanel.svc.previewMirror : true)
            }

            // Idle / waiting state
            Column {
                anchors.centerIn: parent
                spacing: 6
                visible: !cameraPanel.inUse || !preview.ready
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: cameraPanel.svc && cameraPanel.svc.starting ? "󰑐" : "󰄀"
                    color: root.ink(0.314)
                    font.family: root.fontMono
                    font.pixelSize: 22
                    RotationAnimation on rotation {
                        running: cameraPanel.svc && cameraPanel.svc.starting
                        loops: Animation.Infinite
                        from: 0; to: 360; duration: 1200
                    }
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: cameraPanel.svc && cameraPanel.svc.starting ? "Starting camera…"
                        : cameraPanel.connected ? "Camera idle" : "Not connected"
                    color: root.ink(0.439)
                    font.family: root.fontSans
                    font.pixelSize: 11
                }
            }

            // The gesture the daemon sees right now, and a pulse while a
            // reaction is playing.
            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 12
                visible: !!(cameraPanel.connected && cameraPanel.reactionsEnabled()
                            && cameraPanel.svc.gesture !== "" && !cameraPanel.svc.reactionsActive)
                height: 26
                width: gestureText.implicitWidth + 20
                radius: 13
                color: "#B0000000"
                border.width: 1
                border.color: cameraPanel.accentA(0.4)
                Text {
                    id: gestureText
                    anchors.centerIn: parent
                    text: cameraPanel.gestureLabel(cameraPanel.svc.gesture)
                    color: root.cFgPrimary
                    font.family: root.fontSans
                    font.pixelSize: 11
                }
            }
            Rectangle {
                anchors.fill: parent
                visible: cameraPanel.svc.reactionsActive
                color: "transparent"
                border.width: 3
                border.color: cameraPanel.accentA(0.55)
                radius: 14
                SequentialAnimation on opacity {
                    running: cameraPanel.svc.reactionsActive
                    loops: Animation.Infinite
                    NumberAnimation { from: 1.0; to: 0.25; duration: 620; easing.type: Easing.InOutSine }
                    NumberAnimation { from: 0.25; to: 1.0; duration: 620; easing.type: Easing.InOutSine }
                }
            }

            // The webcam is delivering black frames (a closed privacy cover).
            Rectangle {
                anchors.centerIn: parent
                visible: cameraPanel.svc && cameraPanel.svc.covered && !cameraPanel.blocked
                width: coveredText.implicitWidth + 26
                height: coveredText.implicitHeight + 14
                radius: 8
                color: "#99000000"
                Text {
                    id: coveredText
                    anchors.centerIn: parent
                    text: "Something may be covering the lens"
                    color: root.themeFg
                    font.family: root.fontSans
                    font.pixelSize: 11
                }
            }

            // Snapshot countdown
            Rectangle {
                anchors.fill: parent
                visible: cameraPanel.snapCount > 0
                color: "#66000000"
                Text {
                    anchors.centerIn: parent
                    text: cameraPanel.snapCount
                    color: root.themeFg
                    font.family: root.fontSans
                    font.pixelSize: 46
                    font.weight: Font.Bold
                }
            }

            // Drag to pan, wheel to zoom: the camera's own framing.
            MouseArea {
                id: panArea
                anchors.fill: parent
                enabled: cameraPanel.connected && !cameraPanel.blocked
                acceptedButtons: Qt.LeftButton
                cursorShape: pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor
                property real startX: 0
                property real startY: 0
                property real panX0: 0
                property real panY0: 0
                onPressed: (mouse) => { startX = mouse.x; startY = mouse.y; panX0 = cameraPanel.s.panX || 0; panY0 = cameraPanel.s.panY || 0; }
                onPositionChanged: (mouse) => {
                    if (!pressed || !cameraPanel.svc) return;
                    var r = cameraPanel.svc.panRange;
                    var rx = r[0] || 0, ry = r[1] || 0;
                    if (rx <= 0 && ry <= 0) return;
                    var px = rx > 0 ? Math.max(-1, Math.min(1, panX0 - (mouse.x - startX) / (rx * width))) : panX0;
                    var py = ry > 0 ? Math.max(-1, Math.min(1, panY0 - (mouse.y - startY) / (ry * height))) : panY0;
                    cameraPanel.setCam("panX", Math.round(px * 1000) / 1000);
                    cameraPanel.setCam("panY", Math.round(py * 1000) / 1000);
                }
                onWheel: (wheel) => {
                    if (!cameraPanel.svc) return;
                    var z = Math.round(Math.max(1, Math.min(4, (cameraPanel.s.zoom || 1) + (wheel.angleDelta.y > 0 ? 0.1 : -0.1))) * 10) / 10;
                    cameraPanel.setCam("zoom", z);
                }
                onDoubleClicked: {
                    cameraPanel.setCam("zoom", 1);
                    cameraPanel.setCam("panX", 0);
                    cameraPanel.setCam("panY", 0);
                }
            }
        }

        // The Mic tab shows the meters instead of the picture: the levels are
        // what the microphone half of the plugin is about.
        Rectangle {
            anchors.fill: parent
            radius: 14
            color: root.ink(0.039)
            border.width: 1
            border.color: root.ink(0.102)
            visible: cameraPanel.tab === "mic"

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 10

                Text {
                    text: cameraPanel.svc ? cameraPanel.svc.micLabel : "Microphone Effects"
                    color: root.cFgPrimary
                    font.family: root.fontSans
                    font.pixelSize: 13
                    font.weight: Font.DemiBold
                }

                Item { Layout.fillHeight: true }

                Text {
                    text: "BEFORE"
                    color: root.cFgMuted
                    font.family: root.fontSans
                    font.pixelSize: 9
                    font.letterSpacing: 1
                }
                MeterBar {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 8
                    level: cameraPanel.svc ? cameraPanel.svc.micIn : 0
                }

                Text {
                    text: "AFTER"
                    color: root.cFgMuted
                    font.family: root.fontSans
                    font.pixelSize: 9
                    font.letterSpacing: 1
                }
                MeterBar {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 8
                    level: cameraPanel.svc ? cameraPanel.svc.micOut : 0
                    tone: cameraPanel.svc && cameraPanel.svc.micMuted ? root.cDanger : cameraPanel.accent
                }

                Text {
                    Layout.fillWidth: true
                    text: cameraPanel.micFooter()
                    color: root.cFgMuted
                    font.family: root.fontSans
                    font.pixelSize: 10
                    elide: Text.ElideRight
                }
            }
        }
        }

        // ── Tab strip ────────────────────────────────────────────
        Row {
            Layout.fillWidth: true
            spacing: 4

            Repeater {
                model: cameraPanel.tabs
                delegate: Rectangle {
                    required property var modelData
                    height: 26
                    width: tabText.implicitWidth + 18
                    radius: 13
                    color: cameraPanel.tab === modelData.key ? cameraPanel.accentA(0.2) : (tabMouse.containsMouse ? root.ink(0.063) : "transparent")
                    border.width: 1
                    border.color: cameraPanel.tab === modelData.key ? cameraPanel.accentA(0.42) : root.ink(0.063)
                    Behavior on color { ColorAnimation { duration: 130 } }

                    Text {
                        id: tabText
                        anchors.centerIn: parent
                        text: modelData.label
                        color: cameraPanel.tab === modelData.key ? root.cFgPrimary : root.cFgMuted
                        font.family: root.fontSans
                        font.pixelSize: 11
                        font.weight: cameraPanel.tab === modelData.key ? Font.DemiBold : Font.Medium
                    }
                    MouseArea {
                        id: tabMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: cameraPanel.tab = modelData.key;
                    }
                }
            }

            Item { Layout.fillWidth: true }

            // A dot on the Mic tab while the microphone is muted: the one
            // state you can reach from a key binding and then forget about.
            Rectangle {
                visible: cameraPanel.svc && cameraPanel.svc.micMuted
                width: 8; height: 8; radius: 4
                color: root.cDanger
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        // ── Body ─────────────────────────────────────────────────
        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            contentWidth: availableWidth
            ScrollBar.vertical: ScrollBar {
                policy: ScrollBar.AsNeeded
                contentItem: Rectangle {
                    implicitWidth: 3
                    radius: 1.5
                    color: root.ink(0.251)
                }
            }

            ColumnLayout {
                width: cameraPanel.width - 28
                spacing: 9

                // ══════ VIDEO ══════
                ColumnLayout {
                    visible: cameraPanel.tab === "video"
                    spacing: 8
                    Layout.fillWidth: true

                    SectionLabel { text: "Presets"; Layout.fillWidth: true }
                    ChipGrid {
                        options: cameraPanel.camPresetList.map(function(p) { return { value: p.key, label: p.label } })
                        current: cameraPanel.activeCamPreset
                        onPicked: (value) => cameraPanel.applyCamPreset(value)
                    }
                    Text {
                        Layout.fillWidth: true
                        visible: cameraPanel.activeCamPreset === "custom"
                        text: "Custom — the settings no longer match a preset"
                        color: root.cFgMuted
                        font.family: root.fontSans
                        font.pixelSize: 9
                    }

                    SectionLabel { text: "Camera"; Layout.fillWidth: true }
                    ChipGrid {
                        options: cameraPanel.svc ? (cameraPanel.svc.cameras || []).map(function(c) { return { value: String(c.bus), label: cameraPanel.camLabel(c) } }) : []
                        current: cameraPanel.svc && cameraPanel.svc.camera ? String(cameraPanel.svc.camera.bus) : ""
                        onPicked: (value) => { if (cameraPanel.svc) cameraPanel.svc.selectCamera(value); }
                    }

                    // One set of effects for every webcam, or a set per
                    // webcam. The daemon keeps both; this switch picks
                    // which one the rows below edit.
                    ToggleRow {
                        visible: cameraPanel.multiCam
                        label: "Same effects on every camera"
                        checked: cameraPanel.svc ? cameraPanel.svc.sameForAll : true
                        onToggled: { if (cameraPanel.svc) cameraPanel.svc.setSameForAll(!cameraPanel.svc.sameForAll); }
                    }
                    Text {
                        Layout.fillWidth: true
                        visible: cameraPanel.multiCam && cameraPanel.svc && !cameraPanel.svc.sameForAll
                        text: "Editing " + cameraPanel.camLabel(cameraPanel.svc.camera) + " only"
                        color: cameraPanel.accent
                        font.family: root.fontSans
                        font.pixelSize: 9
                        elide: Text.ElideRight
                    }

                    ToggleRow {
                        label: "Center Stage"
                        summary: "Keeps you framed"
                        checked: !!cameraPanel.s.centerStage
                        onToggled: cameraPanel.setCam("centerStage", !cameraPanel.s.centerStage)
                    }
                    SliderRow {
                        label: "Follow"
                        value: cameraPanel.s.centerStageIntensity !== undefined ? cameraPanel.s.centerStageIntensity : 0.6
                        enabled: !!cameraPanel.s.centerStage
                        onMoved: (v) => cameraPanel.setCam("centerStageIntensity", v)
                    }

                    SliderRow {
                        label: "Zoom"
                        value: cameraPanel.s.zoom !== undefined ? cameraPanel.s.zoom : 1
                        from: 1
                        to: 4
                        suffix: "×"
                        onMoved: (v) => cameraPanel.setCam("zoom", v)
                    }

                    SectionLabel { text: "Fit"; Layout.fillWidth: true }
                    ChipGrid {
                        options: [{ value: "cover", label: "Cover" }, { value: "contain", label: "Contain" }, { value: "stretch", label: "Stretch" }]
                        current: cameraPanel.s.fit || "cover"
                        onPicked: (value) => cameraPanel.setCam("fit", value)
                    }

                    SectionLabel { text: "Rotate"; Layout.fillWidth: true }
                    ChipGrid {
                        options: [{ value: "0", label: "Off" }, { value: "90", label: "90°" }, { value: "180", label: "180°" }, { value: "270", label: "270°" }]
                        current: String(cameraPanel.s.rotate || 0)
                        onPicked: (value) => cameraPanel.setCam("rotate", parseInt(value))
                    }

                    ToggleRow {
                        label: "Mirror preview"
                        summary: "Self-view only"
                        checked: cameraPanel.svc ? cameraPanel.svc.previewMirror : true
                        onToggled: cameraPanel.setCam("previewMirror", !cameraPanel.svc.previewMirror)
                    }
                    ToggleRow {
                        label: "Mirror output"
                        summary: "What apps see"
                        checked: !!cameraPanel.s.mirror
                        onToggled: cameraPanel.setCam("mirror", !cameraPanel.s.mirror)
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 30
                        radius: 9
                        color: resetMouse.containsMouse ? root.ink(0.078) : root.ink(0.031)
                        border.width: 1
                        border.color: root.ink(0.078)
                        Text {
                            anchors.centerIn: parent
                            text: "Reset this camera"
                            color: root.cFgSecondary
                            font.family: root.fontSans
                            font.pixelSize: 11
                        }
                        MouseArea {
                            id: resetMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: { if (cameraPanel.svc) cameraPanel.svc.reset(); }
                        }
                    }

                    // ── Output size ────────────────────────────────
                    // What apps get. Bigger than the camera's own capture
                    // size means the daemon upscales in real time; the
                    // daemon is restarted to pick the new size up.
                    SectionLabel { text: "Output size"; Layout.fillWidth: true }
                    ChipGrid {
                        options: cameraPanel.outputSizes.map(function(o) { return { value: o.value, label: o.label } })
                        current: cameraPanel.currentOutput
                        enabled: !cameraPanel.svc || !cameraPanel.svc.setupBusy
                        onPicked: (value) => {
                            var picked = cameraPanel.outputSizes.filter(function(o) { return o.value === value; })[0];
                            if (!picked || !cameraPanel.svc) return;
                            cameraPanel.svc.applyOutput(picked.w, picked.h, cameraPanel.currentFps);
                        }
                    }
                    ChipGrid {
                        options: [{ value: "15", label: "15 fps" }, { value: "24", label: "24 fps" },
                                   { value: "30", label: "30 fps" }, { value: "60", label: "60 fps" }]
                        current: String(cameraPanel.currentFps)
                        enabled: !cameraPanel.svc || !cameraPanel.svc.setupBusy
                        onPicked: (value) => {
                            if (!cameraPanel.svc || !cameraPanel.output) return;
                            var w = cameraPanel.svc.output.width || 1280;
                            var h = cameraPanel.svc.output.height || 720;
                            cameraPanel.svc.applyOutput(w, h, parseInt(value));
                        }
                    }
                    Text {
                        Layout.fillWidth: true
                        visible: cameraPanel.upscaling
                        text: "Upscaling from " + (cameraPanel.svc && cameraPanel.svc.state && cameraPanel.svc.state.capture
                            ? cameraPanel.svc.state.capture.width + "×" + cameraPanel.svc.state.capture.height : "the camera")
                            + " in real time"
                        color: cameraPanel.accent
                        font.family: root.fontSans
                        font.pixelSize: 9
                        elide: Text.ElideRight
                    }
                }

                // ══════ LOOK ══════
                ColumnLayout {
                    visible: cameraPanel.tab === "look"
                    spacing: 8
                    Layout.fillWidth: true

                    ToggleRow {
                        label: "Portrait"
                        summary: "Blurs the background"
                        checked: !!cameraPanel.s.portrait
                        strong: true
                        onToggled: cameraPanel.setCam("portrait", !cameraPanel.s.portrait)
                    }
                    SliderRow {
                        label: "Strength"
                        value: cameraPanel.s.portraitIntensity !== undefined ? cameraPanel.s.portraitIntensity : 0.6
                        enabled: !!cameraPanel.s.portrait
                        onMoved: (v) => cameraPanel.setCam("portraitIntensity", v)
                    }

                    ToggleRow {
                        label: "Studio Light"
                        summary: "Brightens your face"
                        checked: !!cameraPanel.s.studioLight
                        strong: true
                        onToggled: cameraPanel.setCam("studioLight", !cameraPanel.s.studioLight)
                    }
                    SliderRow {
                        label: "Strength"
                        value: cameraPanel.s.studioLightIntensity !== undefined ? cameraPanel.s.studioLightIntensity : 0.6
                        enabled: !!cameraPanel.s.studioLight
                        onMoved: (v) => cameraPanel.setCam("studioLightIntensity", v)
                    }

                    SectionLabel { text: "Background"; Layout.fillWidth: true }
                    ChipGrid {
                        options: [{ value: "none", label: "None" }, { value: "color", label: "Colour" },
                                   { value: "image", label: "Image" }, { value: "video", label: "Video" }]
                        current: cameraPanel.s.background || "none"
                        onPicked: (value) => cameraPanel.setCam("background", value)
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        visible: cameraPanel.s.background === "color" || cameraPanel.s.background === "image" || cameraPanel.s.background === "video"
                        spacing: 8

                        Rectangle {
                            width: 30; height: 24; radius: 8
                            color: cameraPanel.s.backgroundColor || root.themeSurface
                            border.width: 1
                            border.color: root.ink(0.125)
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: colorDialog.open()
                            }
                        }
                        Text {
                            Layout.fillWidth: true
                            text: cameraPanel.s.background === "color" ? (cameraPanel.s.backgroundColor || "")
                                : cameraPanel.s.background === "image" ? (cameraPanel.s.backgroundImage || "No image picked")
                                : (cameraPanel.s.backgroundVideo || "No video picked")
                            color: root.cFgMuted
                            font.family: root.fontSans
                            font.pixelSize: 10
                            elide: Text.ElideMiddle
                        }
                        Rectangle {
                            height: 24
                            width: pickText.implicitWidth + 16
                            radius: 12
                            color: root.ink(0.055)
                            border.width: 1
                            border.color: root.ink(0.094)
                            Text {
                                id: pickText
                                anchors.centerIn: parent
                                text: cameraPanel.s.background === "color" ? "Pick" : "Browse…"
                                color: root.cFgSecondary
                                font.family: root.fontSans
                                font.pixelSize: 10
                            }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (cameraPanel.s.background === "color") colorDialog.open();
                                    else if (cameraPanel.s.background === "image") imageDialog.open();
                                    else videoDialog.open();
                                }
                            }
                        }
                    }

                    SectionLabel { text: "Filter"; Layout.fillWidth: true }
                    ChipGrid {
                        options: [{ value: "none", label: "None" }, { value: "mono", label: "Mono" }, { value: "sepia", label: "Sepia" },
                                   { value: "warm", label: "Warm" }, { value: "cool", label: "Cool" }, { value: "vivid", label: "Vivid" },
                                   { value: "soft", label: "Soft" }, { value: "sharpen", label: "Sharpen" }, { value: "vintage", label: "Vintage" }]
                        current: cameraPanel.s.filter || "none"
                        onPicked: (value) => cameraPanel.setCam("filter", value)
                    }
                }

                // ══════ FUN ══════
                ColumnLayout {
                    visible: cameraPanel.tab === "fun"
                    spacing: 8
                    Layout.fillWidth: true

                    SectionLabel { text: "Effect"; Layout.fillWidth: true }
                    ChipGrid {
                        options: [{ value: "none", label: "None" }, { value: "sunglasses", label: "Sunglasses" }, { value: "glasses", label: "Glasses" },
                                   { value: "mask", label: "Mask" }, { value: "tophat", label: "Top hat" }, { value: "crown", label: "Crown" },
                                   { value: "cat", label: "Cat" }, { value: "halo", label: "Halo" }, { value: "flowers", label: "Flowers" },
                                   { value: "blur", label: "Blur" }, { value: "pixelate", label: "Pixelate" }]
                        current: cameraPanel.s.fun || "none"
                        onPicked: (value) => cameraPanel.setCam("fun", value)
                    }

                    SectionLabel { text: "Ambience"; Layout.fillWidth: true }
                    ChipGrid {
                        options: [{ value: "none", label: "None" }, { value: "rain", label: "Rain" }, { value: "snow", label: "Snow" },
                                   { value: "sparkles", label: "Sparkles" }, { value: "confetti", label: "Confetti" }, { value: "bubbles", label: "Bubbles" }]
                        current: cameraPanel.s.ambience || "none"
                        onPicked: (value) => cameraPanel.setCam("ambience", value)
                    }

                    ToggleRow {
                        label: "React to hand gestures"
                        summary: "Hold a sign to play one"
                        checked: cameraPanel.reactionsEnabled()
                        strong: true
                        onToggled: cameraPanel.setCam("reactions", !cameraPanel.reactionsEnabled())
                    }

                    SectionLabel { text: "Reactions"; Layout.fillWidth: true }
                    Flow {
                        Layout.fillWidth: true
                        spacing: 6
                        Repeater {
                            model: [
                                { key: "hearts", label: "Hearts" }, { key: "thumbsup", label: "Thumbs up" },
                                { key: "thumbsdown", label: "Thumbs down" }, { key: "balloons", label: "Balloons" },
                                { key: "confetti", label: "Confetti" }, { key: "fireworks", label: "Fireworks" },
                                { key: "rain", label: "Rain" }, { key: "lasers", label: "Lasers" }
                            ]
                            delegate: Rectangle {
                                required property var modelData
                                height: 28
                                width: reactionText.implicitWidth + 20
                                radius: 14
                                color: reactionMouse.containsMouse ? cameraPanel.accentA(0.24) : root.ink(0.031)
                                border.width: 1
                                border.color: reactionMouse.containsMouse ? cameraPanel.accentA(0.42) : root.ink(0.078)
                                Text {
                                    id: reactionText
                                    anchors.centerIn: parent
                                    text: modelData.label
                                    color: root.cFgSecondary
                                    font.family: root.fontSans
                                    font.pixelSize: 11
                                }
                                MouseArea {
                                    id: reactionMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: { if (cameraPanel.svc) cameraPanel.svc.react(modelData.key); }
                                }
                            }
                        }
                    }
                }

                // ══════ MIC ══════
                ColumnLayout {
                    visible: cameraPanel.tab === "mic"
                    spacing: 8
                    Layout.fillWidth: true

                    SectionLabel { text: "Microphone"; Layout.fillWidth: true }
                    ChipGrid {
                        options: [{ value: "", label: "System default" }].concat(
                            cameraPanel.svc ? (cameraPanel.svc.micSources || []).map(function(c) { return { value: String(c.name), label: cameraPanel.micName(c) } }) : [])
                        current: cameraPanel.svc ? String(cameraPanel.svc.micWanted || "") : ""
                        onPicked: (value) => { if (cameraPanel.svc) cameraPanel.svc.selectMic(value); }
                    }

                    ToggleRow {
                        label: "Mute microphone"
                        summary: "Apps hear silence"
                        checked: cameraPanel.svc ? cameraPanel.svc.micMuted : false
                        onToggled: { if (cameraPanel.svc) cameraPanel.svc.setMicMuted(!cameraPanel.svc.micMuted); }
                    }
                    ToggleRow {
                        label: "Listen to yourself"
                        summary: "Through your speakers"
                        checked: cameraPanel.svc ? cameraPanel.svc.micListen : false
                        onToggled: { if (cameraPanel.svc) cameraPanel.svc.setMicListen(!cameraPanel.svc.micListen); }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        SliderRow {
                            Layout.fillWidth: true
                            label: "Volume"
                            value: cameraPanel.m.volume !== undefined ? cameraPanel.m.volume : 0.5
                            onMoved: (v) => cameraPanel.setMicSetting("volume", v)
                        }
                        Rectangle {
                            height: 24
                            width: autoText.implicitWidth + 16
                            radius: 12
                            color: cameraPanel.autoGainRunning ? cameraPanel.accentA(0.24) : root.ink(0.039)
                            border.width: 1
                            border.color: cameraPanel.autoGainRunning ? cameraPanel.accentA(0.4) : root.ink(0.078)
                            Text {
                                id: autoText
                                anchors.centerIn: parent
                                text: cameraPanel.autoGainRunning ? "Listening…" : "Auto"
                                color: root.cFgSecondary
                                font.family: root.fontSans
                                font.pixelSize: 10
                            }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: cameraPanel.startAutoGain()
                            }
                        }
                    }
                    Text {
                        Layout.fillWidth: true
                        visible: cameraPanel.autoGainNote !== ""
                        text: cameraPanel.autoGainNote
                        color: root.cFgMuted
                        font.family: root.fontSans
                        font.pixelSize: 10
                    }

                    SectionLabel { text: "Presets"; Layout.fillWidth: true }
                    ChipGrid {
                        options: [{ value: "clean", label: "Clean" }, { value: "voice", label: "Voice" },
                                   { value: "meeting", label: "Meeting" }, { value: "podcast", label: "Podcast" }]
                        current: cameraPanel.activePreset
                        onPicked: (value) => cameraPanel.applyPreset(value)
                    }

                    SectionLabel { text: "Cleanup"; Layout.fillWidth: true }
                    ToggleRow {
                        label: "Voice isolation"
                        checked: !!cameraPanel.m.voiceIsolation
                        onToggled: cameraPanel.setMicSetting("voiceIsolation", !cameraPanel.m.voiceIsolation)
                    }
                    SliderRow {
                        label: "Strength"
                        value: cameraPanel.m.voiceIsolationIntensity !== undefined ? cameraPanel.m.voiceIsolationIntensity : 0.6
                        enabled: !!cameraPanel.m.voiceIsolation
                        onMoved: (v) => cameraPanel.setMicSetting("voiceIsolationIntensity", v)
                    }
                    ToggleRow {
                        label: "Noise gate"
                        checked: !!cameraPanel.m.noiseGate
                        onToggled: cameraPanel.setMicSetting("noiseGate", !cameraPanel.m.noiseGate)
                    }
                    SliderRow {
                        label: "Strength"
                        value: cameraPanel.m.noiseGateIntensity !== undefined ? cameraPanel.m.noiseGateIntensity : 0.55
                        enabled: !!cameraPanel.m.noiseGate
                        onMoved: (v) => cameraPanel.setMicSetting("noiseGateIntensity", v)
                    }
                    ToggleRow {
                        label: "Auto level"
                        checked: !!cameraPanel.m.autoLevel
                        onToggled: cameraPanel.setMicSetting("autoLevel", !cameraPanel.m.autoLevel)
                    }
                    ToggleRow {
                        label: "De-esser"
                        checked: !!cameraPanel.m.deEsser
                        onToggled: cameraPanel.setMicSetting("deEsser", !cameraPanel.m.deEsser)
                    }
                    ToggleRow {
                        label: "Rumble filter"
                        checked: cameraPanel.m.highPass !== false
                        onToggled: cameraPanel.setMicSetting("highPass", cameraPanel.m.highPass === false)
                    }
                    ToggleRow {
                        label: "Hum filter"
                        checked: !!cameraPanel.m.humFilter
                        onToggled: cameraPanel.setMicSetting("humFilter", !cameraPanel.m.humFilter)
                    }

                    SectionLabel { text: "Character"; Layout.fillWidth: true }
                    ChipGrid {
                        options: [{ value: "none", label: "Tone: None" }, { value: "warm", label: "Warm" }, { value: "bright", label: "Bright" },
                                   { value: "clarity", label: "Clarity" }, { value: "podcast", label: "Podcast" }, { value: "telephone", label: "Telephone" }]
                        current: cameraPanel.m.tone || "none"
                        onPicked: (value) => cameraPanel.setMicSetting("tone", value)
                    }
                    ChipGrid {
                        options: [{ value: "none", label: "Voice: None" }, { value: "deep", label: "Deep" }, { value: "chipmunk", label: "Chipmunk" },
                                   { value: "robot", label: "Robot" }, { value: "alien", label: "Alien" }, { value: "megaphone", label: "Megaphone" },
                                   { value: "monster", label: "Monster" }]
                        current: cameraPanel.m.voice || "none"
                        onPicked: (value) => cameraPanel.setMicSetting("voice", value)
                    }
                    ChipGrid {
                        options: [{ value: "none", label: "Space: None" }, { value: "room", label: "Room" }, { value: "hall", label: "Hall" },
                                   { value: "cathedral", label: "Cathedral" }, { value: "echo", label: "Echo" }, { value: "underwater", label: "Underwater" }]
                        current: cameraPanel.m.space || "none"
                        onPicked: (value) => cameraPanel.setMicSetting("space", value)
                    }

                    ToggleRow {
                        label: "Hide raw microphones"
                        summary: "Apps only see Microphone Effects"
                        checked: cameraPanel.svc ? cameraPanel.svc.micHideAll : false
                        onToggled: { if (cameraPanel.svc) cameraPanel.svc.runMicHide("all", !cameraPanel.svc.micHideAll); }
                    }
                }

                // ══════ PRIVACY ══════
                ColumnLayout {
                    visible: cameraPanel.tab === "privacy"
                    spacing: 8
                    Layout.fillWidth: true

                    ToggleRow {
                        label: "Block camera"
                        summary: "Apps get a card instead of you"
                        checked: cameraPanel.blocked
                        strong: true
                        onToggled: cameraPanel.setCam("block", !cameraPanel.blocked)
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        visible: cameraPanel.blocked
                        spacing: 8

                        SectionLabel { text: "Placeholder"; Layout.fillWidth: true }
                        ChipGrid {
                            options: [{ value: "", label: "Card" }, { value: "image", label: "Image" }, { value: "video", label: "Video" }]
                            current: cameraPanel.svc && cameraPanel.svc.blockSource ? "file" : ""
                            onPicked: (value) => {
                                if (value === "") { cameraPanel.setCam("blockSource", ""); return; }
                                if (value === "image") blockImageDialog.open();
                                else blockVideoDialog.open();
                            }
                        }
                        SliderRow {
                            label: "Zoom"
                            value: cameraPanel.svc && cameraPanel.svc.blockZoom !== undefined ? cameraPanel.svc.blockZoom : 1
                            from: 1
                            to: 4
                            suffix: "×"
                            onMoved: (v) => cameraPanel.setCam("blockZoom", v)
                        }
                        ChipGrid {
                            options: [{ value: "cover", label: "Cover" }, { value: "contain", label: "Contain" }, { value: "stretch", label: "Stretch" }]
                            current: cameraPanel.svc ? cameraPanel.svc.blockFit : "cover"
                            onPicked: (value) => cameraPanel.setCam("blockFit", value)
                        }
                    }

                    ToggleRow {
                        label: "Hide raw camera"
                        summary: "Apps only see Camera Effects"
                        checked: cameraPanel.svc ? cameraPanel.svc.hideRaw : false
                        onToggled: { if (cameraPanel.svc) cameraPanel.svc.runSetup("hide-all", !cameraPanel.svc.hideRaw); }
                    }

                    Text {
                        Layout.fillWidth: true
                        text: "Hiding the raw camera changes udev rules, so the system asks for your password. It is a courtesy boundary, not protection from malware."
                        wrapMode: Text.WordWrap
                        color: root.cFgMuted
                        font.family: root.fontSans
                        font.pixelSize: 10
                    }
                }
            }
        }

        // ── Footer ───────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Text {
                Layout.fillWidth: true
                text: cameraPanel.footerLine()
                color: root.cFgMuted
                font.family: root.fontSans
                font.pixelSize: 10
                elide: Text.ElideRight
            }

            Text {
                visible: cameraPanel.svc && cameraPanel.svc.loopback !== ""
                text: cameraPanel.svc ? cameraPanel.svc.loopback : ""
                color: root.cFgMuted
                font.family: root.fontMono
                font.pixelSize: 9
            }
        }
    }

    // ── Keyboard ───────────────────────────────────────────────
    FocusScope {
        anchors.fill: parent
        focus: cameraPanel.visible
        Keys.onEscapePressed: {
            root.displayState = 0;
            root.updateState();
        }
        Keys.onPressed: (event) => {
            // Digits pick the tabs, the way the original panel's key catcher
            // did: 1 Video · 2 Look · 3 Fun · 4 Mic · 5 Privacy.
            var order = ["video", "look", "fun", "mic", "privacy"];
            var idx = event.key - Qt.Key_1;
            if (idx >= 0 && idx < order.length) {
                cameraPanel.tab = order[idx];
                event.accepted = true;
            }
        }
    }

    // ── Native pickers (xdg portal) ────────────────────────────
    ColorDialog {
        id: colorDialog
        title: "Background colour"
        onAccepted: cameraPanel.setCam("backgroundColor", selectedColor.toString())
    }
    FileDialog {
        id: imageDialog
        title: "Background image"
        nameFilters: ["Images (*.png *.jpg *.jpeg *.webp *.bmp)", "All files (*)"]
        onAccepted: cameraPanel.setCam("backgroundImage", selectedFile.toString())
    }

    FileDialog {
        id: videoDialog
        title: "Background video"
        nameFilters: ["Videos (*.mp4 *.webm *.mkv *.mov)", "All files (*)"]
        onAccepted: cameraPanel.setCam("backgroundVideo", selectedFile.toString())
    }

    FileDialog {
        id: blockImageDialog
        title: "Placeholder image"
        nameFilters: ["Images (*.png *.jpg *.jpeg *.webp *.bmp)", "All files (*)"]
        onAccepted: cameraPanel.setCam("blockSource", selectedFile.toString())
    }

    FileDialog {
        id: blockVideoDialog
        title: "Placeholder video"
        nameFilters: ["Videos (*.mp4 *.webm *.mkv *.mov)", "All files (*)"]
        onAccepted: cameraPanel.setCam("blockSource", selectedFile.toString())
    }
}
