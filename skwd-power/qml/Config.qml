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
    readonly property string installDir: Quickshell.env("SKWD_POWER_INSTALL") || Quickshell.env("SKWD_INSTALL") || configDir
    readonly property string runtimeDir: (Quickshell.env("XDG_RUNTIME_DIR") || "/tmp") + "/skwd"
    readonly property string cacheDir: _resolve(_data.paths?.cache)
        || Quickshell.env("SKWD_CACHE")
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


    readonly property string compositor: _data.compositor ?? "niri"
    readonly property string mainMonitor: _data.monitor ?? ""

    readonly property var powerMenuOptions: {
        var arr = _data.power?.options
        return Array.isArray(arr) ? arr : []
    }

    readonly property real uiScale: _data.uiScale ?? 1.0
}
