import Quickshell
import QtQuick
import "qml"


ShellRoot {
  id: root

  Colors { id: colors }

  SettingsWindow {
    id: settingsWindow
    colors: colors
    
    
    onCloseRequested: _quitTimer.restart()
  }

  Timer {
    id: _quitTimer
    interval: 300
    onTriggered: Qt.quit()
  }
}
