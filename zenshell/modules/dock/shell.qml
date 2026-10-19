import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Services.SystemTray
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

Scope {
  id: root
  
  property var pinnedApps: []
  property string pinnedJsonPath: Quickshell.shellDir + "/pinned_apps.json"
  property string dockTheme: "liquid"
  property bool isAutoHide: true
  
  Process {
    command: ["cat", Quickshell.env("HOME") + "/.config/quickshell/shell_settings.json"]
    running: true
    stdout: SplitParser {
      onRead: (data) => {
        try {
          var settings = JSON.parse(data);
          if (settings.dock_theme) root.dockTheme = settings.dock_theme;
        } catch (e) {}
      }
    }
  }

  IpcHandler {
    target: "qs-dock"
    function updateTheme(themeName: string): void {
      root.dockTheme = themeName;
    }
    function toggleAutoHide(): void {
      root.isAutoHide = !root.isAutoHide;
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
          
          for (var i=0; i<clients.length; i++) {
            var c = clients[i];
            if (c.class === "" || c.class === "quickshell") continue;
            var wid = c.initialClass || c.class;
            var addr = c.address;
            var rIcon = c.resolvedIcon || wid;
            var wsId = c.workspaceId || 1;
            
            if (!apps[wid]) apps[wid] = { count: 0, focused: false, address: addr, icon: rIcon, workspace: wsId };
            apps[wid].count++;
            if (focused && focused.address === addr) {
              apps[wid].focused = true;
            } else if (c.focusHistoryID === 0) {
              apps[wid].focused = true;
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
      var isOpen = !!openApps[pApp.id];
      var isFocused = isOpen ? openApps[pApp.id].focused : false;
      var address = isOpen ? openApps[pApp.id].address : "";
      
      pItems.push({
        id: pApp.id,
        icon: pApp.iconName || pApp.id,
        exec: pApp.exec || pApp.id,
        isPinned: true,
        isOpen: isOpen,
        isFocused: isFocused,
        address: address,
        workspace: isOpen ? openApps[pApp.id].workspace : 1
      });
      
      if (isOpen) delete openApps[pApp.id];
    }
    
    var openKeys = Object.keys(openApps);
    for (var k = 0; k < openKeys.length; k++) {
      var uId = openKeys[k];
      uItems.push({
        id: uId,
        icon: openApps[uId].icon,
        exec: uId,
        isPinned: false,
        isOpen: true,
        isFocused: openApps[uId].focused,
        address: openApps[uId].address,
        workspace: openApps[uId].workspace
      });
    }
    
    root.pinnedDockItems = pItems;
    root.unpinnedDockItems = uItems;
  }
  
  onOpenAppsDataChanged: updateDockItems()
  onPinnedAppsChanged: updateDockItems()
  
  function execCmd(cmd) {
    Hyprland.dispatch("hl.dsp.exec_cmd([[" + cmd + "]])");
  }
  
  Component {
    id: appDelegate
    Item {
      width: 44
      height: 44
      
      Rectangle {
        anchors.fill: parent
        radius: 14
        color: modelData.isFocused ? "#30FFFFFF" : (mouse.containsMouse ? "#20FFFFFF" : "transparent")
        Behavior on color { ColorAnimation { duration: 150 } }
        
        scale: mouse.containsMouse ? 1.15 : 1.0
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
          color: "#FFFFFF"
          font.pixelSize: 18
          font.family: "Outfit"
          font.weight: Font.Bold
          visible: appIcon.status !== Image.Ready
        }
      }
      
      Rectangle {
        width: modelData.isFocused ? 6 : 4
        height: modelData.isFocused ? 6 : 4
        radius: width / 2
        color: modelData.isFocused ? "#FFFFFF" : "#A0A0A0"
        anchors.bottom: parent.bottom
        anchors.bottomMargin: -4
        anchors.horizontalCenter: parent.horizontalCenter
        visible: modelData.isOpen
        
        Behavior on width { NumberAnimation { duration: 150 } }
        Behavior on height { NumberAnimation { duration: 150 } }
      }
      
      MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        
        onClicked: {
          if (modelData.isOpen) {
            Hyprland.dispatch('hl.dsp.focus({ workspace = ' + modelData.workspace + ' })');
            Hyprland.dispatch('hl.dsp.focus({ window = "address:' + modelData.address + '" })');
          } else {
            root.execCmd(modelData.exec);
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
      
      anchors { bottom: true }
      
      property bool isHidden: !panelHover.hovered
      margins { bottom: root.isAutoHide ? (isHidden ? -54 : 12) : 12 }
      Behavior on margins.bottom { NumberAnimation { duration: 300; easing.type: Easing.OutExpo } }
      
      implicitWidth: Math.min(layout.implicitWidth + 24, modelData.width - 40)
      implicitHeight: 56
      color: "transparent"
      
      WlrLayershell.layer: WlrLayer.Top
      WlrLayershell.namespace: "qs-dock"
      WlrLayershell.exclusiveZone: root.isAutoHide ? -1 : 68
      
      HoverHandler {
        id: panelHover
      }
      
      Rectangle {
          anchors.fill: parent
          color: root.dockTheme === "liquid" ? "#35000000" : "#E60D0D11"
          border.color: root.dockTheme === "liquid" ? "#30FFFFFF" : "#28FFFFFF"
          border.width: 1
        radius: height / 2
        Behavior on color { ColorAnimation { duration: 200 } }
        Behavior on border.color { ColorAnimation { duration: 200 } }
      }
      
      Flickable {
        anchors.fill: parent
        anchors.margins: 12
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        anchors.topMargin: 0
        anchors.bottomMargin: 0
        
        contentWidth: layout.implicitWidth
        contentHeight: parent.height
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
          color: "#40FFFFFF"
          radius: 1
          visible: root.unpinnedDockItems.length > 0
          anchors.verticalCenter: parent.verticalCenter
        }
        
        Repeater {
          model: root.unpinnedDockItems
          delegate: appDelegate
        }
      
      
      // Tray Divider
      Rectangle {
        width: 1
        height: 32
        color: "white"
        opacity: trayRepeater.count > 0 ? 0.2 : 0
        visible: trayRepeater.count > 0
        anchors.verticalCenter: parent.verticalCenter
      }
      
      // System Tray
      Row {
        spacing: 6
        anchors.verticalCenter: parent.verticalCenter
        Repeater {
          id: trayRepeater
          model: SystemTray.items
          delegate: Rectangle {
            width: 42
            height: 42
            radius: 12
            color: trayMouseArea.containsMouse ? "rgba(255,255,255,0.15)" : "transparent"
            
            property var iconSource: {
              if (!modelData.icon) return "";
              var i = String(modelData.icon);
              if (i.startsWith("file:") || i.startsWith("image://") || i.startsWith("/")) return i;
              return "image://icon/" + i;
            }
            
            Image {
              anchors.centerIn: parent
              width: 22
              height: 22
              source: iconSource
              smooth: true
            }
            
            MouseArea {
              id: trayMouseArea
              anchors.fill: parent
              hoverEnabled: true
              acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
              onClicked: (mouse) => {
                var pos = mapToGlobal(mouse.x, mouse.y);
                if (mouse.button === Qt.LeftButton) {
                  if (modelData.activate.length === 2) {
                    modelData.activate(pos.x, pos.y);
                  } else {
                    modelData.activate();
                  }
                } else if (mouse.button === Qt.RightButton) {
                  if (menuAnchor.menu) menuAnchor.open();
                  else if (modelData.secondaryActivate) modelData.secondaryActivate();
                } else if (mouse.button === Qt.MiddleButton) {
                  // Middle click force-kills the app using its title
                  var appName = modelData.tooltipTitle || modelData.id || "";
                  if (appName) {
                    // Extract base name if id has "_status_icon" suffix
                    appName = appName.replace(/_status_icon.*/, "");
                    root.execCmd("pkill -fi \\\"" + appName + "\\\"");
                  }
                }
              }
              onDoubleClicked: (mouse) => {
                var pos = mapToGlobal(mouse.x, mouse.y);
                if (mouse.button === Qt.LeftButton) {
                  if (modelData.activate.length === 2) {
                    modelData.activate(pos.x, pos.y);
                  } else {
                    modelData.activate();
                  }
                }
              }
            }
            
            QsMenuAnchor {
              id: menuAnchor
              menu: modelData.menu
              anchor.item: parent
            }
          }
        }
      }
    }
  }
}
}
}
