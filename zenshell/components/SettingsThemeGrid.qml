import QtQuick
import QtQuick.Layouts

// A grid of the installed Hyprland themes. Each tile paints the theme's own
// palette rather than a generic swatch, so the choice reads as a preview of
// the desktop instead of a row of coloured squares.
GridLayout {
    id: grid

    property var themes: root.themesList
    property string currentId: root.currentThemeId

    // A search term narrows the grid to the themes whose name matches, so
    // the search field filters the tiles as well as the navigation.
    property string filter: ""

    readonly property var visibleThemes: {
        var list = grid.themes ? grid.themes : [];
        var q = grid.filter ? grid.filter.trim().toLowerCase() : "";
        if (q === "") return list;
        var out = [];
        for (var i = 0; i < list.length; i++) {
            var theme = list[i];
            if (!theme) continue;
            var name = String(theme.name || theme.id || "").toLowerCase();
            if (name.indexOf(q) !== -1) out.push(theme);
        }
        return out;
    }

    signal picked(var themeId)

    // The grid reflows instead of clipping: a tile is 118 wide plus 10 of
    // spacing, so the column count is whatever fits the page. A fixed count
    // cut the last column off whenever the window was scaled down.
    readonly property int tileWidth: 118
    columns: Math.max(2, Math.floor((width - columnSpacing) / (tileWidth + columnSpacing)))
    columnSpacing: 10
    rowSpacing: 10

    Repeater {
        model: grid.visibleThemes

        delegate: Rectangle {
            id: tile
            required property var modelData

            readonly property bool selected: grid.currentId === modelData.id

            Layout.preferredWidth: grid.tileWidth
            Layout.preferredHeight: 74
            radius: 12
            color: modelData.bg || root.themeBg
            border.width: selected ? 2 : 1
            border.color: selected
                ? (modelData.accent || root.themeAccent)
                : (tileMouse.containsMouse ? root.ink(0.188) : root.ink(0.102))
            clip: true
            Behavior on border.color { ColorAnimation { duration: 150 } }
            scale: tileMouse.containsMouse ? 1.02 : 1.0
            Behavior on scale { NumberAnimation { duration: 130; easing.type: Easing.OutCubic } }

            // A miniature of the shell: surface, accent pill and body text.
            Rectangle {
                anchors.fill: parent
                anchors.margins: 1
                radius: parent.radius
                gradient: Gradient {
                    GradientStop { position: 0.0; color: modelData.surface || modelData.bg || root.themeBg }
                    GradientStop { position: 1.0; color: modelData.bg || root.themeBg }
                }
                opacity: 0.85
            }

            Rectangle {
                x: 10
                y: 11
                width: 46
                height: 9
                radius: 4.5
                color: modelData.accent || root.themeAccent
            }

            Rectangle {
                x: 10
                y: 25
                width: 74
                height: 6
                radius: 3
                color: modelData.fg || root.themeFg
                opacity: 0.55
            }

            Rectangle {
                x: 10
                y: 35
                width: 52
                height: 6
                radius: 3
                color: modelData.fg || root.themeFg
                opacity: 0.3
            }

            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.margins: 1
                height: 21
                color: "#B0000000"
                opacity: 0.55
            }

            Text {
                anchors.left: parent.left
                anchors.leftMargin: 10
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 4
                width: parent.width - 30
                text: tile.modelData.name || tile.modelData.id
                color: root.ink(0.949)
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
                color: modelData.accent || root.themeAccent

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
                onClicked: grid.picked(tile.modelData.id)
            }
        }
    }

    Text {
        visible: grid.visibleThemes.length === 0
        text: grid.filter ? "No theme matches \"" + grid.filter + "\"" : "No themes installed"
        color: root.cFgMuted
        font.family: root.fontSans
        font.pixelSize: 11
    }
}
