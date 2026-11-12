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
    duration: 240
    easing.type: Easing.OutCubic
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
      implicitHeight: resultsModel.count > 0
        ? 105 + Math.min(resultsModel.count, 6) * 56
        : 96
      Behavior on implicitHeight {
        NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
      }

      visible: root.windowVisible
      color: "transparent"

      WlrLayershell.layer: WlrLayer.Overlay
      WlrLayershell.namespace: "qs-spotlight"
      WlrLayershell.keyboardFocus: root.isVisible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
      
      Rectangle {
        id: spotlightSurface
        anchors.fill: parent
        color: Qt.rgba(root.themeSurface.r, root.themeSurface.g, root.themeSurface.b, 0.985)
        radius: 24
        border.color: root.ink(0.12)
        border.width: 1
        opacity: root.reveal
        transform: Translate { y: (1 - root.reveal) * 6 }

        ColumnLayout {
          anchors.fill: parent
          anchors.margins: 20
          spacing: 8

          RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 56
            spacing: 12

            Text {
              Layout.alignment: Qt.AlignVCenter
              text: "\uef7a"
              color: root.currentQuery.length > 0 ? root.themeAccent : root.ink(0.62)
              font.family: "Material Symbols Rounded"
              font.pixelSize: 24
            }

            TextField {
              id: searchInput
              Layout.fillWidth: true
              Layout.alignment: Qt.AlignVCenter
              font.pixelSize: 22
              font.family: "Google Sans Flex"
              placeholderText: "Search apps and files"
              placeholderTextColor: root.ink(0.48)
              color: root.themeFg
              selectionColor: root.accent(0.30)
              selectedTextColor: root.themeFg
              background: Item {}
              verticalAlignment: TextInput.AlignVCenter
              selectByMouse: true
              padding: 0

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
              Layout.alignment: Qt.AlignVCenter
              width: 34
              height: 22
              radius: 6
              color: root.ink(0.06)
              border.width: 1
              border.color: root.ink(0.12)

              Text {
                anchors.centerIn: parent
                text: "esc"
                color: root.ink(0.66)
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 10
              }
            }
          }

          Rectangle {
            Layout.fillWidth: true
            height: 1
            color: root.ink(0.09)
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
              id: resultRow
              width: resultList.width
              height: 56
              radius: 12
              color: resultList.currentIndex === index
                ? root.accent(0.14)
                : (rowArea.containsMouse ? root.ink(0.04) : "transparent")
              Behavior on color { ColorAnimation { duration: 110 } }

              RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                spacing: 14

                IconImage {
                  width: 28
                  height: 28
                  source: Quickshell.iconPath(model.icon, true)
                  asynchronous: true
                }

                ColumnLayout {
                  Layout.fillWidth: true
                  spacing: 1

                  Text {
                    Layout.fillWidth: true
                    text: model.name
                    color: root.themeFg
                    font.family: "Google Sans Flex"
                    font.pixelSize: 15
                    font.weight: Font.Medium
                    elide: Text.ElideRight
                  }

                  Text {
                    Layout.fillWidth: true
                    text: model.type === "app" ? model.exec : model.path
                    color: root.ink(0.64)
                    font.family: "Google Sans Flex"
                    font.pixelSize: 12
                    elide: Text.ElideRight
                  }
                }
              }

              MouseArea {
                id: rowArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
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
