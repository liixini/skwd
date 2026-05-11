import Quickshell
import QtQuick
import "."

Scope {
  id: settingsShell

  property bool showing: false

  Colors { id: colors }

  SettingsWindow {
    id: settingsWindow
    colors: colors
    onCloseRequested: settingsShell.showing = false
  }

  onShowingChanged: {
    if (settingsWindow.showing !== settingsShell.showing) {
      settingsWindow.showing = settingsShell.showing
    }
  }

  Connections {
    target: settingsWindow
    function onShowingChanged() {
      if (settingsWindow.showing !== settingsShell.showing) {
        settingsShell.showing = settingsWindow.showing
      }
    }
  }
}
