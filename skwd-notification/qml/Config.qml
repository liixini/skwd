pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: config

    function _resolve(path) { return path ? path.replace("~", homeDir) : "" }

    readonly property string homeDir: Quickshell.env("HOME")
    
    
    readonly property string configDir: Quickshell.env("SKWD_CONFIG")
        || (Quickshell.env("XDG_CONFIG_HOME") || (homeDir + "/.config")) + "/skwd"
    readonly property string cacheDir: _resolve(_data.paths?.cache)
        || (Quickshell.env("XDG_CACHE_HOME") || (homeDir + "/.cache")) + "/skwd"

    property var _data: ({})

    property var _configFile: FileView {
        path: configDir + "/data/config.json"
        preload: true
        watchChanges: true
        onLoaded: config._reparse()
        onFileChanged: { reload(); config._reparse() }
    }

    function _reparse() {
        var raw = _configFile.text() || ""
        if (!raw) return
        try { config._data = JSON.parse(raw) } catch (e) {}
    }

    readonly property string mainMonitor: _data.monitor ?? ""

    property var _notif: _data.notifications ?? {}
    readonly property int notificationExpireMs: _notif.expireMs ?? 5000
    readonly property int popupMaxVisible: _notif.popupMaxVisible ?? 4
    readonly property int popupWidth: _notif.popupWidth ?? 320
    readonly property int popupRightMargin: _notif.popupRightMargin ?? 16
    readonly property int popupLeftMargin:  _notif.popupLeftMargin  ?? popupRightMargin
    readonly property int popupTopMargin: _notif.popupTopMargin ?? 12
    readonly property string popupSide: (_notif.popupSide === "left" ? "left" : "right")
    readonly property int historyMax: _notif.historyMax ?? 200
    readonly property string historyPath: (Quickshell.env("XDG_RUNTIME_DIR") || "/tmp") + "/skwd/notifications.json"
}
