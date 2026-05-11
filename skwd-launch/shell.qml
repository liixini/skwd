import Quickshell
import QtQuick
import "qml/launcher"

ShellRoot {
  id: root

  LauncherShell {
    id: launcherShell
    showing: true
  }

  Connections {
    target: launcherShell
    function onShowingChanged() {
      if (!launcherShell.showing) Qt.quit()
    }
  }
}
