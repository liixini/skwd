// Imports
import QtQuick
import "../.."


Item {
  id: lyricsIsland

  required property var colors
  required property var activePlayer
  required property real diagSlant
  required property real barHeight
  required property real waveformHeight

  // Playback and lyric state
  readonly property bool musicPlaying: activePlayer && activePlayer.isPlaying
  readonly property bool hasLyrics: service.currentLyric !== ""

  LyricsIslandService {
    id: service
    installDir: Config.installDir
    scriptsDir: Config.scriptsDir
    preferredPlayer: Config.preferredPlayer
    onClearAnimationRequested: lyricClearAnim.restart()
  }

  width: 700
  visible: musicPlaying
  opacity: visible ? 1.0 : 0.0
  Behavior on opacity {
    NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
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
        if (service.lyricState === "searching") return "RETRIEVING LYRICS..."
        if (service.lyricState === "nolyrics") return "NO LYRICS :("
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
      visible: service.lyricEnhanced
      x: (lyricCurrent.width - lyricCurrent.contentWidth) / 2
      y: lyricCurrent.y
      width: lyricCurrent.contentWidth * service.lyricProgress
      height: lyricCurrent.implicitHeight
      clip: true

      Text {
        id: lyricHighlight
        x: -lyricClipMask.x
        y: 0
        width: lyricContainer.width
        text: service.currentLyric
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
      onFinished: {
        lyricCurrent.text = ""
        lyricCurrent.opacity = 0
        lyricOutgoing.text = ""
        lyricOutgoing.opacity = 0
        service.finishClear()
      }
    }

    Connections {
      target: service
      function onCurrentLyricChanged() {
        if (service.currentLyric === "") return
        outgoingAnim.stop()
        incomingAnim.stop()
        lyricOutgoing.text = lyricCurrent.text
        lyricOutgoing.y = lyricContainer.centerY
        lyricOutgoing.opacity = 1.0
        lyricCurrent.text = service.currentLyric
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
      target: service
      function onAudioBarsChanged() {
        let newBars = service.audioBars
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
      var theme = lyricsIsland.vizTheme

      if (theme === "bars") {
        var grad = ctx.createLinearGradient(0, 0, 0, height)
        grad.addColorStop(0, Qt.rgba(sur.r, sur.g, sur.b, 0.88))
        grad.addColorStop(1, Qt.rgba(sur.r, sur.g, sur.b, 0.0))
        ctx.fillStyle = grad
        lyricsIsland._vizDrawBars(ctx, raw, baseY, maxAmp, 1, slant, width)
      } else if (theme === "blocks") {
        ctx.fillStyle = Qt.rgba(sur.r, sur.g, sur.b, 0.88)
        lyricsIsland._vizDrawBlocks(ctx, raw, baseY, maxAmp, 1, slant, width)
      } else if (theme === "dots") {
        ctx.fillStyle = Qt.rgba(sur.r, sur.g, sur.b, 0.88)
        ctx.strokeStyle = Qt.rgba(sur.r, sur.g, sur.b, 0.4)
        ctx.lineWidth = 1
        lyricsIsland._vizDrawDots(ctx, raw, baseY, maxAmp, 1, slant, width)
      } else if (theme === "line") {
        var vals = lyricsIsland._vizEdgePad(raw)
        var step = width / (vals.length - 1)
        ctx.beginPath()
        lyricsIsland._vizDrawLine(ctx, vals, step, baseY, maxAmp, 1)
        ctx.strokeStyle = Qt.rgba(sur.r, sur.g, sur.b, 0.3)
        ctx.lineWidth = 4
        ctx.stroke()
        ctx.beginPath()
        lyricsIsland._vizDrawLine(ctx, vals, step, baseY, maxAmp, 1)
        ctx.strokeStyle = Qt.rgba(sur.r, sur.g, sur.b, 0.88)
        ctx.lineWidth = 1.5
        ctx.stroke()
      } else {
        // wave is default
        var vals = lyricsIsland._vizEdgePad(raw)
        var step = width / (vals.length - 1)

        ctx.beginPath()
        lyricsIsland._vizDrawWave(ctx, vals, step, baseY, maxAmp, 1)
        ctx.closePath()
        var grad = ctx.createLinearGradient(0, 0, 0, maxAmp)
        grad.addColorStop(0, Qt.rgba(sur.r, sur.g, sur.b, 0.88))
        grad.addColorStop(0.7, Qt.rgba(sur.r, sur.g, sur.b, 0.88))
        grad.addColorStop(0.9, Qt.rgba(sur.r, sur.g, sur.b, 0.35))
        grad.addColorStop(1, Qt.rgba(sur.r, sur.g, sur.b, 0.0))
        ctx.fillStyle = grad
        ctx.fill()

        ctx.beginPath()
        lyricsIsland._vizDrawWave(ctx, vals, step, baseY, maxAmp, 1)
        ctx.strokeStyle = Qt.rgba(sur.r, sur.g, sur.b, 0.5)
        ctx.lineWidth = 1
        ctx.stroke()
      }

      ctx.restore()
    }

    Connections {
      target: lyricsIsland.colors
      function onSurfaceChanged() { audioVisualizer.requestPaint() }
    }
    Connections {
      target: lyricsIsland
      function onVizThemeChanged() { audioVisualizer.requestPaint() }
      function onVizBottomChanged() { audioVisualizer.requestPaint() }
    }
  }
}
