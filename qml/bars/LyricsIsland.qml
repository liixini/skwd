// Imports
import Quickshell.Io
import QtQuick
import ".."


Item {
  id: lyricsIsland

  required property var colors
  required property var activePlayer
  required property real diagSlant
  required property real barHeight
  required property real waveformHeight

  // Playback and lyric state
  readonly property bool musicPlaying: activePlayer && activePlayer.isPlaying
  readonly property bool hasLyrics: currentLyric !== ""

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

  width: 700
  visible: musicPlaying
  opacity: visible ? 1.0 : 0.0
  Behavior on opacity {
    NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
  }


  // Track position estimation and lyric clearing helpers
  function estimatedTrackMs() {
    if (syncWallTime <= 0) return 0
    return syncTrackMs + (Date.now() - syncWallTime)
  }

  function clearLyricsAnimated(pendingData) {
    if (lyricsIsland.currentLyric === "" && lyricsIsland.lyricLines.length === 0) {
      if (pendingData) lyricsIsland._loadLyricData(pendingData)
      return
    }
    lyricsIsland.lyricClearing = true
    lyricsIsland.pendingLyricData = pendingData || null
    lyricClearAnim.restart()
  }

  function _finishClear() {
    lyricsIsland.lyricLines = []
    lyricsIsland.lyricCurrentIdx = -1
    lyricsIsland.currentLyric = ""
    lyricsIsland.lyricProgress = 0.0
    lyricsIsland.syncWallTime = 0
    lyricsIsland.lyricEnhanced = false
    lyricCurrent.text = ""
    lyricCurrent.opacity = 0
    lyricOutgoing.text = ""
    lyricOutgoing.opacity = 0
    lyricsIsland.lyricClearing = false
    if (lyricsIsland.pendingLyricData) {
      lyricsIsland._loadLyricData(lyricsIsland.pendingLyricData)
      lyricsIsland.pendingLyricData = null
    }
  }

  function _loadLyricData(obj) {
    lyricsIsland.lyricLines = obj.lines
    lyricsIsland.lyricEnhanced = obj.enhanced || false
    lyricsIsland.lyricCurrentIdx = -1
    lyricsIsland.currentLyric = ""
    lyricsIsland.lyricProgress = 0.0
    lyricsIsland.launchSync()
  }

  function launchSync() {
    syncProcess.launchTime = Date.now()
    syncProcess.running = true
  }


  // Cava audio visualizer process
  Process {
    id: cavaProcess
    command: ["cava", "-p", Config.configDir + "/ext/cava/cava-bar.conf"]
    running: true
    stdout: SplitParser {
      onRead: data => {
        let raw = data.trim()
        if (!raw) return
        let vals = raw.split(";").filter(s => s !== "").map(s => parseInt(s) || 0)
        if (vals.length > 0) lyricsIsland.audioBars = vals
      }
    }
    onExited: {
      cavaRestartTimer.start()
    }
  }

  Timer {
    id: cavaRestartTimer
    interval: 2000
    onTriggered: { if (!cavaProcess.running) cavaProcess.running = true }
  }

  // Lyrics pipe reader (ytm-lyrics-pipe)
  Process {
    id: lyricsProcess
    command: [Config.scriptsDir + "/python/ytm-lyrics-pipe"]
    running: true
    stdout: SplitParser {
      onRead: data => {
        let raw = data.trim()
        if (raw === "CLEAR") {
          lyricsIsland.lyricState = "idle"
          lyricsIsland.clearLyricsAnimated(null)
          return
        }
        if (raw === "SEARCHING") {
          lyricsIsland.lyricState = "searching"
          lyricsIsland.clearLyricsAnimated(null)
          return
        }
        if (raw === "NOLYRICS") {
          lyricsIsland.lyricState = "nolyrics"
          lyricsIsland.clearLyricsAnimated(null)
          return
        }
        try {
          let obj = JSON.parse(raw)
          if (obj.lines && obj.lines.length > 0) {
            lyricsIsland.lyricState = "haslyrics"
            if (obj.player) syncProcess.activePlayer = obj.player
            lyricsIsland.clearLyricsAnimated(obj)
          }
        } catch (e) {}
      }
    }
    onExited: { lyricsRestartTimer.start() }
  }

  Timer {
    id: lyricsRestartTimer
    interval: 2000
    onTriggered: {
      if (!lyricsProcess.running) {
        lyricsProcess.running = true
      }
    }
  }

  // Playerctl position sync process
  // Uses preferred player if playing, otherwise queries any playing player
  Process {
    id: syncProcess
    property string buf: ""
    property real launchTime: 0
    property string activePlayer: ""
    command: activePlayer
             ? ["playerctl", "--player=" + activePlayer, "position"]
             : ["playerctl", "--player=" + Config.preferredPlayer + ",%any", "position"]
    stdout: SplitParser {
      onRead: data => { syncProcess.buf += data }
    }
    onExited: {
      let sec = parseFloat(syncProcess.buf.trim())
      syncProcess.buf = ""
      if (!isNaN(sec)) {
        let reportedMs = sec * 1000
        let wallAtRead = Date.now()

        if (lyricsIsland.syncWallTime <= 0) {
          lyricsIsland.syncTrackMs = reportedMs
          lyricsIsland.syncWallTime = wallAtRead
        } else {
          let ourEstimate = lyricsIsland.syncTrackMs + (wallAtRead - lyricsIsland.syncWallTime)
          let drift = reportedMs - ourEstimate
          if (Math.abs(drift) >= 5000) {
            lyricsIsland.syncTrackMs = reportedMs
            lyricsIsland.syncWallTime = wallAtRead
          } else if (drift > 50) {
            lyricsIsland.syncTrackMs = ourEstimate + drift * 0.4
            lyricsIsland.syncWallTime = wallAtRead
          } else if (drift < -50) {
            let corrected = ourEstimate + drift * 0.15
            let lines = lyricsIsland.lyricLines
            let idx = lyricsIsland.lyricCurrentIdx
            if (idx >= 0 && idx < lines.length && corrected < lines[idx].start) {
              corrected = lines[idx].start
            }
            lyricsIsland.syncTrackMs = corrected
            lyricsIsland.syncWallTime = wallAtRead
          }
        }
      }
    }
  }


  // Periodic position re-sync
  Timer {
    id: syncTimer
    interval: 5000
    repeat: true
    running: lyricsIsland.lyricLines.length > 0
    onTriggered: { lyricsIsland.launchSync() }
  }

  // Lyric line animation timer (word-level highlight progress)
  Timer {
    id: lyricAnimTimer
    interval: 33
    repeat: true
    running: lyricsIsland.lyricLines.length > 0 && lyricsIsland.syncWallTime > 0
    onTriggered: {
      let posMs = lyricsIsland.estimatedTrackMs()
      let lines = lyricsIsland.lyricLines

      let newIdx = -1
      for (let i = lines.length - 1; i >= 0; i--) {
        if (posMs >= lines[i].start) {
          newIdx = i
          break
        }
      }

      if (newIdx < 0) return

      let line = lines[newIdx]

      if (newIdx !== lyricsIsland.lyricCurrentIdx) {
        lyricsIsland.previousLyric = lyricsIsland.currentLyric
        lyricsIsland.currentLyric = line.text
        lyricsIsland.lyricCurrentIdx = newIdx
      }

      if (posMs > line.end) {
        lyricsIsland.lyricProgress = 1.0
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

        lyricsIsland.lyricProgress = totalChars > 0 ? Math.max(0, Math.min(1.0, charsHighlighted / totalChars)) : 1.0
      } else {
        let duration = line.end - line.start
        lyricsIsland.lyricProgress = duration > 0 ? Math.max(0, Math.min(1.0, (posMs - line.start) / duration)) : 1.0
      }
    }
  }


  // Parallelogram background shape
  Canvas {
    id: centerBg
    anchors.fill: parent
    onPaint: {
      var ctx = getContext("2d")
      ctx.clearRect(0, 0, width, height)
      ctx.beginPath()
      ctx.moveTo(0, 0)
      ctx.lineTo(width, 0)
      ctx.lineTo(width - lyricsIsland.diagSlant, height)
      ctx.lineTo(lyricsIsland.diagSlant, height)
      ctx.closePath()
      ctx.fillStyle = Qt.rgba(lyricsIsland.colors.surface.r, lyricsIsland.colors.surface.g, lyricsIsland.colors.surface.b, 0.88)
      ctx.fill()
    }
    Connections {
      target: lyricsIsland.colors
      function onSurfaceChanged() { centerBg.requestPaint() }
      function onPrimaryChanged() { centerBg.requestPaint() }
    }
  }


  // Artist name label (left side)
  Text {
    id: artistLabel
    anchors.left: parent.left
    anchors.leftMargin: lyricsIsland.diagSlant + 10
    anchors.verticalCenter: parent.verticalCenter
    text: lyricsIsland.activePlayer ? lyricsIsland.activePlayer.trackArtist.toUpperCase() : ""
    font.pixelSize: 12
    font.weight: Font.DemiBold
    font.family: Style.fontFamily
    color: lyricsIsland.colors.primary
    elide: Text.ElideRight
    maximumLineCount: 1
    width: Math.min(implicitWidth, 120)
    visible: lyricsIsland.musicPlaying
  }


  // Track title label (right side)
  Text {
    id: trackLabel
    anchors.right: parent.right
    anchors.rightMargin: lyricsIsland.diagSlant + 10
    anchors.verticalCenter: parent.verticalCenter
    text: {
      if (!lyricsIsland.activePlayer) return ""
      var t = lyricsIsland.activePlayer.trackTitle
      var a = lyricsIsland.activePlayer.trackArtist
      if (a && t.toLowerCase().startsWith(a.toLowerCase() + " - "))
        t = t.substring(a.length + 3)
      return t.toUpperCase()
    }
    font.pixelSize: 12
    font.weight: Font.DemiBold
    font.family: Style.fontFamily
    color: lyricsIsland.colors.primary
    elide: Text.ElideRight
    maximumLineCount: 1
    width: Math.min(implicitWidth, 120)
    horizontalAlignment: Text.AlignRight
    visible: lyricsIsland.musicPlaying
  }


  // Lyric text display container
  Item {
    id: lyricContainer
    anchors.centerIn: parent
    width: parent.width - lyricsIsland.diagSlant * 2 - 16 - (lyricsIsland.musicPlaying ? 240 : 0)
    height: parent.height
    clip: true

    property real centerY: (height - 16) / 2
    property real slideDistance: 20

    Text {
      id: lyricFallback
      visible: !lyricsIsland.hasLyrics
      width: parent.width
      y: lyricContainer.centerY
      text: {
        if (lyricsIsland.lyricState === "searching") return "RETRIEVING LYRICS..."
        if (lyricsIsland.lyricState === "nolyrics") return "NO LYRICS :("
        return ""
      }
      font.pixelSize: 12
      font.weight: Font.Medium
      font.italic: true
      font.family: Style.fontFamily
      color: Qt.rgba(lyricsIsland.colors.tertiary.r, lyricsIsland.colors.tertiary.g, lyricsIsland.colors.tertiary.b, 0.6)
      horizontalAlignment: Text.AlignHCenter
      elide: Text.ElideRight
      maximumLineCount: 1
      opacity: 1
    }

    Text {
      id: lyricOutgoing
      width: parent.width
      y: lyricContainer.centerY
      text: ""
      font.pixelSize: 12
      font.weight: Font.Medium
      font.italic: true
      font.family: Style.fontFamily
      color: lyricsIsland.colors.tertiary
      horizontalAlignment: Text.AlignHCenter
      elide: Text.ElideRight
      maximumLineCount: 1
      opacity: 0
    }

    Text {
      id: lyricCurrent
      width: parent.width
      y: lyricContainer.centerY
      text: ""
      font.pixelSize: 12
      font.weight: Font.Medium
      font.italic: true
      font.family: Style.fontFamily
      color: lyricsIsland.colors.tertiary
      horizontalAlignment: Text.AlignHCenter
      elide: Text.ElideRight
      maximumLineCount: 1
      opacity: 1
    }


    // Word-level highlight mask for enhanced lyrics
    Item {
      id: lyricClipMask
      visible: lyricsIsland.lyricEnhanced
      x: (lyricCurrent.width - lyricCurrent.contentWidth) / 2
      y: lyricCurrent.y
      width: lyricCurrent.contentWidth * lyricsIsland.lyricProgress
      height: lyricCurrent.implicitHeight
      clip: true

      Text {
        id: lyricHighlight
        x: -lyricClipMask.x
        y: 0
        width: lyricContainer.width
        text: lyricsIsland.currentLyric
        font: lyricCurrent.font
        color: lyricsIsland.colors.primary
        horizontalAlignment: Text.AlignHCenter
        elide: Text.ElideRight
        maximumLineCount: 1
      }
    }

    // Lyric transition animations
    ParallelAnimation {
      id: outgoingAnim
      NumberAnimation {
        target: lyricOutgoing; property: "y"
        to: lyricContainer.centerY - lyricContainer.slideDistance
        duration: 250; easing.type: Easing.OutCubic
      }
      NumberAnimation {
        target: lyricOutgoing; property: "opacity"
        to: 0.0
        duration: 250; easing.type: Easing.OutCubic
      }
    }

    ParallelAnimation {
      id: incomingAnim
      NumberAnimation {
        target: lyricCurrent; property: "y"
        to: lyricContainer.centerY
        duration: 300; easing.type: Easing.OutCubic
      }
      NumberAnimation {
        target: lyricCurrent; property: "opacity"
        to: 1.0
        duration: 300; easing.type: Easing.OutCubic
      }
    }

    ParallelAnimation {
      id: lyricClearAnim
      NumberAnimation {
        target: lyricCurrent; property: "opacity"
        to: 0.0; duration: 300; easing.type: Easing.OutCubic
      }
      NumberAnimation {
        target: lyricCurrent; property: "y"
        to: lyricContainer.centerY - lyricContainer.slideDistance
        duration: 300; easing.type: Easing.OutCubic
      }
      NumberAnimation {
        target: lyricOutgoing; property: "opacity"
        to: 0.0; duration: 200; easing.type: Easing.OutCubic
      }
      onFinished: lyricsIsland._finishClear()
    }

    Connections {
      target: lyricsIsland
      function onCurrentLyricChanged() {
        if (lyricsIsland.currentLyric === "") return
        outgoingAnim.stop()
        incomingAnim.stop()
        lyricOutgoing.text = lyricCurrent.text
        lyricOutgoing.y = lyricContainer.centerY
        lyricOutgoing.opacity = 1.0
        lyricCurrent.text = lyricsIsland.currentLyric
        lyricCurrent.y = lyricContainer.centerY + lyricContainer.slideDistance
        lyricCurrent.opacity = 0.0
        outgoingAnim.restart()
        incomingAnim.restart()
      }
    }
  }


  // Visualizer theme from config
  property string vizTheme: Config.visualizerTheme
  property bool vizTop: Config.visualizerTop
  property bool vizBottom: Config.visualizerBottom


  // Shared drawing helpers used by both canvases
  function _vizEdgePad(raw) {
    var first = raw[0] || 0
    var last = raw[raw.length - 1] || 0
    return [0, first * 0.1, first * 0.35]
      .concat(raw)
      .concat([last * 0.35, last * 0.1, 0])
  }

  function _vizDrawWave(ctx, vals, step, baseY, maxAmp, dir) {
    ctx.moveTo(0, baseY)
    for (var i = 0; i < vals.length; i++) {
      var x = i * step
      var y = baseY + dir * (vals[i] / 100) * maxAmp
      if (i === 0) {
        ctx.lineTo(x, y)
      } else {
        var cpX = ((i - 1) * step + x) / 2
        ctx.quadraticCurveTo(cpX, baseY + dir * (vals[i-1] / 100) * maxAmp, x, y)
      }
    }
    ctx.lineTo(ctx.canvas.width, baseY)
  }

  function _vizDrawBars(ctx, raw, baseY, maxAmp, dir, slant, w) {
    var count = raw.length
    var usable = w - slant * 2
    var gap = 2
    var barW = (usable - gap * (count - 1)) / count
    var startX = slant
    var radius = Math.min(barW / 2, 3)
    for (var i = 0; i < count; i++) {
      var x = startX + i * (barW + gap)
      var h = (raw[i] / 100) * maxAmp
      if (h < 1) continue
      var y = dir < 0 ? baseY - h : baseY
      ctx.beginPath()
      if (radius > 0) {
        var topR = dir < 0 ? radius : 0
        var botR = dir < 0 ? 0 : radius
        ctx.moveTo(x + topR, y)
        ctx.lineTo(x + barW - topR, y)
        if (topR > 0) ctx.quadraticCurveTo(x + barW, y, x + barW, y + topR)
        else ctx.lineTo(x + barW, y)
        ctx.lineTo(x + barW, y + h - botR)
        if (botR > 0) ctx.quadraticCurveTo(x + barW, y + h, x + barW - botR, y + h)
        else ctx.lineTo(x + barW, y + h)
        ctx.lineTo(x + botR, y + h)
        if (botR > 0) ctx.quadraticCurveTo(x, y + h, x, y + h - botR)
        else ctx.lineTo(x, y + h)
        ctx.lineTo(x, y + topR)
        if (topR > 0) ctx.quadraticCurveTo(x, y, x + topR, y)
        else ctx.lineTo(x, y)
      } else {
        ctx.rect(x, y, barW, h)
      }
      ctx.closePath()
      ctx.fill()
    }
  }

  function _vizDrawBlocks(ctx, raw, baseY, maxAmp, dir, slant, w) {
    var count = raw.length
    var usable = w - slant * 2
    var gap = 2
    var barW = (usable - gap * (count - 1)) / count
    var startX = slant
    var blockH = 3
    var blockGap = 1
    for (var i = 0; i < count; i++) {
      var x = startX + i * (barW + gap)
      var h = (raw[i] / 100) * maxAmp
      var blocks = Math.floor(h / (blockH + blockGap))
      for (var b = 0; b < blocks; b++) {
        var by = dir < 0
          ? baseY - (b + 1) * (blockH + blockGap)
          : baseY + b * (blockH + blockGap)
        ctx.fillRect(x, by, barW, blockH)
      }
    }
  }

  function _vizDrawDots(ctx, raw, baseY, maxAmp, dir, slant, w) {
    var count = raw.length
    var usable = w - slant * 2
    var gap = 2
    var barW = (usable - gap * (count - 1)) / count
    var startX = slant
    var dotR = Math.min(barW / 2, 4)
    for (var i = 0; i < count; i++) {
      var cx = startX + i * (barW + gap) + barW / 2
      var h = (raw[i] / 100) * maxAmp
      if (h < 1) continue
      var cy = dir < 0 ? baseY - h : baseY + h
      ctx.beginPath()
      ctx.arc(cx, cy, dotR, 0, Math.PI * 2)
      ctx.fill()
      // trail line
      ctx.beginPath()
      ctx.moveTo(cx, baseY)
      ctx.lineTo(cx, cy)
      ctx.stroke()
    }
  }

  function _vizDrawLine(ctx, vals, step, baseY, maxAmp, dir) {
    ctx.moveTo(0, baseY)
    for (var i = 0; i < vals.length; i++) {
      var x = i * step
      var y = baseY + dir * (vals[i] / 100) * maxAmp
      if (i === 0) {
        ctx.lineTo(x, y)
      } else {
        var cpX = ((i - 1) * step + x) / 2
        ctx.quadraticCurveTo(cpX, baseY + dir * (vals[i-1] / 100) * maxAmp, x, y)
      }
    }
  }


  // Upper visualizer canvas (inside bar area)
  Canvas {
    id: audioVisualizerUp
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    height: lyricsIsland.waveformHeight
    visible: lyricsIsland.vizTop

    onPaint: {
      var ctx = getContext("2d")
      ctx.clearRect(0, 0, width, height)

      var raw = audioVisualizer.displayBars
      if (!raw || raw.length === 0) return

      var baseY = height
      var maxAmp = height
      var slant = lyricsIsland.diagSlant
      var islandH = lyricsIsland.barHeight
      var topFrac = (islandH - height) / islandH
      var leftAtTop = slant * topFrac
      var rightAtTop = width - slant * topFrac
      var leftAtBot = slant
      var rightAtBot = width - slant

      ctx.save()
      ctx.beginPath()
      ctx.moveTo(leftAtTop, 0)
      ctx.lineTo(rightAtTop, 0)
      ctx.lineTo(rightAtBot, height)
      ctx.lineTo(leftAtBot, height)
      ctx.closePath()
      ctx.clip()

      var pri = lyricsIsland.colors.primary
      var ter = lyricsIsland.colors.tertiary
      var theme = lyricsIsland.vizTheme

      if (theme === "bars") {
        var grad = ctx.createLinearGradient(0, baseY, 0, 0)
        grad.addColorStop(0, Qt.rgba(pri.r, pri.g, pri.b, 0.3))
        grad.addColorStop(1, Qt.rgba(pri.r, pri.g, pri.b, 0.05))
        ctx.fillStyle = grad
        lyricsIsland._vizDrawBars(ctx, raw, baseY, maxAmp, -1, slant, width)
      } else if (theme === "blocks") {
        ctx.fillStyle = Qt.rgba(pri.r, pri.g, pri.b, 0.25)
        lyricsIsland._vizDrawBlocks(ctx, raw, baseY, maxAmp, -1, slant, width)
      } else if (theme === "dots") {
        ctx.fillStyle = Qt.rgba(pri.r, pri.g, pri.b, 0.35)
        ctx.strokeStyle = Qt.rgba(ter.r, ter.g, ter.b, 0.12)
        ctx.lineWidth = 1
        lyricsIsland._vizDrawDots(ctx, raw, baseY, maxAmp, -1, slant, width)
      } else if (theme === "line") {
        var vals = lyricsIsland._vizEdgePad(raw)
        var step = width / (vals.length - 1)
        // glow
        ctx.beginPath()
        lyricsIsland._vizDrawLine(ctx, vals, step, baseY, maxAmp, -1)
        ctx.strokeStyle = Qt.rgba(pri.r, pri.g, pri.b, 0.08)
        ctx.lineWidth = 4
        ctx.stroke()
        // line
        ctx.beginPath()
        lyricsIsland._vizDrawLine(ctx, vals, step, baseY, maxAmp, -1)
        ctx.strokeStyle = Qt.rgba(pri.r, pri.g, pri.b, 0.3)
        ctx.lineWidth = 1.5
        ctx.stroke()
      } else {
        // "wave" — default
        var vals = lyricsIsland._vizEdgePad(raw)
        var step = width / (vals.length - 1)

        ctx.beginPath()
        lyricsIsland._vizDrawWave(ctx, vals, step, baseY, maxAmp, -1)
        ctx.closePath()
        var grad = ctx.createLinearGradient(0, baseY, 0, baseY - maxAmp)
        grad.addColorStop(0, Qt.rgba(pri.r, pri.g, pri.b, 0.25))
        grad.addColorStop(0.6, Qt.rgba(pri.r, pri.g, pri.b, 0.08))
        grad.addColorStop(1, Qt.rgba(pri.r, pri.g, pri.b, 0.0))
        ctx.fillStyle = grad
        ctx.fill()

        ctx.beginPath()
        lyricsIsland._vizDrawWave(ctx, vals, step, baseY, maxAmp, -1)
        ctx.strokeStyle = Qt.rgba(ter.r, ter.g, ter.b, 0.2)
        ctx.lineWidth = 1
        ctx.stroke()
      }

      ctx.restore()
    }

    Connections {
      target: audioVisualizer
      function onDisplayBarsChanged() { audioVisualizerUp.requestPaint() }
    }
    Connections {
      target: lyricsIsland.colors
      function onPrimaryChanged() { audioVisualizerUp.requestPaint() }
      function onTertiaryChanged() { audioVisualizerUp.requestPaint() }
    }
    Connections {
      target: lyricsIsland
      function onVizThemeChanged() { audioVisualizerUp.requestPaint() }
      function onVizTopChanged() { audioVisualizerUp.requestPaint() }
    }
  }


  // Lower waveform canvas (below bar, mirrored reflection)
  Canvas {
    id: audioVisualizer
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.top: parent.bottom
    height: lyricsIsland.waveformHeight
    visible: lyricsIsland.vizBottom
    property var displayBars: [0,0,0,0,0,0,0,0,0,0,0,0,0,0]

    Connections {
      target: lyricsIsland
      function onAudioBarsChanged() {
        let newBars = lyricsIsland.audioBars
        let smoothed = []
        let prev = audioVisualizer.displayBars
        for (let i = 0; i < newBars.length; i++) {
          let p = i < prev.length ? prev[i] : 0
          smoothed.push(p + (newBars[i] - p) * 0.45)
        }
        audioVisualizer.displayBars = smoothed
        audioVisualizer.requestPaint()
      }
    }

    onPaint: {
      var ctx = getContext("2d")
      ctx.clearRect(0, 0, width, height)

      var raw = displayBars
      if (!raw || raw.length === 0) return

      var baseY = 0
      var maxAmp = height
      var slant = lyricsIsland.diagSlant

      ctx.save()
      ctx.beginPath()
      ctx.moveTo(slant, 0)
      ctx.lineTo(width - slant, 0)
      ctx.lineTo(width, height)
      ctx.lineTo(0, height)
      ctx.closePath()
      ctx.clip()

      var sur = lyricsIsland.colors.surface
      var pri = lyricsIsland.colors.primary
      var theme = lyricsIsland.vizTheme

      // Fill the region from top edge down to the waveform with the island
      // surface color, so it looks like the island background extends into
      // the visualizer shape.
      if (theme === "bars") {
        // Surface-coloured bars
        ctx.fillStyle = Qt.rgba(sur.r, sur.g, sur.b, 0.88)
        lyricsIsland._vizDrawBars(ctx, raw, baseY, maxAmp, 1, slant, width)
      } else if (theme === "blocks") {
        ctx.fillStyle = Qt.rgba(sur.r, sur.g, sur.b, 0.88)
        lyricsIsland._vizDrawBlocks(ctx, raw, baseY, maxAmp, 1, slant, width)
      } else if (theme === "dots") {
        ctx.fillStyle = Qt.rgba(sur.r, sur.g, sur.b, 0.88)
        ctx.strokeStyle = Qt.rgba(pri.r, pri.g, pri.b, 0.15)
        ctx.lineWidth = 1
        lyricsIsland._vizDrawDots(ctx, raw, baseY, maxAmp, 1, slant, width)
      } else if (theme === "line") {
        // Fill from top to waveline with surface, then stroke the line
        var vals = lyricsIsland._vizEdgePad(raw)
        var step = width / (vals.length - 1)
        // filled region: top edge → waveline → back across bottom-of-top
        ctx.beginPath()
        ctx.moveTo(slant, 0)
        ctx.lineTo(width - slant, 0)
        // trace wave rightward at the line level
        for (var i = vals.length - 1; i >= 0; i--) {
          var x = i * step
          var y = baseY + (vals[i] / 100) * maxAmp
          ctx.lineTo(x, y)
        }
        ctx.closePath()
        ctx.fillStyle = Qt.rgba(sur.r, sur.g, sur.b, 0.88)
        ctx.fill()
        // accent stroke along the wave edge
        ctx.beginPath()
        lyricsIsland._vizDrawLine(ctx, vals, step, baseY, maxAmp, 1)
        ctx.strokeStyle = Qt.rgba(pri.r, pri.g, pri.b, 0.2)
        ctx.lineWidth = 1
        ctx.stroke()
      } else {
        // "wave" — default: fill from top edge down to wave contour
        var vals = lyricsIsland._vizEdgePad(raw)
        var step = width / (vals.length - 1)

        ctx.beginPath()
        // start at top-left of trapezoid
        ctx.moveTo(slant, 0)
        ctx.lineTo(width - slant, 0)
        // trace wave contour backwards (right to left)
        for (var i = vals.length - 1; i >= 0; i--) {
          var x = i * step
          var y = baseY + (vals[i] / 100) * maxAmp
          if (i === vals.length - 1) {
            ctx.lineTo(x, y)
          } else {
            var cpX = (x + (i + 1) * step) / 2
            ctx.quadraticCurveTo(cpX, baseY + (vals[i+1] / 100) * maxAmp, x, y)
          }
        }
        ctx.closePath()
        ctx.fillStyle = Qt.rgba(sur.r, sur.g, sur.b, 0.88)
        ctx.fill()

        // subtle accent stroke along the wave edge
        ctx.beginPath()
        lyricsIsland._vizDrawWave(ctx, vals, step, baseY, maxAmp, 1)
        ctx.strokeStyle = Qt.rgba(pri.r, pri.g, pri.b, 0.15)
        ctx.lineWidth = 1
        ctx.stroke()
      }

      ctx.restore()
    }

    Connections {
      target: lyricsIsland.colors
      function onSurfaceChanged() { audioVisualizer.requestPaint() }
      function onPrimaryChanged() { audioVisualizer.requestPaint() }
    }
    Connections {
      target: lyricsIsland
      function onVizThemeChanged() { audioVisualizer.requestPaint() }
      function onVizBottomChanged() { audioVisualizer.requestPaint() }
    }
  }
}
