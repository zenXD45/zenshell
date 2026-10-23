import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Widgets
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

Scope {
  id: root

  property bool isVisible: false

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
  property string currentQuery: ""

  // The layer stays mapped for the length of its exit animation. Hiding the
  // PanelWindow immediately made Spotlight vanish between frames.
  property bool windowVisible: false
  property real reveal: 0

  signal requestFocus()

  NumberAnimation {
    id: showAnim
    target: root
    property: "reveal"
    to: 1
    duration: 230
    easing.type: Easing.OutExpo
  }

  NumberAnimation {
    id: hideAnim
    target: root
    property: "reveal"
    to: 0
    duration: 150
    easing.type: Easing.OutCubic
  }

  Timer {
    id: hideTimer
    interval: 180
    onTriggered: {
      if (!root.isVisible) root.windowVisible = false;
    }
  }

  onIsVisibleChanged: {
    if (isVisible) {
      hideTimer.stop();
      hideAnim.stop();
      windowVisible = true;
      showAnim.restart();
      requestFocus();
    } else if (windowVisible) {
      showAnim.stop();
      hideAnim.restart();
      hideTimer.restart();
    }
  }

  IpcHandler {
    target: "qs-spotlight"
    function toggle(): void {
      root.isVisible = !root.isVisible;
    }
    function show(): void {
      root.isVisible = true;
    }
    function hide(): void {
      root.isVisible = false;
    }
  }

  function launchResult(item) {
    if (item.type === "app") {
      var execStr = item.exec.replace(/%[a-zA-Z]/g, "");
      Hyprland.dispatch("hl.dsp.exec_cmd([[" + execStr + "]])");
    } else {
      if (item.icon === "text-x-generic" || item.icon === "text-x-script" || item.path.indexOf(".config") !== -1 || item.path.indexOf(".bashrc") !== -1) {
        Hyprland.dispatch("hl.dsp.exec_cmd([[kitty -e nvim '" + item.path + "']])");
      } else {
        Hyprland.dispatch("hl.dsp.exec_cmd([[xdg-open '" + item.path + "']])");
      }
    }
    root.isVisible = false;
    root.currentQuery = "";
    resultsModel.clear();
  }

  ListModel {
    id: resultsModel
  }

  Process {
    id: searchProc
    command: [Quickshell.shellDir + "/search.py", root.currentQuery]
    running: false
    stdout: SplitParser {
      onRead: (data) => {
        try {
          var results = JSON.parse(data);
          resultsModel.clear();
          for (var i = 0; i < results.length; i++) {
            resultsModel.append(results[i]);
          }
          if (panel.resultListRef) {
            panel.resultListRef.currentIndex = 0;
          }
        } catch (e) {}
      }
    }
  }

  Timer {
    id: debounceTimer
    interval: 200
    repeat: false
    onTriggered: {
      if (root.currentQuery.length > 0) {
        searchProc.running = true;
      } else {
        resultsModel.clear();
      }
    }
  }

  onCurrentQueryChanged: {
    if (root.currentQuery.length === 0) {
      resultsModel.clear();
    }
    debounceTimer.restart();
  }

  Variants {
    model: [Quickshell.screens[0]]
    PanelWindow {
      id: panel
      required property var modelData
      screen: modelData
      
      property var resultListRef: resultList

      Connections {
        target: root
        function onRequestFocus() {
          Qt.callLater(function() {
            searchInput.forceActiveFocus();
            searchInput.selectAll();
          });
        }
      }

      implicitWidth: 700
      implicitHeight: 80 + (resultsModel.count > 0 ? (Math.min(resultsModel.count, 7) * 60 + 34) : 0)
      Behavior on implicitHeight {
        NumberAnimation { duration: 230; easing.type: Easing.OutExpo }
      }

      visible: root.windowVisible
      color: "transparent"

      WlrLayershell.layer: WlrLayer.Overlay
      WlrLayershell.namespace: "qs-spotlight"
      WlrLayershell.keyboardFocus: root.isVisible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
      
      Rectangle {
        id: spotlightSurface
        anchors.fill: parent
        color: "#35000000"
        radius: 16
        border.color: root.ink(0.188)
        border.width: 1
        opacity: root.reveal
        scale: 0.985 + root.reveal * 0.015
        transform: Translate { y: (1 - root.reveal) * 8 }

        ColumnLayout {
          anchors.fill: parent
          anchors.margins: 20
          spacing: 16

          TextField {
            id: searchInput
            Layout.fillWidth: true
            font.pixelSize: 26
            placeholderText: "Spotlight Search..."
            color: "white"
            background: Item {}
            
            text: root.currentQuery
            onTextEdited: root.currentQuery = text

            Keys.onPressed: (event) => {
              if (event.key === Qt.Key_Escape) {
                root.isVisible = false;
                event.accepted = true;
              } else if (event.key === Qt.Key_Down) {
                if (resultList.currentIndex < resultsModel.count - 1) {
                  resultList.currentIndex++;
                }
                event.accepted = true;
              } else if (event.key === Qt.Key_Up) {
                if (resultList.currentIndex > 0) {
                  resultList.currentIndex--;
                }
                event.accepted = true;
              } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                if (resultsModel.count > 0 && resultList.currentIndex >= 0) {
                  root.launchResult(resultsModel.get(resultList.currentIndex));
                }
                event.accepted = true;
              }
            }
          }

          Rectangle {
            Layout.fillWidth: true
            height: 1
            color: root.ink(0.251)
            visible: resultsModel.count > 0
          }

          ListView {
            id: resultList
            Layout.fillWidth: true
            Layout.fillHeight: true
            model: resultsModel
            clip: true
            visible: resultsModel.count > 0

            add: Transition {
              NumberAnimation {
                property: "opacity"
                from: 0
                to: 1
                duration: 170
                easing.type: Easing.OutCubic
              }
            }

            delegate: Rectangle {
              width: resultList.width
              height: 60
              color: resultList.currentIndex === index ? root.ink(0.251) : "transparent"
              radius: 8
              Behavior on color { ColorAnimation { duration: 120 } }
              
              RowLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 15
                
                IconImage {
                  width: 32
                  height: 32
                  source: Quickshell.iconPath(model.icon, true)
                }
                
                ColumnLayout {
                  Layout.fillWidth: true
                  spacing: 4
                  Text {
                    text: model.name
                    color: "white"
                    font.pixelSize: 18
                    font.bold: true
                  }
                  Text {
                    text: model.type === "app" ? model.exec : model.path
                    color: root.ink(0.65)
                    font.pixelSize: 12
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                  }
                }
              }
              
              MouseArea {
                anchors.fill: parent
                onClicked: {
                  resultList.currentIndex = index;
                  root.launchResult(resultsModel.get(index));
                }
              }
            }
          }
        }
      }
    }
  }
}
