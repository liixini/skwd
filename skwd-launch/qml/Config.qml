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
    readonly property string installDir: Quickshell.env("SKWD_LAUNCH_INSTALL") || Quickshell.env("SKWD_INSTALL") || configDir
    readonly property string runtimeDir: (Quickshell.env("XDG_RUNTIME_DIR") || "/tmp") + "/skwd"
    readonly property string scriptsDir: _resolve(_data.paths?.scripts) || (installDir + "/scripts")
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
    readonly property string terminal: _data.terminal ?? "kitty"

    
    readonly property string steamDir: _resolve(_data.paths?.steam)

    
    readonly property string splashDir: _resolve(_data.paths?.splash) || (homeDir + "/appsplash")

    
    readonly property real uiScale: Math.max(1.0, Math.min(2.0, _data.general?.uiScale ?? 1.0))

    
    property var _launcher: _data.components?.appLauncher ?? {}
    readonly property string displayMode: _launcher.displayMode ?? "slice"
    readonly property int sliceWidth: _launcher.sliceWidth ?? 135
    readonly property int expandedWidth: _launcher.expandedWidth ?? 924
    readonly property int sliceHeight: _launcher.sliceHeight ?? 520
    readonly property int skewOffset: _launcher.skewOffset ?? 35
    readonly property int sliceSpacing: _launcher.sliceSpacing ?? -22
    readonly property int visibleCount: _launcher.visibleCount ?? 12
    readonly property bool sliceRoundCorners: _launcher.roundCorners === true
    readonly property int sliceCornerRadius: sliceRoundCorners ? (_launcher.cornerRadius ?? 16) : 0

    
    readonly property var customPresets: _launcher.customPresets ?? ({})

    
    readonly property int hexRadius:        _launcher.hexRadius        ?? 140
    readonly property int hexRows:          _launcher.hexRows          ?? 3
    readonly property int hexCols:          _launcher.hexCols          ?? 7
    readonly property int hexScrollStep:    _launcher.hexScrollStep    ?? 1
    readonly property bool hexArc:          _launcher.hexArc           !== false
    readonly property real hexArcIntensity: _launcher.hexArcIntensity  ?? 1.2

    
    readonly property int gridColumns:      _launcher.gridColumns      ?? 6
    readonly property int gridRows:         _launcher.gridRows         ?? 3
    readonly property int gridThumbWidth:   _launcher.gridThumbWidth   ?? 300
    readonly property int gridThumbHeight:  _launcher.gridThumbHeight  ?? 169

    
    readonly property int mosaicCells:      _launcher.mosaicCells      ?? 48
    readonly property int mosaicSeed:       _launcher.mosaicSeed       ?? 7
    readonly property int mosaicRelaxation: _launcher.mosaicRelaxation ?? 2
    readonly property int mosaicWidth:      _launcher.mosaicWidth      ?? 1500
    readonly property int mosaicHeight:     _launcher.mosaicHeight     ?? 800

    function saveKey(path, value) {
        _configWriter.reload()
        var data
        try { data = JSON.parse(_configWriter.text()) } catch(e) { data = {} }
        var parts = path.split(".")
        var obj = data
        for (var i = 0; i < parts.length - 1; i++) {
            if (typeof obj[parts[i]] !== "object" || obj[parts[i]] === null)
                obj[parts[i]] = {}
            obj = obj[parts[i]]
        }
        obj[parts[parts.length - 1]] = value
        _configWriter.setText(JSON.stringify(data, null, 2) + "\n")
    }

    property var _configWriter: FileView {
        path: configDir + "/data/config.json"
        preload: true
    }
}
