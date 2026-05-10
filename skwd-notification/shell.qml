import Quickshell
import Quickshell.Services.Notifications
import QtQuick
import "qml"

ShellRoot {
    id: root

    Colors { id: colors }

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
        }
    }

    NotificationPopup {
        colors: colors
        notifications: notificationServer.trackedNotifications
    }
}
