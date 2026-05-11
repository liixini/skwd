import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import QtQuick.Controls
import ".."
import "../components"
import "../services"


Scope {
  id: powerMenuScope

  property var colors
  property bool showing: false

  property string homeDir: Config.homeDir
  property string mainMonitor: Config.mainMonitor

  property bool cardVisible: false
  property int selectedIndex: 0

  property string iconFont: Style.fontFamilyNerdIcons

  property var _commands: ({
    "lock": "loginctl lock-session",
    "logout": "__wm_quit__",
    "reboot": "systemctl reboot",
    "poweroff": "systemctl poweroff"
  })

  property var _defaultOptions: [
    { label: "Lock", icon: "󰌾", action: "lock" },
    { label: "Logout", icon: "󰍃", action: "logout" },
    { label: "Reboot", icon: "󰜉", action: "reboot" },
    { label: "Poweroff", icon: "󰐥", action: "poweroff" }
  ]

  property var options: {
    var src = Config.powerMenuOptions.length > 0 ? Config.powerMenuOptions : _defaultOptions
    var result = []
    for (var i = 0; i < src.length; i++) {
      var opt = src[i]
      if (opt.enabled === false) continue
      var cmd = opt.command && opt.command.length > 0 ? opt.command : (_commands[opt.action] || "")
      if (cmd) result.push({ label: opt.label || "", icon: opt.icon || "", command: cmd })
    }
    return result
  }

  onShowingChanged: {
    if (showing) {
      selectedIndex = 0
      cardShowTimer.restart()
    } else {
      cardVisible = false
    }
  }

  Timer {
    id: cardShowTimer
    interval: 50
    onTriggered: powerMenuScope.cardVisible = true
  }

  function executeOption(index) {
    var opt = options[index]
    if (opt.command === "__wm_quit__") {
      WmService.quit()
    } else {
      executor.command = ["sh", "-c", opt.command]
      executor.running = true
    }
    showing = false
  }

  Process {
    id: executor
    command: ["true"]
  }


  readonly property var _mainScreen: Quickshell.screens.find(s => s.name === powerMenuScope.mainMonitor) ?? Quickshell.screens[0]

  Variants {
    model: Quickshell.screens

    PanelWindow {
      id: powerPanel

      property var modelData
      property bool isMainMonitor: modelData === powerMenuScope._mainScreen || Quickshell.screens.length === 1

      screen: modelData

      anchors {
        top: true
        bottom: true
        left: true
        right: true
      }

      visible: powerMenuScope.showing
      color: "transparent"

      WlrLayershell.namespace: "powermenu"
      WlrLayershell.layer: WlrLayer.Top
      WlrLayershell.keyboardFocus: powerMenuScope.showing ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

      exclusionMode: ExclusionMode.Ignore


      Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.01)
      }

      DimOverlay {
        active: powerMenuScope.cardVisible
        dimOpacity: 0.45
        onClicked: powerMenuScope.showing = false
      }


      FocusScope {
        id: keyboardProxy
        anchors.fill: parent
        focus: powerMenuScope.showing && !isMainMonitor

        Keys.onPressed: event => {
          if (event.key === Qt.Key_Escape) {
            powerMenuScope.showing = false
            event.accepted = true
          } else if (event.key === Qt.Key_Left) {
            powerMenuScope.selectedIndex = Math.max(0, powerMenuScope.selectedIndex - 1)
            event.accepted = true
          } else if (event.key === Qt.Key_Right) {
            powerMenuScope.selectedIndex = Math.min(powerMenuScope.options.length - 1, powerMenuScope.selectedIndex + 1)
            event.accepted = true
          } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            powerMenuScope.executeOption(powerMenuScope.selectedIndex)
            event.accepted = true
          }
        }
      }


      Item {
        focus: powerMenuScope.showing && isMainMonitor
        Keys.onPressed: event => {
          if (event.key === Qt.Key_Escape) {
            powerMenuScope.showing = false
            event.accepted = true
          } else if (event.key === Qt.Key_Left) {
            powerMenuScope.selectedIndex = Math.max(0, powerMenuScope.selectedIndex - 1)
            event.accepted = true
          } else if (event.key === Qt.Key_Right) {
            powerMenuScope.selectedIndex = Math.min(powerMenuScope.options.length - 1, powerMenuScope.selectedIndex + 1)
            event.accepted = true
          } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            powerMenuScope.executeOption(powerMenuScope.selectedIndex)
            event.accepted = true
          }
        }
      }


      Item {
        id: powerCard
        visible: isMainMonitor && powerMenuScope.cardVisible

        width: 1200
        height: 380
        anchors.centerIn: parent


        Row {
          anchors.centerIn: parent
          spacing: 80

          Repeater {
            model: powerMenuScope.options

            Item {
              width: 220
              height: 320

              property bool isSelected: powerMenuScope.selectedIndex === index
              property bool isHovered: buttonMouse.containsMouse

              Column {
                anchors.centerIn: parent
                spacing: 24


                Text {
                  anchors.horizontalCenter: parent.horizontalCenter
                  text: modelData.icon
                  font.family: powerMenuScope.iconFont
                  font.pixelSize: 216
                  color: isSelected ? powerMenuScope.colors.primary : powerMenuScope.colors.tertiary

                  Behavior on color { ColorAnimation { duration: 150 } }

                  scale: isHovered ? 1.1 : 1.0
                  Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

                  layer.enabled: true
                  layer.smooth: true
                  layer.samples: 4
                  layer.effect: MultiEffect {
                    shadowEnabled: true
                    shadowColor: Qt.rgba(0, 0, 0, 0.5)
                    shadowBlur: 0.8
                    shadowVerticalOffset: 2
                    shadowHorizontalOffset: 0
                  }
                }


                Text {
                  anchors.horizontalCenter: parent.horizontalCenter
                  text: modelData.label
                  font.family: Style.fontFamily
                  font.weight: Font.Bold
                  font.pixelSize: 24
                  color: isSelected ? powerMenuScope.colors.primary : powerMenuScope.colors.tertiary

                  Behavior on color { ColorAnimation { duration: 150 } }
                }
              }

              MouseArea {
                id: buttonMouse
                anchors.fill: parent
                hoverEnabled: true
                onClicked: powerMenuScope.executeOption(index)
                onEntered: powerMenuScope.selectedIndex = index
              }
            }
          }
        }
      }
    }
  }
}
