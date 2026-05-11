import Quickshell
import QtQuick
import "qml/switcher"

ShellRoot {
  id: root
  SwitchShell {
    id: switchShell
    autoOpen: true
  }
}
