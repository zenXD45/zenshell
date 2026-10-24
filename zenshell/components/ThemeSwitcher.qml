import QtQuick
import QtQuick.Layouts

Item {
    id: themeRoot
    anchors.fill: parent
    property real reveal: root.displayState === 11 ? 1 : 0
    opacity: reveal
    visible: opacity > 0
    clip: true
    scale: 0.992 + reveal * 0.008
    transform: Translate { y: (1 - themeRoot.reveal) * 8 }

    Behavior on reveal {
        NumberAnimation {
            duration: root.displayState === 11 ? root.motionPanel : root.motionExit
            easing.type: root.displayState === 11 ? Easing.OutExpo : Easing.OutCubic
        }
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
        anchors.margins: root.s5
        spacing: 0

        MenuHeader {
            title: "Themes"
            hint: "\u2191 \u2193  \u00b7  \u21b5 apply"
            meta: root.themesList.length > 0 ? (themeList.currentIndex + 1) + " / " + root.themesList.length : ""
        }

        Item { Layout.preferredHeight: root.s4 }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            Rectangle {
                anchors.fill: parent
                radius: 14
                color: root.ink(0.055)
            }

            ListView {
                id: themeList
                anchors.fill: parent
                anchors.margins: 4
                spacing: 0
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                currentIndex: 0
                property real scrollAcc: 0

                model: root.themesList.length
                focus: root.displayState === 11

                Keys.onEscapePressed: { root.displayState = 0; root.updateState(); }
                Keys.onUpPressed: (event) => {
                    if (themeList.currentIndex > 0) { themeList.currentIndex--; themeList.positionViewAtIndex(themeList.currentIndex, ListView.Contain); }
                    event.accepted = true;
                }
                Keys.onDownPressed: (event) => {
                    if (themeList.currentIndex < root.themesList.length - 1) { themeList.currentIndex++; themeList.positionViewAtIndex(themeList.currentIndex, ListView.Contain); }
                    event.accepted = true;
                }
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
                    id: themeRow
                    width: themeList.width
                    height: 46

                    property var theme: root.themesList[index] || {}
                    property color tBg: theme.bg || root.themeSurface
                    property color tAccent: theme.accent || root.themeAccent
                    property bool isActive: theme.id === root.currentThemeId
                    property bool isSel: index === themeList.currentIndex

                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: 2
                        radius: 10
                        color: themeRow.isSel
                            ? root.ink(0.065)
                            : (rowHover.containsMouse ? root.ink(0.04) : "transparent")
                        Behavior on color { ColorAnimation { duration: root.dMicro } }
                    }

                    Rectangle {
                        visible: index < themeList.count - 1
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        anchors.leftMargin: 56
                        anchors.rightMargin: 16
                        height: 1
                        color: root.ink(0.07)
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 14
                        spacing: root.s3

                        Rectangle {
                            Layout.alignment: Qt.AlignVCenter
                            Layout.preferredWidth: 26
                            Layout.preferredHeight: 26
                            radius: 7
                            color: themeRow.tBg
                            border.width: 1
                            border.color: root.ink(0.12)

                            Rectangle {
                                anchors.centerIn: parent
                                width: 13
                                height: 3
                                radius: 1.5
                                color: themeRow.tAccent
                            }
                        }

                        Text {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter
                            text: themeRow.theme.name || themeRow.theme.id || "Theme"
                            color: root.cFgPrimary
                            font.family: root.fontSans
                            font.pixelSize: 14
                            font.weight: themeRow.isActive ? Font.DemiBold : Font.Normal
                            elide: Text.ElideRight
                        }

                        Text {
                            Layout.alignment: Qt.AlignVCenter
                            visible: themeRow.isActive
                            text: "\uf00c"
                            color: root.currentThemeAccent
                            font.family: root.fontMono
                            font.pixelSize: 13
                        }
                    }

                    MouseArea {
                        id: rowHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: themeList.currentIndex = index
                        onClicked: {
                            themeList.currentIndex = index;
                            root.applyTheme(themeRow.theme.id);
                        }
                    }
                }
            }

            EmptyState {
                anchors.centerIn: parent
                visible: root.themesList.length === 0
                title: "No themes found"
            }
        }
    }
}
