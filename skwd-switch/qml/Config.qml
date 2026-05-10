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
    readonly property string installDir: Quickshell.env("SKWD_SWITCH_INSTALL") || Quickshell.env("SKWD_INSTALL") || configDir
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

    
    readonly property string displayMode: _data.switcher?.displayMode ?? "slice"

    
    readonly property int sliceWidth:        _data.switcher?.sliceWidth        ?? 135
    readonly property int sliceExpandedWidth:_data.switcher?.sliceExpandedWidth ?? 924
    readonly property int sliceHeight:       _data.switcher?.sliceHeight       ?? 520
    readonly property int sliceSkewOffset:   _data.switcher?.sliceSkewOffset   ?? 35
    readonly property int sliceSpacing:      _data.switcher?.sliceSpacing      ?? -22
    readonly property int sliceVisibleCount: _data.switcher?.sliceVisibleCount ?? 12


    readonly property int cardWidth:  _data.switcher?.cardWidth  ?? 1600
    readonly property int cardHeightPad: _data.switcher?.cardHeightPad ?? 40


    readonly property int gridColumns:     _data.switcher?.gridColumns     ?? 5
    readonly property int gridRows:        _data.switcher?.gridRows        ?? 4
    readonly property int gridCellWidth:   _data.switcher?.gridCellWidth   ?? 240
    readonly property int gridCellHeight:  _data.switcher?.gridCellHeight  ?? 170
    readonly property int gridSpacing:     _data.switcher?.gridSpacing     ?? 14
    readonly property int gridIconSize:    _data.switcher?.gridIconSize    ?? 64


    readonly property int compactCellWidth:  _data.switcher?.compactCellWidth  ?? 92
    readonly property int compactCellHeight: _data.switcher?.compactCellHeight ?? 110
    readonly property int compactSpacing:    _data.switcher?.compactSpacing    ?? 8
    readonly property int compactIconSize:   _data.switcher?.compactIconSize   ?? 56
    readonly property int compactCardPad:    _data.switcher?.compactCardPad    ?? 28


    readonly property int  wheelOuterRadius: _data.switcher?.wheelOuterRadius ?? 320
    readonly property int  wheelInnerRadius: _data.switcher?.wheelInnerRadius ?? 90
    readonly property int  wheelIconSize:    _data.switcher?.wheelIconSize    ?? 80
    readonly property int  wheelGap:         _data.switcher?.wheelGap         ?? 4
    readonly property real wheelStartAngle:  _data.switcher?.wheelStartAngle  ?? -90.0

    readonly property int  animFadeIn:  _data.switcher?.animFadeIn  ?? 400
    readonly property real dimOpacity:  _data.switcher?.dimOpacity  ?? 0.5
}
