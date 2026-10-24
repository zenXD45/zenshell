import QtQuick
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
    property bool hovered: false

    // Emitted when the user picks a new value. The parent turns it into a
    // root.setValue() call so every write goes through one door.
    signal picked(var v)

    implicitHeight: 58
    implicitWidth: 1

    // An open dropdown paints over the rows below it, so the row itself has
    // to be lifted in the stacking order while the list is showing.
    property bool dropdownOpen: false
    z: dropdownOpen ? 30 : 0

    readonly property bool hasDesc: row.spec && row.spec.desc !== undefined && row.spec.desc !== "";

    // ── Toggle ────────────────────────────────────────────────────
    Rectangle {
        id: toggle
        visible: row.spec && row.spec.type === "toggle"
        width: 38
        height: 22
        radius: 11
        // The switch belongs on the right edge of the row, opposite the
        // label. Without these anchors it sat at (0,0) and covered the
        // title text.
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        color: row.value === true ? row.accent : root.themeSurface
        border.width: 1
        border.color: row.value === true ? Qt.rgba(row.accent.r, row.accent.g, row.accent.b, 0.6) : root.ink(0.141)
        Behavior on color { ColorAnimation { duration: 150 } }

        Rectangle {
            width: 17
            height: 17
            radius: 8.5
            y: 2.5
            x: row.value === true ? 19 : 2
            color: root.themeFg
            Behavior on x { NumberAnimation { duration: 170; easing.type: Easing.OutCubic } }
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

                height: 30
                width: Math.max(52, chipLabel.implicitWidth + 22)
                radius: 9
                color: selected
                    ? Qt.rgba(row.accent.r, row.accent.g, row.accent.b, 0.16)
                    : (chipMouse.containsMouse ? root.ink(0.071) : root.ink(0.031))
                border.width: 1
                border.color: selected
                    ? Qt.rgba(row.accent.r, row.accent.g, row.accent.b, 0.45)
                    : (chipMouse.containsMouse ? root.ink(0.149) : root.ink(0.078))
                Behavior on color { ColorAnimation { duration: 140 } }
                Behavior on border.color { ColorAnimation { duration: 140 } }

                Text {
                    id: chipLabel
                    anchors.centerIn: parent
                    text: chip.modelData.label
                    color: chip.selected ? row.accent : root.cFgSecondary
                    font.family: root.fontSans
                    font.pixelSize: 11
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
            height: 5
            radius: 2.5
            color: root.ink(0.122)

            Rectangle {
                width: Math.max(0, slider.valueToX(slider.current))
                height: parent.height
                radius: parent.radius
                color: row.accent
                Behavior on width { NumberAnimation { duration: 90 } }
            }
        }

        Rectangle {
            id: knob
            width: 16
            height: 16
            radius: 8
            y: (parent.height - height) / 2
            x: Math.max(0, Math.min(parent.width - width, slider.valueToX(slider.current)))
            color: root.themeFg
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
        color: root.cFgSecondary
        font.family: root.fontSans
        font.pixelSize: 11
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

                Layout.preferredWidth: 152
                Layout.preferredHeight: 30
                radius: 9
                color: checked
                    ? Qt.rgba(row.accent.r, row.accent.g, row.accent.b, 0.12)
                    : (optionMouse.containsMouse ? root.ink(0.071) : root.ink(0.031))
                border.width: 1
                border.color: checked
                    ? Qt.rgba(row.accent.r, row.accent.g, row.accent.b, 0.40)
                    : (optionMouse.containsMouse ? root.ink(0.149) : root.ink(0.078))
                Behavior on color { ColorAnimation { duration: 140 } }
                Behavior on border.color { ColorAnimation { duration: 140 } }

                Row {
                    anchors.fill: parent
                    anchors.leftMargin: 9
                    anchors.rightMargin: 9
                    spacing: 7

                    Rectangle {
                        width: 14
                        height: 14
                        radius: 4
                        anchors.verticalCenter: parent.verticalCenter
                        color: optionBox.checked
                            ? Qt.rgba(row.accent.r, row.accent.g, row.accent.b, 0.22)
                            : "transparent"
                        border.width: 1
                        border.color: optionBox.checked
                            ? Qt.rgba(row.accent.r, row.accent.g, row.accent.b, 0.55)
                            : root.ink(0.188)

                        Text {
                            anchors.centerIn: parent
                            visible: optionBox.checked
                            text: "\uf00c"
                            color: row.accent
                            font.family: root.fontMono
                            font.pixelSize: 8
                        }
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        width: Math.min(implicitWidth, 104)
                        text: optionBox.modelData.label
                        color: optionBox.checked ? root.cFgPrimary : root.cFgSecondary
                        font.family: root.fontSans
                        font.pixelSize: 11
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
        width: 176
        height: 32
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter

        readonly property var options: row.spec && row.spec.options ? row.spec.options : []

        readonly property string currentLabel: {
            if (!row.value) return "";
            var needle = String(row.value).split("@")[0];
            for (var i = 0; i < dropdown.options.length; i++) {
                if (String(dropdown.options[i].value).split("@")[0] === needle) {
                    return dropdown.options[i].label;
                }
            }
            return String(row.value);
        }

        function toggle() {
            dropdownOpen = !dropdownOpen;
        }

        Rectangle {
            id: dropButton
            anchors.fill: parent
            radius: 9
            color: dropdownOpen
                ? Qt.rgba(row.accent.r, row.accent.g, row.accent.b, 0.14)
                : (dropMouse.containsMouse ? root.ink(0.071) : root.ink(0.031))
            border.width: 1
            border.color: dropdownOpen
                ? Qt.rgba(row.accent.r, row.accent.g, row.accent.b, 0.40)
                : (dropMouse.containsMouse ? root.ink(0.149) : root.ink(0.078))
            Behavior on color { ColorAnimation { duration: 140 } }

            Text {
                anchors.left: parent.left
                anchors.leftMargin: 12
                anchors.right: chevron.left
                anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                text: dropdown.currentLabel
                color: root.cFgPrimary
                font.family: root.fontSans
                font.pixelSize: 11
                font.weight: Font.Medium
                elide: Text.ElideRight
            }

            Text {
                id: chevron
                anchors.right: parent.right
                anchors.rightMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                text: "\uf078"
                color: root.cFgSecondary
                font.family: root.fontMono
                font.pixelSize: 9
            }

            MouseArea {
                id: dropMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: dropdown.toggle()
            }
        }

        Rectangle {
            id: dropList
            z: 40
            visible: dropdownOpen
            width: dropButton.width
            x: 0
            y: dropButton.height + 6
            height: Math.min(dropListView.count * 34 + 10, 240)
            radius: 12
            color: root.surface(0.94)
            border.width: 1
            border.color: root.ink(0.149)

            ListView {
                id: dropListView
                anchors.fill: parent
                anchors.margins: 5
                model: dropdown.options
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                interactive: dropList.height < dropListView.contentHeight

                delegate: Rectangle {
                    id: dropItem
                    required property var modelData

                    readonly property bool selected: String(row.value) === String(modelData.value)

                    width: dropListView.width
                    height: 34
                    radius: 8
                    color: dropMouse.containsMouse
                        ? Qt.rgba(row.accent.r, row.accent.g, row.accent.b, 0.18)
                        : "transparent"

                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 10
                        anchors.verticalCenter: parent.verticalCenter
                        text: dropItem.modelData.label
                        color: dropItem.selected ? row.accent : root.cFgPrimary
                        font.family: root.fontSans
                        font.pixelSize: 11
                        font.weight: Font.Medium
                    }

                    Text {
                        anchors.right: parent.right
                        anchors.rightMargin: 10
                        anchors.verticalCenter: parent.verticalCenter
                        visible: dropItem.selected
                        text: "\uf00c"
                        color: row.accent
                        font.family: root.fontMono
                        font.pixelSize: 9
                    }

                    MouseArea {
                        id: dropMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            dropdownOpen = false;
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
        width: Math.max(78, actionLabel.implicitWidth + 24)
        height: 32
        radius: 9
        color: actionMouse.containsMouse
            ? Qt.rgba(row.accent.r, row.accent.g, row.accent.b, 0.18)
            : Qt.rgba(row.accent.r, row.accent.g, row.accent.b, 0.09)
        border.width: 1
        border.color: Qt.rgba(row.accent.r, row.accent.g, row.accent.b, 0.32)
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        Behavior on color { ColorAnimation { duration: 140 } }

        Text {
            id: actionLabel
            anchors.centerIn: parent
            text: row.spec && row.spec.actionLabel ? row.spec.actionLabel : "Open"
            color: row.accent
            font.family: root.fontSans
            font.pixelSize: 11
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
            color: root.cFgPrimary
            font.family: root.fontSans
            font.pixelSize: 13
            font.weight: Font.DemiBold
            elide: Text.ElideRight
        }

        Text {
            width: parent.width
            visible: row.hasDesc
            text: row.spec && row.spec.desc ? row.spec.desc : ""
            color: root.cFgMuted
            font.family: root.fontSans
            font.pixelSize: 11
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
