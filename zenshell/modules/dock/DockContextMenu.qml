import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import QtQuick

PanelWindow {
  id: menu

  property bool menuVisible: false
  property var appData: null
  property var contextScreen: null
  property real anchorScreenX: 0
  property real anchorScreenY: 0
  property string menuMode: "app"
  property color accent: root.ink(0.949)
  property string uiFont: "Google Sans Flex"
  property string iconFont: "JetBrainsMono Nerd Font"
  property bool dockAutoHide: true
  property bool dockLiquid: true
  property int pinnedCount: 0
  property int runningCount: 0

  readonly property int surfaceWidth: 250
  readonly property int surfaceHeight: contentColumn.implicitHeight + 16

  signal actionTriggered(string actionId)
  signal menuClosed()

  property var actions: []
  property int currentIndex: 0
  property bool keyboardActive: false

  screen: contextScreen
  anchors {
    top: true
    bottom: true
    left: true
    right: true
  }
  color: "transparent"
  visible: false

  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.namespace: "qs-dock-menu"
  WlrLayershell.exclusiveZone: -1
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

  onMenuVisibleChanged: {
    if (menuVisible) {
      closeTimer.stop();
      visible = true;
      Qt.callLater(function() { focusScope.forceActiveFocus(); });
    } else if (visible) {
      closeTimer.restart();
    }
  }

  // Keep the layer mapped until the exit animation has finished. Hiding the
  // surface immediately made the menu disappear between frames.
  Timer {
    id: closeTimer
    interval: 170
    onTriggered: {
      if (!menu.menuVisible) {
        menu.visible = false;
        menu.menuClosed();
      }
    }
  }

  function showMenu() {
    if (!appData && menuMode !== "dock") return;
    if (!contextScreen) return;
    currentIndex = 0;
    keyboardActive = false;
    menuVisible = true;
  }

  function dismiss() {
    if (!menuVisible) return;
    menuVisible = false;
  }

  function trigger(actionId) {
    menu.actionTriggered(actionId);
    dismiss();
  }

  function moveSelection(delta) {
    if (actions.length === 0) return;
    var next = currentIndex;
    for (var i = 0; i < actions.length; i++) {
      next = (next + delta + actions.length) % actions.length;
      if (!actions[next].disabled) {
        currentIndex = next;
        keyboardActive = true;
        return;
      }
    }
  }

  function buildAppActions() {
    if (!appData) return [];
    var app = appData;
    var actions = [];
    actions.push({
      id: app.isOpen ? "focus" : "open",
      label: app.isOpen ? "Focus window" : "Open",
      glyph: app.isOpen ? "\uF06E" : "\uF04B",
      hint: app.isOpen ? "" : "Launch"
    });
    actions.push({
      id: "new-window",
      label: "New window",
      glyph: "\uF055"
    });
    if (app.isOpen && app.count > 1) {
      actions.push({
        id: "next-window",
        label: "Next window",
        glyph: "\uF061",
        hint: "scroll"
      });
    }

    actions.push({
      id: app.isPinned ? "unpin" : "pin",
      label: app.isPinned ? "Unpin from dock" : "Pin to dock",
      glyph: "\uF08D",
      separatorBefore: true
    });

    if (app.isPinned) {
      actions.push({
        id: "move-left",
        label: "Move left",
        glyph: "\uF060",
        disabled: app.pinnedIndex <= 0
      });
      actions.push({
        id: "move-right",
        label: "Move right",
        glyph: "\uF061",
        disabled: app.pinnedIndex < 0 || app.pinnedIndex >= pinnedCount - 1
      });
    }

    if (app.isOpen) {
      actions.push({
        id: "close-windows",
        label: app.count > 1 ? "Close " + app.count + " windows" : "Close window",
        glyph: "\uF00D",
        danger: true,
        separatorBefore: true
      });
    }
    return actions;
  }

  function buildDockActions() {
    return [
      {
        id: "toggle-autohide",
        label: "Auto-hide dock",
        glyph: dockAutoHide ? "\uF070" : "\uF06E",
        hint: dockAutoHide ? "" : "Off",
        checked: dockAutoHide
      },
      {
        id: "toggle-theme",
        label: "Liquid glass",
        glyph: "\uF53F",
        hint: dockLiquid ? "" : "Off",
        checked: dockLiquid
      }
    ];
  }

  function rebuildActions() {
    actions = menuMode === "dock" ? buildDockActions() : buildAppActions();
    if (currentIndex >= actions.length) currentIndex = Math.max(0, actions.length - 1);
  }

  function appTitle() {
    if (menuMode === "dock") return "Dock";
    return appData ? (appData.name || appData.id) : "Application";
  }

  function appMeta() {
    if (menuMode === "dock") {
      return pinnedCount + " pinned \u00B7 " + runningCount + " running";
    }
    if (!appData) return "";
    var pieces = [];
    if (appData.isPinned) pieces.push("Pinned");
    else if (appData.isOpen) pieces.push("Running");
    if (appData.isOpen) {
      pieces.push(appData.count + (appData.count === 1 ? " window" : " windows"));
    }
    return pieces.join(" \u00B7 ");
  }

  FocusScope {
    id: focusScope
    anchors.fill: parent
    focus: true

    Keys.onEscapePressed: menu.dismiss()
    Keys.onUpPressed: menu.moveSelection(-1)
    Keys.onDownPressed: menu.moveSelection(1)
    Keys.onReturnPressed: {
      if (menu.actions[menu.currentIndex]) menu.trigger(menu.actions[menu.currentIndex].id);
    }
    Keys.onEnterPressed: {
      if (menu.actions[menu.currentIndex]) menu.trigger(menu.actions[menu.currentIndex].id);
    }

    MouseArea {
      anchors.fill: parent
      acceptedButtons: Qt.AllButtons
      onClicked: menu.dismiss()
    }

    Rectangle {
      id: surface
      width: menu.surfaceWidth
      height: menu.surfaceHeight
      x: {
        var screenWidth = menu.contextScreen ? menu.contextScreen.width : menu.width;
        return Math.max(12, Math.min(menu.anchorScreenX - width / 2, screenWidth - width - 12));
      }
      y: {
        var screenHeight = menu.contextScreen ? menu.contextScreen.height : menu.height;
        var above = menu.anchorScreenY - height - 10;
        if (above >= 12) return above;
        return Math.min(menu.anchorScreenY + 10, screenHeight - height - 12);
      }
      radius: 16
      color: root.glass(0.98)
      border.width: 1
      border.color: root.ink(0.149)
      opacity: menu.menuVisible ? 1 : 0
      scale: menu.menuVisible ? 1 : 0.97
      transformOrigin: Item.Bottom
      transform: Translate { y: (1 - surface.opacity) * 8 }

      Behavior on opacity {
        NumberAnimation {
          duration: menu.menuVisible ? 150 : 110
          easing.type: menu.menuVisible ? Easing.OutExpo : Easing.OutCubic
        }
      }
      Behavior on scale {
        NumberAnimation {
          duration: menu.menuVisible ? 180 : 130
          easing.type: menu.menuVisible ? Easing.OutExpo : Easing.OutCubic
        }
      }

      MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.AllButtons
        onClicked: {}
      }

      Column {
        id: contentColumn
        anchors {
          left: parent.left
          right: parent.right
          top: parent.top
          margins: 8
        }
        spacing: 2

        Item {
          width: parent.width
          height: 54

          Rectangle {
            id: headerIcon
            x: 4
            anchors.verticalCenter: parent.verticalCenter
            width: 38
            height: 38
            radius: 11
            color: root.ink(0.078)
            border.width: 1
            border.color: root.ink(0.11)

            IconImage {
              id: appIcon
              anchors.centerIn: parent
              width: 26
              height: 26
              source: menu.menuMode === "app" && menu.appData
                ? Quickshell.iconPath(menu.appData.icon || menu.appData.id, true)
                : ""
              visible: status === Image.Ready
            }

            Text {
              anchors.centerIn: parent
              visible: menu.menuMode === "dock" || appIcon.status !== Image.Ready
              text: menu.menuMode === "dock"
                ? "\uF009"
                : (menu.appData && menu.appData.id ? menu.appData.id.charAt(0).toUpperCase() : "?")
              color: menu.accent
              font.family: menu.iconFont
              font.pixelSize: menu.menuMode === "dock" ? 16 : 18
              font.weight: Font.DemiBold
            }
          }

          Column {
            anchors {
              left: headerIcon.right
              leftMargin: 11
              right: parent.right
              rightMargin: 4
              verticalCenter: parent.verticalCenter
            }
            spacing: 2

            Text {
              width: parent.width
              text: menu.appTitle()
              color: menu.accent
              font.family: menu.uiFont
              font.pixelSize: 14
              font.weight: Font.DemiBold
              elide: Text.ElideRight
              maximumLineCount: 1
            }

            Text {
              width: parent.width
              text: menu.appMeta()
              color: root.ink(0.651)
              font.family: menu.uiFont
              font.pixelSize: 10
              font.weight: Font.Medium
              elide: Text.ElideRight
              maximumLineCount: 1
            }
          }
        }

        Rectangle {
          width: parent.width
          height: 1
          color: root.ink(0.086)
        }

        Repeater {
          model: menu.actions

          delegate: Item {
            id: actionItem
            required property var modelData
            required property int index
            width: contentColumn.width
            height: modelData.separatorBefore ? 39 : 34

            Rectangle {
              width: parent.width
              height: 1
              y: 4
              color: root.ink(0.078)
              visible: !!modelData.separatorBefore
            }

            Rectangle {
              id: actionRow
              width: parent.width
              height: 34
              y: modelData.separatorBefore ? 5 : 0
              radius: 9
              color: {
                if (modelData.danger && (mouse.containsMouse || (menu.keyboardActive && menu.currentIndex === index))) return "#24FF6B5E";
                if (mouse.containsMouse || (menu.keyboardActive && menu.currentIndex === index)) return root.ink(0.086);
                return "transparent";
              }
              opacity: modelData.disabled === true ? 0.38 : 1.0

              Behavior on color { ColorAnimation { duration: 100 } }

              Text {
                id: actionGlyph
                x: 10
                anchors.verticalCenter: parent.verticalCenter
                width: 18
                text: modelData.glyph
                color: modelData.danger ? "#FFB4AB" : root.ink(0.839)
                font.family: menu.iconFont
                font.pixelSize: 12
                horizontalAlignment: Text.AlignHCenter
              }

              Text {
                anchors {
                  left: actionGlyph.right
                  leftMargin: 9
                  right: actionHint.left
                  rightMargin: modelData.checked ? 30 : 8
                  verticalCenter: parent.verticalCenter
                }
                text: modelData.label
                color: modelData.danger ? "#FFB4AB" : menu.accent
                font.family: menu.uiFont
                font.pixelSize: 12
                font.weight: Font.Medium
                elide: Text.ElideRight
                maximumLineCount: 1
              }

              Text {
                id: actionHint
                anchors {
                  right: parent.right
                  rightMargin: 10
                  verticalCenter: parent.verticalCenter
                }
                text: modelData.hint || ""
                color: root.ink(0.502)
                font.family: menu.uiFont
                font.pixelSize: 9
                font.weight: Font.Medium
              }

              Rectangle {
                visible: modelData.checked === true
                width: 14
                height: 14
                radius: 4
                anchors {
                  right: parent.right
                  rightMargin: 9
                  verticalCenter: parent.verticalCenter
                }
                color: root.ink(0.11)
                Text {
                  anchors.centerIn: parent
                  text: "\uF00C"
                  color: menu.accent
                  font.family: menu.iconFont
                  font.pixelSize: 8
                }
              }

              MouseArea {
                id: mouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: modelData.disabled ? Qt.ArrowCursor : Qt.PointingHandCursor
                enabled: !modelData.disabled
                onEntered: {
                  menu.currentIndex = index;
                  menu.keyboardActive = false;
                }
                onClicked: menu.trigger(modelData.id)
              }
            }
          }
        }

        Item {
          width: parent.width
          height: 28

          Rectangle {
            anchors {
              left: parent.left
              leftMargin: 10
              verticalCenter: parent.verticalCenter
            }
            width: 24
            height: 17
            radius: 5
            color: root.ink(0.078)
            Text {
              anchors.centerIn: parent
              text: "esc"
              color: root.ink(0.62)
              font.family: menu.uiFont
              font.pixelSize: 8
              font.weight: Font.Medium
            }
          }

          Text {
            anchors {
              left: parent.left
              leftMargin: 42
              verticalCenter: parent.verticalCenter
            }
            text: "close"
            color: root.ink(0.502)
            font.family: menu.uiFont
            font.pixelSize: 9
          }
        }
      }
    }
  }

  onAppDataChanged: {
    if (appData) currentIndex = 0;
    rebuildActions();
  }
  onMenuModeChanged: {
    currentIndex = 0;
    rebuildActions();
  }
  onDockAutoHideChanged: rebuildActions()
  onDockLiquidChanged: rebuildActions()
  onPinnedCountChanged: rebuildActions()
  Component.onCompleted: rebuildActions()
}
