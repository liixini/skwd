import Quickshell
import QtQuick
import "qml"
import "qml/launcher"

ShellRoot {
  id: root

  Colors { id: colors }

  AppLauncher {
    id: launcher
    colors: colors
    showing: true
  }

  Connections {
    target: launcher
    function onShowingChanged() {
      if (!launcher.showing) Qt.quit()
    }
  }
}
