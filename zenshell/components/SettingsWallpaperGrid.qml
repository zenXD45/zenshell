import QtQuick
import Quickshell
import Quickshell.Io

// A grid of the wallpapers found in ~/wallpapers and ~/Pictures/Wallpapers.
// Picking one goes through wallpaper-selector.sh rather than calling awww
// directly, so the matugen theme and the hyprlock background stay in step
// with the desktop.
//
// The tiles live in a GridView rather than a Repeater + GridLayout: the
// settings page sits inside one long scrolling column, so only the tiles on
// screen ever decode a wallpaper (33 full frames were being decoded at once).
Item {
    id: grid

    property var wallpapers: root.allWallpapers
    property string currentPath: ""

    // A search term narrows the grid to the wallpapers whose file name
    // matches, so the search field filters the tiles as well as the
    // navigation.
    property string filter: ""

    readonly property var visibleWallpapers: {
        var list = grid.wallpapers ? grid.wallpapers : [];
        var q = grid.filter ? grid.filter.trim().toLowerCase() : "";
        if (q === "") return list;
        var out = [];
        for (var i = 0; i < list.length; i++) {
            var paper = list[i];
            if (!paper) continue;
            var name = String(paper.filename || paper.name || "").toLowerCase();
            if (name.indexOf(q) !== -1) out.push(paper);
        }
        return out;
    }

    signal picked(var path)

    // Same as the theme grid: reflow to the width instead of clipping the
    // last column when the window is scaled down.
    readonly property int tileWidth: 164
    readonly property int tileHeight: 104
    readonly property int gap: 12

    readonly property bool empty: visibleWallpapers.length === 0

    // The parent is a plain Column, so the height has to be reported
    // explicitly — a GridView has no implicit size of its own. The view owns
    // the column count, so ask it for the content height rather than
    // recomputing rows here and risking the two disagreeing.
    height: empty ? emptyText.implicitHeight : gridView.contentHeight
    implicitHeight: height

    Process {
        id: currentProc
        command: ["bash", "-c", "readlink -f \"$HOME/wallpapers/current\" 2>/dev/null"]
        stdout: SplitParser {
            onRead: data => {
                var p = data.trim();
                if (p !== "") grid.currentPath = p;
            }
        }
    }

    onVisibleChanged: {
        if (visible) currentProc.running = true;
    }

    GridView {
        id: gridView
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        // GridView charges a trailing gap to every cell, so a 323 px column
        // would fit only one 152 px tile even though two (152 + 10 + 152) do
        // fit. Let the view run one gap past the edge and clip it.
        anchors.rightMargin: -grid.gap
        height: grid.height

        cellWidth: grid.tileWidth + grid.gap
        cellHeight: grid.tileHeight + grid.gap
        flow: GridView.FlowLeftToRight
        // The page scrolls as one column; this grid only lays tiles out.
        interactive: false
        boundsBehavior: Flickable.StopAtBounds
        clip: true

        model: grid.visibleWallpapers

        delegate: Rectangle {
            id: tile
            required property var modelData

            readonly property bool selected: grid.currentPath === modelData.path

            width: grid.tileWidth
            height: grid.tileHeight
            radius: 11
            color: root.themeBg
            border.width: selected ? 2 : 1
            border.color: selected
                ? root.currentThemeAccent
                : (tileMouse.containsMouse ? root.ink(0.188) : root.ink(0.086))
            clip: true
            Behavior on border.color { ColorAnimation { duration: 150 } }
            scale: tileMouse.containsMouse ? 1.03 : 1.0
            Behavior on scale { NumberAnimation { duration: 130; easing.type: Easing.OutCubic } }

            Image {
                anchors.fill: parent
                source: "file://" + tile.modelData.path
                sourceSize: Qt.size(328, 208)
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                cache: true
                opacity: tile.selected ? 1.0 : (tileMouse.containsMouse ? 0.95 : 0.78)
                Behavior on opacity { NumberAnimation { duration: 180 } }
            }

            // Clean subtle gradient at bottom for legible label
            Rectangle {
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                height: 32
                gradient: Gradient {
                    GradientStop { position: 0.0; color: "transparent" }
                    GradientStop { position: 1.0; color: "#D0000000" }
                }
            }

            Text {
                anchors.left: parent.left
                anchors.leftMargin: 8
                anchors.right: parent.right
                anchors.rightMargin: 8
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 7
                text: {
                    var raw = String(tile.modelData.filename || tile.modelData.name || "");
                    return raw.replace(/\.[^/.]+$/, "").replace(/[-_]/g, " ");
                }
                color: "#FFFFFF"
                font.family: root.fontSans
                font.pixelSize: 10
                font.weight: Font.DemiBold
                elide: Text.ElideRight
            }

            Rectangle {
                visible: tile.selected
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 6
                width: 17
                height: 17
                radius: 8.5
                color: root.currentThemeAccent

                Text {
                    anchors.centerIn: parent
                    text: "\uf00c"
                    color: root.onAccent()
                    font.family: root.fontMono
                    font.pixelSize: 8
                }
            }

            MouseArea {
                id: tileMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: grid.picked(tile.modelData.path)
            }
        }
    }

    Text {
        id: emptyText
        visible: grid.empty
        width: parent.width
        text: grid.filter
            ? "No wallpaper matches \"" + grid.filter + "\""
            : "No wallpapers found in ~/wallpapers or ~/Pictures/Wallpapers"
        color: root.cFgMuted
        font.family: root.fontSans
        font.pixelSize: 11
        wrapMode: Text.WordWrap
    }
}
