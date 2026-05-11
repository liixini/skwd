import Quickshell
import QtQuick
import ".."

Scope {
  id: powerShell

  property bool showing: false

  Colors { id: colors }

  PowerMenu {
    id: powerMenu
    colors: colors
  }

  onShowingChanged: {
    if (powerMenu.showing !== powerShell.showing) {
      powerMenu.showing = powerShell.showing
    }
  }

  Connections {
    target: powerMenu
    function onShowingChanged() {
      if (powerMenu.showing !== powerShell.showing) {
        powerShell.showing = powerMenu.showing
      }
    }
  }
}
