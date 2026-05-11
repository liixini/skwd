import Quickshell
import QtQuick
import ".."
import "../services"

Scope {
  id: switchShell

  property bool startIpc: true
  property bool autoOpen: false

  Colors { id: colors }

  WindowSwitcher {
    id: switcher
    colors: colors
  }

  function open()    { switcher.open() }
  function next()    { if (!switcher.showing) switcher.open(); else switcher.next() }
  function prev()    { if (!switcher.showing) switcher.open(); else switcher.prev() }
  function confirm() { switcher.confirm() }
  function cancel()  { switcher.cancel() }
  function closeSelected() { switcher.closeSelected() }

  Component.onCompleted: {
    if (switchShell.startIpc) {
      IpcSwitchService.start()
      IpcSwitchService.switchOpen.connect(function()    { switchShell.open() })
      IpcSwitchService.switchNext.connect(function()    { switchShell.next() })
      IpcSwitchService.switchPrev.connect(function()    { switchShell.prev() })
      IpcSwitchService.switchConfirm.connect(function() { switchShell.confirm() })
      IpcSwitchService.switchCancel.connect(function()  { switchShell.cancel() })
      IpcSwitchService.switchClose.connect(function()   { switchShell.closeSelected() })
    }
    if (switchShell.autoOpen) switchShell.open()
  }
}
