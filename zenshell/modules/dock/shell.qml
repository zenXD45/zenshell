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
  readonly property int shadowPad: 40
  readonly property color shadowColor: dockTheme === "liquid" ? "#60000000" : "#9A000000"
  readonly property int shadowBlur: dockTheme === "liquid" ? 36 : 28
  readonly property int shadowOffsetY: dockTheme === "liquid" ? 12 : 10
  readonly property color liquidSurface: root.themeDark ? root.glass(0.43) : root.ink(0.28)

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
        Behavior on color { ColorAnimation { duration: 150 } }
        
        scale: mouseArea.containsMouse ? 1.15 : 1.0
        Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
        
        IconImage {
          id: appIcon
          anchors.centerIn: parent
          width: 32
          height: 32
          source: Quickshell.iconPath(modelData.icon, true)
        }
        
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

            Behavior on width { NumberAnimation { duration: 150 } }
            Behavior on height { NumberAnimation { duration: 150 } }
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

      // Shadow lives in the transparent padding above and beside the pill.
      // It is a sibling of the surface so the pill's own fill stays on top.
      RectangularShadow {
        anchors.fill: dockSurface
        radius: dockSurface.radius
        color: root.shadowColor
        blur: root.shadowBlur
        offset: Qt.vector2d(0, root.shadowOffsetY)

        Behavior on color { ColorAnimation { duration: 200 } }
        Behavior on blur { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
      }

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

        // Inner sheen: the top catches light, the bottom settles into shade.
        Rectangle {
          anchors.fill: parent
          radius: parent.radius
          opacity: root.dockTheme === "liquid" ? 1 : 0.7
          gradient: Gradient {
            GradientStop { position: 0.0; color: root.ink(0.086) }
            GradientStop { position: 0.38; color: root.ink(0.012) }
            GradientStop { position: 0.62; color: "#00000000" }
            GradientStop { position: 1.0; color: "#30000000" }
          }
          Behavior on opacity { NumberAnimation { duration: 200 } }
        }

        // Rim light along the flat part of the top edge.
        Rectangle {
          width: parent.width - 64
          height: 1
          anchors.top: parent.top
          anchors.topMargin: 1
          anchors.horizontalCenter: parent.horizontalCenter
          opacity: root.dockTheme === "liquid" ? 0.9 : 0.65
          gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: "transparent" }
            GradientStop { position: 0.5; color: root.ink(0.251) }
            GradientStop { position: 1.0; color: "transparent" }
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
          Rectangle {
            width: 2
            height: 32
            color: root.ink(0.251)
            radius: 1
            visible: root.unpinnedDockItems.length > 0
            anchors.verticalCenter: parent.verticalCenter
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
