pragma Singleton
import QtQuick
import Quickshell
import "services"


QtObject {
    id: config

    function _resolve(path) { return path ? path.replace("~", homeDir) : "" }

    readonly property string homeDir: Quickshell.env("HOME")
    readonly property string configDir: Quickshell.env("SKWD_CONFIG")
        || (Quickshell.env("XDG_CONFIG_HOME") || (homeDir + "/.config")) + "/skwd"
    readonly property string configFilePath: configDir + "/data/config.json"
    readonly property string mdiIconsPath: configDir + "/data/mdi-icons.json"

    readonly property string wallConfigDir: Quickshell.env("SKWD_WALL_CONFIG")
        || (Quickshell.env("XDG_CONFIG_HOME") || (homeDir + "/.config")) + "/skwd-wall"
    readonly property string wallConfigFilePath: wallConfigDir + "/config.json"

    readonly property string cacheDir: Quickshell.env("SKWD_CACHE")
        || (Quickshell.env("XDG_CACHE_HOME") || (homeDir + "/.cache")) + "/skwd"

    readonly property var _data: SettingsService.data ?? ({})

    readonly property real uiScale: _data.uiScale ?? 1.0
    readonly property bool devMode: _data.dev === true
    readonly property string mainMonitor: _data.monitor ?? ""
    readonly property string terminal: _data.terminal ?? "kitty"
    readonly property string splashDir: _resolve(_data.paths?.splash) || (homeDir + "/appsplash")
    readonly property string steamDir: _resolve(_data.paths?.steam)
    readonly property string appsConfigPath: configDir + "/data/apps.json"
    readonly property string appLauncherCachePath: cacheDir + "/app-launcher/list.jsonl"

    property var _launcher: _data.components?.appLauncher ?? {}
    readonly property var    launchCustomPresets:  _launcher.customPresets   ?? ({})
    readonly property string launchDisplayMode:    _launcher.displayMode    ?? "slice"
    readonly property int    launchSliceWidth:     _launcher.sliceWidth     ?? 135
    readonly property int    launchExpandedWidth:  _launcher.expandedWidth  ?? 924
    readonly property int    launchSliceHeight:    _launcher.sliceHeight    ?? 520
    readonly property int    launchSkewOffset:     _launcher.skewOffset     ?? 35
    readonly property int    launchSliceSpacing:   _launcher.sliceSpacing   ?? -22
    readonly property int    launchVisibleCount:   _launcher.visibleCount   ?? 12
    readonly property bool   launchSliceRoundCorners: _launcher.roundCorners === true
    readonly property int    launchSliceCornerRadius: _launcher.cornerRadius ?? 16
    readonly property int    launchHexRadius:      _launcher.hexRadius      ?? 140
    readonly property int    launchHexRows:        _launcher.hexRows        ?? 3
    readonly property int    launchHexCols:        _launcher.hexCols        ?? 7
    readonly property int    launchHexScrollStep:  _launcher.hexScrollStep  ?? 1
    readonly property bool   launchHexArc:         _launcher.hexArc         !== false
    readonly property real   launchHexArcIntensity:_launcher.hexArcIntensity?? 1.2
    readonly property int    launchGridColumns:    _launcher.gridColumns    ?? 6
    readonly property int    launchGridRows:       _launcher.gridRows       ?? 3
    readonly property int    launchGridThumbWidth: _launcher.gridThumbWidth ?? 300
    readonly property int    launchGridThumbHeight:_launcher.gridThumbHeight?? 169
    readonly property int    launchMosaicCells:    _launcher.mosaicCells    ?? 48
    readonly property int    launchMosaicSeed:     _launcher.mosaicSeed     ?? 7
    readonly property int    launchMosaicRelaxation: _launcher.mosaicRelaxation ?? 2
    readonly property int    launchMosaicWidth:    _launcher.mosaicWidth    ?? 1500
    readonly property int    launchMosaicHeight:   _launcher.mosaicHeight   ?? 800

    
    property var _bar: _data.components?.bar ?? {}
    readonly property bool   barEnabled:        _bar.enabled !== false
    readonly property bool   barMouseoverEnabled: _bar.mouseoverEnabled !== false
    readonly property bool   barBrightnessEnabled: _bar.brightness !== undefined && _bar.brightness !== false && _bar.brightness?.enabled !== false
    readonly property bool   barBatteryEnabled:    _bar.battery !== false && _bar.battery?.enabled !== false
    readonly property bool   barNotificationsEnabled: _bar.notifications?.enabled === true
    readonly property bool   barNotificationsHideWhenEmpty: _bar.notifications?.hideWhenEmpty === true
    readonly property bool   barNotificationsAlwaysShowIfPresent: _bar.notifications?.alwaysShowIfPresent === true
    readonly property int    barNotificationsHistoryMax: _bar.notifications?.historyMax ?? 50
    property var _battery: _bar.battery ?? ({})
    readonly property var    barBatteryNotifyRules: Array.isArray(_battery.notify) ? _battery.notify : []

    readonly property var _defaultBarLeftLayout:  ["cpu", "gpu", "memory"]
    readonly property var _defaultBarRightLayout: ["weather", "bluetooth", "wifi", "brightness", "battery", "volume", "notifications", "clock"]
    readonly property var allBarWidgets: ["cpu", "gpu", "memory", "weather", "bluetooth", "wifi", "volume", "clock", "brightness", "battery", "notifications"]
    readonly property var barWidgetLabels: ({
        "cpu": "CPU",
        "gpu": "GPU",
        "memory": "Memory",
        "weather": "Weather",
        "bluetooth": "Bluetooth",
        "wifi": "Wi-Fi",
        "volume": "Volume",
        "clock": "Clock",
        "brightness": "Brightness",
        "battery": "Battery",
        "notifications": "Notifications"
    })
    readonly property var barWidgetIcons: ({
        "cpu":           "󰻠",
        "gpu":           "󰢮",
        "memory":        "󰍛",
        "weather":       "󰖐",
        "bluetooth":     "󰂯",
        "wifi":          "󰤨",
        "volume":        "󰕾",
        "clock":         "󰥔",
        "brightness":    "󰃠",
        "battery":       "󰁹",
        "notifications": "󰂚"
    })
    readonly property var barLeftLayout:  Array.isArray(_bar.leftLayout)  ? _bar.leftLayout.filter(s => allBarWidgets.indexOf(s) !== -1)  : _defaultBarLeftLayout
    readonly property var barRightLayout: Array.isArray(_bar.rightLayout) ? _bar.rightLayout.filter(s => allBarWidgets.indexOf(s) !== -1) : _defaultBarRightLayout
    readonly property var barWidgetOverrides: (typeof _bar.widgets === "object" && _bar.widgets !== null) ? _bar.widgets : ({})
    function barWidgetIconOverride(id)  { var o = barWidgetOverrides[id]; return (o && o.icon)  ? o.icon  : "" }
    function barWidgetLabelOverride(id) { var o = barWidgetOverrides[id]; return (o && o.label) ? o.label : "" }
    function barWidgetMouseoverEnabled(id) { var o = barWidgetOverrides[id]; return !!(o && o.mouseover) }
    readonly property bool   barWeatherEnabled: _bar.weather !== undefined && _bar.weather !== false && _bar.weather?.enabled !== false
    readonly property string barWeatherCity:    _bar.weather?.city ?? ""
    readonly property var    barWeatherCities:  Array.isArray(_bar.weather?.cities) ? _bar.weather.cities : (_bar.weather?.city ? [_bar.weather.city] : [])
    readonly property string barWeatherDefaultCity: _bar.weather?.defaultCity ?? _bar.weather?.city ?? (Array.isArray(_bar.weather?.cities) && _bar.weather.cities.length > 0 ? _bar.weather.cities[0] : "")
    readonly property bool   barWifiEnabled:    _bar.wifi !== undefined && _bar.wifi !== false && _bar.wifi?.enabled !== false
    readonly property string barWifiInterface:  _bar.wifi?.interface ?? ""
    readonly property bool   barBluetoothEnabled: _bar.bluetooth !== false
    readonly property bool   barVolumeEnabled:  _bar.volume !== false
    readonly property bool   barCalendarEnabled:_bar.calendar !== false
    readonly property bool   barMusicEnabled:   _bar.music !== undefined && _bar.music !== false && _bar.music?.enabled !== false
    readonly property string barMusicVisualizer:_bar.music?.visualizer ?? "wave"
    readonly property bool   barMusicVisualizerTop:    (_bar.music?.visualizerTop !== false)
    readonly property bool   barMusicVisualizerBottom: (_bar.music?.visualizerBottom !== false)
    readonly property bool   barMusicAutohide:  (_bar.music?.autohide !== false)
    readonly property bool   barMusicShowMeta:  (_bar.music?.showMeta !== false)
    readonly property bool   barMusicShowLyrics:(_bar.music?.showLyrics !== false)
    readonly property bool   barMusicAlwaysHoverable: (_bar.music?.alwaysHoverable === true)
    readonly property bool   barMusicCleanVisualizer: (_bar.music?.cleanVisualizer === true)
    readonly property bool   barMusicShowLyricsStatus: (_bar.music?.showLyricsStatus !== false)

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

    
    property var _music: _data.components?.bar?.music ?? _data.music ?? {}
    readonly property string musicPreferredPlayer:  _music.preferredPlayer ?? "spotify"
    readonly property string musicLibrespotDevice:  _music.librespotDevice ?? "skwd-music"
    readonly property string musicLibrespotBackend: _music.librespotBackend ?? "pulseaudio"
    readonly property int    musicLibrespotBitrate: _music.librespotBitrate ?? 320
    readonly property string musicSpotifyClientId:  _music.spotifyClientId ?? ""

    
    property var _notif: _data.notifications ?? {}
    readonly property int notifExpireMs:        _notif.expireMs ?? 5000
    readonly property int notifPopupMaxVisible: _notif.popupMaxVisible ?? 4
    readonly property int notifPopupWidth:      _notif.popupWidth ?? 320
    readonly property int notifPopupRightMargin:_notif.popupRightMargin ?? 16
    readonly property int notifPopupLeftMargin: _notif.popupLeftMargin  ?? notifPopupRightMargin
    readonly property int notifPopupTopMargin:  _notif.popupTopMargin ?? 12
    readonly property string notifPopupSide:    _notif.popupSide === "left" ? "left" : "right"
    readonly property string notifBuiltIn:      _notif.builtIn ?? "auto"

    readonly property var powerOptions: {
        var arr = _data.power?.options
        return Array.isArray(arr) ? arr : _powerDefaults
    }
    readonly property var _powerDefaults: [
        { label: "Lock",     icon: "󰌾", action: "lock",     enabled: true },
        { label: "Logout",   icon: "󰍃", action: "logout",   enabled: true },
        { label: "Reboot",   icon: "󰜉", action: "reboot",   enabled: true },
        { label: "Poweroff", icon: "󰐥", action: "poweroff", enabled: true }
    ]

    readonly property var _wallFeatures: (SettingsService.wallData && SettingsService.wallData.features) || ({})
    readonly property bool featMatugen:   _wallFeatures.matugen   !== false
    readonly property bool featOllama:    _wallFeatures.ollama    === true
    readonly property bool featSteam:     _wallFeatures.steam     === true
    readonly property bool featWallhaven: _wallFeatures.wallhaven === true
    readonly property bool featLyrics:    _wallFeatures.lyrics    !== false
    readonly property bool featMusic:     _wallFeatures.music     !== false
    readonly property bool featAnalysis:  _wallFeatures.analysis  !== false
    readonly property bool featVideo:     _wallFeatures.video     !== false

    
    readonly property string switchDisplayMode:        _data.switcher?.displayMode        ?? "slice"
    readonly property int    switchSliceWidth:         _data.switcher?.sliceWidth         ?? 135
    readonly property int    switchSliceExpandedWidth: _data.switcher?.sliceExpandedWidth ?? 924
    readonly property int    switchSliceHeight:        _data.switcher?.sliceHeight        ?? 520
    readonly property int    switchSliceSkewOffset:    _data.switcher?.sliceSkewOffset    ?? 35
    readonly property int    switchSliceSpacing:       _data.switcher?.sliceSpacing       ?? -22
    readonly property int    switchSliceVisibleCount:  _data.switcher?.sliceVisibleCount  ?? 12
    readonly property int    switchCardWidth:          _data.switcher?.cardWidth          ?? 1600
    readonly property int    switchCardHeightPad:      _data.switcher?.cardHeightPad      ?? 40
    readonly property int    switchAnimFadeIn:         _data.switcher?.animFadeIn         ?? 400
    readonly property real   switchDimOpacity:         _data.switcher?.dimOpacity         ?? 0.5

    readonly property int    switchGridColumns:        _data.switcher?.gridColumns        ?? 5
    readonly property int    switchGridRows:           _data.switcher?.gridRows           ?? 4
    readonly property int    switchGridCellWidth:      _data.switcher?.gridCellWidth      ?? 240
    readonly property int    switchGridCellHeight:     _data.switcher?.gridCellHeight     ?? 170
    readonly property int    switchGridSpacing:        _data.switcher?.gridSpacing        ?? 14
    readonly property int    switchGridIconSize:       _data.switcher?.gridIconSize       ?? 64

    readonly property int    switchCompactCellWidth:   _data.switcher?.compactCellWidth   ?? 92
    readonly property int    switchCompactCellHeight:  _data.switcher?.compactCellHeight  ?? 110
    readonly property int    switchCompactSpacing:     _data.switcher?.compactSpacing     ?? 8
    readonly property int    switchCompactIconSize:    _data.switcher?.compactIconSize    ?? 56
    readonly property int    switchCompactCardPad:     _data.switcher?.compactCardPad     ?? 28

    readonly property int    switchWheelOuterRadius: _data.switcher?.wheelOuterRadius ?? 320
    readonly property int    switchWheelInnerRadius: _data.switcher?.wheelInnerRadius ?? 90
    readonly property int    switchWheelIconSize:    _data.switcher?.wheelIconSize    ?? 80
    readonly property int    switchWheelGap:         _data.switcher?.wheelGap         ?? 4
    readonly property real   switchWheelStartAngle:  _data.switcher?.wheelStartAngle  ?? -90.0
}
