import Quickshell
import Quickshell.Io
import QtQuick
import "qml"
import "qml/switcher"
import "qml/services"

ShellRoot {
  id: root

  Colors { id: colors }

  WindowSwitcher {
    id: switcher
    colors: colors
  }

  Component.onCompleted: {
    IpcSwitchService.start()
    IpcSwitchService.switchOpen.connect(function() { switcher.open() })
    IpcSwitchService.switchNext.connect(function() {
      if (!switcher.showing) switcher.open()
      else switcher.next()
    })
    IpcSwitchService.switchPrev.connect(function() {
      if (!switcher.showing) switcher.open()
      else switcher.prev()
    })
    IpcSwitchService.switchConfirm.connect(function() { switcher.confirm() })
    IpcSwitchService.switchCancel.connect(function() { switcher.cancel() })
    IpcSwitchService.switchClose.connect(function() { switcher.closeSelected() })

    
    switcher.open()
  }
}
