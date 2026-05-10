pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import ".."


QtObject {
    id: service

    
    property string state: "idle"
    property var lines: []
    property bool enhanced: false
    property string playerName: ""

    
    signal lyricsReady(var data)
    signal lyricsCleared()
    signal lyricsSearching()
    signal lyricsNotFound()

    
    property string _lastTrackKey: ""

    function _isActiveTrackRequest(trackKey) {
        return trackKey && trackKey === _lastTrackKey
    }

    property var _pollTimer: Timer {
        interval: 1000
        repeat: true
        running: Config.musicEnabled
        onTriggered: service._checkTrack()
    }

    property var _configWatch: Connections {
        target: Config
        function onMusicEnabledChanged() {
            if (!Config.musicEnabled) {
                service._lastTrackKey = ""
                service.state = "idle"
                service.lines = []
                service.enhanced = false
                service.playerName = ""
                service.lyricsCleared()
            }
        }
    }

    function _checkTrack() {
        var player = _findActivePlayer()
        if (!player || !player.isPlaying) {
            if (_lastTrackKey !== "") {
                _lastTrackKey = ""
                state = "idle"
                lines = []
                enhanced = false
                lyricsCleared()
            }
            return
        }

        var artist = player.trackArtist || ""
        var title = player.trackTitle || ""
        if (!artist || !title) return

        var cleanTitle = title
        if (artist && cleanTitle.toLowerCase().indexOf(artist.toLowerCase() + " - ") === 0)
            cleanTitle = cleanTitle.substring(artist.length + 3)

        var key = artist + "|||" + cleanTitle
        if (key === _lastTrackKey) return

        _lastTrackKey = key
        playerName = player.identity || ""
        state = "searching"
        lyricsSearching()
        _fetchLyrics(artist, cleanTitle, key)
    }

    function _findActivePlayer() {
        if (!Mpris.players) return null
        var preferred = Config.preferredPlayer.toLowerCase()
        var preferredPlaying = null
        var anyPlaying = null

        for (var i = 0; i < Mpris.players.values.length; i++) {
            var p = Mpris.players.values[i]
            if (!p) continue
            var id = (p.identity || "").toLowerCase()
            if (id.indexOf(preferred) !== -1 && p.isPlaying)
                preferredPlaying = p
            if (p.isPlaying && !anyPlaying)
                anyPlaying = p
        }
        return preferredPlaying || anyPlaying
    }

    
    function _fetchLyrics(artist, title, trackKey) {
        DaemonClient.call("lyrics.get", {artist: artist, title: title}, function(result, err) {
            if (err) {
                console.warn("lyrics.get error:", JSON.stringify(err))
                if (service._isActiveTrackRequest(trackKey)) {
                    service.state = "nolyrics"
                    service.lines = []
                    service.lyricsNotFound()
                }
                return
            }

            if (!service._isActiveTrackRequest(trackKey))
                return

            if (result && result.lines && result.lines.length > 0) {
                service.lines = result.lines
                service.enhanced = result.enhanced || false
                service.state = "haslyrics"
                service.lyricsReady({
                    lines: result.lines,
                    enhanced: result.enhanced || false,
                    player: service.playerName
                })
            } else {
                service.state = "nolyrics"
                service.lines = []
                service.lyricsNotFound()
            }
        })
    }
}
