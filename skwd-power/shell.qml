import Quickshell
import QtQuick
import "qml/power"

ShellRoot {
  id: root

  PowerShell {
    id: powerShell
    showing: true
  }

  Connections {
    target: powerShell
    function onShowingChanged() {
      if (!powerShell.showing) Qt.quit()
    }
  }
}
