import QtQuick
import QtQuick.Layouts

Item {
    id: barSettings
    anchors.fill: parent
    opacity: root.displayState === 17 ? 1 : 0
    visible: opacity > 0
    clip: true
    Behavior on opacity {
        NumberAnimation { duration: root.displayState === 17 ? 220 : 140; easing.type: Easing.OutCubic }
    }

    property var widgetDefinitions: [
        { id: "workspaces", label: "Workspaces" },
        { id: "window", label: "Window title" },
        { id: "media", label: "Now playing" },
        { id: "clock", label: "Clock & date" },
        { id: "weather", label: "Weather" },
        { id: "system", label: "System & tray" }
    ]

    onVisibleChanged: {
        if (visible) focusScope.forceActiveFocus()
    }

    FocusScope {
        id: focusScope
        anchors.fill: parent
        focus: root.displayState === 17

        Keys.onEscapePressed: {
            root.displayState = 0;
            root.updateState();
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 8

            MenuHeader {
                title: "Bar"
                icon: "\uf1de"
                hint: "changes apply live"
                meta: "PROFILE 02"
            }

            Text {
                text: "LAYOUT"
                color: root.uiFgFaint
                font.family: root.uiFont
                font.pixelSize: 8
                font.weight: Font.DemiBold
                font.letterSpacing: 1.1
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 54
                spacing: 8

                Repeater {
                    model: [
                        { value: "floating", label: "Floating", detail: "detached" },
                        { value: "edge", label: "Edge", detail: "full width" }
                    ]

                    delegate: Rectangle {
                        required property var modelData

                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: 13
                        color: root.barStyle === modelData.value
                            ? Qt.rgba(root.currentThemeAccent.r, root.currentThemeAccent.g, root.currentThemeAccent.b, 0.10)
                            : (styleMouse.containsMouse ? "#0EFFFFFF" : "#07FFFFFF")
                        border.width: 1
                        border.color: root.barStyle === modelData.value
                            ? Qt.rgba(root.currentThemeAccent.r, root.currentThemeAccent.g, root.currentThemeAccent.b, 0.42)
                            : (styleMouse.containsMouse ? "#22FFFFFF" : "#12FFFFFF")
                        Behavior on color { ColorAnimation { duration: 140 } }
                        Behavior on border.color { ColorAnimation { duration: 140 } }

                        Row {
                            anchors.fill: parent
                            anchors.margins: 9
                            spacing: 9

                            Item {
                                width: 42
                                height: 22
                                anchors.verticalCenter: parent.verticalCenter

                                Rectangle {
                                    width: modelData.value === "floating" ? 30 : 42
                                    height: modelData.value === "floating" ? 6 : 4
                                    radius: modelData.value === "floating" ? 3 : 1
                                    anchors.centerIn: parent
                                    color: root.barStyle === modelData.value
                                        ? root.currentThemeAccent
                                        : "#48FFFFFF"
                                    opacity: root.barStyle === modelData.value ? 0.9 : 1
                                }
                            }

                            Column {
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 0

                                Text {
                                    text: modelData.label
                                    color: root.barStyle === modelData.value ? root.uiFg : root.uiFgDim
                                    font.family: root.uiFont
                                    font.pixelSize: 10
                                    font.weight: Font.DemiBold
                                }

                                Text {
                                    text: modelData.detail
                                    color: root.uiFgFaint
                                    font.family: root.uiFont
                                    font.pixelSize: 8
                                    font.weight: Font.Medium
                                }
                            }
                        }

                        MouseArea {
                            id: styleMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.setBarStyle(modelData.value)
                        }
                    }
                }
            }

            Text {
                text: "POSITION"
                color: root.uiFgFaint
                font.family: root.uiFont
                font.pixelSize: 8
                font.weight: Font.DemiBold
                font.letterSpacing: 1.1
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 28
                spacing: 8

                Repeater {
                    model: [
                        { value: "top", label: "Top edge" },
                        { value: "bottom", label: "Bottom edge" }
                    ]

                    delegate: Rectangle {
                        required property var modelData

                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: 9
                        color: root.barPosition === modelData.value
                            ? Qt.rgba(root.currentThemeAccent.r, root.currentThemeAccent.g, root.currentThemeAccent.b, 0.13)
                            : (positionMouse.containsMouse ? "#0EFFFFFF" : "#07FFFFFF")
                        border.width: 1
                        border.color: root.barPosition === modelData.value
                            ? Qt.rgba(root.currentThemeAccent.r, root.currentThemeAccent.g, root.currentThemeAccent.b, 0.34)
                            : "#12FFFFFF"
                        Behavior on color { ColorAnimation { duration: 140 } }
                        Behavior on border.color { ColorAnimation { duration: 140 } }

                        Rectangle {
                            visible: root.barPosition === modelData.value
                            width: 3
                            height: 3
                            radius: 1.5
                            anchors.left: parent.left
                            anchors.leftMargin: 10
                            anchors.verticalCenter: parent.verticalCenter
                            color: root.currentThemeAccent
                        }

                        Text {
                            anchors.centerIn: parent
                            text: modelData.label
                            color: root.barPosition === modelData.value ? root.currentThemeAccent : root.uiFgDim
                            font.family: root.uiFont
                            font.pixelSize: 9
                            font.weight: Font.DemiBold
                        }

                        MouseArea {
                            id: positionMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.setBarPosition(modelData.value)
                        }
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 18
                spacing: 6

                Text {
                    text: "WIDGETS"
                    color: root.uiFgFaint
                    font.family: root.uiFont
                    font.pixelSize: 8
                    font.weight: Font.DemiBold
                    font.letterSpacing: 1.1
                }

                Item { Layout.fillWidth: true }

                Text {
                    text: root.barWidgets.length + " / " + root.barWidgetIds.length
                    color: root.uiFgFaint
                    font.family: root.font
                    font.pixelSize: 8
                    font.weight: Font.Medium
                }
            }

            GridLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 96
                columns: 2
                columnSpacing: 8
                rowSpacing: 6

                Repeater {
                    model: barSettings.widgetDefinitions

                    delegate: Rectangle {
                        required property var modelData

                        Layout.fillWidth: true
                        Layout.preferredHeight: 28
                        radius: 9
                        color: root.hasBarWidget(modelData.id)
                            ? Qt.rgba(root.currentThemeAccent.r, root.currentThemeAccent.g, root.currentThemeAccent.b, 0.08)
                            : (widgetMouse.containsMouse ? "#0EFFFFFF" : "#06FFFFFF")
                        border.width: 1
                        border.color: root.hasBarWidget(modelData.id)
                            ? Qt.rgba(root.currentThemeAccent.r, root.currentThemeAccent.g, root.currentThemeAccent.b, 0.28)
                            : "#10FFFFFF"
                        Behavior on color { ColorAnimation { duration: 140 } }
                        Behavior on border.color { ColorAnimation { duration: 140 } }

                        Row {
                            anchors.fill: parent
                            anchors.leftMargin: 9
                            anchors.rightMargin: 9
                            spacing: 7

                            Rectangle {
                                width: 13
                                height: 13
                                radius: 4
                                anchors.verticalCenter: parent.verticalCenter
                                color: root.hasBarWidget(modelData.id)
                                    ? Qt.rgba(root.currentThemeAccent.r, root.currentThemeAccent.g, root.currentThemeAccent.b, 0.18)
                                    : "transparent"
                                border.width: 1
                                border.color: root.hasBarWidget(modelData.id)
                                    ? Qt.rgba(root.currentThemeAccent.r, root.currentThemeAccent.g, root.currentThemeAccent.b, 0.48)
                                    : "#28FFFFFF"

                                Text {
                                    anchors.centerIn: parent
                                    visible: root.hasBarWidget(modelData.id)
                                    text: "\uf00c"
                                    color: root.currentThemeAccent
                                    font.family: root.font
                                    font.pixelSize: 7
                                }
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: modelData.label
                                color: root.hasBarWidget(modelData.id) ? root.uiFg : root.uiFgDim
                                font.family: root.uiFont
                                font.pixelSize: 9
                                font.weight: Font.Medium
                                elide: Text.ElideRight
                            }
                        }

                        MouseArea {
                            id: widgetMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.toggleBarWidget(modelData.id)
                        }
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 16
                spacing: 8

                Text {
                    Layout.fillWidth: true
                    text: "Launcher, control center and profile controls stay fixed."
                    color: root.uiFgFaint
                    font.family: root.uiFont
                    font.pixelSize: 8
                    font.weight: Font.Medium
                    elide: Text.ElideRight
                }

                Rectangle {
                    height: 18
                    implicitWidth: barEscText.implicitWidth + 12
                    radius: 6
                    color: "#0AFFFFFF"
                    border.width: 1
                    border.color: "#16FFFFFF"

                    Text {
                        id: barEscText
                        anchors.centerIn: parent
                        text: "esc"
                        color: root.uiFgFaint
                        font.family: root.font
                        font.pixelSize: 8
                        font.weight: Font.Medium
                    }
                }
            }
        }
    }
}
