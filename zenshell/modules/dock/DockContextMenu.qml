import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import QtQuick
import Qt5Compat.GraphicalEffects

PanelWindow {
  id: menu

  property bool menuVisible: false
  property var appData: null
  property var contextScreen: null
  property real anchorScreenX: 0
  property real anchorScreenY: 0
  property string menuMode: "app"
  property color accent: root.ink(0.94)
  property string uiFont: "Google Sans Flex"
  property string iconFont: "JetBrainsMono Nerd Font"
  property bool dockAutoHide: true
  property bool dockLiquid: true
  property int pinnedCount: 0
  property int runningCount: 0

  readonly property color cSurface: root.themeSurface
  readonly property color cSurfaceHigh: Qt.lighter(root.themeSurface, 1.10)
  readonly property color cOnSurface: root.themeFg
  readonly property color cOnSurfaceVariant: root.ink(0.72)
  readonly property color cOutlineVariant: root.ink(0.105)
  readonly property color cPrimary: root.themeAccent
  readonly property color cError: root.themeExtra

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

    Item {
      id: menuSurface
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
      opacity: menu.menuVisible ? 1 : 0
      scale: menu.menuVisible ? 1 : 0.97
      transformOrigin: Item.Bottom
      transform: Translate { y: (1 - menuSurface.opacity) * 8 }

      Behavior on opacity {
        NumberAnimation {
          duration: menu.menuVisible ? 150 : 110
          easing.type: Easing.OutCubic
        }
      }
      Behavior on scale {
        NumberAnimation {
          duration: menu.menuVisible ? 180 : 130
          easing.type: Easing.OutCubic
        }
      }

      // Context menu shadow stack — true rounded-rect shadows via layered blur
      Item {
        id: menuShadowStack
        anchors.fill: surface
        y: 18

        // AO pool (wider, softer)
        Rectangle {
          anchors.fill: parent
          radius: 16
          color: "#26000000"
          anchors.margins: -12
          layer.enabled: true
          layer.effect: FastBlur { radius: 28; transparentBorder: true }
        }

        // Key shadow (tighter)
        Rectangle {
          anchors.fill: parent
          radius: 16
          color: "#40000000"
          anchors.margins: -6
          layer.enabled: true
          layer.effect: FastBlur { radius: 16; transparentBorder: true }
        }
      }

      Rectangle {
        id: surface
        anchors.fill: parent
        radius: 16
        color: Qt.rgba(menu.cSurface.r, menu.cSurface.g, menu.cSurface.b, 0.985)
        border.width: 1
        border.color: menu.cOutlineVariant

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
            radius: 12
            color: menu.cSurfaceHigh
            border.width: 1
            border.color: menu.cOutlineVariant

            IconImage {
              id: appIcon
              anchors.centerIn: parent
              width: 26
              height: 26
              source: menu.menuMode === "app" && menu.appData
                ? Quickshell.iconPath(menu.appData.icon || menu.appData.id, true)
                : ""
              asynchronous: true
              visible: status === Image.Ready
            }

            Text {
              anchors.centerIn: parent
              visible: menu.menuMode === "dock" || appIcon.status !== Image.Ready
              text: menu.menuMode === "dock"
                ? "\uF009"
                : (menu.appData && menu.appData.id ? menu.appData.id.charAt(0).toUpperCase() : "?")
              color: menu.cOnSurfaceVariant
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
              color: menu.cOnSurface
              font.family: menu.uiFont
              font.pixelSize: 14
              font.weight: Font.DemiBold
              elide: Text.ElideRight
              maximumLineCount: 1
            }

            Text {
              width: parent.width
              text: menu.appMeta()
              color: menu.cOnSurfaceVariant
              font.family: menu.uiFont
              font.pixelSize: 11
              font.weight: Font.Medium
              elide: Text.ElideRight
              maximumLineCount: 1
            }
          }
        }

        Rectangle {
          width: parent.width
          height: 1
          color: menu.cOutlineVariant
        }

        Repeater {
          model: menu.actions

          delegate: Item {
            id: actionItem
            required property var modelData
            required property int index
            width: contentColumn.width
            height: 40 + (modelData.separatorBefore ? 8 : 0)

            Rectangle {
              id: actionRow
              width: parent.width
              height: 40
              y: modelData.separatorBefore ? 8 : 0
              radius: 12
              color: {
                if (modelData.danger && (mouse.containsMouse || (menu.keyboardActive && menu.currentIndex === index)))
                  return Qt.rgba(menu.cError.r, menu.cError.g, menu.cError.b, 0.16);
                if (mouse.containsMouse || (menu.keyboardActive && menu.currentIndex === index))
                  return root.ink(0.06);
                return "transparent";
              }
              opacity: modelData.disabled === true ? 0.38 : 1.0

              Behavior on color { ColorAnimation { duration: 100 } }

              Text {
                id: actionGlyph
                x: 12
                anchors.verticalCenter: parent.verticalCenter
                width: 20
                text: modelData.glyph
                color: modelData.danger ? menu.cError : menu.cOnSurfaceVariant
                font.family: menu.iconFont
                font.pixelSize: 15
                horizontalAlignment: Text.AlignHCenter
              }

              Text {
                anchors {
                  left: actionGlyph.right
                  leftMargin: 12
                  right: actionHint.left
                  rightMargin: modelData.checked !== undefined ? 48 : 10
                  verticalCenter: parent.verticalCenter
                }
                text: modelData.label
                color: modelData.danger ? menu.cError : menu.cOnSurface
                font.family: menu.uiFont
                font.pixelSize: 13
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
                visible: modelData.checked === undefined
                text: modelData.hint || ""
                color: menu.cOnSurfaceVariant
                font.family: menu.uiFont
                font.pixelSize: 10
                font.weight: Font.Medium
              }

              Rectangle {
                visible: modelData.checked !== undefined
                width: 32
                height: 18
                radius: 9
                anchors {
                  right: parent.right
                  rightMargin: 10
                  verticalCenter: parent.verticalCenter
                }
                color: modelData.checked === true
                  ? menu.cPrimary
                  : root.ink(0.14)
                border.width: modelData.checked === true ? 0 : 1
                border.color: menu.cOutlineVariant

                Rectangle {
                  width: 14
                  height: 14
                  radius: 7
                  y: 2
                  x: modelData.checked === true ? 16 : 2
                  color: modelData.checked === true ? root.themeBg : menu.cOnSurfaceVariant
                  Behavior on x { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
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
            width: 28
            height: 20
            radius: 6
            color: root.ink(0.07)
            border.width: 1
            border.color: menu.cOutlineVariant
            Text {
              anchors.centerIn: parent
              text: "esc"
              color: menu.cOnSurfaceVariant
              font.family: menu.uiFont
              font.pixelSize: 9
              font.weight: Font.Medium
            }
          }

          Text {
            anchors {
              left: parent.left
              leftMargin: 46
              verticalCenter: parent.verticalCenter
            }
            text: "close"
            color: menu.cOnSurfaceVariant
            font.family: menu.uiFont
            font.pixelSize: 10
          }
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
