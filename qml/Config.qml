pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Singleton that reads data/config.json and exposes all shell configuration.
// Hot-reloads on file change. Used by every component for paths, flags, and intervals.
QtObject {
    id: config

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


    // Directory paths
    readonly property string homeDir: Quickshell.env("HOME")
    readonly property string configDir: homeDir + "/.config/piixident"

    function _resolve(path) { return path ? path.replace("~", homeDir) : "" }

    readonly property string scriptsDir: _resolve(_data.paths?.scripts) || (configDir + "/scripts")
    readonly property string cacheDir: _resolve(_data.paths?.cache) || (homeDir + "/.cache/piixident")
    readonly property string wallpaperDir: _resolve(_data.paths?.wallpaper)
    readonly property string weDir: _resolve(_data.paths?.steamWorkshop)
    readonly property string weAssetsDir: _resolve(_data.paths?.steamWeAssets)
    readonly property string steamDir: _resolve(_data.paths?.steam)


    // Compositor
    readonly property string compositor: _data.compositor ?? "niri"

    // General settings (monitor, network, polling intervals)
    readonly property string mainMonitor: _data.monitor ?? ""
    readonly property string weatherCity: _data.location?.city ?? ""
    readonly property string wifiInterface: _data.network?.wifiInterface ?? ""
    readonly property string ollamaUrl: _data.ollama?.url ?? ""
    readonly property string ollamaModel: _data.ollama?.model ?? ""
    readonly property int weatherPollMs: _data.intervals?.weatherPollMs ?? 0
    readonly property int wifiPollMs: _data.intervals?.wifiPollMs ?? 0
    readonly property int smartHomePollMs: _data.intervals?.smartHomePollMs ?? 0
    readonly property int ollamaStatusPollMs: _data.intervals?.ollamaStatusPollMs ?? 0
    readonly property int notificationExpireMs: _data.intervals?.notificationExpireMs ?? 0


    // Component enable/disable flags
    property var _components: _data.components ?? {}
    readonly property bool barEnabled: _components.bar !== false
    readonly property bool appLauncherEnabled: _components.appLauncher !== false
    readonly property bool wallpaperSelectorEnabled: _components.wallpaperSelector !== false
    readonly property bool windowSwitcherEnabled: _components.windowSwitcher !== false
    readonly property bool workspaceSwitcherEnabled: _components.workspaceSwitcher !== false
    readonly property bool powerMenuEnabled: _components.powerMenu !== false
    readonly property bool notificationsEnabled: _components.notifications !== false
    readonly property bool weatherEnabled: _components.weather !== false
    readonly property bool wifiEnabled: _components.wifi !== false
    readonly property bool bluetoothEnabled: _components.bluetooth !== false
    readonly property bool volumeEnabled: _components.volume !== false
    readonly property bool calendarEnabled: _components.calendar !== false
    readonly property bool lyricsEnabled: _components.lyrics !== false
    // These require extra setup (Home Assistant / PAM lockscreen) and are still WIP.
    readonly property bool lockscreenEnabled: _components.lockscreen === true
    readonly property bool smartHomeEnabled: _components.smartHome === true
}
