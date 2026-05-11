
import QtQuick
import "../.."


Item {
  id: lyricsIsland

  required property var colors
  required property var activePlayer
  required property real diagSlant
  required property real barHeight
  required property real waveformHeight

  
  readonly property bool musicPlaying: activePlayer && activePlayer.isPlaying
  readonly property bool hasLyrics: service.currentLyric !== ""

  LyricsIslandService {
    id: service
    installDir: Config.installDir
    scriptsDir: Config.scriptsDir
    preferredPlayer: Config.preferredPlayer
    onClearAnimationRequested: lyricClearAnim.restart()
  }

  width: 699
  visible: true
  property bool _hovered: false
  readonly property bool _islandActive: musicPlaying || (_hovered && Config.musicAlwaysHoverable)
  readonly property bool _controlsVisible: _hovered && _islandActive
  opacity: _islandActive ? 1.0 : 0.0
  Behavior on opacity {
    NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
  }

  HoverHandler {
    acceptedDevices: PointerDevice.AllDevices
    onHoveredChanged: lyricsIsland._hovered = hovered
  }


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
    visible: lyricsIsland.musicPlaying && Config.musicShowMeta
    opacity: Config.musicCleanVisualizer ? 0 : 1
    Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
  }


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
    visible: lyricsIsland.musicPlaying && Config.musicShowMeta
    opacity: Config.musicCleanVisualizer ? 0 : 1
    Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
  }


  Item {
    id: lyricContainer
    visible: Config.musicShowLyrics
    opacity: (lyricsIsland._controlsVisible || Config.musicCleanVisualizer) ? 0 : 1
    Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
    anchors.centerIn: parent
    width: parent.width - lyricsIsland.diagSlant * 2 - 16 - (lyricsIsland.musicPlaying && Config.musicShowMeta ? 240 : 0)
    height: parent.height
    clip: true

    property real centerY: (height - 16) / 2
    property real slideDistance: 20

    Text {
      id: lyricFallback
      visible: !lyricsIsland.hasLyrics && opacity > 0.01 && Config.musicShowLyricsStatus
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
      Behavior on opacity { NumberAnimation { duration: 600; easing.type: Easing.OutCubic } }

      onTextChanged: {
        opacity = 1
        lyricFallbackTimer.restart()
      }
      Component.onCompleted: if (text !== "") lyricFallbackTimer.start()
    }

    Timer {
      id: lyricFallbackTimer
      interval: 5000
      repeat: false
      onTriggered: lyricFallback.opacity = 0
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


  Row {
    id: controlsRow
    anchors.centerIn: parent
    spacing: 16
    z: 10
    opacity: lyricsIsland._controlsVisible ? 1 : 0
    visible: opacity > 0.01
    Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

    property var player: lyricsIsland.activePlayer

    Text {
      id: prevBtn
      text: "\u{F04AE}"
      font.family: Style.fontFamilyIcons
      font.pixelSize: 18
      anchors.verticalCenter: parent.verticalCenter
      color: prevMouse.containsMouse
        ? lyricsIsland.colors.primary
        : Qt.rgba(lyricsIsland.colors.tertiary.r, lyricsIsland.colors.tertiary.g, lyricsIsland.colors.tertiary.b, 0.85)
      Behavior on color { ColorAnimation { duration: 120 } }
      MouseArea {
        id: prevMouse
        anchors.fill: parent
        anchors.margins: -6
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: if (controlsRow.player) controlsRow.player.previous()
      }
    }

    Text {
      id: playPauseBtn
      text: (controlsRow.player && controlsRow.player.isPlaying) ? "\u{F03E4}" : "\u{F040A}"
      font.family: Style.fontFamilyIcons
      font.pixelSize: 22
      anchors.verticalCenter: parent.verticalCenter
      color: playPauseMouse.containsMouse
        ? lyricsIsland.colors.primary
        : Qt.rgba(lyricsIsland.colors.tertiary.r, lyricsIsland.colors.tertiary.g, lyricsIsland.colors.tertiary.b, 0.95)
      Behavior on color { ColorAnimation { duration: 120 } }
      MouseArea {
        id: playPauseMouse
        anchors.fill: parent
        anchors.margins: -6
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
          if (!controlsRow.player) return
          if (controlsRow.player.isPlaying) controlsRow.player.pause()
          else controlsRow.player.play()
        }
      }
    }

    Text {
      id: nextBtn
      text: "\u{F04AD}"
      font.family: Style.fontFamilyIcons
      font.pixelSize: 18
      anchors.verticalCenter: parent.verticalCenter
      color: nextMouse.containsMouse
        ? lyricsIsland.colors.primary
        : Qt.rgba(lyricsIsland.colors.tertiary.r, lyricsIsland.colors.tertiary.g, lyricsIsland.colors.tertiary.b, 0.85)
      Behavior on color { ColorAnimation { duration: 120 } }
      MouseArea {
        id: nextMouse
        anchors.fill: parent
        anchors.margins: -6
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: if (controlsRow.player) controlsRow.player.next()
      }
    }
  }


  property string vizTheme: Config.visualizerTheme
  property bool vizTop: Config.visualizerTop
  property bool vizBottom: Config.visualizerBottom

  property var _vizPeaks: []
  property var _vizSpectrogramHistory: []
  readonly property int _vizSpectrogramCols: Config.vizSpectrogramCols
  property var _vizRipples: []
  property var _vizCometTrail: []
  property real _vizCometX: 0.5
  property real _vizBassRunning: 0
  property var _vizStardust: []
  property real _vizAuroraEnv: 0

  Component.onCompleted: lyricsIsland._initStardust()


  function _initStardust() {
    var pts = []
    var seed = 12345
    function next() {
      seed = (seed * 1103515245 + 12345) & 0x7fffffff
      return seed / 0x7fffffff
    }
    var n = Math.max(1, Config.vizStardustCount)
    for (var i = 0; i < n; i++) {
      pts.push({ x: next(), y: next(), band: Math.floor(next() * 14), size: 0.8 + next() * 1.4 })
    }
    lyricsIsland._vizStardust = pts
  }

  Connections {
    target: Config
    function onVizStardustCountChanged() { lyricsIsland._initStardust() }
  }

  function _vizUpdatePeaks(disp) {
    if (lyricsIsland._vizPeaks.length !== disp.length) {
      lyricsIsland._vizPeaks = disp.slice()
      return
    }
    var p = lyricsIsland._vizPeaks
    var decay = Config.vizVuPeakDecay
    for (var i = 0; i < disp.length; i++) p[i] = Math.max(p[i] - decay, disp[i])
  }

  function _vizUpdateSpectrogram(disp) {
    var hist = lyricsIsland._vizSpectrogramHistory
    hist.push(disp.slice())
    if (hist.length > lyricsIsland._vizSpectrogramCols) hist.shift()
    lyricsIsland._vizSpectrogramHistory = hist
  }

  function _vizUpdateRipples(disp) {
    var bass = (disp[0] + disp[1] + disp[2]) / 3
    var running = lyricsIsland._vizBassRunning * 0.85 + bass * 0.15
    var threshold = Config.vizRippleThreshold
    var maxAge = Config.vizRippleMaxAge
    if (bass > running * threshold && bass > 22) {
      var rs = lyricsIsland._vizRipples
      rs.push({ age: 0, intensity: bass / 100 })
      lyricsIsland._vizRipples = rs
    }
    var ripples = lyricsIsland._vizRipples
    var alive = []
    for (var i = 0; i < ripples.length; i++) {
      ripples[i].age += 1
      if (ripples[i].age < maxAge) alive.push(ripples[i])
    }
    lyricsIsland._vizRipples = alive
    lyricsIsland._vizBassRunning = running
  }

  function _vizUpdateAuroraEnv(disp) {
    var e = 0
    for (var i = 0; i < disp.length; i++) e += disp[i]
    e = (e / disp.length) / 100
    var prev = lyricsIsland._vizAuroraEnv
    var alpha = e > prev ? Config.vizAuroraRespAttack : Config.vizAuroraRespDecay
    lyricsIsland._vizAuroraEnv = prev + (e - prev) * alpha
  }

  function _vizUpdateComet(disp) {
    var maxV = 0, maxI = 0
    for (var i = 0; i < disp.length; i++) if (disp[i] > maxV) { maxV = disp[i]; maxI = i }
    var targetT = disp.length === 1 ? 0.5 : maxI / (disp.length - 1)
    var newT = lyricsIsland._vizCometX + (targetT - lyricsIsland._vizCometX) * 0.18
    lyricsIsland._vizCometX = newT
    var trail = lyricsIsland._vizCometTrail
    trail.push({ x: newT, intensity: maxV / 100 })
    var maxLen = Math.max(2, Config.vizCometTrailLen)
    while (trail.length > maxLen) trail.shift()
    lyricsIsland._vizCometTrail = trail
  }


  function _vizEdgePad(raw) {
    var first = raw[0] || 0
    var last = raw[raw.length - 1] || 0
    return [0, first * 0.1, first * 0.35]
      .concat(raw)
      .concat([last * 0.35, last * 0.1, 0])
  }

  function _vizDrawWave(ctx, vals, step, baseY, maxAmp, dir) {
    ctx.moveTo(0, baseY)
    var n = vals.length
    if (n === 0) { ctx.lineTo(ctx.canvas.width, baseY); return }
    var firstY = baseY + dir * (vals[0] / 100) * maxAmp
    ctx.lineTo(0, firstY)
    for (var i = 1; i < n - 1; i++) {
      var x = i * step
      var y = baseY + dir * (vals[i] / 100) * maxAmp
      var nx = (i + 1) * step
      var ny = baseY + dir * (vals[i+1] / 100) * maxAmp
      ctx.quadraticCurveTo(x, y, (x + nx) / 2, (y + ny) / 2)
    }
    var lastX = (n - 1) * step
    var lastY = baseY + dir * (vals[n-1] / 100) * maxAmp
    ctx.lineTo(lastX, lastY)
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
      
      ctx.beginPath()
      ctx.moveTo(cx, baseY)
      ctx.lineTo(cx, cy)
      ctx.stroke()
    }
  }

  function _vizDrawLine(ctx, vals, step, baseY, maxAmp, dir) {
    var n = vals.length
    if (n === 0) return
    var firstY = baseY + dir * (vals[0] / 100) * maxAmp
    ctx.moveTo(0, firstY)
    if (n === 1) return
    for (var i = 1; i < n - 1; i++) {
      var x = i * step
      var y = baseY + dir * (vals[i] / 100) * maxAmp
      var nx = (i + 1) * step
      var ny = baseY + dir * (vals[i+1] / 100) * maxAmp
      ctx.quadraticCurveTo(x, y, (x + nx) / 2, (y + ny) / 2)
    }
    var lastX = (n - 1) * step
    var lastY = baseY + dir * (vals[n-1] / 100) * maxAmp
    ctx.lineTo(lastX, lastY)
  }

  function _vizDrawPulse(ctx, raw, baseY, maxAmp, dir, slant, w, palette) {
    var count = raw.length
    var usable = Math.max(1, w - slant * 2)
    var pillWidth = Math.max(1, Config.vizPulsePillWidth)
    var visualCount = Math.max(1, Math.floor(usable / (pillWidth + 2)))
    var spacing = usable / visualCount

    var grad = ctx.createLinearGradient(slant, 0, slant + usable, 0)
    for (var p = 0; p < palette.length; p++) {
      var stop = palette.length === 1 ? 0 : p / (palette.length - 1)
      var pc = palette[p]
      grad.addColorStop(stop, Qt.rgba(pc.r, pc.g, pc.b, 1.0))
    }

    ctx.save()
    ctx.fillStyle = grad
    ctx.shadowColor = "rgba(0, 0, 0, 0.65)"
    ctx.shadowOffsetX = 0
    ctx.shadowOffsetY = 1
    ctx.shadowBlur = 4

    var radius = pillWidth / 2
    var minH = radius

    for (var i = 0; i < visualCount; i++) {
      var t = visualCount === 1 ? 0 : i / (visualCount - 1)
      var srcIdx = t * (count - 1)
      var srcLow = Math.floor(srcIdx)
      var srcHigh = Math.min(count - 1, srcLow + 1)
      var frac = srcIdx - srcLow
      var v = raw[srcLow] * (1 - frac) + raw[srcHigh] * frac
      var h = Math.max(minH, (v / 100) * maxAmp)
      var cx = slant + spacing * (i + 0.5)
      var x = cx - pillWidth / 2
      var y = dir < 0 ? baseY - h : baseY
      var topR = dir < 0 ? radius : 0
      var botR = dir < 0 ? 0 : radius

      ctx.beginPath()
      ctx.moveTo(x + topR, y)
      ctx.lineTo(x + pillWidth - topR, y)
      if (topR > 0) ctx.quadraticCurveTo(x + pillWidth, y, x + pillWidth, y + topR)
      else ctx.lineTo(x + pillWidth, y)
      ctx.lineTo(x + pillWidth, y + h - botR)
      if (botR > 0) ctx.quadraticCurveTo(x + pillWidth, y + h, x + pillWidth - botR, y + h)
      else ctx.lineTo(x + pillWidth, y + h)
      ctx.lineTo(x + botR, y + h)
      if (botR > 0) ctx.quadraticCurveTo(x, y + h, x, y + h - botR)
      else ctx.lineTo(x, y + h)
      ctx.lineTo(x, y + topR)
      if (topR > 0) ctx.quadraticCurveTo(x, y, x + topR, y)
      else ctx.lineTo(x, y)
      ctx.closePath()
      ctx.fill()
    }

    ctx.restore()
  }

  function _vizDrawNeonWave(ctx, raw, baseY, maxAmp, dir, slant, w, color) {
    var vals = lyricsIsland._vizEdgePad(raw)
    var step = w / (vals.length - 1)
    var coreColor = Qt.rgba(
      Math.min(1, color.r + (1 - color.r) * 0.85),
      Math.min(1, color.g + (1 - color.g) * 0.85),
      Math.min(1, color.b + (1 - color.b) * 0.85),
      1.0
    )

    ctx.save()
    ctx.lineCap = "round"
    ctx.lineJoin = "round"

    ctx.beginPath()
    lyricsIsland._vizDrawWave(ctx, vals, step, baseY, maxAmp, dir)
    ctx.closePath()
    var fill = ctx.createLinearGradient(0, baseY, 0, baseY + dir * maxAmp)
    fill.addColorStop(0, Qt.rgba(color.r, color.g, color.b, 0.20))
    fill.addColorStop(1, Qt.rgba(color.r, color.g, color.b, 0.0))
    ctx.fillStyle = fill
    ctx.fill()

    ctx.beginPath()
    lyricsIsland._vizDrawLine(ctx, vals, step, baseY, maxAmp, dir)
    ctx.strokeStyle = Qt.rgba(color.r, color.g, color.b, 0.30)
    ctx.lineWidth = 6
    ctx.stroke()

    ctx.beginPath()
    lyricsIsland._vizDrawLine(ctx, vals, step, baseY, maxAmp, dir)
    ctx.strokeStyle = Qt.rgba(color.r, color.g, color.b, 0.55)
    ctx.lineWidth = 3
    ctx.stroke()

    ctx.beginPath()
    lyricsIsland._vizDrawLine(ctx, vals, step, baseY, maxAmp, dir)
    ctx.strokeStyle = coreColor
    ctx.lineWidth = 1
    ctx.stroke()

    ctx.restore()
  }

  function _vizPaletteGradient(ctx, palette, x0, y0, x1, y1, alpha) {
    var grad = ctx.createLinearGradient(x0, y0, x1, y1)
    for (var p = 0; p < palette.length; p++) {
      var stop = palette.length === 1 ? 0 : p / (palette.length - 1)
      var c = palette[p]
      grad.addColorStop(stop, Qt.rgba(c.r, c.g, c.b, alpha))
    }
    return grad
  }

  function _vizDrawVU(ctx, raw, peaks, baseY, maxAmp, dir, slant, w, palette) {
    var count = raw.length
    var usable = w - slant * 2
    var gap = 3
    var barW = (usable - gap * (count - 1)) / count
    var startX = slant
    ctx.save()
    ctx.fillStyle = lyricsIsland._vizPaletteGradient(ctx, palette, slant, 0, slant + usable, 0, 1.0)
    for (var i = 0; i < count; i++) {
      var x = startX + i * (barW + gap)
      var h = (raw[i] / 100) * maxAmp
      if (h >= 1) {
        var y = dir < 0 ? baseY - h : baseY
        ctx.fillRect(x, y, barW, h)
      }
      var ph = ((peaks[i] || 0) / 100) * maxAmp
      if (ph >= 1) {
        var py = dir < 0 ? baseY - ph - 1.5 : baseY + ph
        ctx.fillRect(x, py, barW, 1.5)
      }
    }
    ctx.restore()
  }

  function _vizDrawSpectrogram(ctx, history, palette, baseY, maxAmp, dir, slant, w) {
    if (!history.length) return
    var bandCount = history[0].length
    var cols = lyricsIsland._vizSpectrogramCols
    var usable = w - slant * 2
    var colW = usable / cols
    var rowH = maxAmp / bandCount
    var startCol = cols - history.length
    ctx.save()
    for (var c = 0; c < history.length; c++) {
      var entry = history[c]
      var x = slant + (startCol + c) * colW
      for (var b = 0; b < bandCount; b++) {
        var v = entry[b] / 100
        if (v < 0.04) continue
        var palStop = Math.min(palette.length - 1, Math.max(0, Math.floor(v * (palette.length - 1))))
        var col = palette[palStop]
        var bIdx = bandCount - 1 - b
        var y = dir < 0 ? baseY - (bIdx + 1) * rowH : baseY + bIdx * rowH
        ctx.fillStyle = Qt.rgba(col.r, col.g, col.b, Math.min(1, v * 0.95))
        ctx.fillRect(x, y, colW + 0.5, rowH + 0.5)
      }
    }
    ctx.restore()
  }

  function _vizDrawStardust(ctx, raw, baseY, maxAmp, dir, slant, w, palette) {
    var pts = lyricsIsland._vizStardust
    if (!pts.length) return
    var usable = w - slant * 2
    ctx.save()
    for (var i = 0; i < pts.length; i++) {
      var p = pts[i]
      var v = (raw[p.band] || 0) / 100
      var brightness = 0.10 + v * 0.90
      var x = slant + p.x * usable
      var y = dir < 0 ? baseY - p.y * maxAmp : baseY + p.y * maxAmp
      var palIdx = Math.floor(p.x * (palette.length - 1))
      var c = palette[palIdx]
      ctx.fillStyle = Qt.rgba(c.r, c.g, c.b, brightness)
      ctx.beginPath()
      ctx.arc(x, y, p.size * (0.6 + v * 0.6), 0, Math.PI * 2)
      ctx.fill()
    }
    ctx.restore()
  }

  function _vizDrawLiquid(ctx, raw, baseY, maxAmp, dir, slant, w, palette) {
    var energy = 0
    for (var i = 0; i < raw.length; i++) energy += raw[i]
    energy = (energy / raw.length) / 100
    var bass = (raw[0] + raw[1] + raw[2]) / 300
    var fillH = energy * maxAmp
    if (fillH < 1) return
    var amp = bass * 3.5
    var cycles = 3
    var t = Date.now() / 220
    ctx.save()
    ctx.beginPath()
    var surfY = baseY + dir * fillH
    ctx.moveTo(0, baseY)
    for (var x = 0; x <= w; x += 2) {
      var phase = (x / w) * cycles * Math.PI * 2 + t
      var dy = Math.sin(phase) * amp + Math.sin(phase * 2.3 + 1.7) * amp * 0.3
      ctx.lineTo(x, surfY + dir * dy)
    }
    ctx.lineTo(w, baseY)
    ctx.closePath()
    var gradV = ctx.createLinearGradient(0, baseY, 0, baseY + dir * maxAmp)
    var c0 = palette[Math.floor(palette.length * 0.3)] || palette[0]
    var c1 = palette[Math.floor(palette.length * 0.6)] || palette[0]
    var c2 = palette[palette.length - 1] || palette[0]
    gradV.addColorStop(0, Qt.rgba(c0.r, c0.g, c0.b, 0.85))
    gradV.addColorStop(0.7, Qt.rgba(c1.r, c1.g, c1.b, 0.45))
    gradV.addColorStop(1, Qt.rgba(c2.r, c2.g, c2.b, 0.10))
    ctx.fillStyle = gradV
    ctx.fill()
    ctx.beginPath()
    ctx.moveTo(0, surfY)
    for (var x2 = 0; x2 <= w; x2 += 2) {
      var phase2 = (x2 / w) * cycles * Math.PI * 2 + t
      var dy2 = Math.sin(phase2) * amp + Math.sin(phase2 * 2.3 + 1.7) * amp * 0.3
      ctx.lineTo(x2, surfY + dir * dy2)
    }
    ctx.strokeStyle = lyricsIsland._vizPaletteGradient(ctx, palette, 0, 0, w, 0, 0.95)
    ctx.lineWidth = 1.2
    ctx.stroke()
    ctx.restore()
  }

  function _vizDrawRipple(ctx, ripples, baseY, maxAmp, dir, slant, w, palette) {
    if (!ripples.length) return
    var cx = w / 2
    var maxR = Math.max(maxAmp, (w - slant * 2) / 2)
    ctx.save()
    for (var i = 0; i < ripples.length; i++) {
      var r = ripples[i]
      var t = r.age / 36
      var radius = t * maxR
      var alpha = (1 - t) * r.intensity * 0.55
      var palIdx = Math.floor(t * (palette.length - 1))
      var c = palette[palIdx]
      ctx.beginPath()
      ctx.strokeStyle = Qt.rgba(c.r, c.g, c.b, alpha)
      ctx.lineWidth = 1.4
      if (dir < 0) ctx.arc(cx, baseY, radius, Math.PI, 2 * Math.PI)
      else ctx.arc(cx, baseY, radius, 0, Math.PI)
      ctx.stroke()
    }
    ctx.restore()
  }

  function _vizDrawZigzag(ctx, raw, baseY, maxAmp, dir, slant, w, palette) {
    var count = raw.length
    var usable = w - slant * 2
    var step = usable / Math.max(1, count - 1)
    var grad = lyricsIsland._vizPaletteGradient(ctx, palette, slant, 0, slant + usable, 0, 1.0)
    ctx.save()
    ctx.beginPath()
    ctx.moveTo(slant, baseY)
    for (var i = 0; i < count; i++) {
      ctx.lineTo(slant + i * step, baseY + dir * (raw[i] / 100) * maxAmp)
    }
    ctx.lineTo(slant + (count - 1) * step, baseY)
    ctx.closePath()
    ctx.fillStyle = grad
    ctx.globalAlpha = 0.30
    ctx.fill()
    ctx.globalAlpha = 1.0
    ctx.beginPath()
    ctx.moveTo(slant, baseY + dir * (raw[0] / 100) * maxAmp)
    for (var j = 1; j < count; j++) {
      ctx.lineTo(slant + j * step, baseY + dir * (raw[j] / 100) * maxAmp)
    }
    ctx.strokeStyle = grad
    ctx.lineWidth = 1.6
    ctx.lineCap = "square"
    ctx.lineJoin = "miter"
    ctx.stroke()
    ctx.restore()
  }

  function _vizDrawMetaballs(ctx, raw, baseY, maxAmp, dir, slant, w, palette) {
    var count = raw.length
    var usable = w - slant * 2
    var step = usable / (count + 1)
    ctx.save()
    for (var i = 0; i < count; i++) {
      var x = slant + step * (i + 1)
      var v = raw[i] / 100
      var radius = 1.5 + v * (maxAmp * 0.7)
      if (radius < 1.5) continue
      var y = dir < 0 ? baseY - radius * 0.85 : baseY + radius * 0.85
      var palIdx = Math.floor((i / Math.max(1, count - 1)) * (palette.length - 1))
      var c = palette[palIdx]
      var rg = ctx.createRadialGradient(x, y, 0, x, y, radius)
      rg.addColorStop(0, Qt.rgba(c.r, c.g, c.b, 0.85))
      rg.addColorStop(0.55, Qt.rgba(c.r, c.g, c.b, 0.45))
      rg.addColorStop(1, Qt.rgba(c.r, c.g, c.b, 0))
      ctx.fillStyle = rg
      ctx.beginPath()
      ctx.arc(x, y, radius, 0, Math.PI * 2)
      ctx.fill()
    }
    ctx.restore()
  }

  function _vizDrawComet(ctx, baseY, maxAmp, dir, slant, w, palette) {
    var trail = lyricsIsland._vizCometTrail
    if (!trail.length) return
    var usable = w - slant * 2
    var midY = dir < 0 ? baseY - maxAmp / 2 : baseY + maxAmp / 2
    ctx.save()
    for (var i = 0; i < trail.length; i++) {
      var t = trail[i]
      var ageT = (trail.length - 1 - i) / Math.max(1, trail.length - 1)
      var alpha = (1 - ageT) * (0.20 + t.intensity * 0.75)
      var radius = 0.8 + (1 - ageT) * 2.6
      var x = slant + t.x * usable
      var palIdx = Math.floor(t.x * (palette.length - 1))
      var c = palette[palIdx]
      ctx.fillStyle = Qt.rgba(c.r, c.g, c.b, alpha)
      ctx.beginPath()
      ctx.arc(x, midY, radius, 0, Math.PI * 2)
      ctx.fill()
    }
    ctx.restore()
  }

  function _vizDrawAurora(ctx, raw, baseY, maxAmp, dir, slant, w, colors, ampScale) {
    var count = raw.length
    var scale = ampScale === undefined ? 1.0 : ampScale
    ctx.save()
    ctx.lineCap = "round"
    ctx.lineJoin = "round"

    var fillCol = dir < 0 ? colors.primary : colors.surface
    var strokeCol = dir < 0 ? colors.tertiary : colors.surface
    var fillBase = dir < 0 ? 0.25 : 0.88
    var fillMid  = dir < 0 ? 0.08 : 0.88
    var strokeAlpha = dir < 0 ? 0.20 : 0.50

    var layerCount = Math.max(1, Config.vizAuroraLayerCount)
    var minAmp = Math.max(0.01, Math.min(1.0, Config.vizAuroraMinAmp))

    for (var L = 0; L < layerCount; L++) {
      var t = layerCount === 1 ? 0 : L / (layerCount - 1)
      var shift = L
      var aMul = 1.0 - (1.0 - minAmp) * t
      var hMul = 1.0 - (1.0 - minAmp) * Math.pow(t, 1.2)
      var layerAmp = maxAmp * hMul * scale
      var shiftedVals = []
      for (var i = 0; i < count; i++) shiftedVals.push(raw[(i + shift) % count])
      var padded = lyricsIsland._vizEdgePad(shiftedVals)
      var pStep = w / (padded.length - 1)

      ctx.beginPath()
      lyricsIsland._vizDrawWave(ctx, padded, pStep, baseY, layerAmp, dir)
      ctx.closePath()
      var fill
      if (dir < 0) {
        fill = ctx.createLinearGradient(0, baseY, 0, baseY + dir * layerAmp)
        fill.addColorStop(0,   Qt.rgba(fillCol.r, fillCol.g, fillCol.b, fillBase * aMul))
        fill.addColorStop(0.6, Qt.rgba(fillCol.r, fillCol.g, fillCol.b, fillMid * aMul))
        fill.addColorStop(1,   Qt.rgba(fillCol.r, fillCol.g, fillCol.b, 0.0))
      } else {
        fill = ctx.createLinearGradient(0, 0, 0, layerAmp)
        fill.addColorStop(0,   Qt.rgba(fillCol.r, fillCol.g, fillCol.b, fillBase * aMul))
        fill.addColorStop(0.7, Qt.rgba(fillCol.r, fillCol.g, fillCol.b, fillMid * aMul))
        fill.addColorStop(0.9, Qt.rgba(fillCol.r, fillCol.g, fillCol.b, 0.35 * aMul))
        fill.addColorStop(1,   Qt.rgba(fillCol.r, fillCol.g, fillCol.b, 0.0))
      }
      ctx.fillStyle = fill
      ctx.fill()

      ctx.beginPath()
      lyricsIsland._vizDrawLine(ctx, padded, pStep, baseY, layerAmp, dir)
      ctx.strokeStyle = Qt.rgba(strokeCol.r, strokeCol.g, strokeCol.b, strokeAlpha * aMul)
      ctx.lineWidth = 1
      ctx.stroke()
    }
    ctx.restore()
  }



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
      var dir = -1
      var maxAmp = height
      var slant = lyricsIsland.diagSlant
      var islandH = lyricsIsland.barHeight
      var topFrac = (islandH - height) / islandH

      ctx.save()
      ctx.beginPath()
      var leftAtTop = slant * topFrac
      var rightAtTop = width - slant * topFrac
      var leftAtBot = slant
      var rightAtBot = width - slant
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
        var grad = ctx.createLinearGradient(0, baseY, 0, baseY + dir * maxAmp)
        grad.addColorStop(0, Qt.rgba(pri.r, pri.g, pri.b, 0.3))
        grad.addColorStop(1, Qt.rgba(pri.r, pri.g, pri.b, 0.05))
        ctx.fillStyle = grad
        lyricsIsland._vizDrawBars(ctx, raw, baseY, maxAmp, dir, slant, width)
      } else if (theme === "neon") {
        lyricsIsland._vizDrawNeonWave(ctx, raw, baseY, maxAmp, dir, slant, width, pri)
      } else if (theme === "pulse") {
        var cp = lyricsIsland.colors
        lyricsIsland._vizDrawPulse(ctx, raw, baseY, maxAmp, dir, slant, width, [
          cp.tertiaryContainer, cp.tertiary, cp.primary, cp.secondary, cp.primaryContainer, cp.tertiary, cp.tertiaryContainer
        ])
      } else if (theme === "vu") {
        var cv = lyricsIsland.colors
        lyricsIsland._vizDrawVU(ctx, raw, lyricsIsland._vizPeaks, baseY, maxAmp, dir, slant, width, [
          cv.tertiary, cv.primary, cv.secondary
        ])
      } else if (theme === "spectrogram") {
        var cs = lyricsIsland.colors
        lyricsIsland._vizDrawSpectrogram(ctx, lyricsIsland._vizSpectrogramHistory, [
          cs.surfaceContainer, cs.tertiaryContainer, cs.tertiary, cs.primary, cs.secondary
        ], baseY, maxAmp, dir, slant, width)
      } else if (theme === "stardust") {
        var cd = lyricsIsland.colors
        lyricsIsland._vizDrawStardust(ctx, raw, baseY, maxAmp, dir, slant, width, [
          cd.tertiaryContainer, cd.tertiary, cd.primary, cd.secondary, cd.primaryContainer
        ])
      } else if (theme === "liquid") {
        var cl = lyricsIsland.colors
        lyricsIsland._vizDrawLiquid(ctx, raw, baseY, maxAmp, dir, slant, width, [
          cl.tertiaryContainer, cl.tertiary, cl.primary, cl.secondary, cl.primaryContainer
        ])
      } else if (theme === "ripple") {
        var cr = lyricsIsland.colors
        lyricsIsland._vizDrawRipple(ctx, lyricsIsland._vizRipples, baseY, maxAmp, dir, slant, width, [
          cr.primary, cr.tertiary, cr.secondary, cr.primaryContainer
        ])
      } else if (theme === "zigzag") {
        var cz = lyricsIsland.colors
        lyricsIsland._vizDrawZigzag(ctx, raw, baseY, maxAmp, dir, slant, width, [
          cz.tertiary, cz.primary, cz.secondary
        ])
      } else if (theme === "metaballs") {
        var cm = lyricsIsland.colors
        lyricsIsland._vizDrawMetaballs(ctx, raw, baseY, maxAmp, dir, slant, width, [
          cm.tertiaryContainer, cm.tertiary, cm.primary, cm.secondary, cm.primaryContainer
        ])
      } else if (theme === "comet") {
        var cc = lyricsIsland.colors
        lyricsIsland._vizDrawComet(ctx, baseY, maxAmp, dir, slant, width, [
          cc.tertiary, cc.primary, cc.secondary
        ])
      } else if (theme === "aurora") {
        lyricsIsland._vizDrawAurora(ctx, raw, baseY, maxAmp, dir, slant, width, lyricsIsland.colors)
      } else if (theme === "aurora-responsive") {
        var pumpA = Math.min(1.0, Math.pow(lyricsIsland._vizAuroraEnv, Config.vizAuroraRespPumpExp) * Config.vizAuroraRespPumpScale)
        lyricsIsland._vizDrawAurora(ctx, raw, baseY, maxAmp, dir, slant, width, lyricsIsland.colors, pumpA)
      } else if (theme === "blocks") {
        ctx.fillStyle = Qt.rgba(pri.r, pri.g, pri.b, 0.25)
        lyricsIsland._vizDrawBlocks(ctx, raw, baseY, maxAmp, dir, slant, width)
      } else if (theme === "dots") {
        ctx.fillStyle = Qt.rgba(pri.r, pri.g, pri.b, 0.35)
        ctx.strokeStyle = Qt.rgba(ter.r, ter.g, ter.b, 0.12)
        ctx.lineWidth = 1
        lyricsIsland._vizDrawDots(ctx, raw, baseY, maxAmp, dir, slant, width)
      } else if (theme === "line") {
        var vals = lyricsIsland._vizEdgePad(raw)
        var step = width / (vals.length - 1)

        ctx.beginPath()
        lyricsIsland._vizDrawLine(ctx, vals, step, baseY, maxAmp, dir)
        ctx.strokeStyle = Qt.rgba(pri.r, pri.g, pri.b, 0.08)
        ctx.lineWidth = 4
        ctx.stroke()

        ctx.beginPath()
        lyricsIsland._vizDrawLine(ctx, vals, step, baseY, maxAmp, dir)
        ctx.strokeStyle = Qt.rgba(pri.r, pri.g, pri.b, 0.3)
        ctx.lineWidth = 1.5
        ctx.stroke()
      } else {
        var vals = lyricsIsland._vizEdgePad(raw)
        var step = width / (vals.length - 1)

        ctx.beginPath()
        lyricsIsland._vizDrawWave(ctx, vals, step, baseY, maxAmp, dir)
        ctx.closePath()
        var grad = ctx.createLinearGradient(0, baseY, 0, baseY + dir * maxAmp)
        grad.addColorStop(0, Qt.rgba(pri.r, pri.g, pri.b, 0.25))
        grad.addColorStop(0.6, Qt.rgba(pri.r, pri.g, pri.b, 0.08))
        grad.addColorStop(1, Qt.rgba(pri.r, pri.g, pri.b, 0.0))
        ctx.fillStyle = grad
        ctx.fill()

        ctx.beginPath()
        lyricsIsland._vizDrawWave(ctx, vals, step, baseY, maxAmp, dir)
        ctx.strokeStyle = Qt.rgba(ter.r, ter.g, ter.b, 0.2)
        ctx.lineWidth = 1
        ctx.stroke()
      }

      ctx.restore()
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
      function onAudioBarsUpdated() {
        let bars = service.audioBars
        let display = audioVisualizer.displayBars
        for (let i = 0; i < bars.length && i < display.length; i++) {
          display[i] = display[i] + (bars[i] - display[i]) * 0.45
        }
        var theme = lyricsIsland.vizTheme
        if (theme === "vu")           lyricsIsland._vizUpdatePeaks(display)
        if (theme === "spectrogram")  lyricsIsland._vizUpdateSpectrogram(display)
        if (theme === "ripple")       lyricsIsland._vizUpdateRipples(display)
        if (theme === "comet")        lyricsIsland._vizUpdateComet(display)
        if (theme === "aurora-responsive") lyricsIsland._vizUpdateAuroraEnv(display)
        audioVisualizer.requestPaint()
        audioVisualizerUp.requestPaint()
      }
    }

    onPaint: {
      var ctx = getContext("2d")
      ctx.clearRect(0, 0, width, height)

      var raw = displayBars
      if (!raw || raw.length === 0) return

      var baseY = 0
      var dir = 1
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
        var grad = ctx.createLinearGradient(0, baseY, 0, baseY + dir * maxAmp)
        grad.addColorStop(0, Qt.rgba(sur.r, sur.g, sur.b, 0.88))
        grad.addColorStop(1, Qt.rgba(sur.r, sur.g, sur.b, 0.0))
        ctx.fillStyle = grad
        lyricsIsland._vizDrawBars(ctx, raw, baseY, maxAmp, dir, slant, width)
      } else if (theme === "neon") {
        lyricsIsland._vizDrawNeonWave(ctx, raw, baseY, maxAmp, dir, slant, width, lyricsIsland.colors.primary)
      } else if (theme === "pulse") {
        var cp2 = lyricsIsland.colors
        lyricsIsland._vizDrawPulse(ctx, raw, baseY, maxAmp, dir, slant, width, [
          cp2.tertiaryContainer, cp2.tertiary, cp2.primary, cp2.secondary, cp2.primaryContainer, cp2.tertiary, cp2.tertiaryContainer
        ])
      } else if (theme === "vu") {
        var cv2 = lyricsIsland.colors
        lyricsIsland._vizDrawVU(ctx, raw, lyricsIsland._vizPeaks, baseY, maxAmp, dir, slant, width, [
          cv2.tertiary, cv2.primary, cv2.secondary
        ])
      } else if (theme === "spectrogram") {
        var cs2 = lyricsIsland.colors
        lyricsIsland._vizDrawSpectrogram(ctx, lyricsIsland._vizSpectrogramHistory, [
          cs2.surfaceContainer, cs2.tertiaryContainer, cs2.tertiary, cs2.primary, cs2.secondary
        ], baseY, maxAmp, dir, slant, width)
      } else if (theme === "stardust") {
        var cd2 = lyricsIsland.colors
        lyricsIsland._vizDrawStardust(ctx, raw, baseY, maxAmp, dir, slant, width, [
          cd2.tertiaryContainer, cd2.tertiary, cd2.primary, cd2.secondary, cd2.primaryContainer
        ])
      } else if (theme === "liquid") {
        var cl2 = lyricsIsland.colors
        lyricsIsland._vizDrawLiquid(ctx, raw, baseY, maxAmp, dir, slant, width, [
          cl2.tertiaryContainer, cl2.tertiary, cl2.primary, cl2.secondary, cl2.primaryContainer
        ])
      } else if (theme === "ripple") {
        var cr2 = lyricsIsland.colors
        lyricsIsland._vizDrawRipple(ctx, lyricsIsland._vizRipples, baseY, maxAmp, dir, slant, width, [
          cr2.primary, cr2.tertiary, cr2.secondary, cr2.primaryContainer
        ])
      } else if (theme === "zigzag") {
        var cz2 = lyricsIsland.colors
        lyricsIsland._vizDrawZigzag(ctx, raw, baseY, maxAmp, dir, slant, width, [
          cz2.tertiary, cz2.primary, cz2.secondary
        ])
      } else if (theme === "metaballs") {
        var cm2 = lyricsIsland.colors
        lyricsIsland._vizDrawMetaballs(ctx, raw, baseY, maxAmp, dir, slant, width, [
          cm2.tertiaryContainer, cm2.tertiary, cm2.primary, cm2.secondary, cm2.primaryContainer
        ])
      } else if (theme === "comet") {
        var cc2 = lyricsIsland.colors
        lyricsIsland._vizDrawComet(ctx, baseY, maxAmp, dir, slant, width, [
          cc2.tertiary, cc2.primary, cc2.secondary
        ])
      } else if (theme === "aurora") {
        lyricsIsland._vizDrawAurora(ctx, raw, baseY, maxAmp, dir, slant, width, lyricsIsland.colors)
      } else if (theme === "aurora-responsive") {
        var pumpA2 = Math.min(1.0, Math.pow(lyricsIsland._vizAuroraEnv, Config.vizAuroraRespPumpExp) * Config.vizAuroraRespPumpScale)
        lyricsIsland._vizDrawAurora(ctx, raw, baseY, maxAmp, dir, slant, width, lyricsIsland.colors, pumpA2)
      } else if (theme === "blocks") {
        ctx.fillStyle = Qt.rgba(sur.r, sur.g, sur.b, 0.88)
        lyricsIsland._vizDrawBlocks(ctx, raw, baseY, maxAmp, dir, slant, width)
      } else if (theme === "dots") {
        ctx.fillStyle = Qt.rgba(sur.r, sur.g, sur.b, 0.88)
        ctx.strokeStyle = Qt.rgba(sur.r, sur.g, sur.b, 0.4)
        ctx.lineWidth = 1
        lyricsIsland._vizDrawDots(ctx, raw, baseY, maxAmp, dir, slant, width)
      } else if (theme === "line") {
        var vals = lyricsIsland._vizEdgePad(raw)
        var step = width / (vals.length - 1)
        ctx.beginPath()
        lyricsIsland._vizDrawLine(ctx, vals, step, baseY, maxAmp, dir)
        ctx.strokeStyle = Qt.rgba(sur.r, sur.g, sur.b, 0.3)
        ctx.lineWidth = 4
        ctx.stroke()
        ctx.beginPath()
        lyricsIsland._vizDrawLine(ctx, vals, step, baseY, maxAmp, dir)
        ctx.strokeStyle = Qt.rgba(sur.r, sur.g, sur.b, 0.88)
        ctx.lineWidth = 1.5
        ctx.stroke()
      } else {
        var vals = lyricsIsland._vizEdgePad(raw)
        var step = width / (vals.length - 1)

        ctx.beginPath()
        lyricsIsland._vizDrawWave(ctx, vals, step, baseY, maxAmp, dir)
        ctx.closePath()
        var grad = ctx.createLinearGradient(0, 0, 0, maxAmp)
        grad.addColorStop(0, Qt.rgba(sur.r, sur.g, sur.b, 0.88))
        grad.addColorStop(0.7, Qt.rgba(sur.r, sur.g, sur.b, 0.88))
        grad.addColorStop(0.9, Qt.rgba(sur.r, sur.g, sur.b, 0.35))
        grad.addColorStop(1, Qt.rgba(sur.r, sur.g, sur.b, 0.0))
        ctx.fillStyle = grad
        ctx.fill()

        ctx.beginPath()
        lyricsIsland._vizDrawWave(ctx, vals, step, baseY, maxAmp, dir)
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
