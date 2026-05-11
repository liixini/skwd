import Quickshell
import QtQuick
import "qml"

ShellRoot {
  id: root

  SettingsShell {
    id: settingsShell
    showing: true
  }

  Timer {
    id: _quitTimer
    interval: 300
    onTriggered: Qt.quit()
  }

  Connections {
    target: settingsShell
    function onShowingChanged() {
      if (!settingsShell.showing) _quitTimer.restart()
    }
  }
}
