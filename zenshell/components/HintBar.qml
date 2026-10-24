import QtQuick
import QtQuick.Layouts

// Footer hint line. Keys and actions are typography, not keycaps: the key is
// mono at a readable weight, the verb is muted sans. One line, always.
RowLayout {
    id: hintBar

    property var hints: []
    property string meta: ""

    Layout.fillWidth: true
    Layout.preferredHeight: 24
    spacing: root.s4

    Repeater {
        model: hintBar.hints

        RowLayout {
            spacing: 5

            Text {
                text: modelData.key
                color: root.ink(0.62)
                font.family: root.fontMono
                font.pixelSize: 11
            }

            Text {
                text: modelData.label
                color: root.ink(0.40)
                font.family: root.fontSans
                font.pixelSize: 11
            }
        }
    }

    Item { Layout.fillWidth: true }

    Text {
        visible: hintBar.meta !== ""
        text: hintBar.meta
        color: root.ink(0.40)
        font.family: root.fontMono
        font.pixelSize: 11
    }
}
