import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import QtQuick

Scope {
  id: notificationShell

  property var historyEntries: []

  Colors { id: colors }

  Process {
    id: ensureHistoryDir
    command: ["mkdir", "-p", Config.historyPath.substring(0, Config.historyPath.lastIndexOf("/"))]
    running: true
  }

  FileView {
    id: historyFile
    path: Config.historyPath
  }

  function _twoDigit(n) { return (n < 10 ? "0" : "") + n }

  function _writeHistory() {
    var text = JSON.stringify(notificationShell.historyEntries.slice(0, Math.max(1, Config.historyMax)), null, 0)
    historyFile.setText(text)
  }

  function _recordNotification(notification) {
    var now = new Date()
    var entry = {
      ts:       now.getTime(),
      appName:  notification.appName  || "",
      summary:  notification.summary  || "",
      body:     notification.body     || "",
      timeText: _twoDigit(now.getHours()) + ":" + _twoDigit(now.getMinutes())
    }
    var arr = notificationShell.historyEntries.slice()
    arr.unshift(entry)
    while (arr.length > Math.max(1, Config.historyMax)) arr.pop()
    notificationShell.historyEntries = arr
    _writeHistory()
  }

  NotificationServer {
    id: notificationServer
    bodySupported: true
    bodyMarkupSupported: true
    imageSupported: true
    actionsSupported: true
    keepOnReload: true

    onNotification: notification => {
      var app = (notification.appName || "").toLowerCase()
      var summary = (notification.summary || "").toLowerCase()
      if ((app === "niri" || app === "hyprland" || app === "sway" || app === "kwin") && summary.indexOf("screenshot") !== -1) {
        notification.dismiss()
        return
      }
      notification.tracked = true
      notificationShell._recordNotification(notification)
    }
  }

  NotificationPopup {
    colors: colors
    notifications: notificationServer.trackedNotifications
  }
}
