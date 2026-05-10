import QtQuick
import Quickshell

import ".." as Root


QtObject {
    id: service

    property var player: null

    property string trackTitle: ""
    property string trackArtist: ""
    property string trackAlbum: ""
    property url trackArtUrl: ""
    property real trackLength: 0

    property bool isPlaying: false
    property bool canPlay: true
    property bool canPause: true
    property bool canGoNext: true
    property bool canGoPrevious: true
    property bool canSeek: false
    property real volume: 1.0
    property bool shuffle: false
    property int loopStatus: 0

    property real position: 0

    property var _positionTimer: Timer {
        interval: 250
        repeat: true
        running: service.isPlaying
        onTriggered: service.position += 250
    }

    function playPause() {
        if (service.isPlaying) DaemonClient.call("music.player.pause", {}, function() {})
        else                    DaemonClient.call("music.player.play",  {}, function() {})
    }
    function next()      { DaemonClient.call("music.player.next",     {}, function() {}) }
    function previous()  { DaemonClient.call("music.player.previous", {}, function() {}) }
    function seek(pos)   { service.position = pos }
    function seekRelative(offset) { service.position = Math.max(0, service.position + offset) }

    function setVolume(vol) {
        var v = Math.round(Math.max(0, Math.min(1, vol)) * 65535)
        service.volume = vol
        DaemonClient.call("music.player.volume", { volume: v }, function() {})
    }

    function toggleShuffle() { service.shuffle = !service.shuffle }
    function cycleLoop() { service.loopStatus = (service.loopStatus + 1) % 3 }

    property var _events: Connections {
        target: DaemonClient
        function onEventReceived(event, data) {
            if (event === "skwd.music.track.changed") {
                service.trackTitle = data.name || ""
                service.trackArtist = data.artist || ""
                service.trackAlbum = data.album || ""
                service.trackLength = data.duration_ms || 0
                service.position = 0
                if (data.covers && data.covers.length > 0) service.trackArtUrl = data.covers[0]
                else service.trackArtUrl = ""
            } else if (event === "skwd.music.playing") {
                service.isPlaying = true
                if (typeof data.position_ms === "number") service.position = data.position_ms
            } else if (event === "skwd.music.paused") {
                service.isPlaying = false
                if (typeof data.position_ms === "number") service.position = data.position_ms
            } else if (event === "skwd.music.stopped" || event === "skwd.music.end_of_track") {
                service.isPlaying = false
            } else if (event === "skwd.music.position" || event === "skwd.music.seeked") {
                if (typeof data.position_ms === "number") service.position = data.position_ms
            } else if (event === "skwd.music.volume") {
                if (typeof data.volume === "number") service.volume = data.volume / 65535
            } else if (event === "skwd.music.shuffle") {
                service.shuffle = !!data.shuffle
            }
        }
    }
}
