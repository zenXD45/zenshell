import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Io
import QtQuick
import QtQuick.Effects
import QtQuick.Layouts

Scope {
  id: root
  
  property var pinnedApps: []
  property string pinnedJsonPath: Quickshell.shellDir + "/pinned_apps.json"
  property string dockTheme: "liquid"
  property bool isAutoHide: true
  property string shellProfile: "island"
  readonly property string uiFont: "Google Sans Flex"
  readonly property string iconFont: "JetBrainsMono Nerd Font"

    // ── Theme palette ─────────────────────────────────────────────
    // The manifest at ~/.config/hypr/themes/themes.json is the single source
    // of truth: hyprzen/scripts/gen-themes.py writes the same colours the
    // GTK and Hyprland side read, so every part of the shell repaints
    // together and can never disagree with the desktop about a theme.
    property color themeBg: "#0f1715"
    property color themeSurface: "#18221f"
    property color themeFg: "#d3c6aa"
    property color themeExtra: "#e67e80"
    property bool themeDark: true
    property int themeRounding: 14
    property var themesList: []
    property string currentThemeId: ""
    property string currentThemeAccent: "#838996"
    readonly property color themeAccent: currentThemeAccent

    // Tinted overlays: the alpha stays as designed, the hue comes from the
    // theme, so a light theme shades its glass where a dark theme lifts it.
    function ink(alpha: real): color {
        return Qt.rgba(root.themeFg.r, root.themeFg.g, root.themeFg.b, alpha);
    }
    function glass(alpha: real): color {
        return Qt.rgba(root.themeBg.r, root.themeBg.g, root.themeBg.b, alpha);
    }
    function glassDeep(alpha: real): color {
        var c = Qt.darker(root.themeBg, 1.25);
        return Qt.rgba(c.r, c.g, c.b, alpha);
    }
    function surface(alpha: real): color {
        return Qt.rgba(root.themeSurface.r, root.themeSurface.g, root.themeSurface.b, alpha);
    }
    function accent(alpha: real): color {
        return Qt.rgba(root.themeAccent.r, root.themeAccent.g, root.themeAccent.b, alpha);
    }
    // Text drawn on top of an accent-filled shape needs the opposite lightness
    // from the accent, not from the theme.
    function onAccent(): color {
        return root.themeAccent.hslLightness > 0.6 ? root.themeBg : root.themeFg;
    }

    function updateThemePalette() {
        for (var i = 0; i < root.themesList.length; i++) {
            var t = root.themesList[i];
            if (t.id === root.currentThemeId) {
                root.currentThemeAccent = t.accent || root.currentThemeAccent;
                if (t.bg) root.themeBg = t.bg;
                if (t.surface) root.themeSurface = t.surface;
                if (t.fg) root.themeFg = t.fg;
                if (t.extra) root.themeExtra = t.extra;
                if (t.dark !== undefined) root.themeDark = !!t.dark;
                if (t.rounding !== undefined) root.themeRounding = t.rounding;
                break;
            }
        }
    }

    FileView {
        id: themeManifest
        path: Quickshell.env("HOME") + "/.config/hypr/themes/themes.json"
        watchChanges: true
        onFileChanged: reload()
        onTextChanged: {
            try {
                root.themesList = JSON.parse(text());
                root.updateThemePalette();
            } catch (e) {}
        }
    }

    FileView {
        id: activeTheme
        path: Quickshell.env("HOME") + "/.config/hypr/themes/current_theme.conf"
        watchChanges: true
        onFileChanged: reload()
        onTextChanged: {
            var m = text().match(/themes\/([^\.]+)\.conf/);
            if (m) {
                root.currentThemeId = m[1];
                root.updateThemePalette();
            }
        }
    }

  // ── Depth ───────────────────────────────────────────────────────
  // Transparent padding inside the layer surface gives the shadow room to
  // fall without moving the visible pill or changing the auto-hide travel.
  readonly property int shadowPad: 48

  // Configurable appearance (synced with shell_settings.json)
  property real dockTransparency: 0.5      // 0.0 = opaque, 1.0 = fully transparent
  property real dockFrost: 0.5             // 0.0 = clear glass, 1.0 = heavy frost

  // Base theme values (used as multipliers)
  property color baseShadowColor: dockTheme === "liquid" ? "#4D000000" : "#66000000"
  property int baseShadowBlur: dockTheme === "liquid" ? 48 : 36
  property int baseShadowOffsetY: dockTheme === "liquid" ? 16 : 14
  property color baseAoColor: dockTheme === "liquid" ? "#1A000000" : "#26000000"
  property int baseAoBlur: dockTheme === "liquid" ? 64 : 48
  property int baseAoOffsetY: dockTheme === "liquid" ? 24 : 20

  // Computed effective values
  readonly property color shadowColor: Qt.rgba(
    root.baseShadowColor.r, root.baseShadowColor.g, root.baseShadowColor.b,
    root.baseShadowColor.a * (1.0 - root.dockTransparency * 0.3)
  )
  readonly property int shadowBlur: Math.round(root.baseShadowBlur * (1.0 - root.dockTransparency * 0.2))
  readonly property int shadowOffsetY: root.baseShadowOffsetY
  readonly property color aoColor: Qt.rgba(
    root.baseAoColor.r, root.baseAoColor.g, root.baseAoColor.b,
    root.baseAoColor.a * (1.0 - root.dockTransparency * 0.4)
  )
  readonly property int aoBlur: Math.round(root.baseAoBlur * (1.0 - root.dockTransparency * 0.2))
  readonly property int aoOffsetY: root.baseAoOffsetY

  // Liquid surface color with transparency/frost
  readonly property color liquidSurface: root.themeDark
    ? Qt.rgba(root.glass(0.38).r, root.glass(0.38).g, root.glass(0.38).b, 0.38 * (1.0 - root.dockTransparency * 0.5))
    : Qt.rgba(root.ink(0.24).r, root.ink(0.24).g, root.ink(0.24).b, 0.24 * (1.0 - root.dockTransparency * 0.5))

  // One popup owns both menus so only one can ever be open. appData is a
  // snapshot of the dock item; it is refreshed while the menu is open so the
  // window count and pin state never go stale.
  property var contextApp: null
  property var contextScreen: null
  property real contextAnchorX: 0
  property real contextAnchorY: 0
  property bool contextMenuOpen: false
  property string contextMode: "app"
  property var appAnchors: ({})
  property Item ipcMenuAnchor: null
  property real dockPanelWidth: 0
  property real dockPanelHeight: 56
  property var dockScreen: null

  // One FileView owns both the visual theme and the global profile. Watching
  // the file means the dock disappears the instant Profile 02 is selected from
  // the island or the bar — no process restart and no IPC race.
  FileView {
    id: shellSettings
    path: Quickshell.env("HOME") + "/.config/quickshell/shell_settings.json"
    watchChanges: true
    onFileChanged: reload()
    onTextChanged: {
      try {
        var settings = JSON.parse(text());
        if (settings.dock_theme === "liquid" || settings.dock_theme === "solid") {
          root.dockTheme = settings.dock_theme;
        }
        if (typeof settings.dock_auto_hide === "boolean") {
          root.isAutoHide = settings.dock_auto_hide;
        }
        if (typeof settings.dock_transparency === "number") {
          root.dockTransparency = Math.max(0.0, Math.min(1.0, settings.dock_transparency));
        }
        if (typeof settings.dock_frost === "number") {
          root.dockFrost = Math.max(0.0, Math.min(1.0, settings.dock_frost));
        }
        if (settings.profile === "island" || settings.profile === "bar") {
          if (root.shellProfile !== settings.profile) {
            root.closeContextMenu();
          }
          root.shellProfile = settings.profile;
        }
      } catch (e) {}
    }
  }

  Process {
    id: saveSettingProcess
    command: []
  }

  function saveDockSetting(key, value) {
    saveSettingProcess.running = false;
    saveSettingProcess.command = [
      "python3",
      Quickshell.shellDir + "/../../scripts/set_setting.py",
      key,
      JSON.stringify(value)
    ];
    saveSettingProcess.running = true;
  }

  function setDockTheme(theme) {
    if (theme !== "liquid" && theme !== "solid") return;
    root.dockTheme = theme;
    root.saveDockSetting("dock_theme", theme);
  }

  function setAutoHide(enabled) {
    root.isAutoHide = enabled;
    root.saveDockSetting("dock_auto_hide", enabled);
  }

  function setDockTransparency(value) {
    root.dockTransparency = Math.max(0.0, Math.min(1.0, value));
    root.saveDockSetting("dock_transparency", root.dockTransparency);
  }

  function setDockFrost(value) {
    root.dockFrost = Math.max(0.0, Math.min(1.0, value));
    root.saveDockSetting("dock_frost", root.dockFrost);
  }

  IpcHandler {
    target: "qs-dock"
    function updateTheme(themeName: string): void {
      root.setDockTheme(themeName);
    }
    function toggleAutoHide(): void {
      root.setAutoHide(!root.isAutoHide);
    }
    function showAppMenu(appId: string): void {
      var app = root.findDockItem(appId);
      var anchor = root.appAnchors[appId];
      if (app && anchor) root.openAppMenu(app, anchor);
    }
    function showDockMenu(): void {
      if (root.ipcMenuAnchor) root.openDockMenu(root.ipcMenuAnchor);
    }
    function closeMenu(): void {
      root.closeContextMenu();
    }
    function menuAction(actionId: string): void {
      root.handleMenuAction(actionId);
      root.closeContextMenu();
    }
    function setTransparency(value: real): void {
      root.setDockTransparency(value);
    }
    function setFrost(value: real): void {
      root.setDockFrost(value);
    }
  }
  
  // Read pinned apps from JSON. FileView watches the file natively, so there is
  // no external `inotifywait` loop to orphan when the dock restarts — the old
  // Process-based watcher left one stray bash+inotifywait pair per restart,
  // all reparented to PID 1.
  function loadPinned() {
    pinnedFile.reload();
  }

  FileView {
    id: pinnedFile
    path: root.pinnedJsonPath
    watchChanges: true
    onFileChanged: reload()
    onTextChanged: {
      try {
        root.pinnedApps = JSON.parse(text());
      } catch (e) {}
    }
  }
  
  property var openAppsData: ({})
  
  function fetchOpenApps() {
    hyprctlProcess.running = true;
  }
  
  Process {
    id: hyprctlProcess
    command: ["python3", Quickshell.shellDir + "/get_clients.py"]
    stdout: SplitParser {
      onRead: data => {
        try {
          var clients = JSON.parse(data);
          var apps = {};
          var focused = Hyprland.focusedClient;

          for (var i = 0; i < clients.length; i++) {
            var c = clients[i];
            if (c.class === "" || c.class === "quickshell") continue;
            var wid = c.initialClass || c.class;
            var addr = c.address;
            var rIcon = c.resolvedIcon || wid;
            var wsId = c.workspaceId || 1;

            if (!apps[wid]) {
              apps[wid] = {
                count: 0,
                focused: false,
                address: addr,
                icon: rIcon,
                name: c.resolvedName || wid,
                exec: c.resolvedExec || wid,
                workspace: wsId,
                windows: []
              };
            }

            var app = apps[wid];
            app.count++;
            app.windows.push({
              address: addr,
              title: c.title || wid,
              workspace: wsId,
              focused: false
            });

            var isFocused = !!focused && focused.address === addr;
            if (isFocused || c.focusHistoryID === 0) {
              app.focused = true;
              app.address = addr;
              app.workspace = wsId;
              app.windows[app.windows.length - 1].focused = true;
            }
          }
          root.openAppsData = apps;
        } catch(e) {}
      }
    }
  }
  
  Timer {
    interval: 1000
    running: true
    repeat: true
    onTriggered: fetchOpenApps()
  }
  
  Component.onCompleted: {
    loadPinned();
    fetchOpenApps();
  }
  
  property var pinnedDockItems: []
  property var unpinnedDockItems: []

  function updateDockItems() {
    var pItems = [];
    var uItems = [];
    var openApps = Object.assign({}, root.openAppsData);

    for (var p = 0; p < root.pinnedApps.length; p++) {
      var pApp = root.pinnedApps[p];
      if (!pApp || !pApp.id) continue;
      var openApp = openApps[pApp.id];
      var windows = openApp ? openApp.windows : [];
      var focusIndex = -1;
      for (var w = 0; w < windows.length; w++) {
        if (windows[w].focused) {
          focusIndex = w;
          break;
        }
      }
      if (focusIndex < 0 && openApp && openApp.focused && windows.length > 0) focusIndex = 0;

      pItems.push({
        id: pApp.id,
        name: pApp.name || (openApp ? openApp.name : pApp.id),
        icon: pApp.iconName || (openApp ? openApp.icon : pApp.id),
        exec: pApp.exec || (openApp ? openApp.exec : pApp.id),
        isPinned: true,
        isOpen: !!openApp,
        isFocused: openApp ? openApp.focused : false,
        address: openApp ? openApp.address : "",
        workspace: openApp ? openApp.workspace : 1,
        count: openApp ? openApp.count : 0,
        windows: windows,
        focusedWindowIndex: focusIndex,
        pinnedIndex: p
      });

      if (openApp) delete openApps[pApp.id];
    }

    var openKeys = Object.keys(openApps);
    for (var k = 0; k < openKeys.length; k++) {
      var uId = openKeys[k];
      var uApp = openApps[uId];
      var uFocusIndex = -1;
      for (var u = 0; u < uApp.windows.length; u++) {
        if (uApp.windows[u].focused) {
          uFocusIndex = u;
          break;
        }
      }
      if (uFocusIndex < 0 && uApp.focused && uApp.windows.length > 0) uFocusIndex = 0;

      uItems.push({
        id: uId,
        name: uApp.name || uId,
        icon: uApp.icon,
        exec: uApp.exec || uId,
        isPinned: false,
        isOpen: true,
        isFocused: uApp.focused,
        address: uApp.address,
        workspace: uApp.workspace,
        count: uApp.count,
        windows: uApp.windows,
        focusedWindowIndex: uFocusIndex,
        pinnedIndex: -1
      });
    }

    root.pinnedDockItems = pItems;
    root.unpinnedDockItems = uItems;
    root.refreshContextApp();
  }

  onOpenAppsDataChanged: updateDockItems()
  onPinnedAppsChanged: updateDockItems()
  
  function execCmd(cmd) {
    if (!cmd) return;
    // JSON string escaping is also valid Lua string syntax. The old nested
    // table form was not a valid exec_cmd argument and broke launcher commands
    // containing spaces or shell metacharacters.
    Hyprland.dispatch("hl.dsp.exec_cmd(" + JSON.stringify(cmd) + ")");
  }

  function findDockItem(id) {
    for (var i = 0; i < root.pinnedDockItems.length; i++) {
      if (root.pinnedDockItems[i].id === id) return root.pinnedDockItems[i];
    }
    for (var j = 0; j < root.unpinnedDockItems.length; j++) {
      if (root.unpinnedDockItems[j].id === id) return root.unpinnedDockItems[j];
    }
    return null;
  }

  function screenAt(x, y) {
    var screens = Quickshell.screens;
    for (var i = 0; i < screens.length; i++) {
      var s = screens[i];
      if (x >= s.x && x < s.x + s.width && y >= s.y && y < s.y + s.height) return s;
    }
    return screens.length > 0 ? screens[0] : null;
  }

  function placeMenuAt(anchor) {
    if (!anchor) return false;
    // mapToGlobal on a layer-shell item returns its position inside the dock
    // window, not its monitor position. Add the dock's known bottom-centre
    // offset so the menu still lands on the icon in every profile.
    var local = anchor.mapToGlobal(anchor.width / 2, 0);
    var screen = root.dockScreen || root.screenAt(local.x, local.y);
    if (!screen) return false;
    var panelWidth = root.dockPanelWidth > 0 ? root.dockPanelWidth : 0;
    var panelHeight = root.dockPanelHeight > 0 ? root.dockPanelHeight : 56;
    // mapToGlobal is window-relative, while dockPanelWidth/Height describe
    // the visible pill. Reconstruct the window origin, padding included, so
    // menus still land on the icon they were opened from.
    var panelX = (screen.width - panelWidth) / 2 - root.shadowPad;
    var panelY = screen.height - panelHeight - 12 - root.shadowPad;
    root.contextScreen = screen;
    root.contextAnchorX = panelX + local.x;
    root.contextAnchorY = panelY + local.y;
    return true;
  }

  function focusWindow(win) {
    if (!win || !win.address) return;
    Hyprland.dispatch("hl.dsp.focus({ workspace = " + win.workspace + " })");
    Hyprland.dispatch('hl.dsp.focus({ window = "address:' + win.address + '" })');
  }

  function focusApp(app) {
    if (!app) return;
    if (app.windows && app.windows.length > 0) {
      var winIndex = app.focusedWindowIndex >= 0 ? app.focusedWindowIndex : 0;
      root.focusWindow(app.windows[winIndex]);
    } else if (app.isOpen && app.address) {
      root.focusWindow({ address: app.address, workspace: app.workspace });
    } else {
      root.execCmd(app.exec);
    }
  }

  function focusNextWindow(app, direction) {
    if (!app || !app.windows || app.windows.length < 2) return;
    var step = direction === undefined ? 1 : direction;
    var current = app.focusedWindowIndex >= 0 ? app.focusedWindowIndex : -1;
    var next = (current + step + app.windows.length) % app.windows.length;
    root.focusWindow(app.windows[next]);
  }

  function closeAppWindows(app) {
    if (!app || !app.windows) return;
    for (var i = 0; i < app.windows.length; i++) {
      var win = app.windows[i];
      if (!win.address) continue;
      Hyprland.dispatch('hl.dsp.window.close({ window = "address:' + win.address + '" })');
    }
  }

  Process {
    id: pinProcess
    command: []
  }

  function runPinCommand(args) {
    pinProcess.running = false;
    pinProcess.command = ["python3", Quickshell.shellDir + "/pin_app.py"].concat(args);
    pinProcess.running = true;
  }

  function pinApp(app) {
    if (!app) return;
    root.runPinCommand(["pin", app.id, app.icon || app.id, app.exec || app.id]);
  }

  function unpinApp(app) {
    if (!app) return;
    root.runPinCommand(["unpin", app.id]);
  }

  function movePinned(id, direction) {
    var ids = [];
    for (var i = 0; i < root.pinnedApps.length; i++) {
      if (root.pinnedApps[i] && root.pinnedApps[i].id) ids.push(root.pinnedApps[i].id);
    }
    var from = ids.indexOf(id);
    var to = from + direction;
    if (from < 0 || to < 0 || to >= ids.length) return;
    var moved = ids[from];
    ids[from] = ids[to];
    ids[to] = moved;
    root.runPinCommand(["set-order", JSON.stringify(ids)]);
  }

  function openAppMenu(app, anchor) {
    if (!app || !root.placeMenuAt(anchor)) return;
    root.contextMode = "app";
    root.contextApp = app;
    root.contextMenuOpen = true;
    dockContextMenu.showMenu();
  }

  function openDockMenu(anchor) {
    if (!root.placeMenuAt(anchor)) return;
    root.contextMode = "dock";
    root.contextApp = null;
    root.contextMenuOpen = true;
    dockContextMenu.showMenu();
  }

  function closeContextMenu() {
    if (!root.contextMenuOpen) return;
    root.contextMenuOpen = false;
    dockContextMenu.dismiss();
  }

  function refreshContextApp() {
    if (!root.contextMenuOpen || root.contextMode !== "app" || !root.contextApp) return;
    var current = root.findDockItem(root.contextApp.id);
    if (current) {
      root.contextApp = current;
    } else {
      root.closeContextMenu();
    }
  }

  function handleMenuAction(actionId) {
    var app = root.contextApp;
    if (root.contextMode === "dock") {
      if (actionId === "toggle-autohide") root.setAutoHide(!root.isAutoHide);
      else if (actionId === "toggle-theme") root.setDockTheme(root.dockTheme === "liquid" ? "solid" : "liquid");
      return;
    }
    if (!app) return;

    switch (actionId) {
      case "open":
      case "new-window":
        root.execCmd(app.exec);
        break;
      case "focus":
        root.focusApp(app);
        break;
      case "next-window":
        root.focusNextWindow(app);
        break;
      case "pin":
        root.pinApp(app);
        break;
      case "unpin":
        root.unpinApp(app);
        break;
      case "move-left":
        root.movePinned(app.id, -1);
        break;
      case "move-right":
        root.movePinned(app.id, 1);
        break;
      case "close-windows":
        root.closeAppWindows(app);
        break;
    }
  }

  DockContextMenu {
    id: dockContextMenu
    appData: root.contextApp
    contextScreen: root.contextScreen
    anchorScreenX: root.contextAnchorX
    anchorScreenY: root.contextAnchorY
    menuMode: root.contextMode
    uiFont: root.uiFont
    iconFont: root.iconFont
    dockAutoHide: root.isAutoHide
    dockLiquid: root.dockTheme === "liquid"
    pinnedCount: root.pinnedApps.length
    runningCount: Object.keys(root.openAppsData).length
    onActionTriggered: actionId => root.handleMenuAction(actionId)
    onMenuClosed: root.contextMenuOpen = false
  }
  
  Component {
    id: appDelegate
    Item {
      id: iconRect
      width: 44
      height: 44

      Component.onCompleted: root.appAnchors[modelData.id] = mouseArea
      Component.onDestruction: {
        if (root.appAnchors[modelData.id] === mouseArea) delete root.appAnchors[modelData.id];
      }
      
      Rectangle {
        anchors.fill: parent
        radius: 14
        color: modelData.isFocused ? root.ink(0.188) : (mouseArea.containsMouse ? root.ink(0.125) : "transparent")
        Behavior on color { ColorAnimation { duration: 120 } }
        
        // Hover/focus elevation shadow for the icon itself
        RectangularShadow {
          anchors.fill: parent
          radius: 14
          color: mouseArea.containsMouse || modelData.isFocused ? "#40000000" : "#00000000"
          blur: 16
          offset: Qt.vector2d(0, 4)
          opacity: mouseArea.containsMouse || modelData.isFocused ? 1 : 0
          Behavior on opacity { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
          Behavior on blur { NumberAnimation { duration: 120 } }
        }
        
        // Inner press depth
        Rectangle {
          anchors.fill: parent
          radius: 14
          opacity: mouseArea.pressed ? 0.6 : 0
          gradient: Gradient {
            GradientStop { position: 0.0; color: "#10000000" }
            GradientStop { position: 1.0; color: "#30000000" }
          }
          Behavior on opacity { NumberAnimation { duration: 80 } }
        }

        IconImage {
          id: appIcon
          anchors.centerIn: parent
          width: 32
          height: 32
          source: Quickshell.iconPath(modelData.icon, true)
        }
        
        // Scale animation on hover
        scale: mouseArea.containsMouse ? 1.12 : 1.0
        Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
        
        // Pressed scale
        property real pressScale: mouseArea.pressed ? 0.94 : 1.0
        Behavior on pressScale { NumberAnimation { duration: 60; easing.type: Easing.OutQuad } }
        transform: Scale { origin.x: 22; origin.y: 22; xScale: iconRect.pressScale; yScale: iconRect.pressScale }
        
        Text {
          anchors.centerIn: parent
          text: modelData.id.charAt(0).toUpperCase()
          color: root.themeFg
          font.pixelSize: 18
          font.family: root.uiFont
          font.weight: Font.Bold
          visible: appIcon.status !== Image.Ready
        }
      }
      
      Row {
        id: windowIndicators
        anchors.bottom: parent.bottom
        anchors.bottomMargin: -4
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 3
        visible: modelData.isOpen

        Repeater {
          model: Math.min(modelData.count, 3)

          Rectangle {
            required property int index
            width: modelData.isFocused && index === modelData.focusedWindowIndex ? 6 : 4
            height: width
            radius: width / 2
            color: modelData.isFocused && index === modelData.focusedWindowIndex ? root.themeFg : root.ink(0.65)
            
            // Subtle shadow for the indicator dots
            RectangularShadow {
              anchors.fill: parent
              radius: width / 2
              color: modelData.isFocused && index === modelData.focusedWindowIndex ? "#40000000" : "#20000000"
              blur: 6
              offset: Qt.vector2d(0, 2)
              opacity: 1
            }

            Behavior on width { NumberAnimation { duration: 120 } }
            Behavior on height { NumberAnimation { duration: 120 } }
            Behavior on color { ColorAnimation { duration: 120 } }
          }
        }
      }
      
      MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        cursorShape: Qt.PointingHandCursor

        onClicked: (event) => {
          if (event.button === Qt.RightButton) {
            root.openAppMenu(modelData, mouseArea);
          } else if (event.button === Qt.MiddleButton) {
            root.execCmd(modelData.exec);
          } else {
            root.focusApp(modelData);
          }
        }

        onWheel: (event) => {
          if (modelData.isOpen && modelData.count > 1) {
            root.focusNextWindow(modelData, event.angleDelta.y < 0 ? 1 : -1);
          }
        }
      }
    }
  }
  
  Variants {
    model: Quickshell.screens
    PanelWindow {
      id: panel
      required property var modelData
      screen: modelData
      visible: root.shellProfile !== "bar"
      
      anchors { bottom: true }
      
      property bool isHidden: !panelHover.hovered && !root.contextMenuOpen
      margins { bottom: root.isAutoHide ? (isHidden ? -54 : 12) : 12 }
      Behavior on margins.bottom { NumberAnimation { duration: 300; easing.type: Easing.OutExpo } }
      
      implicitWidth: Math.min(layout.implicitWidth + 24, modelData.width - 40) + root.shadowPad * 2
      implicitHeight: 56 + root.shadowPad
      color: "transparent"
      
      WlrLayershell.layer: WlrLayer.Top
      WlrLayershell.namespace: "qs-dock"
      WlrLayershell.exclusiveZone: root.isAutoHide ? -1 : 68
      // Only the pill accepts input; the transparent shadow padding passes
      // clicks through to whatever is under the dock.
      mask: Region { item: dockSurface }

      // ── Optimized Pill Shadow ──
      // Uses RectangularShadow (GPU-accelerated) for the base, plus a single
      // blurred Item for the true capsule ends. Only 2 blur passes total.
      Item {
        id: shadowStack
        anchors.fill: dockSurface
        y: root.shadowOffsetY

        // Base shadow: RectangularShadow handles the straight sections efficiently.
        // The radius makes it a rounded-rect; we add end caps for true pill shape.
        RectangularShadow {
          id: baseShadow
          anchors.fill: dockSurface
          radius: dockSurface.radius
          color: root.shadowColor
          blur: root.shadowBlur
          offset: Qt.vector2d(0, 0)
          Behavior on color { ColorAnimation { duration: 200 } }
          Behavior on blur { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
        }

        // True capsule end caps — only these need per-frame blur.
        // Single blurred item with both caps; one render target, one blur pass.
        Item {
          id: endCaps
          anchors.fill: parent
          anchors.topMargin: 0
          anchors.bottomMargin: 0

          Rectangle {
            width: dockSurface.height
            height: dockSurface.height
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            radius: dockSurface.height / 2
            color: root.shadowColor
            layer.enabled: true
            layer.effect: FastBlur {
              radius: root.shadowBlur / 2
              samples: root.shadowBlur > 24 ? 9 : 5
              transparentBorder: true
            }
          }

          Rectangle {
            width: dockSurface.height
            height: dockSurface.height
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            radius: dockSurface.height / 2
            color: root.shadowColor
            layer.enabled: true
            layer.effect: FastBlur {
              radius: root.shadowBlur / 2
              samples: root.shadowBlur > 24 ? 9 : 5
              transparentBorder: true
            }
          }
        }

        // Ambient occlusion pool — single wide blurred rect (no end caps needed;
        // the softness hides the rectangular shape).
        Rectangle {
          id: aoPool
          anchors.left: parent.left
          anchors.right: parent.right
          anchors.top: parent.top
          anchors.bottom: parent.bottom
          anchors.margins: -16
          radius: dockSurface.radius + 8
          color: root.aoColor
          layer.enabled: true
          layer.effect: FastBlur {
            radius: root.aoBlur / 2
            samples: 9
            transparentBorder: true
          }
        }
      }

      // The visible pill surface.
      Rectangle {
        id: dockSurface
        width: Math.min(layout.implicitWidth + 24, modelData.width - 40)
        height: 56
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        radius: height / 2
        color: root.dockTheme === "liquid" ? root.liquidSurface : root.glass(0.9)
        border.color: root.dockTheme === "liquid" ? root.ink(0.188) : root.ink(0.157)
        border.width: 1
        Behavior on color { ColorAnimation { duration: 200 } }
        Behavior on border.color { ColorAnimation { duration: 200 } }

        HoverHandler {
          id: panelHover
        }

        // ── Liquid glass material (liquid theme) ──
        // Combined into 2 layers: (1) base glass + subsurface + fresnel + inner depth,
        // (2) waterline + lower specular catch. Minimal overdraw.
        // Frost (0=clear, 1=heavy) increases milkiness and reduces clarity.
        Item {
          id: liquidMaterial
          anchors.fill: parent
          visible: root.dockTheme === "liquid"

          // Frost overlay — adds milkiness based on dockFrost (0.0 to 1.0)
          Rectangle {
            anchors.fill: parent
            radius: parent.radius
            opacity: root.dockFrost * 0.4
            color: root.themeDark ? root.glass(1.0) : root.ink(1.0)
            Behavior on opacity { NumberAnimation { duration: 200 } }
          }

          // Layer 1: Combined base glass — subsurface warmth, fresnel top, inner depth bottom
          Rectangle {
            anchors.fill: parent
            radius: parent.radius
            opacity: 1.0 - root.dockFrost * 0.3
            gradient: Gradient {
              // Top: Fresnel highlight + subsurface warmth
              GradientStop { position: 0.00; color: root.ink(0.12) }
              GradientStop { position: 0.08; color: root.accent(0.08) }
              GradientStop { position: 0.15; color: root.ink(0.06) }
              GradientStop { position: 0.22; color: root.accent(0.03) }
              GradientStop { position: 0.35; color: "#00000000" }
              GradientStop { position: 0.50; color: "#00000000" }
              GradientStop { position: 0.65; color: "#00000000" }
              // Bottom: inner depth + lower specular
              GradientStop { position: 0.75; color: root.ink(0.015) }
              GradientStop { position: 0.85; color: root.accent(0.02) }
              GradientStop { position: 0.92; color: "#20000000" }
              GradientStop { position: 1.00; color: "#3A000000" }
            }
            Behavior on opacity { NumberAnimation { duration: 200 } }
          }

          // Layer 2: Waterline + lower specular catch (thin horizontal accents)
          Rectangle {
            anchors.fill: parent
            radius: parent.radius
            opacity: 1.0 - root.dockFrost * 0.5
            gradient: Gradient {
              // Waterline at ~22%
              GradientStop { position: 0.00; color: "#00000000" }
              GradientStop { position: 0.20; color: "#00000000" }
              GradientStop { position: 0.22; color: root.ink(0.18) }
              GradientStop { position: 0.24; color: "#00000000" }
              GradientStop { position: 0.94; color: "#00000000" }
              // Lower specular at ~96%
              GradientStop { position: 0.96; color: root.ink(0.15) }
              GradientStop { position: 1.00; color: "#00000000" }
            }
            Behavior on opacity { NumberAnimation { duration: 200 } }
          }
        }

        // ── Solid theme material ──
        Item {
          id: solidMaterial
          anchors.fill: parent
          visible: root.dockTheme !== "liquid"

          // Combined: top highlight + inner depth
          Rectangle {
            anchors.fill: parent
            radius: parent.radius
            gradient: Gradient {
              GradientStop { position: 0.00; color: root.ink(0.12) }
              GradientStop { position: 0.15; color: root.ink(0.06) }
              GradientStop { position: 0.35; color: "#00000000" }
              GradientStop { position: 0.50; color: "#00000000" }
              GradientStop { position: 0.65; color: "#00000000" }
              GradientStop { position: 0.80; color: "#15000000" }
              GradientStop { position: 1.00; color: "#2A000000" }
            }
          }

          // Top rim catch
          Rectangle {
            width: parent.width - 64
            height: 1
            anchors.top: parent.top
            anchors.topMargin: 1
            anchors.horizontalCenter: parent.horizontalCenter
            opacity: 0.65
            gradient: Gradient {
              orientation: Gradient.Horizontal
              GradientStop { position: 0.0; color: "transparent" }
              GradientStop { position: 0.5; color: root.ink(0.25) }
              GradientStop { position: 1.0; color: "transparent" }
            }
          }
        }

        MouseArea {
          anchors.fill: parent
          acceptedButtons: Qt.RightButton
          onPressed: (event) => {
            dockMenuAnchor.x = event.x;
            dockMenuAnchor.y = event.y;
          }
          onClicked: root.openDockMenu(dockMenuAnchor)
        }

        Item {
          id: dockMenuAnchor
          width: 1
          height: 1
          // Bound (not assigned once) so the IPC menu follows the dock as
          // the app row grows. A right-click replaces these with the click
          // position, which is exactly where that menu should open.
          x: dockSurface.width / 2
          y: dockSurface.height - 2
          visible: true
          opacity: 0
          enabled: false
        }
      }

      Component.onCompleted: {
        root.dockPanelWidth = dockSurface.width;
        root.dockPanelHeight = dockSurface.height;
        root.dockScreen = modelData;
        if (!root.ipcMenuAnchor) {
          root.ipcMenuAnchor = dockMenuAnchor;
        }
      }
      onWidthChanged: root.dockPanelWidth = dockSurface.width
      onHeightChanged: root.dockPanelHeight = dockSurface.height

      Flickable {
        anchors.fill: dockSurface
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        anchors.topMargin: 0
        anchors.bottomMargin: 0
        
        contentWidth: layout.implicitWidth
        contentHeight: height
        clip: true
        interactive: true
        flickableDirection: Flickable.HorizontalFlick
        
        Row {
          id: layout
          x: Math.max(0, (parent.width - implicitWidth) / 2)
          anchors.verticalCenter: parent.verticalCenter
          spacing: 8
        
          Repeater {
            model: root.pinnedDockItems
            delegate: appDelegate
          }
          
          // Visual separator
          Item {
            width: 2
            height: 32
            visible: root.unpinnedDockItems.length > 0
            anchors.verticalCenter: parent.verticalCenter

            Rectangle {
              anchors.fill: parent
              radius: 1
              gradient: Gradient {
                GradientStop { position: 0.0; color: "#00000000" }
                GradientStop { position: 0.3; color: root.ink(0.15) }
                GradientStop { position: 0.7; color: root.ink(0.15) }
                GradientStop { position: 1.0; color: "#00000000" }
              }
            }
            
            // Subtle glow on the separator
            Rectangle {
              anchors.fill: parent
              radius: 1
              opacity: 0.5
              gradient: Gradient {
                GradientStop { position: 0.0; color: root.accent(0.08) }
                GradientStop { position: 0.5; color: root.accent(0.02) }
                GradientStop { position: 1.0; color: root.accent(0.08) }
              }
            }
          }
          
          Repeater {
            model: root.unpinnedDockItems
            delegate: appDelegate
          }
        }
      }
    }
  }
}
