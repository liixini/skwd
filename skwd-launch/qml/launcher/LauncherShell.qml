import Quickshell
import QtQuick
import ".."

Scope {
  id: launcherShell

  property bool showing: false

  Colors { id: colors }

  AppLauncher {
    id: launcher
    colors: colors
  }

  onShowingChanged: {
    if (launcher.showing !== launcherShell.showing) {
      launcher.showing = launcherShell.showing
    }
  }

  Connections {
    target: launcher
    function onShowingChanged() {
      if (launcher.showing !== launcherShell.showing) {
        launcherShell.showing = launcher.showing
      }
    }
  }
}
