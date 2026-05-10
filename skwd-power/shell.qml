import Quickshell
import Quickshell.Io
import QtQuick
import "qml"
import "qml/power"
import "qml/services"

ShellRoot {
  id: root

  Colors { id: colors }

  PowerMenu {
    id: powerMenu
    colors: colors
  }

  Connections {
    target: DaemonClient
    function onEventReceived(event, data) {
      switch (event) {
      case "skwd.power.toggle": powerMenu.showing = !powerMenu.showing; break
      case "skwd.power.show":   powerMenu.showing = true;  break
      case "skwd.power.hide":   powerMenu.showing = false; break
      }
    }
  }

  Component.onCompleted: {
    powerMenu.showing = true
  }
}
