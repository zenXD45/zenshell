import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

// A grid of the wallpapers found in ~/wallpapers and ~/Pictures/Wallpapers.
// Picking one goes through wallpaper-selector.sh rather than calling awww
// directly, so the matugen theme and the hyprlock background stay in step
// with the desktop.
GridLayout {
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
    readonly property int tileWidth: 152
    columns: Math.max(1, Math.floor((width - columnSpacing) / (tileWidth + columnSpacing)))
    columnSpacing: 10
    rowSpacing: 10

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

    Repeater {
        model: grid.visibleWallpapers

        delegate: Rectangle {
            id: tile
            required property var modelData

            readonly property bool selected: grid.currentPath === modelData.path

            Layout.preferredWidth: grid.tileWidth
            Layout.preferredHeight: 92
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
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                cache: true
                opacity: tile.selected ? 1.0 : (tileMouse.containsMouse ? 0.8 : 0.55)
                Behavior on opacity { ColorAnimation { duration: 180 } }
            }

            // A soft floor keeps the crop from ending abruptly against the
            // rounded corners on bright images.
            Rectangle {
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                height: parent.height * 0.42
                gradient: Gradient {
                    GradientStop { position: 0.0; color: "transparent" }
                    GradientStop { position: 1.0; color: "#C0000000" }
                }
            }

            Text {
                anchors.left: parent.left
                anchors.leftMargin: 8
                anchors.right: parent.right
                anchors.rightMargin: 8
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 6
                text: tile.modelData.filename || tile.modelData.name
                color: root.ink(0.949)
                font.family: root.uiFont
                font.pixelSize: 9
                font.weight: Font.Medium
                elide: Text.ElideMiddle
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
                    font.family: root.font
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
        visible: grid.visibleWallpapers.length === 0
        text: grid.filter
            ? "No wallpaper matches \"" + grid.filter + "\""
            : "No wallpapers found in ~/wallpapers or ~/Pictures/Wallpapers"
        color: root.uiFgFaint
        font.family: root.uiFont
        font.pixelSize: 11
    }
}
