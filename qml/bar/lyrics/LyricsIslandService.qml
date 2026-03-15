import Quickshell.Io
import QtQuick

QtObject {
  id: service

  required property string installDir
  required property string scriptsDir
  required property string preferredPlayer

  // Lyric line data and tracking
  property string currentLyric: ""
  property string previousLyric: ""
  property real lyricProgress: 0.0
  property var lyricLines: []
  property int lyricCurrentIdx: -1
  property bool lyricEnhanced: false
  property string lyricState: "idle"
  property bool lyricClearing: false
  property var pendingLyricData: null

  // Track position sync state
  property real syncWallTime: 0
  property real syncTrackMs: 0

  // Audio visualizer bars from cava
  property var audioBars: [0,0,0,0,0,0,0,0,0,0,0,0,0,0]

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

  function launchSync() {
    _syncProcess.launchTime = Date.now()
    _syncProcess.running = true
  }

  // Cava audio visualizer process
  property var _cavaProcess: Process {
    id: cavaProcess
    command: ["cava", "-p", service.installDir + "/ext/cava/cava-bar.conf"]
    running: true
    stdout: SplitParser {
      onRead: data => {
        let raw = data.trim()
        if (!raw) return
        let vals = raw.split(";").filter(s => s !== "").map(s => parseInt(s) || 0)
        if (vals.length > 0) service.audioBars = vals
      }
    }
    onExited: cavaRestartTimer.start()
  }

  property var _cavaRestartTimer: Timer {
    id: cavaRestartTimer
    interval: 2000
    onTriggered: { if (!cavaProcess.running) cavaProcess.running = true }
  }

  // Lyrics pipe reader (ytm-lyrics-pipe)
  property var _lyricsProcess: Process {
    id: lyricsProcess
    command: [service.scriptsDir + "/python/ytm-lyrics-pipe"]
    running: true
    stdout: SplitParser {
      onRead: data => {
        let raw = data.trim()
        if (raw === "CLEAR") {
          service.lyricState = "idle"
          service.requestClear(null)
          return
        }
        if (raw === "SEARCHING") {
          service.lyricState = "searching"
          service.requestClear(null)
          return
        }
        if (raw === "NOLYRICS") {
          service.lyricState = "nolyrics"
          service.requestClear(null)
          return
        }
        try {
          let obj = JSON.parse(raw)
          if (obj.lines && obj.lines.length > 0) {
            service.lyricState = "haslyrics"
            if (obj.player) syncProcess.activePlayer = obj.player
            service.requestClear(obj)
          }
        } catch (e) {}
      }
    }
    onExited: lyricsRestartTimer.start()
  }

  property var _lyricsRestartTimer: Timer {
    id: lyricsRestartTimer
    interval: 2000
    onTriggered: { if (!lyricsProcess.running) lyricsProcess.running = true }
  }

  // Playerctl position sync process
  property var _syncProcess: Process {
    id: syncProcess
    property string buf: ""
    property real launchTime: 0
    property string activePlayer: ""
    command: activePlayer
             ? ["playerctl", "--player=" + activePlayer, "position"]
             : ["playerctl", "--player=" + service.preferredPlayer + ",%any", "position"]
    stdout: SplitParser {
      onRead: data => { syncProcess.buf += data }
    }
    onExited: {
      let sec = parseFloat(syncProcess.buf.trim())
      syncProcess.buf = ""
      if (!isNaN(sec)) {
        let reportedMs = sec * 1000
        let wallAtRead = Date.now()

        if (service.syncWallTime <= 0) {
          service.syncTrackMs = reportedMs
          service.syncWallTime = wallAtRead
        } else {
          let ourEstimate = service.syncTrackMs + (wallAtRead - service.syncWallTime)
          let drift = reportedMs - ourEstimate
          if (Math.abs(drift) >= 5000) {
            service.syncTrackMs = reportedMs
            service.syncWallTime = wallAtRead
          } else if (drift > 50) {
            service.syncTrackMs = ourEstimate + drift * 0.4
            service.syncWallTime = wallAtRead
          } else if (drift < -50) {
            let corrected = ourEstimate + drift * 0.15
            let lines = service.lyricLines
            let idx = service.lyricCurrentIdx
            if (idx >= 0 && idx < lines.length && corrected < lines[idx].start) {
              corrected = lines[idx].start
            }
            service.syncTrackMs = corrected
            service.syncWallTime = wallAtRead
          }
        }
      }
    }
  }

  // Periodic position re-sync
  property var _syncTimer: Timer {
    interval: 5000
    repeat: true
    running: service.lyricLines.length > 0
    onTriggered: service.launchSync()
  }

  // Lyric line animation timer (word-level highlight progress)
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

        service.lyricProgress = totalChars > 0 ? Math.max(0, Math.min(1.0, charsHighlighted / totalChars)) : 1.0
      } else {
        let duration = line.end - line.start
        service.lyricProgress = duration > 0 ? Math.max(0, Math.min(1.0, (posMs - line.start) / duration)) : 1.0
      }
    }
  }
}
