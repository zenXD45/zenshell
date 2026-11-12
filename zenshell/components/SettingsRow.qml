import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Effects
import QtQuick.Layouts

// One setting row: a title and a description on the left, the control on
// the right. Every control type the settings menu needs lives here so the
// pages only have to describe what they want, never how it looks.
Item {
    id: row

    // The row descriptor. See the catalog in SettingsWindow.qml for the
    // shape: { id, type, label, desc, options, min, max, step, ... }
    property var spec: null
    property var value: null
    property color accent: root.themeAccent
    readonly property color muted: root.cOnSurfaceVariant
    property bool hovered: false
    // The window that owns the row. The dropdown needs it to know where the
    // bottom of the screen is so the list can open upwards near the edge.
    property var hostWindow: null

    // Mirrors the popup's open state so the trigger can stay highlighted.
    readonly property bool dropdownOpen: dropMenu.opened

    // Emitted when the user picks a new value. The parent turns it into a
    // root.setValue() call so every write goes through one door.
    signal picked(var v)

    implicitHeight: 58
    implicitWidth: 1

    readonly property bool hasDesc: row.spec && row.spec.desc !== undefined && row.spec.desc !== "";

    // A state layer behind the whole row, like a Material list item. The
    // HoverHandler only observes the pointer, so it never steals clicks from
    // the switch, slider or dropdown that sit on top of it.
    Rectangle {
        anchors.fill: parent
        anchors.margins: 2
        radius: root.rMd
        color: row.hovered ? root.cStateHover : "transparent"
        Behavior on color { ColorAnimation { duration: root.dMicro } }
    }

    HoverHandler {
        onHoveredChanged: row.hovered = hovered
    }

    // ── Toggle ────────────────────────────────────────────────────
    Rectangle {
        id: toggle
        visible: row.spec && row.spec.type === "toggle"
        width: 44
        height: 24
        radius: 12
        // The switch belongs on the right edge of the row, opposite the
        // label. Without these anchors it sat at (0,0) and covered the
        // title text.
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        color: row.value === true ? root.cPrimary : root.cSurfaceContainerHighest
        border.width: row.value === true ? 0 : 1
        border.color: root.cOutline
        Behavior on color { ColorAnimation { duration: 150 } }

        Rectangle {
            width: 18
            height: 18
            radius: 9
            y: 3
            x: row.value === true ? 23 : 3
            color: row.value === true ? root.cOnPrimary : root.cOutline
            Behavior on x { NumberAnimation { duration: 170; easing.type: Easing.OutCubic } }
            Behavior on color { ColorAnimation { duration: 150 } }
        }
    }

    MouseArea {
        id: toggleHit
        visible: toggle.visible
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        width: toggle.width
        height: toggle.height + 18
        cursorShape: Qt.PointingHandCursor
        onClicked: row.picked(row.value !== true)
    }

    // ── Segmented control ─────────────────────────────────────────
    Row {
        id: segment
        visible: row.spec && row.spec.type === "segment"
        spacing: 6
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter

        Repeater {
            model: row.spec && row.spec.options ? row.spec.options : []

            delegate: Rectangle {
                id: chip
                required property var modelData

                readonly property bool selected: String(row.value) === String(modelData.value)

                height: 32
                width: Math.max(56, chipLabel.implicitWidth + 24)
                radius: 8
                color: selected
                    ? root.cSecondaryContainer
                    : (chipMouse.containsMouse ? root.cSurfaceContainerHighest : root.cSurfaceContainerHigh)
                Behavior on color { ColorAnimation { duration: 140 } }

                Text {
                    id: chipLabel
                    anchors.centerIn: parent
                    text: chip.modelData.label
                    color: chip.selected ? root.cOnSecondaryContainer : root.cOnSurfaceVariant
                    font.family: root.fontSans
                    font.pixelSize: 12
                    font.weight: Font.Medium
                }

                MouseArea {
                    id: chipMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: row.picked(chip.modelData.value)
                }
            }
        }
    }

    // ── Slider ────────────────────────────────────────────────────
    Item {
        id: slider
        visible: row.spec && row.spec.type === "slider"
        width: 168
        height: 24
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter

        readonly property real min: row.spec && row.spec.min !== undefined ? row.spec.min : 0
        readonly property real max: row.spec && row.spec.max !== undefined ? row.spec.max : 1
        readonly property real step: row.spec && row.spec.step !== undefined ? row.spec.step : 0.05
        readonly property real current: row.value !== null && row.value !== undefined ? row.value : min

        function valueToX(v) {
            if (max === min) return 0;
            return ((v - min) / (max - min)) * (width - knob.width);
        }

        function setFromX(x) {
            var travel = width - knob.width;
            if (travel <= 0) return;
            var t = Math.max(0, Math.min(1, (x - knob.width / 2) / travel));
            var raw = min + t * (max - min);
            var snapped = Math.round(raw / step) * step;
            snapped = Math.max(min, Math.min(max, snapped));
            snapped = Math.round(snapped * 1000) / 1000;
            if (snapped !== current) row.picked(snapped);
        }

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width
            height: 4
            radius: 2
            color: root.cSurfaceContainerHighest

            Rectangle {
                width: Math.max(0, Math.min(parent.width, slider.valueToX(slider.current) + knob.width / 2))
                height: parent.height
                radius: parent.radius
                color: root.cPrimary
                Behavior on width { NumberAnimation { duration: 90 } }
            }
        }

        Rectangle {
            id: knob
            width: 18
            height: 18
            radius: 9
            y: (parent.height - height) / 2
            x: Math.max(0, Math.min(parent.width - width, slider.valueToX(slider.current)))
            color: root.cPrimary
            border.width: 2
            border.color: root.cSurface
            scale: sliderArea.containsMouse ? 1.12 : 1.0
            Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
            Behavior on x { NumberAnimation { duration: 90 } }
        }

        MouseArea {
            id: sliderArea
            anchors.fill: parent
            anchors.margins: -8
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onPressed: slider.setFromX(mouse.x)
            onPositionChanged: if (pressed) slider.setFromX(mouse.x)
        }
    }

    Text {
        id: sliderValue
        visible: slider.visible
        anchors.right: slider.left
        anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        text: {
            if (row.value === null || row.value === undefined) return "";
            var suffix = row.spec && row.spec.unit !== undefined ? row.spec.unit : "";
            return (Math.round(row.value * 100) / 100) + suffix;
        }
        color: root.cOnSurfaceVariant
        font.family: root.fontSans
        font.pixelSize: 12
        font.weight: Font.Medium
    }

    // ── Checklist ─────────────────────────────────────────────────
    GridLayout {
        id: checklist
        visible: row.spec && row.spec.type === "checklist"
        columns: 2
        columnSpacing: 6
        rowSpacing: 6
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter

        Repeater {
            model: row.spec && row.spec.options ? row.spec.options : []

            delegate: Rectangle {
                id: optionBox
                required property var modelData

                readonly property bool checked: row.value && row.value.indexOf(modelData.value) !== -1

                Layout.preferredWidth: 156
                Layout.preferredHeight: 34
                radius: 8
                color: checked
                    ? root.cSecondaryContainer
                    : (optionMouse.containsMouse ? root.cSurfaceContainerHighest : root.cSurfaceContainerHigh)
                Behavior on color { ColorAnimation { duration: 140 } }

                Row {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    spacing: 8

                    Rectangle {
                        width: 16
                        height: 16
                        radius: 4
                        anchors.verticalCenter: parent.verticalCenter
                        color: optionBox.checked ? root.cPrimary : "transparent"
                        border.width: optionBox.checked ? 0 : 1
                        border.color: root.cOutline

                        Text {
                            anchors.centerIn: parent
                            visible: optionBox.checked
                            text: root.icoCheck
                            color: root.cOnPrimary
                            font.family: root.fontIcon
                            font.pixelSize: 12
                        }
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        width: Math.min(implicitWidth, 104)
                        text: optionBox.modelData.label
                        color: optionBox.checked ? root.cOnSecondaryContainer : root.cOnSurfaceVariant
                        font.family: root.fontSans
                        font.pixelSize: 12
                        font.weight: Font.Medium
                        elide: Text.ElideRight
                    }
                }

                MouseArea {
                    id: optionMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        var current = row.value ? row.value.slice() : [];
                        var at = current.indexOf(optionBox.modelData.value);
                        if (at === -1) current.push(optionBox.modelData.value);
                        else current.splice(at, 1);
                        row.picked(current);
                    }
                }
            }
        }
    }

    // ── Dropdown ──────────────────────────────────────────────────
    Item {
        id: dropdown
        visible: row.spec && row.spec.type === "dropdown"
        width: 220
        height: 40
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter

        readonly property var options: row.spec && row.spec.options ? row.spec.options : []
        readonly property int itemHeight: 40
        readonly property int menuHeight: Math.min(options.length * itemHeight + 10, 320)

        readonly property string currentLabel: {
            if (!row.value) return "Not set";
            var needle = String(row.value).replace(/@.*$/, "").replace(/\.desktop$/, "");
            for (var i = 0; i < dropdown.options.length; i++) {
                var candidate = String(dropdown.options[i].value).replace(/@.*$/, "").replace(/\.desktop$/, "");
                if (candidate === needle) {
                    return dropdown.options[i].label;
                }
            }
            // The stored association is not in the filtered list (a role with
            // no matching application, or an app that was uninstalled). Show
            // the id without its file suffix rather than raw "name.desktop".
            return needle;
        }

        function toggle() {
            if (dropMenu.opened) dropMenu.close();
            else dropMenu.open();
        }

        function selectedIndex() {
            var needle = String(row.value || "").replace(/@.*$/, "").replace(/\.desktop$/, "");
            if (needle === "") return -1;
            for (var i = 0; i < dropdown.options.length; i++) {
                var candidate = String(dropdown.options[i].value).replace(/@.*$/, "").replace(/\.desktop$/, "");
                if (candidate === needle) return i;
            }
            return -1;
        }

        Rectangle {
            id: dropButton
            anchors.fill: parent
            radius: 12
            color: row.dropdownOpen
                ? root.cSurfaceContainerHighest
                : (dropMouse.containsMouse ? root.cSurfaceContainerHighest : root.cSurfaceContainerHigh)
            border.width: row.dropdownOpen ? 2 : 1
            border.color: row.dropdownOpen ? root.cPrimary : root.cOutlineVariant
            Behavior on color { ColorAnimation { duration: 140 } }
            Behavior on border.color { ColorAnimation { duration: 140 } }

            Text {
                anchors.left: parent.left
                anchors.leftMargin: 14
                anchors.right: chevron.left
                anchors.rightMargin: 6
                anchors.verticalCenter: parent.verticalCenter
                text: dropdown.currentLabel
                color: root.cOnSurface
                font.family: root.fontSans
                font.pixelSize: 13
                font.weight: Font.Medium
                elide: Text.ElideRight
            }

            Text {
                id: chevron
                anchors.right: parent.right
                anchors.rightMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                text: root.icoChevronRight
                color: root.cOnSurfaceVariant
                font.family: root.fontIcon
                font.pixelSize: 18
                rotation: row.dropdownOpen ? 270 : 90
                Behavior on rotation { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
            }

            MouseArea {
                id: dropMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: dropdown.toggle()
            }
        }

        // A Popup lives in the window's overlay, not in the row's layout.
        // The old in-row list was a child of the row, so QML kept it under
        // every row painted after it — the next row's trigger drew straight
        // through the open menu. The overlay also means the list is no
        // longer clipped by the settings page's Flickable.
        Controls.Popup {
            id: dropMenu
            parent: dropdown
            popupType: Controls.Popup.Item
            width: dropdown.width
            height: dropdown.menuHeight
            padding: 5
            closePolicy: Controls.Popup.CloseOnEscape | Controls.Popup.CloseOnPressOutsideParent

            // Open below the trigger, or above it when the row is too close
            // to the bottom of the window for the list to fit.
            onAboutToShow: {
                var anchor = dropdown.mapToItem(null, 0, 0);
                var windowHeight = row.hostWindow ? row.hostWindow.height : 900;
                var below = anchor.y + dropdown.height + 6;
                dropMenu.y = (below + dropMenu.height <= windowHeight - 8)
                    ? dropdown.height + 6
                    : -dropMenu.height - 6;
            }

            // A long application list should open at the current choice, not
            // at "A" with the selected row several screens down.
            onOpened: {
                var index = dropdown.selectedIndex();
                if (index >= 0) menuList.positionViewAtIndex(index, ListView.Center);
            }

            enter: Transition {
                NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 110; easing.type: Easing.OutCubic }
            }
            exit: Transition {
                NumberAnimation { property: "opacity"; from: 1; to: 0; duration: 80; easing.type: Easing.InCubic }
            }

            background: Item {
                RectangularShadow {
                    anchors.fill: panel
                    radius: panel.radius
                    color: "#80000000"
                    blur: 26
                    spread: 1
                    offset: Qt.vector2d(0, 6)
                }

                Rectangle {
                    id: panel
                    anchors.fill: parent
                    radius: 12
                    // Opaque on purpose: an overlay menu that lets the row
                    // underneath ghost through reads as a rendering bug.
                    color: root.cSurfaceContainerHigh
                    border.width: 1
                    border.color: root.cOutlineVariant
                }
            }

            contentItem: ListView {
                id: menuList
                clip: true
                model: dropdown.options
                boundsBehavior: Flickable.StopAtBounds
                interactive: contentHeight > height

                Controls.ScrollBar.vertical: Controls.ScrollBar {
                    id: menuScroll
                    width: 4
                    policy: Controls.ScrollBar.AsNeeded
                    background: Item {}
                    contentItem: Rectangle {
                        implicitWidth: 4
                        radius: 2
                        color: root.ink(0.24)
                        visible: menuScroll.size < 1
                    }
                }

                delegate: Rectangle {
                    id: dropItem
                    required property var modelData

                    readonly property bool selected: {
                        var needle = String(row.value || "").replace(/@.*$/, "").replace(/\.desktop$/, "");
                        var candidate = String(modelData.value).replace(/@.*$/, "").replace(/\.desktop$/, "");
                        return needle !== "" && needle === candidate;
                    }

                    width: ListView.view.width
                    height: dropdown.itemHeight
                    radius: 8
                    color: dropItem.selected
                        ? root.cSecondaryContainer
                        : (itemMouse.containsMouse ? root.cStateHover : "transparent")

                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 12
                        anchors.right: checkMark.left
                        anchors.rightMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        text: dropItem.modelData.label
                        color: dropItem.selected ? root.cOnSecondaryContainer : root.cOnSurface
                        font.family: root.fontSans
                        font.pixelSize: 13
                        font.weight: dropItem.selected ? Font.DemiBold : Font.Medium
                        elide: Text.ElideRight
                    }

                    Text {
                        id: checkMark
                        anchors.right: parent.right
                        anchors.rightMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        visible: dropItem.selected
                        text: root.icoCheck
                        color: root.cPrimary
                        font.family: root.fontIcon
                        font.pixelSize: 16
                    }

                    MouseArea {
                        id: itemMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            dropMenu.close();
                            row.picked(dropItem.modelData.value);
                        }
                    }
                }
            }
        }
    }

    // ── Action button ─────────────────────────────────────────────
    Rectangle {
        id: actionButton
        visible: row.spec && row.spec.type === "action"
        width: Math.max(88, actionLabel.implicitWidth + 28)
        height: 36
        radius: 18
        color: actionMouse.containsMouse
            ? root.mixColor(root.cPrimaryContainer, root.cPrimary, 0.14)
            : root.cPrimaryContainer
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        Behavior on color { ColorAnimation { duration: 140 } }

        Text {
            id: actionLabel
            anchors.centerIn: parent
            text: row.spec && row.spec.actionLabel ? row.spec.actionLabel : "Open"
            color: root.cOnPrimaryContainer
            font.family: root.fontSans
            font.pixelSize: 12
            font.weight: Font.DemiBold
        }

        MouseArea {
            id: actionMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: row.picked("__action__")
        }
    }

    // ── Label / description ───────────────────────────────────────
    // A plain Column rather than a ColumnLayout: the column is anchored
    // directly, so giving the texts a definite width keeps the description
    // from collapsing to nothing.
    Column {
        anchors.left: parent.left
        anchors.right: controlLeftEdge.left
        anchors.rightMargin: 22
        anchors.verticalCenter: parent.verticalCenter
        spacing: 3

        Text {
            width: parent.width
            text: row.spec && row.spec.label ? row.spec.label : ""
            color: root.cOnSurface
            font.family: root.fontSans
            font.pixelSize: 14
            font.weight: Font.Medium
            elide: Text.ElideRight
        }

        Text {
            width: parent.width
            visible: row.hasDesc
            text: row.spec && row.spec.desc ? row.spec.desc : ""
            color: row.muted
            font.family: root.fontSans
            font.pixelSize: 12
            font.weight: Font.Normal
            elide: Text.ElideRight
        }
    }

    // A spacer that reserves the width of whatever control the row uses,
    // so the label never runs underneath it.
    Item {
        id: controlLeftEdge
        anchors.right: parent.right
        width: {
            if (!row.spec) return 0;
            switch (row.spec.type) {
                case "toggle": return toggle.width;
                case "segment": return segment.width;
                case "slider": return slider.width + (sliderValue.implicitWidth > 0 ? sliderValue.implicitWidth + 12 : 0);
                case "checklist": return checklist.width;
                case "dropdown": return dropdown.width;
                case "action": return actionButton.width;
                default: return 0;
            }
        }
        height: 1
    }
}
