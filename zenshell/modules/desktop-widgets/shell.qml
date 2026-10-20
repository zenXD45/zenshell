import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects

Scope {
    id: root

    // ... State ...
    property string font: "JetBrainsMono Nerd Font"
    property bool widgetsVisible: true
    property string shellProfile: "island"

    FileView {
        id: shellSettings
        path: Quickshell.env("HOME") + "/.config/quickshell/shell_settings.json"
        watchChanges: true
        onFileChanged: reload()
        onTextChanged: {
            try {
                var settings = JSON.parse(text());
                if (settings.profile === "island" || settings.profile === "bar") {
                    root.shellProfile = settings.profile;
                }
            } catch (e) {}
        }
    }
    
    // Clock State
    property string currentTime: "00:00"
    property string currentDate: "Monday, Jan 1"
    property string currentGreeting: "Good morning, Zen"

    // Weather State
    property string weatherTemp: "--°"
    property string weatherIcon: "󰖐"
    property string weatherDesc: "Loading..."
    property string weatherHigh: ""
    property string weatherLow: ""
    
    // Timers
    Timer {
        id: clockTimer
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            var d = new Date()
            root.currentTime = d.toLocaleTimeString(Qt.locale(), "hh:mm")
            root.currentDate = d.toLocaleDateString(Qt.locale(), "dddd, MMMM dd")
            var h = d.getHours()
            if (h < 6) root.currentGreeting = "Good night, Zen"
            else if (h < 12) root.currentGreeting = "Good morning, Zen"
            else if (h < 17) root.currentGreeting = "Good afternoon, Zen"
            else if (h < 21) root.currentGreeting = "Good evening, Zen"
            else root.currentGreeting = "Good night, Zen"
        }
        Component.onCompleted: triggered()
    }

    Timer {
        id: weatherTimer
        interval: 600000 // Every 10 mins
        running: true
        repeat: true
        onTriggered: weatherProcess.running = true
        Component.onCompleted: triggered()
    }

    Process {
        id: weatherProcess
        command: ["python3", Quickshell.shellDir + "/get_weather.py"]
        stdout: SplitParser {
            onRead: (data) => {
                try {
                    var w = JSON.parse(data)
                    root.weatherTemp = w.temp
                    root.weatherIcon = w.icon
                    root.weatherDesc = w.desc
                    root.weatherHigh = w.high
                    root.weatherLow = w.low
                } catch(e) {}
            }
        }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: widgetWindow
            required property var modelData
            screen: modelData

            color: "transparent"
            visible: root.shellProfile !== "bar"
            
            WlrLayershell.layer: WlrLayer.Bottom
            WlrLayershell.namespace: "qs-widgets"
            exclusionMode: ExclusionMode.Ignore

            anchors {
                top: true
                right: true
                bottom: true
                left: true
            }

            // Widget Container
            Column {
                opacity: root.widgetsVisible ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 350; easing.type: Easing.OutCubic } }
                anchors.top: parent.top
                anchors.right: parent.right
                anchors.margins: 48
                spacing: 32

                // Clock Widget Container
                Item {
                    width: 380
                    height: 180

                    DropShadow {
                        anchors.fill: clockRect
                        source: clockRect
                        color: "#40000000"
                        horizontalOffset: 0
                        verticalOffset: 12
                        radius: 32
                        samples: 33
                        transparentBorder: true
                    }

                    Rectangle {
                        id: clockRect
                        anchors.fill: parent
                        radius: 28
                        border.color: "#30FFFFFF"
                        border.width: 1
                        
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: "#25FFFFFF" }
                            GradientStop { position: 1.0; color: "#0AFFFFFF" }
                        }

                        Column {
                            anchors.centerIn: parent
                            spacing: -4
                            
                            Text {
                                text: root.currentTime
                                font.family: "Outfit"
                                font.pixelSize: 84
                                font.weight: Font.Black
                                font.letterSpacing: -2
                                color: "white"
                                anchors.horizontalCenter: parent.horizontalCenter
                            }
                            Text {
                                text: root.currentDate
                                font.family: "Outfit"
                                font.pixelSize: 20
                                font.weight: Font.Bold
                                font.letterSpacing: 1
                                color: "white"
                                opacity: 0.8
                                anchors.horizontalCenter: parent.horizontalCenter
                            }
                            Item { height: 12; width: 1 } // Spacer
                            Text {
                                text: root.currentGreeting
                                font.family: "Outfit"
                                font.pixelSize: 15
                                color: "white"
                                opacity: 0.5
                                anchors.horizontalCenter: parent.horizontalCenter
                            }
                        }
                    }
                }

                // Weather Widget Container
                Item {
                    width: 380
                    height: 140

                    DropShadow {
                        anchors.fill: weatherRect
                        source: weatherRect
                        color: "#40000000"
                        horizontalOffset: 0
                        verticalOffset: 12
                        radius: 32
                        samples: 33
                        transparentBorder: true
                    }

                    Rectangle {
                        id: weatherRect
                        anchors.fill: parent
                        radius: 28
                        border.color: "#30FFFFFF"
                        border.width: 1
                        
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: "#25FFFFFF" }
                            GradientStop { position: 1.0; color: "#0AFFFFFF" }
                        }

                        Row {
                            anchors.fill: parent
                            anchors.margins: 28
                            spacing: 28

                            // Icon with floating micro-animation
                            Item {
                                width: 64
                                height: 64
                                anchors.verticalCenter: parent.verticalCenter
                                
                                Text {
                                    id: wIcon
                                    text: root.weatherIcon
                                    font.family: root.font
                                    font.pixelSize: 64
                                    color: "white"
                                    anchors.centerIn: parent
                                    
                                    SequentialAnimation on y {
                                        loops: Animation.Infinite
                                        NumberAnimation { from: -4; to: 4; duration: 2500; easing.type: Easing.InOutSine }
                                        NumberAnimation { from: 4; to: -4; duration: 2500; easing.type: Easing.InOutSine }
                                    }
                                }
                                
                                // Optional subtle glow behind the icon
                                RectangularGlow {
                                    anchors.fill: wIcon
                                    glowRadius: 20
                                    spread: 0.2
                                    color: "#40FFFFFF"
                                    cornerRadius: 32
                                    z: -1
                                }
                            }

                            // Details
                            Column {
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 0

                                Text {
                                    text: root.weatherTemp
                                    font.family: "Outfit"
                                    font.pixelSize: 46
                                    font.weight: Font.Bold
                                    color: "white"
                                }
                                Text {
                                    text: root.weatherDesc
                                    font.family: "Outfit"
                                    font.pixelSize: 15
                                    color: "white"
                                    opacity: 0.7
                                    width: 220
                                    wrapMode: Text.WordWrap
                                    maximumLineCount: 2
                                    elide: Text.ElideRight
                                    lineHeight: 1.1
                                }
                                Item { height: 6; width: 1 } // Spacer
                                Row {
                                    spacing: 12
                                    Text {
                                        text: root.weatherHigh
                                        font.family: "Outfit"
                                        font.pixelSize: 14
                                        color: "white"
                                        font.weight: Font.Bold
                                        opacity: 0.9
                                    }
                                    Text {
                                        text: root.weatherLow
                                        font.family: "Outfit"
                                        font.pixelSize: 14
                                        color: "white"
                                        opacity: 0.5
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    IpcHandler {
        target: "widgets"
        function toggle(): void { root.widgetsVisible = !root.widgetsVisible }
        function show(): void { root.widgetsVisible = true }
        function hide(): void { root.widgetsVisible = false }
    }
}
