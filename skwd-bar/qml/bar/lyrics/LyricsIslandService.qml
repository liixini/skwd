import Quickshell.Io
import Quickshell.Services.Mpris
import QtQuick
import "../../services"

QtObject {
  id: service

  required property string installDir
  required property string scriptsDir
  required property string preferredPlayer

  
  property string currentLyric: ""
  property string previousLyric: ""
  property real lyricProgress: 0.0
  property var lyricLines: []
  property int lyricCurrentIdx: -1
  property bool lyricEnhanced: false
  property string lyricState: "idle"
  property bool lyricClearing: false
  property var pendingLyricData: null

  
  property real syncWallTime: 0
  property real syncTrackMs: 0

  
  property var audioBars: [0,0,0,0,0,0,0,0,0,0,0,0,0,0]
  signal audioBarsUpdated()

  signal clearAnimationRequested()

  function estimatedTrackMs() {
    if (syncWallTime <= 0) return 0
    return syncTrackMs + (Date.now() - syncWallTime)
  }

  function requestClear(pendingData) {
    if (currentLyric === "" && lyricLines.length === 0) {
      if (pendingData) loadLyricData(pendingData)
      return
    }
    lyricClearing = true
    pendingLyricData = pendingData || null
    
    
    lyricLines = []
    lyricCurrentIdx = -1
    syncWallTime = 0
    syncTrackMs = 0
    clearAnimationRequested()
  }

  function finishClear() {
    lyricLines = []
    lyricCurrentIdx = -1
    currentLyric = ""
    lyricProgress = 0.0
    syncWallTime = 0
    lyricEnhanced = false
    lyricClearing = false
    if (pendingLyricData) {
      loadLyricData(pendingLyricData)
      pendingLyricData = null
    }
  }

  function loadLyricData(obj) {
    lyricLines = obj.lines
    lyricEnhanced = obj.enhanced || false
    lyricCurrentIdx = -1
    currentLyric = ""
    lyricProgress = 0.0
    launchSync()
  }

  
  property var _cavaProcess: Process {
    id: cavaProcess
    command: ["cava", "-p", service.installDir + "/ext/cava/cava-bar.conf"]
    running: true
    stdout: SplitParser {
      onRead: data => {
        let raw = data.trim()
        if (!raw) return
        let parts = raw.split(";")
        let bars = service.audioBars
        let j = 0
        for (let i = 0; i < parts.length && j < bars.length; i++) {
          if (parts[i] !== "") bars[j++] = parseInt(parts[i]) || 0
        }
        if (j > 0) service.audioBarsUpdated()
      }
    }
    onExited: cavaRestartTimer.start()
  }

  property var _cavaRestartTimer: Timer {
    id: cavaRestartTimer
    interval: 2000
    onTriggered: { if (!cavaProcess.running) cavaProcess.running = true }
  }

  
  property var _lyricsConnection: Connections {
    target: LyricsService
    function onLyricsCleared() {
      service.lyricState = "idle"
      service.requestClear(null)
    }
    function onLyricsSearching() {
      service.lyricState = "searching"
      service.requestClear(null)
    }
    function onLyricsNotFound() {
      service.lyricState = "nolyrics"
      service.requestClear(null)
    }
    function onLyricsReady(data) {
      if (data.lines && data.lines.length > 0) {
        service.lyricState = "haslyrics"
        service.requestClear(data)
      }
    }
  }

  
  function launchSync() {
    var player = _findSyncPlayer()
    if (!player) return
    var posMs = player.position * 1000
    var wallNow = Date.now()

    if (service.syncWallTime <= 0) {
      service.syncTrackMs = posMs
      service.syncWallTime = wallNow
    } else {
      var ourEstimate = service.syncTrackMs + (wallNow - service.syncWallTime)
      var drift = posMs - ourEstimate
      if (Math.abs(drift) >= 5000) {
        service.syncTrackMs = posMs
        service.syncWallTime = wallNow
      } else if (drift > 50) {
        service.syncTrackMs = ourEstimate + drift * 0.4
        service.syncWallTime = wallNow
      } else if (drift < -50) {
        var corrected = ourEstimate + drift * 0.15
        var lines = service.lyricLines
        var idx = service.lyricCurrentIdx
        if (idx >= 0 && idx < lines.length && corrected < lines[idx].start)
          corrected = lines[idx].start
        service.syncTrackMs = corrected
        service.syncWallTime = wallNow
      }
    }
  }

  function _findSyncPlayer() {
    if (!Mpris.players) return null
    var preferred = service.preferredPlayer.toLowerCase()
    var preferredPlaying = null
    var anyPlaying = null
    for (var i = 0; i < Mpris.players.values.length; i++) {
      var p = Mpris.players.values[i]
      if (!p) continue
      var id = (p.identity || "").toLowerCase()
      if (id.indexOf(preferred) !== -1 && p.isPlaying) preferredPlaying = p
      if (p.isPlaying && !anyPlaying) anyPlaying = p
    }
    return preferredPlaying || anyPlaying
  }

  
  property var _syncTimer: Timer {
    interval: 5000
    repeat: true
    running: service.lyricLines.length > 0
    onTriggered: service.launchSync()
  }

  
  property var _lyricAnimTimer: Timer {
    interval: 33
    repeat: true
    running: service.lyricLines.length > 0 && service.syncWallTime > 0
    onTriggered: {
      let posMs = service.estimatedTrackMs()
      let lines = service.lyricLines

      let newIdx = -1
      for (let i = lines.length - 1; i >= 0; i--) {
        if (posMs >= lines[i].start) {
          newIdx = i
          break
        }
      }

      if (newIdx < 0) return

      let line = lines[newIdx]

      if (newIdx !== service.lyricCurrentIdx) {
        service.previousLyric = service.currentLyric
        service.currentLyric = line.text
        service.lyricCurrentIdx = newIdx
      }

      if (posMs > line.end) {
        service.lyricProgress = 1.0
      } else if (line.words && line.words.length > 0) {
        let fullText = line.text
        let charsHighlighted = 0
        let totalChars = fullText.length
        let hasCharOffsets = line.words[0].charStart !== undefined

        if (hasCharOffsets) {
          for (let w = 0; w < line.words.length; w++) {
            let word = line.words[w]
            if (posMs < word.start) {
              break
            } else if (posMs >= word.end) {
              charsHighlighted = (w < line.words.length - 1)
                ? line.words[w + 1].charStart
                : word.charEnd
            } else {
              let wordProgress = (posMs - word.start) / (word.end - word.start)
              charsHighlighted = word.charStart + word.word.length * wordProgress
              break
            }
          }
        } else {
          for (let w = 0; w < line.words.length; w++) {
            let word = line.words[w]
            let wordLen = word.word.length
            if (posMs < word.start) {
              break
            } else if (posMs >= word.end) {
              charsHighlighted += wordLen
              if (w < line.words.length - 1) charsHighlighted += 1
            } else {
              let wordProgress = (posMs - word.start) / (word.end - word.start)
              charsHighlighted += wordLen * wordProgress
              break
            }
          }
        }

        service.lyricProgress = totalChars > 0 ? Math.max(0, Math.min(1.0, charsHighlighted / totalChars)) : 1.0
      } else {
        let duration = line.end - line.start
        service.lyricProgress = duration > 0 ? Math.max(0, Math.min(1.0, (posMs - line.start) / duration)) : 1.0
      }
    }
  }
}
