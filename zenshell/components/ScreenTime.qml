import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

// Screen-time panel.
//
// Design thesis: a quiet daily report card. One dominant number, one honest
// seven-day trend, a day-rhythm strip, then the app ledger. There are no
// nested cards and no rainbow palette: the theme accent carries "now /
// selected / rank" and everything else is monochrome data ink on the island
// glass. Colour is never the only encoding — every series is labelled.
Item {
    id: screenTimeRoot
    anchors.fill: parent
    visible: opacity > 0
    property bool entered: false
    opacity: (root.displayState === 25 && entered) ? 1 : 0
    transform: Translate { y: (1 - screenTimeRoot.opacity) * 6 }

    Behavior on opacity {
        NumberAnimation {
            duration: root.displayState === 25 ? root.motionPanel : root.motionExit
            easing.type: Easing.OutCubic
        }
    }

    // ---------------------------------------------------------------- state --
    property var usageData: ({ "total": 0, "apps": {}, "hours": [] })
    property bool dayHasData: false
    property var appList: []
    property var barSegments: []
    property var weekData: []          // 7 x { date, total, hasData, loaded, label, offset }
    property string viewDate: Qt.formatDate(new Date(), "yyyy-MM-dd")
    property int viewOffset: 0         // 0 = today, -1 = yesterday…
    property bool weekLoading: false
    property string lastUpdated: ""
    // Maps desktop-entry base names (chrome-<id>-Default) to display names.
    property var appNames: ({})

    readonly property bool isToday: viewOffset === 0

    // -------------------------------------------------------------- helpers --
    function dateStr(offset) {
        var d = new Date();
        d.setDate(d.getDate() + offset);
        return Qt.formatDate(d, "yyyy-MM-dd");
    }

    function dateLabel() {
        if (viewOffset === 0) return "Today";
        if (viewOffset === -1) return "Yesterday";
        var d = new Date();
        d.setDate(d.getDate() + viewOffset);
        return Qt.formatDate(d, "ddd, d MMM");
    }

    function formatTime(sec) {
        sec = Math.max(0, Math.floor(sec || 0));
        var h = Math.floor(sec / 3600);
        var m = Math.floor((sec % 3600) / 60);
        if (h > 0) return m > 0 ? h + "h " + m + "m" : h + "h";
        if (m > 0) return m + "m";
        return sec + "s";
    }

    function prettyName(cls) {
        if (!cls) return "Unknown";
        if (appNames && appNames[cls]) return appNames[cls];
        // Chromium-family PWA whose desktop entry is missing.
        if (cls.indexOf("chrome-") === 0) return "Web App";
        var s = cls;
        // shorten reverse-dns (com.gabm.satty -> satty)
        if (s.indexOf(".") >= 0) {
            var parts = s.split(".");
            s = parts[parts.length - 1];
        }
        s = s.replace(/[-_]/g, " ");
        s = s.replace(/\b\w/g, function (c) { return c.toUpperCase(); });
        return s;
    }

    // Monochrome accent ramp. Rank is also carried by order, bar length and
    // the printed duration, so the colour steps are reinforcement, not the
    // only encoding.
    function appColor(i) {
        var steps = [1.0, 0.72, 0.54, 0.42, 0.32, 0.23];
        var a = steps[Math.min(Math.max(i, 0), steps.length - 1)];
        return Qt.rgba(root.cAccent.r, root.cAccent.g, root.cAccent.b, a);
    }

    function appFraction(sec) {
        var top = appList.length > 0 ? appList[0].seconds : 0;
        return top > 0 ? Math.min(1, sec / top) : 0;
    }

    function hourValue(i) {
        var h = usageData.hours || [];
        return h[i] || 0;
    }

    function hourMax() {
        var h = usageData.hours || [];
        var m = 0;
        for (var i = 0; i < h.length; i++)
            if (h[i] > m) m = h[i];
        return m > 0 ? m : 1;
    }

    function weekMax() {
        var m = 0;
        for (var i = 0; i < weekData.length; i++)
            if (weekData[i].hasData && weekData[i].total > m) m = weekData[i].total;
        return m > 0 ? m : 1;
    }

    function activeHours() {
        var h = usageData.hours || [];
        var n = 0;
        for (var i = 0; i < h.length; i++)
            if (h[i] > 30) n++;
        return n;
    }

    function busiestLabel() {
        var h = usageData.hours || [];
        var max = 0, idx = -1;
        for (var i = 0; i < h.length; i++) {
            if (h[i] > max) { max = h[i]; idx = i; }
        }
        if (idx < 0 || max <= 0) return "—";
        var hr = idx % 12;
        if (hr === 0) hr = 12;
        return hr + (idx < 12 ? "am" : "pm");
    }

    function statsLabel() {
        if (!dayHasData) return "No data recorded for this day";
        var n = appList.length;
        var h = activeHours();
        var s = n + (n === 1 ? " app" : " apps");
        if (h > 0) s += " · " + h + (h === 1 ? " active hour" : " active hours");
        return s;
    }

    function deltaText() {
        if (!dayHasData) return "";
        var idx = 6 + viewOffset;
        if (idx <= 0) return "";
        var prev = weekData[idx - 1];
        if (!prev || !prev.hasData) return "no comparison for the previous day";
        var diff = (usageData.total || 0) - prev.total;
        var rel = viewOffset === 0 ? "yesterday" : "the day before";
        if (Math.abs(diff) < 60) return "about the same as " + rel;
        return (diff > 0 ? "+" : "−") + formatTime(Math.abs(diff)) + " vs " + rel;
    }

    function avgWeekLabel() {
        var sum = 0, n = 0;
        for (var i = 0; i < weekData.length; i++) {
            if (weekData[i].hasData) { sum += weekData[i].total; n++; }
        }
        if (n === 0) return "no history yet";
        return "avg " + formatTime(sum / n);
    }

    function rebuild() {
        var apps = usageData.apps || {};
        var total = usageData.total || 0;
        var arr = [];
        for (var k in apps) {
            var sec = apps[k] || 0;
            if (sec <= 0) continue;
            arr.push({ id: k, name: prettyName(k), seconds: sec });
        }
        arr.sort(function (a, b) { return b.seconds - a.seconds; });
        appList = arr;

        var segs = [];
        var other = 0;
        for (var i = 0; i < arr.length; i++) {
            if (i < 5) segs.push({ name: arr[i].name, seconds: arr[i].seconds, slot: i });
            else other += arr[i].seconds;
        }
        if (other > 0) segs.push({ name: "Other", seconds: other, slot: 5 });
        barSegments = segs;
    }

    function emptyData() {
        return { "total": 0, "apps": {}, "hours": [] };
    }

    function changeDay(step) {
        var next = viewOffset + step;
        if (next > 0 || next < -365) return;
        loadDate(next);
    }

    function loadDate(offset) {
        if (offset > 0) offset = 0;
        if (offset < -365) offset = -365;
        viewOffset = offset;
        viewDate = dateStr(offset);
        dayHasData = false;
        usageData = emptyData();
        rebuild();
        lastUpdated = "";
        fetchDay(viewDate);
    }

    // Read the day file through a Process rather than a watched FileView:
    // FileView only emits onTextChanged when the text actually differs, so
    // reopening the panel (which resets the view to empty first) would keep
    // the empty state until the file changed. A Process always answers.
    function fetchDay(date) {
        if (dayProc.running) dayProc.running = false;
        dayProc.wantDate = date;
        dayProc.command = ["bash", "-c",
            "f=\"$HOME/.local/share/screen-time/" + date + ".json\"; " +
            "[ -f \"$f\" ] && cat \"$f\" || printf '__NODATA__'"];
        dayProc.running = true;
    }

    function applyDayText(raw) {
        if (!raw || raw === "__NODATA__") {
            usageData = emptyData();
            dayHasData = false;
            rebuild();
            return;
        }
        try {
            var parsed = JSON.parse(raw);
            // A restarted Process can still deliver the previous day's
            // output; ignore anything that does not match the viewed date.
            if (parsed.date && parsed.date !== viewDate) return;
            usageData = parsed;
            dayHasData = true;
            lastUpdated = Qt.formatTime(new Date(), "HH:mm");
            rebuild();
            if (isToday)
                updateWeekToday(parsed.total || 0);
        } catch (e) {
            usageData = emptyData();
            dayHasData = false;
            rebuild();
        }
    }

    function loadWeek() {
        if (weekProc.running) {
            weekProc.running = false;
        }
        weekProc.running = true;
    }

    // One pass over the seven day files. Missing days are reported as "|‑"
    // rather than firing seven failing FileViews, which keeps the log clean.
    function weekDataFromText(txt) {
        var lines = String(txt || "").trim().split("\n");
        var arr = [];
        for (var i = 0; i < lines.length; i++) {
            var parts = lines[i].split("|");
            if (parts.length < 2) continue;
            var has = parts[1] !== "-";
            var d = new Date(parts[0] + "T12:00:00");
            arr.push({
                date: parts[0],
                total: has ? (parseInt(parts[1], 10) || 0) : 0,
                hasData: has,
                label: Qt.formatDate(d, "ddd"),
                offset: i - (lines.length - 1)
            });
        }
        if (arr.length === 7)
            weekData = arr;
    }

    function updateWeekToday(total) {
        if (weekData.length !== 7) return;
        var arr = weekData.slice();
        arr[6] = {
            date: arr[6].date,
            total: total || 0,
            hasData: true,
            label: arr[6].label,
            offset: 0
        };
        weekData = arr;
    }

    // ---------------------------------------------------------------- input --
    // Keyboard lives in its own FocusScope, like the other island panels, so
    // arrows and Escape work without stealing focus from the pointer.
    FocusScope {
        anchors.fill: parent
        focus: root.displayState === 25

        Keys.onPressed: function (event) {
            if (event.key === Qt.Key_Escape) {
                root.displayState = 0;
                root.updateState();
                event.accepted = true;
            } else if (event.key === Qt.Key_Left) {
                changeDay(-1);
                event.accepted = true;
            } else if (event.key === Qt.Key_Right) {
                changeDay(1);
                event.accepted = true;
            } else if (event.key === Qt.Key_T) {
                loadDate(0);
                event.accepted = true;
            }
        }
    }

    // ---------------------------------------------------------------- files --
    Process {
        id: dayProc
        property string wantDate: ""
        stdout: StdioCollector {
            onStreamFinished: {
                if (dayProc.wantDate !== screenTimeRoot.viewDate) return;
                screenTimeRoot.applyDayText(String(text || "").trim());
            }
        }
    }

    Process {
        id: weekProc
        command: ["python3", "-c",
            "import json,os,datetime\n" +
            "base=os.path.expanduser('~/.local/share/screen-time')\n" +
            "for i in range(6,-1,-1):\n" +
            "    d=(datetime.date.today()-datetime.timedelta(days=i)).isoformat()\n" +
            "    p=os.path.join(base,d+'.json')\n" +
            "    try:\n" +
            "        t=int(json.load(open(p)).get('total',0)); print(f'{d}|{t}')\n" +
            "    except Exception:\n" +
            "        print(f'{d}|-')"]
        stdout: StdioCollector {
            onStreamFinished: screenTimeRoot.weekDataFromText(text)
        }
    }

    // Resolve installed .desktop entries once, so chromium-family PWA classes
    // such as chrome-<id>-Default show as "YouTube" instead of a raw ID.
    Process {
        id: appNamesProc
        running: true
        command: ["bash", "-c",
            "for f in /usr/share/applications/*.desktop \"$HOME\"/.local/share/applications/*.desktop; do " +
            "[ -f \"$f\" ] || continue; " +
            "n=$(grep -m1 '^Name=' \"$f\" | cut -d= -f2-); " +
            "[ -n \"$n\" ] && printf '%s\\t%s\\n' \"$(basename \"$f\" .desktop)\" \"$n\"; " +
            "done"]
        stdout: StdioCollector {
            onStreamFinished: {
                var map = {};
                var lines = text.split("\n");
                for (var i = 0; i < lines.length; i++) {
                    var p = lines[i].split("\t");
                    if (p.length >= 2 && p[0] && p[1]) map[p[0]] = p[1];
                }
                screenTimeRoot.appNames = map;
                screenTimeRoot.rebuild();
            }
        }
    }

    // Load when the island enters the screen-time state. Watching
    // `displayState` is reliable; `visible` here is driven by an opacity
    // animation and can be missed on a fast close/reopen.
    Component.onCompleted: {
        if (root.displayState === 25) {
            loadDate(0);
            loadWeek();
        }
    }

    Connections {
        target: root
        function onDisplayStateChanged() {
            if (root.displayState !== 25) return;
            loadDate(0);
            loadWeek();
        }
    }

    Timer {
        interval: 30000
        running: root.displayState === 25
        repeat: true
        onTriggered: {
            if (screenTimeRoot.isToday) {
                screenTimeRoot.fetchDay(screenTimeRoot.viewDate);
                screenTimeRoot.loadWeek();
            }
        }
    }

    // ------------------------------------------------------------------ ui --
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: root.s5
        spacing: 0

        // ---- header --------------------------------------------------------
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 26
            spacing: root.s3

            Rectangle {
                Layout.preferredWidth: 3
                Layout.preferredHeight: 12
                radius: 1.5
                color: root.cAccent
            }
            Text {
                text: "Screen time"
                color: root.cFgPrimary
                font.family: root.fontSans
                font.pixelSize: 13
                font.weight: Font.DemiBold
            }
            Text {
                text: "·"
                color: root.cFgMuted
                font.family: root.fontSans
                font.pixelSize: 12
            }
            Text {
                text: screenTimeRoot.dateLabel()
                color: root.cFgMuted
                font.family: root.fontSans
                font.pixelSize: 11
            }

            Item { Layout.fillWidth: true }

            // previous day
            Rectangle {
                Layout.preferredWidth: 24
                Layout.preferredHeight: 24
                radius: 6
                color: prevMa.containsMouse ? root.uiCardHover : "transparent"
                scale: prevMa.pressed ? 0.94 : 1
                Behavior on color { ColorAnimation { duration: 120 } }
                Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                Text {
                    anchors.centerIn: parent
                    text: "‹"
                    color: root.cFgSecondary
                    font.family: root.fontSans
                    font.pixelSize: 16
                    font.weight: Font.Bold
                }
                MouseArea {
                    id: prevMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: screenTimeRoot.changeDay(-1)
                }
            }

            // jump back to today (only when browsing history)
            Rectangle {
                visible: !screenTimeRoot.isToday
                Layout.preferredWidth: 42
                Layout.preferredHeight: 24
                radius: 6
                color: todayMa.containsMouse ? root.uiCardHover : "transparent"
                scale: todayMa.pressed ? 0.94 : 1
                Behavior on color { ColorAnimation { duration: 120 } }
                Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                Text {
                    anchors.centerIn: parent
                    text: "Today"
                    color: root.cAccent
                    font.family: root.fontSans
                    font.pixelSize: 10
                    font.weight: Font.DemiBold
                }
                MouseArea {
                    id: todayMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: screenTimeRoot.loadDate(0)
                }
            }

            // next day
            Rectangle {
                Layout.preferredWidth: 24
                Layout.preferredHeight: 24
                radius: 6
                color: screenTimeRoot.isToday ? "transparent"
                       : (nextMa.containsMouse ? root.uiCardHover : "transparent")
                scale: nextMa.pressed && !screenTimeRoot.isToday ? 0.94 : 1
                Behavior on color { ColorAnimation { duration: 120 } }
                Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                Text {
                    anchors.centerIn: parent
                    text: "›"
                    color: screenTimeRoot.isToday ? root.cFgMuted : root.cFgSecondary
                    font.family: root.fontSans
                    font.pixelSize: 16
                    font.weight: Font.Bold
                }
                MouseArea {
                    id: nextMa
                    anchors.fill: parent
                    enabled: !screenTimeRoot.isToday
                    hoverEnabled: true
                    cursorShape: screenTimeRoot.isToday ? Qt.ArrowCursor : Qt.PointingHandCursor
                    onClicked: screenTimeRoot.changeDay(1)
                }
            }

            // close
            Rectangle {
                Layout.preferredWidth: 24
                Layout.preferredHeight: 24
                radius: 6
                color: closeMa.containsMouse ? root.uiCardHover : "transparent"
                scale: closeMa.pressed ? 0.94 : 1
                Behavior on color { ColorAnimation { duration: 120 } }
                Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                Text {
                    anchors.centerIn: parent
                    text: "×"
                    color: root.cFgMuted
                    font.family: root.fontSans
                    font.pixelSize: 16
                    font.weight: Font.DemiBold
                }
                MouseArea {
                    id: closeMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.displayState = 0;
                        root.updateState();
                    }
                }
            }
        }

        Item { Layout.preferredHeight: 12 }

        // ---- hero ----------------------------------------------------------
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            RowLayout {
                Layout.fillWidth: true
                spacing: root.s4

                Text {
                    text: screenTimeRoot.dayHasData
                          ? screenTimeRoot.formatTime(screenTimeRoot.usageData.total || 0)
                          : "—"
                    color: root.cFgPrimary
                    font.family: root.fontDisplay
                    font.pixelSize: 42
                    font.weight: Font.Bold
                    font.letterSpacing: -0.8
                    lineHeight: 1.0
                    lineHeightMode: Text.ProportionalHeight
                }

                ColumnLayout {
                    Layout.alignment: Qt.AlignBottom
                    Layout.bottomMargin: 5
                    spacing: 2

                    Text {
                        visible: text !== ""
                        text: screenTimeRoot.deltaText()
                        color: root.cFgSecondary
                        font.family: root.fontSans
                        font.pixelSize: 10
                        font.weight: Font.Medium
                    }
                    Text {
                        text: screenTimeRoot.statsLabel()
                        color: root.cFgMuted
                        font.family: root.fontSans
                        font.pixelSize: 10
                    }
                }
            }

            Item { Layout.preferredHeight: 10 }

            // part-to-whole, top five + other
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 8
                radius: 4
                color: Qt.rgba(root.cFgPrimary.r, root.cFgPrimary.g, root.cFgPrimary.b, 0.07)
                clip: true

                Row {
                    anchors.fill: parent
                    Repeater {
                        model: screenTimeRoot.barSegments
                        delegate: Rectangle {
                            width: screenTimeRoot.usageData.total > 0
                                   ? (modelData.seconds / screenTimeRoot.usageData.total) * parent.width
                                   : 0
                            height: parent.height
                            color: screenTimeRoot.appColor(modelData.slot)
                            Behavior on width {
                                NumberAnimation { duration: 260; easing.type: Easing.OutCubic }
                            }
                        }
                    }
                }
            }

            Item {
                Layout.preferredHeight: 8
                visible: screenTimeRoot.appList.length > 0
            }

            // direct labels: colour is never the only encoding
            RowLayout {
                Layout.fillWidth: true
                spacing: root.s4
                visible: screenTimeRoot.appList.length > 0

                Repeater {
                    model: screenTimeRoot.appList.slice(0, 3)
                    delegate: RowLayout {
                        spacing: 5
                        Rectangle {
                            Layout.preferredWidth: 5
                            Layout.preferredHeight: 5
                            radius: 2.5
                            color: screenTimeRoot.appColor(index)
                        }
                        Text {
                            text: modelData.name
                            color: root.cFgSecondary
                            font.family: root.fontSans
                            font.pixelSize: 10
                            elide: Text.ElideRight
                            Layout.maximumWidth: 130
                        }
                        Text {
                            text: screenTimeRoot.formatTime(modelData.seconds)
                            color: root.cFgMuted
                            font.family: root.fontMono
                            font.pixelSize: 10
                        }
                    }
                }
                Item { Layout.fillWidth: true }
            }
        }

        Item { Layout.preferredHeight: 14 }

        // ---- day rhythm ----------------------------------------------------
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 5

            RowLayout {
                Layout.fillWidth: true
                Text {
                    text: "Hourly"
                    color: root.cFgMuted
                    font.family: root.fontSans
                    font.pixelSize: 10
                    font.weight: Font.DemiBold
                    font.letterSpacing: 0.2
                }
                Item { Layout.fillWidth: true }
                Text {
                    text: "busiest " + screenTimeRoot.busiestLabel()
                    color: root.cFgMuted
                    font.family: root.fontMono
                    font.pixelSize: 9
                }
            }

            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 20

                Rectangle {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    height: 1
                    color: root.cBorderSubtle
                }

                Row {
                    id: hourRow
                    anchors.fill: parent
                    spacing: 2

                    Repeater {
                        model: 24
                        delegate: Item {
                            width: (hourRow.width - 23 * hourRow.spacing) / 24
                            height: hourRow.height
                            Rectangle {
                                anchors.bottom: parent.bottom
                                width: parent.width
                                height: Math.max(1.5,
                                    (screenTimeRoot.hourValue(index) / screenTimeRoot.hourMax())
                                    * (parent.height - 1))
                                radius: Math.min(2, width / 2)
                                color: screenTimeRoot.hourValue(index) <= 0
                                       ? Qt.rgba(root.cFgPrimary.r, root.cFgPrimary.g, root.cFgPrimary.b, 0.06)
                                       : (screenTimeRoot.isToday && index === new Date().getHours()
                                          ? root.cAccent
                                          : Qt.rgba(root.cAccent.r, root.cAccent.g, root.cAccent.b, 0.42))
                                Behavior on height {
                                    NumberAnimation { duration: 260; easing.type: Easing.OutCubic }
                                }
                            }
                        }
                    }
                }
            }
        }

        Item { Layout.preferredHeight: 14 }

        // ---- seven-day trend ----------------------------------------------
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 6

            RowLayout {
                Layout.fillWidth: true
                Text {
                    text: "Last 7 days"
                    color: root.cFgMuted
                    font.family: root.fontSans
                    font.pixelSize: 10
                    font.weight: Font.DemiBold
                    font.letterSpacing: 0.2
                }
                Item { Layout.fillWidth: true }
                Text {
                    text: screenTimeRoot.avgWeekLabel()
                    color: root.cFgMuted
                    font.family: root.fontMono
                    font.pixelSize: 9
                }
            }

            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 50

                Row {
                    id: weekRow
                    anchors.fill: parent
                    spacing: 6

                    Repeater {
                        model: screenTimeRoot.weekData
                        delegate: Item {
                            width: (weekRow.width - 6 * weekRow.spacing) / 7
                            height: weekRow.height

                            Rectangle {
                                anchors.fill: parent
                                radius: 4
                                color: weekMa.containsMouse ? Qt.rgba(root.cFgPrimary.r, root.cFgPrimary.g, root.cFgPrimary.b, 0.04) : "transparent"
                            }

                            Rectangle {
                                anchors.bottom: parent.bottom
                                anchors.bottomMargin: 14
                                anchors.horizontalCenter: parent.horizontalCenter
                                width: Math.max(6, parent.width * 0.5)
                                height: modelData.hasData
                                        ? Math.max(2, (modelData.total / screenTimeRoot.weekMax())
                                                   * (parent.height - 18))
                                        : 2
                                radius: 3
                                color: !modelData.hasData
                                       ? Qt.rgba(root.cFgPrimary.r, root.cFgPrimary.g, root.cFgPrimary.b, 0.10)
                                       : (modelData.date === screenTimeRoot.viewDate
                                          ? root.cAccent
                                          : Qt.rgba(root.cAccent.r, root.cAccent.g, root.cAccent.b, 0.38))
                                Behavior on height {
                                    NumberAnimation { duration: 260; easing.type: Easing.OutCubic }
                                }
                                Behavior on color { ColorAnimation { duration: 120 } }
                            }

                            Text {
                                anchors.bottom: parent.bottom
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: modelData.label
                                color: modelData.date === screenTimeRoot.viewDate
                                       ? root.cAccent
                                       : root.cFgMuted
                                font.family: root.fontMono
                                font.pixelSize: 8
                            }

                            MouseArea {
                                id: weekMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: screenTimeRoot.loadDate(modelData.offset)
                            }
                        }
                    }
                }
            }
        }

        Item { Layout.preferredHeight: 14 }

        // ---- app ledger ----------------------------------------------------
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 5

            RowLayout {
                Layout.fillWidth: true
                Text {
                    text: "Top apps"
                    color: root.cFgMuted
                    font.family: root.fontSans
                    font.pixelSize: 10
                    font.weight: Font.DemiBold
                    font.letterSpacing: 0.2
                }
                Item { Layout.fillWidth: true }
                Text {
                    text: screenTimeRoot.appList.length > 0
                          ? screenTimeRoot.appList.length + (screenTimeRoot.appList.length === 1 ? " app" : " apps")
                          : ""
                    color: root.cFgMuted
                    font.family: root.fontMono
                    font.pixelSize: 9
                }
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                ListView {
                    id: appListView
                    anchors.fill: parent
                    clip: true
                    spacing: 2
                    boundsBehavior: Flickable.StopAtBounds
                    model: screenTimeRoot.appList
                    delegate: Item {
                        width: appListView.width
                        height: 21

                        RowLayout {
                            anchors.fill: parent
                            spacing: 8

                            Rectangle {
                                Layout.preferredWidth: 5
                                Layout.preferredHeight: 5
                                radius: 2.5
                                color: screenTimeRoot.appColor(index)
                            }
                            Text {
                                Layout.fillWidth: true
                                text: modelData.name
                                color: root.cFgPrimary
                                font.family: root.fontSans
                                font.pixelSize: 12
                                elide: Text.ElideRight
                            }
                            Rectangle {
                                Layout.preferredWidth: 58
                                Layout.preferredHeight: 3
                                radius: 1.5
                                color: Qt.rgba(root.cFgPrimary.r, root.cFgPrimary.g, root.cFgPrimary.b, 0.06)

                                Rectangle {
                                    height: parent.height
                                    radius: 1.5
                                    width: parent.width * screenTimeRoot.appFraction(modelData.seconds)
                                    color: screenTimeRoot.appColor(index)
                                    Behavior on width {
                                        NumberAnimation { duration: 260; easing.type: Easing.OutCubic }
                                    }
                                }
                            }
                            Text {
                                Layout.preferredWidth: 52
                                horizontalAlignment: Text.AlignRight
                                text: screenTimeRoot.formatTime(modelData.seconds)
                                color: root.cFgSecondary
                                font.family: root.fontMono
                                font.pixelSize: 10
                            }
                        }
                    }
                }

                // Scroll affordance — a 2px thumb only when the ledger overflows.
                Rectangle {
                    anchors.right: parent.right
                    anchors.rightMargin: 1
                    width: 2
                    radius: 1
                    visible: appListView.contentHeight > appListView.height + 2
                    height: Math.max(18, parent.height * (appListView.height
                            / Math.max(1, appListView.contentHeight)))
                    y: (parent.height - height)
                       * Math.max(0, Math.min(1, appListView.contentY
                            / Math.max(1, appListView.contentHeight - appListView.height)))
                    color: Qt.rgba(root.cFgPrimary.r, root.cFgPrimary.g, root.cFgPrimary.b, 0.22)
                }

                Text {
                    anchors.centerIn: parent
                    visible: screenTimeRoot.appList.length === 0
                    text: screenTimeRoot.dayHasData
                          ? "Nothing recorded in apps"
                          : "Nothing recorded on this day"
                    color: root.cFgMuted
                    font.family: root.fontSans
                    font.pixelSize: 11
                }
            }
        }

        Item { Layout.preferredHeight: 8 }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: root.cBorderSubtle
            opacity: 0.7
        }

        Item { Layout.preferredHeight: 6 }

        // ---- footer --------------------------------------------------------
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 14

            Text {
                text: "← → day  ·  T today  ·  Esc close"
                color: root.cFgMuted
                font.family: root.fontMono
                font.pixelSize: 8
                font.letterSpacing: 0.2
            }
            Item { Layout.fillWidth: true }
            Text {
                text: screenTimeRoot.dayHasData && screenTimeRoot.isToday
                      && screenTimeRoot.lastUpdated !== ""
                      ? "updated " + screenTimeRoot.lastUpdated
                      : ""
                color: root.cFgMuted
                font.family: root.fontMono
                font.pixelSize: 8
            }
        }
    }
}
