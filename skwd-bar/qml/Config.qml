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
    readonly property string installDir: Quickshell.env("SKWD_BAR_INSTALL") || Quickshell.env("SKWD_INSTALL") || configDir
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
    readonly property int weatherPollMs: _data.intervals?.weatherPollMs ?? 0
    readonly property int wifiPollMs: _data.intervals?.wifiPollMs ?? 0

    
    property var _bar: _data.components?.bar ?? {}
    readonly property bool barEnabled: _bar.enabled !== false
    readonly property var weatherCities: {
        let arr = _bar.weather?.cities
        if (Array.isArray(arr) && arr.length > 0) return arr.filter(s => typeof s === "string" && s.length > 0)
        let single = Quickshell.env("SKWD_WEATHER_CITY") || _bar.weather?.city
        return single ? [single] : []
    }
    readonly property string weatherDefaultCity: {
        let env = Quickshell.env("SKWD_WEATHER_CITY")
        if (env) return env
        let def = _bar.weather?.defaultCity
        if (def) return def
        let single = _bar.weather?.city
        if (single) return single
        return weatherCities.length > 0 ? weatherCities[0] : ""
    }
    readonly property string weatherCity: weatherDefaultCity
    readonly property bool weatherEnabled: _bar.weather !== undefined && _bar.weather !== false && _bar.weather?.enabled !== false
    readonly property string wifiInterface: _bar.wifi?.interface ?? ""
    readonly property bool wifiEnabled: _bar.wifi !== undefined && _bar.wifi !== false && _bar.wifi?.enabled !== false
    readonly property bool bluetoothEnabled: _bar.bluetooth !== false
    readonly property bool volumeEnabled: _bar.volume !== false
    readonly property bool calendarEnabled: _bar.calendar !== false
    readonly property bool musicEnabled: _bar.music !== undefined && _bar.music !== false && _bar.music?.enabled !== false
    readonly property string preferredPlayer: _bar.music?.preferredPlayer ?? "spotify"
    readonly property string visualizerTheme: _bar.music?.visualizer ?? "wave"
    readonly property bool visualizerTop: (_bar.music?.visualizerTop !== false)
    readonly property bool visualizerBottom: (_bar.music?.visualizerBottom !== false)
    readonly property bool musicAutohide: (_bar.music?.autohide !== false)
    readonly property bool musicShowMeta: (_bar.music?.showMeta !== false)
    readonly property bool musicShowLyrics: (_bar.music?.showLyrics !== false)

    property var _viz: _bar.music?.viz ?? ({})
    readonly property real vizAuroraMinAmp:        _viz.aurora?.minAmp        ?? 0.22
    readonly property int  vizAuroraLayerCount:    _viz.aurora?.layerCount    ?? 4
    readonly property real vizAuroraRespPumpExp:   _viz.auroraResponsive?.pumpExp   ?? 0.45
    readonly property real vizAuroraRespPumpScale: _viz.auroraResponsive?.pumpScale ?? 1.4
    readonly property real vizAuroraRespAttack:    _viz.auroraResponsive?.attack    ?? 0.45
    readonly property real vizAuroraRespDecay:     _viz.auroraResponsive?.decay     ?? 0.10
    readonly property int  vizPulsePillWidth:      _viz.pulse?.pillWidth      ?? 3
    readonly property real vizVuPeakDecay:         _viz.vu?.peakDecay         ?? 1.6
    readonly property int  vizSpectrogramCols:     _viz.spectrogram?.cols     ?? 80
    readonly property int  vizStardustCount:       _viz.stardust?.count       ?? 60
    readonly property int  vizCometTrailLen:       _viz.comet?.trailLen       ?? 24
    readonly property real vizRippleThreshold:     _viz.ripple?.threshold     ?? 1.5
    readonly property int  vizRippleMaxAge:        _viz.ripple?.maxAge        ?? 36
}
