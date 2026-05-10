pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: config

    readonly property string homeDir: Quickshell.env("HOME")
    readonly property string configDir: Quickshell.env("SKWD_MUSIC_CONFIG")
        || Quickshell.env("SKWD_CONFIG")
        || homeDir + "/.config/skwd"
    readonly property string cacheDir: Quickshell.env("SKWD_CACHE") || homeDir + "/.cache/skwd"

    property var _data: ({})

    property var _configFile: FileView {
        path: configDir + "/data/config.json"
        preload: true
        watchChanges: true
        onLoaded: config._reparse()
        onFileChanged: { reload(); config._reparse() }
    }

    function _reparse() {
        let raw = _configFile.text() || ""
        if (!raw) return
        try { config._data = JSON.parse(raw) } catch (e) {}
    }
    property var _music: _data.components?.bar?.music || _data.music || {}

    
    readonly property string preferredPlayer: _music.preferredPlayer || "spotify"
    readonly property string librespotDevice: _music.librespotDevice || "skwd-music"
    readonly property string librespotBackend: _music.librespotBackend || "pulseaudio"
    readonly property int librespotBitrate: _music.librespotBitrate || 320
    readonly property string spotifyClientId: _music.spotifyClientId || ""
}
