pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Singleton that reads data/config.json and exposes all shell configuration.
// Hot-reloads on file change. Used by every component for paths, flags, and intervals.
QtObject {
    id: config

    function _resolve(path) { return path ? path.replace("~", homeDir) : "" }

    // Directory paths
    readonly property string homeDir: Quickshell.env("HOME")
    readonly property string configDir: Quickshell.env("SKWD_CONFIG")
        || (Quickshell.env("XDG_CONFIG_HOME") || (homeDir + "/.config")) + "/skwd"
    readonly property string installDir: Quickshell.env("SKWD_INSTALL") || configDir

    // Config file loader (auto-reloads on change)
    property var _configFile: FileView {
        path: configDir + "/data/config.json"
        preload: true
        watchChanges: true
        onFileChanged: _configFile.reload()
    }
    property string _rawText: _configFile.__text ?? ""
    property var _data: {
        var raw = _rawText
        if (!raw) return {}
        try { return JSON.parse(raw) }
        catch (e) { return {} }
    }


    readonly property string scriptsDir: _resolve(_data.paths?.scripts) || (installDir + "/scripts")
    readonly property string cacheDir: _resolve(_data.paths?.cache)
        || Quickshell.env("SKWD_CACHE")
        || (Quickshell.env("XDG_CACHE_HOME") || (homeDir + "/.cache")) + "/skwd"
    readonly property string wallpaperDir: _resolve(_data.paths?.wallpaper)
    readonly property string weDir: _resolve(_data.paths?.steamWorkshop)
    readonly property string weAssetsDir: _resolve(_data.paths?.steamWeAssets)
    readonly property string steamDir: _resolve(_data.paths?.steam)


    // Compositor
    readonly property string compositor: _data.compositor ?? "niri"

    // General settings (monitor, polling intervals)
    readonly property string mainMonitor: _data.monitor ?? ""
    readonly property string ollamaUrl: Quickshell.env("SKWD_OLLAMA_URL") || (_data.ollama?.url ?? "")
    readonly property string ollamaModel: _data.ollama?.model ?? ""
    readonly property int weatherPollMs: _data.intervals?.weatherPollMs ?? 0
    readonly property int wifiPollMs: _data.intervals?.wifiPollMs ?? 0
    readonly property int smartHomePollMs: _data.intervals?.smartHomePollMs ?? 0
    readonly property int ollamaStatusPollMs: _data.intervals?.ollamaStatusPollMs ?? 0
    readonly property int notificationExpireMs: _data.intervals?.notificationExpireMs ?? 0


    // Terminal emulator used to launch apps with Terminal=true in their .desktop entry.
    readonly property string terminal: _data.terminal ?? "kitty"

    // Bar widget settings and toggles
    property var _bar: _data.components?.bar ?? {}
    readonly property bool barEnabled: _bar.enabled !== false
    readonly property string weatherCity: Quickshell.env("SKWD_WEATHER_CITY") || (_bar.weather?.city ?? "")
    readonly property bool weatherEnabled: _bar.weather !== undefined && _bar.weather !== false
    readonly property string wifiInterface: _bar.wifi?.interface ?? ""
    readonly property bool wifiEnabled: _bar.wifi !== undefined && _bar.wifi !== false
    readonly property bool bluetoothEnabled: _bar.bluetooth !== false
    readonly property bool volumeEnabled: _bar.volume !== false
    readonly property bool calendarEnabled: _bar.calendar !== false
    readonly property bool musicEnabled: _bar.music !== undefined && _bar.music !== false && _bar.music?.enabled !== false
    readonly property string preferredPlayer: _bar.music?.preferredPlayer ?? "spotify"
    readonly property string visualizerTheme: _bar.music?.visualizer ?? "wave"
    readonly property bool visualizerTop: (_bar.music?.visualizerTop !== false)
    readonly property bool visualizerBottom: (_bar.music?.visualizerBottom !== false)
    readonly property bool musicAutohide: (_bar.music?.autohide !== false)

    // Standalone component enable/disable flags
    property var _components: _data.components ?? {}
    readonly property bool appLauncherEnabled: _components.appLauncher !== false
    readonly property bool wallpaperSelectorEnabled: _components.wallpaperSelector !== false
    readonly property bool windowSwitcherEnabled: _components.windowSwitcher !== false
    readonly property bool powerMenuEnabled: _components.powerMenu !== false && _components.powerMenu?.enabled !== false
    readonly property var powerMenuOptions: _components.powerMenu?.items ?? (Array.isArray(_components.powerMenu) ? _components.powerMenu : [])
    readonly property bool notificationsEnabled: _components.notifications !== false
    // These require extra setup (Home Assistant / PAM lockscreen) and are still WIP.
    readonly property bool lockscreenEnabled: _components.lockscreen === true
    readonly property bool smartHomeEnabled: _components.smartHome === true
}
