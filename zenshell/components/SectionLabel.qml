import QtQuick

// Small uppercase section label above a group. One per group, never inside it.
Text {
    property string text: ""

    height: 24
    leftPadding: 4
    verticalAlignment: Text.AlignBottom
    bottomPadding: 6
    color: root.ink(0.38)
    font.family: root.fontSans
    font.pixelSize: 10
    font.weight: Font.DemiBold
    font.letterSpacing: 0.9
    font.capitalization: Font.AllUppercase
}
