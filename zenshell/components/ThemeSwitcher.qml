import QtQuick
import QtQuick.Layouts

Item {
    anchors.fill: parent
    opacity: root.displayState === 11 ? 1 : 0
    visible: opacity > 0
    clip: true
    Behavior on opacity {
        NumberAnimation { duration: root.displayState === 11 ? 240 : 160; easing.type: Easing.OutCubic }
    }

    onVisibleChanged: {
        if (visible) {
            syncCurrent()
            themeList.forceActiveFocus()
        }
    }

    Connections {
        target: root
        function onThemesListChanged() {
            if (visible) syncCurrent()
        }
    }

    function syncCurrent() {
        for (var i = 0; i < root.themesList.length; i++) {
            if (root.themesList[i].id === root.currentThemeId) {
                themeList.currentIndex = i
                themeList.positionViewAtIndex(i, ListView.Center)
                return
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 12

        MenuHeader {
            title: "Themes"
            icon: "\uf1fc"
            hint: "← →  ·  ↵ apply"
            meta: root.themesList.length > 0 ? (themeList.currentIndex + 1) + " / " + root.themesList.length : ""
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            ListView {
                id: themeList
                anchors.fill: parent
                orientation: ListView.Horizontal
                spacing: 10
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                currentIndex: 0
                property real scrollAcc: 0

                model: root.themesList.length
                focus: root.displayState === 11

                Keys.onEscapePressed: { root.displayState = 0; root.updateState(); }
                Keys.onLeftPressed: (event) => {
                    if (themeList.currentIndex > 0) { themeList.currentIndex--; themeList.positionViewAtIndex(themeList.currentIndex, ListView.Contain); }
                    event.accepted = true;
                }
                Keys.onRightPressed: (event) => {
                    if (themeList.currentIndex < root.themesList.length - 1) { themeList.currentIndex++; themeList.positionViewAtIndex(themeList.currentIndex, ListView.Contain); }
                    event.accepted = true;
                }
                Keys.onReturnPressed: {
                    if (root.themesList.length > 0 && themeList.currentIndex >= 0 && themeList.currentIndex < root.themesList.length)
                        root.applyTheme(root.themesList[themeList.currentIndex].id);
                }

                MouseArea {
                    anchors.fill: parent
                    propagateComposedEvents: true
                    onWheel: (wheel) => {
                        var delta = (wheel.angleDelta.y !== 0 ? wheel.angleDelta.y : wheel.angleDelta.x);
                        themeList.scrollAcc += delta;
                        if (Math.abs(themeList.scrollAcc) >= 60) {
                            if (themeList.scrollAcc < 0 && themeList.currentIndex < root.themesList.length - 1) themeList.currentIndex++;
                            else if (themeList.scrollAcc > 0 && themeList.currentIndex > 0) themeList.currentIndex--;
                            themeList.positionViewAtIndex(themeList.currentIndex, ListView.Contain);
                            themeList.scrollAcc = 0;
                        }
                    }
                }

                delegate: Item {
                    width: 90
                    height: ListView.view.height

                    property var theme: root.themesList[index] || {}
                    property color themeBg: theme.bg || "#1e1e2e"
                    property color themeSurface: theme.surface || "#242434"
                    property color themeFg: theme.fg || "#cdd6f4"
                    property color themeAccent: theme.accent || "#838996"
                    property bool themeDark: theme.dark !== false
                    property bool isActive: theme.id === root.currentThemeId
                    property bool isSel: index === themeList.currentIndex
                    property bool isHov: cardArea.containsMouse

                    Rectangle {
                        id: card
                        anchors.fill: parent
                        radius: 14
                        color: isSel ? "#0BFFFFFF" : (isHov ? "#07FFFFFF" : "transparent")
                        border.width: 1
                        border.color: isSel ? "#18FFFFFF" : "transparent"
                        Behavior on color { ColorAnimation { duration: 150 } }
                        Behavior on border.color { ColorAnimation { duration: 150 } }

                        property real press: 1.0
                        transform: Scale {
                            origin.x: card.width / 2
                            origin.y: card.height / 2
                            xScale: card.press
                            yScale: card.press
                        }
                        Behavior on press { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }

                        ColumnLayout {
                            anchors.centerIn: parent
                            width: parent.width - 12
                            spacing: 5

                            // A miniature desktop preview is more useful than a
                            // flat swatch: it shows bg, surface, fg and accent in
                            // the same relationship the real theme uses.
                            Rectangle {
                                id: preview
                                Layout.fillWidth: true
                                Layout.preferredHeight: 68
                                radius: 10
                                color: themeBg
                                clip: true
                                border.width: 1
                                border.color: isActive
                                    ? themeAccent
                                    : (isSel ? "#2EFFFFFF" : (themeDark ? "#1AFFFFFF" : "#1A000000"))
                                Behavior on border.color { ColorAnimation { duration: 150 } }

                                Rectangle {
                                    id: miniWindow
                                    anchors.centerIn: parent
                                    width: parent.width * 0.68
                                    height: parent.height * 0.58
                                    radius: 5
                                    color: themeSurface
                                    border.width: 1
                                    border.color: themeDark ? "#22FFFFFF" : "#18000000"

                                    Column {
                                        anchors.fill: parent
                                        anchors.margins: 5
                                        spacing: 3

                                        Rectangle {
                                            width: miniWindow.width * 0.55
                                            height: 3
                                            radius: 1.5
                                            color: themeAccent
                                        }
                                        Rectangle {
                                            width: miniWindow.width * 0.76
                                            height: 2
                                            radius: 1
                                            color: Qt.rgba(themeFg.r, themeFg.g, themeFg.b, 0.58)
                                        }
                                        Rectangle {
                                            width: miniWindow.width * 0.46
                                            height: 2
                                            radius: 1
                                            color: Qt.rgba(themeFg.r, themeFg.g, themeFg.b, 0.34)
                                        }
                                    }

                                    Rectangle {
                                        anchors.right: parent.right
                                        anchors.bottom: parent.bottom
                                        anchors.margins: 5
                                        width: 4
                                        height: 4
                                        radius: 2
                                        color: themeAccent
                                    }
                                }

                                Rectangle {
                                    visible: isActive
                                    anchors.top: parent.top
                                    anchors.right: parent.right
                                    anchors.margins: 5
                                    width: 14
                                    height: 14
                                    radius: 7
                                    color: themeAccent

                                    Text {
                                        anchors.centerIn: parent
                                        text: "\uf00c"
                                        color: themeAccent.hslLightness > 0.6 ? "#0D0D11" : "#FFFFFF"
                                        font.family: root.font
                                        font.pixelSize: 7
                                    }
                                }
                            }

                            Text {
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignHCenter
                                horizontalAlignment: Text.AlignHCenter
                                text: theme.name || ""
                                color: isActive || isSel ? root.uiFg : (isHov ? root.uiFg : root.uiFgDim)
                                font.family: root.uiFont
                                font.pixelSize: 10
                                font.weight: isActive || isSel ? Font.DemiBold : Font.Medium
                                elide: Text.ElideRight
                                Behavior on color { ColorAnimation { duration: 150 } }
                            }
                        }

                        Rectangle {
                            anchors.bottom: parent.bottom
                            anchors.bottomMargin: 6
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: isActive ? 18 : (isSel ? 8 : 0)
                            height: 2
                            radius: 1
                            color: themeAccent
                            Behavior on width { NumberAnimation { duration: 220; easing.type: Easing.OutQuart } }
                        }

                        MouseArea {
                            id: cardArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onPressed: card.press = 0.95
                            onReleased: card.press = 1.0
                            onClicked: root.applyTheme(theme.id)
                        }
                    }
                }
            }

            // Soften the clipped edge cards so the carousel reads as a
            // continuous strip rather than a hard crop.
            Rectangle {
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: 18
                z: 2
                visible: root.themesList.length > 0
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: "#E60D0D11" }
                    GradientStop { position: 1.0; color: "transparent" }
                }
            }
            Rectangle {
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: 18
                z: 2
                visible: root.themesList.length > 0
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: "transparent" }
                    GradientStop { position: 1.0; color: "#E60D0D11" }
                }
            }

            Column {
                anchors.centerIn: parent
                spacing: 8
                visible: root.themesList.length === 0

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "\uf1fc"
                    color: "#70FFFFFF"
                    font.family: root.font
                    font.pixelSize: 22
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "No themes found"
                    color: root.uiFgDim
                    font.family: root.uiFont
                    font.pixelSize: 11
                    font.weight: Font.Medium
                }
            }
        }
    }
}
