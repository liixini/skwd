
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower
import Quickshell.Bluetooth
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import ".."
import "../services"
import "lyrics"
import "dropdowns"


PanelWindow {
  id: bar


  required property var colors
  required property var clock
  required property bool barVisible
  required property var activePlayer
  required property real cpuUsage
  required property real memUsage
  required property real gpuUsage
  required property real cpuTemp
  required property real gpuTemp
  required property string weatherDesc
  required property string weatherTemp
  required property string weatherCity
  required property var weatherForecast
  screen: Quickshell.screens.find(s => s.name === Config.mainMonitor) ?? Quickshell.screens[0]
  WlrLayershell.namespace: "topbar"
  WlrLayershell.keyboardFocus: wifiDropdown.pendingSsid !== ""
    ? WlrKeyboardFocus.Exclusive
    : WlrKeyboardFocus.OnDemand

  anchors {
    top: true
    left: true
    right: true
  }

  property real barHeight: 32
  property bool _pill: Config.barStyle === "pill"
  property real _pillSideMargin: _pill ? Config.barPillSideMargin : 0
  property real _pillTopMargin: _pill ? Config.barPillTopMargin : 0
  property real topMargin: _pill ? _pillTopMargin : -1
  property real waveformHeight: (Config.visualizerTheme === "aurora" || Config.visualizerTheme === "aurora-responsive") ? 28 : 14
  property real slideOffset: barVisible ? 0 : -(barHeight + topMargin)


  property string activeDropdown: ""
  property real dropdownCenterX: bar.width / 2

  function closeAllDropdowns() {
    activeDropdown = ""
  }

  function _openDropdown(name, sourceItem) {
    if (sourceItem) {
      var p = sourceItem.mapToItem(bar.contentItem, sourceItem.width / 2, 0)
      bar.dropdownCenterX = p.x
    }
    bar.activeDropdown = bar.activeDropdown === name ? "" : name
  }


  FocusScope {
    anchors.fill: parent
    focus: bar.activeDropdown !== ""
    Keys.onEscapePressed: {
      bar.closeAllDropdowns()
    }
  }

  property real animatedBarHeight: barHeight + topMargin + slideOffset

  property real _wifiH: Config.wifiEnabled ? wifiDropdown.animatedHeight : 0
  property real _volumeH: Config.volumeEnabled ? volumeDropdown.animatedHeight : 0
  property real _calendarH: Config.calendarEnabled ? calendarDropdown.animatedHeight : 0
  property real _bluetoothH: Config.bluetoothEnabled ? bluetoothDropdown.animatedHeight : 0
  property real _weatherH: Config.weatherEnabled ? weatherDropdown.animatedHeight : 0
  property real _brightnessH: Config.brightnessEnabled ? brightnessDropdown.animatedHeight : 0
  property real _notifsH: Config.notificationsEnabled ? notificationsDropdown.animatedHeight : 0
  property real _qsmemH: qsmemDropdown.animatedHeight
  property real totalDropdownHeight: _wifiH + _volumeH + _calendarH + _bluetoothH + _weatherH + _brightnessH + _notifsH + _qsmemH

  function _sideHeight(side) {
    return (_widgetSide("wifi")          === side ? _wifiH       : 0)
         + (_widgetSide("volume")        === side ? _volumeH     : 0)
         + (_widgetSide("clock")         === side ? _calendarH   : 0)
         + (_widgetSide("bluetooth")     === side ? _bluetoothH  : 0)
         + (_widgetSide("weather")       === side ? _weatherH    : 0)
         + (_widgetSide("brightness")    === side ? _brightnessH : 0)
         + (_widgetSide("notifications") === side ? _notifsH     : 0)
         + (_widgetSide("qsmem")         === side ? _qsmemH      : 0)
  }
  property real leftDropdownHeight:  _sideHeight("left")
  property real rightDropdownHeight: _sideHeight("right")
  property bool _lyricsPlaying: Config.musicEnabled ? lyricsIsland.musicPlaying : false
  implicitHeight: Math.max(1, animatedBarHeight) + totalDropdownHeight + (_lyricsPlaying ? waveformHeight : 0)
  exclusiveZone: barVisible ? barHeight + topMargin : 0
  color: "transparent"

  function _dropTopMargin(prevAccumulated) {
    return bar.slideOffset + bar.topMargin + (bar._pill ? bar.barHeight : 0) + prevAccumulated
  }


  function focusWorkspace(wsId) {
    WmService.focusWorkspace(wsId.toString())
  }

  property real dropdownMinWidth: 320
  property real dropdownContentWidth: 320
  property real rightDropdownWidth: Math.max(dropdownMinWidth, rightPanel ? rightPanel.width : dropdownMinWidth)
  property real leftDropdownWidth:  Math.max(dropdownMinWidth, leftPanel  ? leftPanel.width  : dropdownMinWidth)

  function _widgetSide(id) {
    return Config.barLeftLayout.indexOf(id) >= 0 ? "left" : "right"
  }

  mask: Region {
    x: bar._pillSideMargin
    width: bar.width - 2 * bar._pillSideMargin
    y: 0
    height: Math.max(1, bar.animatedBarHeight) + (bar._lyricsPlaying ? bar.waveformHeight : 0)

    Region {
      x: 0
      y: Math.max(1, bar.animatedBarHeight)
      width: bar.leftDropdownWidth
      height: bar.totalDropdownHeight
    }
    Region {
      x: bar.width - bar.rightDropdownWidth - 2 * bar._pillSideMargin
      y: Math.max(1, bar.animatedBarHeight)
      width: bar.rightDropdownWidth
      height: bar.totalDropdownHeight
    }
  }

  Behavior on slideOffset {
    NumberAnimation { duration: 150; easing.type: Easing.OutQuad }
  }


  property real diagSlant: 28


  QtObject {
    id: qsmemInfo
    property var processes: []
    property real totalMb: 0
    property real totalRssMb: 0
  }

  property var _qsmemStdout: []
  Process {
    id: qsmemProc
    command: ["sh", "-c",
      "{ pgrep -x quickshell; pgrep -x skwd-daemon; } | while read pid; do " +
      "  pss=$(awk '/^Pss:/{p+=$2} END{print p+0}' /proc/$pid/smaps_rollup 2>/dev/null); " +
      "  rss=$(awk '/^Rss:/{p+=$2} END{print p+0}' /proc/$pid/smaps_rollup 2>/dev/null); " +
      "  args=$(tr '\\0' ' ' < /proc/$pid/cmdline 2>/dev/null); " +
      "  printf '%s %s %s %s\\n' \"$pid\" \"${pss:-0}\" \"${rss:-0}\" \"$args\"; " +
      "done"]
    stdout: SplitParser {
      splitMarker: ""
      onRead: data => bar._qsmemStdout.push(data)
    }
    onExited: {
      var text = bar._qsmemStdout.join("")
      bar._qsmemStdout = []
      var lines = text.split("\n")
      var labelOf = function(qmlPath) {
        if (!qmlPath) return ""
        if (qmlPath.indexOf("skwd-daemon/data/host") >= 0) return "host"
        if (qmlPath.indexOf("skwd-wall") >= 0)         return "wall"
        if (qmlPath.indexOf("skwd-bar") >= 0)          return "bar"
        if (qmlPath.indexOf("skwd-launch") >= 0)       return "launcher"
        if (qmlPath.indexOf("skwd-switch") >= 0)       return "switch"
        if (qmlPath.indexOf("skwd-notification") >= 0) return "notification"
        if (qmlPath.indexOf("skwd-music") >= 0)        return "music"
        if (qmlPath.indexOf("skwd-power") >= 0)        return "power"
        if (qmlPath.indexOf("skwd-settings") >= 0)     return "settings"
        var parts = qmlPath.split("/")
        for (var i = parts.length - 2; i >= 0; i--) {
          if (parts[i] && parts[i] !== "qml" && parts[i] !== "data" && parts[i] !== "host") return parts[i]
        }
        return "quickshell"
      }
      var seen = {}
      var out = []
      var totalPss = 0
      var totalRss = 0
      for (var i = 0; i < lines.length; i++) {
        var line = lines[i].trim()
        if (line.length === 0) continue
        var m = line.match(/^(\d+)\s+(\d+)\s+(\d+)\s+(.*)$/)
        if (!m) continue
        var pssKb = parseInt(m[2], 10)
        var rssKb = parseInt(m[3], 10)
        var args = m[4]
        var bin = args.split(/\s+/)[0]
        var isQuickshell = bin === "quickshell" || bin.endsWith("/quickshell")
        var isDaemon = bin === "skwd-daemon" || bin.endsWith("/skwd-daemon")
        if (!isQuickshell && !isDaemon) continue
        var label
        if (isDaemon) {
          label = "daemon"
        } else {
          var pm = args.match(/(?:^|\s)-p\s+(\S+)/)
          var qmlPath = pm ? pm[1] : ""
          label = labelOf(qmlPath)
        }
        if (seen[label]) {
          seen[label].pss += pssKb / 1024
          seen[label].rss += rssKb / 1024
        } else {
          var entry = { label: label, pss: pssKb / 1024, rss: rssKb / 1024 }
          seen[label] = entry
          out.push(entry)
        }
        totalPss += pssKb / 1024
        totalRss += rssKb / 1024
      }
      out.sort(function(a, b) { return b.pss - a.pss })
      qsmemInfo.processes = out
      qsmemInfo.totalMb = totalPss
      qsmemInfo.totalRssMb = totalRss
    }
  }

  Timer {
    id: qsmemTimer
    interval: Math.max(1, Config.qsmemRefreshSec) * 1000
    running: Config.qsmemEnabled
    repeat: true
    triggeredOnStart: true
    onTriggered: {
      if (!qsmemProc.running) {
        bar._qsmemStdout = []
        qsmemProc.running = true
      }
    }
  }

  QtObject {
    id: bluetoothInfo
    property var connectedDevices: {
      if (!Bluetooth.defaultAdapter || !Bluetooth.defaultAdapter.devices) return []
      return Bluetooth.defaultAdapter.devices.values.filter(dev => dev && dev.connected)
    }
    property string batteryText: {
      let batteries = connectedDevices
        .filter(d => d.batteryAvailable && d.battery > 0)
        .map(d => Math.round(d.battery * 100) + "%")
      return batteries.length > 0 ? batteries[0] : ""
    }
  }


  function _widgetComponent(id) {
    switch (id) {
      case "cpu":           return _cpuComp
      case "gpu":           return _gpuComp
      case "memory":        return _memoryComp
      case "qsmem":         return _qsmemComp
      case "weather":       return _weatherComp
      case "bluetooth":     return _bluetoothComp
      case "wifi":          return _wifiComp
      case "volume":        return _volumeComp
      case "clock":         return _clockComp
      case "brightness":    return _brightnessComp
      case "battery":       return _batteryComp
      case "notifications": return _notificationsComp
    }
    return null
  }

  property bool _leftHovered: false
  property bool _rightHovered: false
  readonly property string _activeDropdownSide:
    bar.activeDropdown !== "" ? bar._widgetSide(bar.activeDropdown) : ""
  readonly property bool _stickyLeft:
    bar._leftHovered || bar.activeDropdown !== ""
  readonly property bool _stickyRight:
    bar._rightHovered || bar.activeDropdown !== ""

  function _widgetHasData(id) {
    switch (id) {
      case "cpu":        return true
      case "gpu":        return true
      case "memory":     return true
      case "qsmem":      return Config.qsmemEnabled && qsmemInfo.totalMb > 0
      case "weather":    return Config.weatherEnabled && bar.weatherTemp !== "" && bar.weatherTemp !== undefined
      case "bluetooth":  return Config.bluetoothEnabled && (bluetoothInfo.batteryText !== "" || Config.barWidgetLabel("bluetooth", "") !== "")
      case "wifi":       return Config.wifiEnabled && (wifiInfo.ssid !== "" || Config.barWidgetLabel("wifi", "") !== "")
      case "volume":     return Config.volumeEnabled
      case "clock":      return Config.calendarEnabled
      case "brightness":    return Config.brightnessEnabled && brightnessInfo.percent >= 0
      case "battery":       return Config.batteryEnabled && batteryInfo.present
      case "notifications": return Config.notificationsEnabled && (!Config.notificationsHideWhenEmpty || notificationsHistory.count > 0)
    }
    return true
  }

  function _widgetShouldShow(id) {
    if (!_widgetHasData(id)) return false
    if (id === "notifications"
        && Config.notificationsAlwaysShowIfPresent
        && notificationsHistory.count > 0) {
      return true
    }
    if (Config.barWidgetMouseover(id)) {
      if (!Config.mouseoverEnabled) return true
      return _widgetSide(id) === "left" ? bar._stickyLeft : bar._stickyRight
    }
    return true
  }

  property real _lastBatteryPct: -1
  property int _lastBatteryState: 0
  Process { id: batteryNotifyProc; command: ["true"] }
  Connections {
    target: batteryInfo
    function onPercentageChanged() { bar._maybeNotifyBattery() }
    function onStateChanged() { bar._lastBatteryState = batteryInfo.state }
  }
  function _maybeNotifyBattery() {
    if (!batteryInfo.present) return
    var current = batteryInfo.percentage
    if (bar._lastBatteryPct < 0) { bar._lastBatteryPct = current; return }
    var prev = bar._lastBatteryPct
    if (Math.floor(prev) === Math.floor(current)) return
    var rules = Config.batteryNotifyRules || []
    for (var i = 0; i < rules.length; i++) {
      var r = rules[i]
      var pct = r.percent
      if (pct === undefined || pct === null) continue
      var crossedDown = prev > pct && current <= pct
      var crossedUp   = prev < pct && current >= pct
      var direction = ""
      if (crossedDown && (r.onDischarge !== false) && !batteryInfo.charging) direction = "discharge"
      else if (crossedUp && r.onCharge === true && batteryInfo.charging) direction = "charge"
      if (direction !== "") bar._sendBatteryNotify(pct, direction, current, r.message || "")
    }
    bar._lastBatteryPct = current
  }
  function _interpolate(tmpl, threshold, current) {
    var pct = Math.round(current)
    var state = batteryInfo.charging ? "charging" : "on battery"
    return tmpl
      .replace(/\{percent\}/g, pct + "%")
      .replace(/\{threshold\}/g, threshold + "%")
      .replace(/\{state\}/g, state)
  }
  function _sendBatteryNotify(threshold, direction, current, customMessage) {
    var defaultSummary = direction === "charge"
      ? "Battery reached " + threshold + "%"
      : "Battery dropped to " + threshold + "%"
    var defaultBody = "Now at " + Math.round(current) + "% (" + (batteryInfo.charging ? "charging" : "on battery") + ")"
    var summary, body
    if (customMessage && customMessage.length > 0) {
      summary = bar._interpolate(customMessage, threshold, current)
      body = ""
    } else {
      summary = defaultSummary
      body = defaultBody
    }
    var args = ["notify-send", "-a", "skwd-bar", "-i", "battery", summary]
    if (body.length > 0) args.push(body)
    batteryNotifyProc.command = args
    batteryNotifyProc.running = true
  }

  Component {
    id: _cpuComp
    Item {
      id: cpuRoot
      implicitWidth: cpuRow.implicitWidth
      implicitHeight: cpuRow.implicitHeight
      property string overrideLabel: Config.barWidgetLabel("cpu", "")
      Row {
        id: cpuRow
        anchors.verticalCenter: parent.verticalCenter
        spacing: 4
        Text { text: Config.barWidgetIcon("cpu", "󰻠"); font.pixelSize: 14; font.family: Style.fontFamilyNerdIcons; color: bar.colors.primary }
        Text { visible: cpuRoot.overrideLabel !== ""; text: cpuRoot.overrideLabel; font.pixelSize: 12; font.weight: Font.Medium; font.family: Style.fontFamily; color: bar.colors.tertiary }
        Text { visible: cpuRoot.overrideLabel === ""; text: Math.round(bar.cpuUsage) + "%"; font.pixelSize: 12; font.weight: Font.Medium; font.family: Style.fontFamily; color: bar.colors.tertiary }
        Text { visible: cpuRoot.overrideLabel === ""; text: Math.round(bar.cpuTemp) + "°";  font.pixelSize: 12; font.weight: Font.Medium; font.family: Style.fontFamily; color: bar.colors.tertiary }
      }
      MouseArea {
        anchors.fill: parent
        enabled: bar.activeDropdown !== ""
        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: bar.activeDropdown = ""
      }
    }
  }

  Component {
    id: _gpuComp
    Item {
      id: gpuRoot
      implicitWidth: gpuRow.implicitWidth
      implicitHeight: gpuRow.implicitHeight
      property string overrideLabel: Config.barWidgetLabel("gpu", "")
      Row {
        id: gpuRow
        anchors.verticalCenter: parent.verticalCenter
        spacing: 4
        Text { text: Config.barWidgetIcon("gpu", "󰢮"); font.pixelSize: 14; font.family: Style.fontFamilyNerdIcons; color: bar.colors.primary }
        Text { visible: gpuRoot.overrideLabel !== ""; text: gpuRoot.overrideLabel; font.pixelSize: 12; font.weight: Font.Medium; font.family: Style.fontFamily; color: bar.colors.tertiary }
        Text { visible: gpuRoot.overrideLabel === ""; text: Math.round(bar.gpuUsage) + "%"; font.pixelSize: 12; font.weight: Font.Medium; font.family: Style.fontFamily; color: bar.colors.tertiary }
        Text { visible: gpuRoot.overrideLabel === ""; text: Math.round(bar.gpuTemp) + "°";  font.pixelSize: 12; font.weight: Font.Medium; font.family: Style.fontFamily; color: bar.colors.tertiary }
      }
      MouseArea {
        anchors.fill: parent
        enabled: bar.activeDropdown !== ""
        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: bar.activeDropdown = ""
      }
    }
  }

  Component {
    id: _memoryComp
    Item {
      id: memRoot
      implicitWidth: memRow.implicitWidth
      implicitHeight: memRow.implicitHeight
      property string overrideLabel: Config.barWidgetLabel("memory", "")
      Row {
        id: memRow
        anchors.verticalCenter: parent.verticalCenter
        spacing: 4
        Text { text: Config.barWidgetIcon("memory", "󰍛"); font.pixelSize: 14; font.family: Style.fontFamilyNerdIcons; color: bar.colors.primary }
        Text { visible: memRoot.overrideLabel !== ""; text: memRoot.overrideLabel; font.pixelSize: 12; font.weight: Font.Medium; font.family: Style.fontFamily; color: bar.colors.tertiary }
        Text { visible: memRoot.overrideLabel === ""; text: Math.round(bar.memUsage) + "%"; font.pixelSize: 12; font.weight: Font.Medium; font.family: Style.fontFamily; color: bar.colors.tertiary }
      }
      MouseArea {
        anchors.fill: parent
        enabled: bar.activeDropdown !== ""
        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: bar.activeDropdown = ""
      }
    }
  }

  Component {
    id: _qsmemComp
    Item {
      id: qsmemRoot
      implicitWidth: qsmemRow.implicitWidth
      implicitHeight: qsmemRow.implicitHeight
      property string overrideLabel: Config.barWidgetLabel("qsmem", "")
      Row {
        id: qsmemRow
        anchors.verticalCenter: parent.verticalCenter
        spacing: 4
        Text { text: Config.barWidgetIcon("qsmem", "󰫳"); font.pixelSize: 14; font.family: Style.fontFamilyNerdIcons; color: bar.colors.primary }
        Text {
          visible: qsmemRoot.overrideLabel !== ""
          text: qsmemRoot.overrideLabel
          font.pixelSize: 12; font.weight: Font.Medium
          font.family: Style.fontFamily; color: bar.colors.tertiary
        }
        Text {
          visible: qsmemRoot.overrideLabel === ""
          text: qsmemInfo.totalMb >= 1024
            ? (qsmemInfo.totalMb / 1024).toFixed(1) + " GB"
            : Math.round(qsmemInfo.totalMb) + " MB"
          font.pixelSize: 12; font.weight: Font.Medium
          font.family: Style.fontFamily; color: bar.colors.tertiary
        }
      }
      MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: bar._openDropdown("qsmem", parent)
      }
    }
  }

  Component {
    id: _weatherComp
    Item {
      implicitWidth: weatherRow.implicitWidth
      implicitHeight: weatherRow.implicitHeight
      visible: Config.weatherEnabled && bar.weatherTemp !== "" && bar.weatherTemp !== undefined

      Row {
        id: weatherRow
        spacing: 4
        Text {
          text: {
            let desc = bar.weatherDesc.toLowerCase()
            if (desc.includes("thunder")) return "󰙾"
            if (desc.includes("blizzard") || desc.includes("blowing snow") || desc.includes("heavy snow")) return "󰼶"
            if (desc.includes("snow")) return "󰖘"
            if (desc.includes("freezing") || desc.includes("ice pellet") || desc.includes("sleet")) return "󰙿"
            if (desc.includes("torrential") || desc.includes("heavy rain") || desc.includes("violent") || desc.includes("heavy shower")) return "󰖖"
            if (desc.includes("rain") || desc.includes("drizzle") || desc.includes("shower")) return "󰖗"
            if (desc.includes("fog") || desc.includes("mist")) return "󰖑"
            if (desc.includes("partly")) return "󰖕"
            if (desc.includes("overcast") || desc.includes("cloudy")) return "󰖐"
            if (desc.includes("sunny") || desc.includes("clear")) return "󰖙"
            return "󰖐"
          }
          font.pixelSize: 14
          font.family: Style.fontFamilyNerdIcons
          color: bar.colors.primary
        }
        Text {
          text: bar.weatherTemp
          font.pixelSize: 12; font.weight: Font.Medium
          font.family: Style.fontFamily
          color: bar.colors.tertiary
        }
      }

      MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: bar._openDropdown("weather", parent)
      }
    }
  }

  Component {
    id: _bluetoothComp
    Item {
      id: bluetoothRoot
      implicitWidth: bluetoothRow.implicitWidth
      implicitHeight: bluetoothRow.implicitHeight
      visible: Config.bluetoothEnabled && (bluetoothInfo.batteryText !== "" || Config.barWidgetLabel("bluetooth", "") !== "")

      property string overrideLabel: Config.barWidgetLabel("bluetooth", "")

      Row {
        id: bluetoothRow
        spacing: 4
        Text { text: Config.barWidgetIcon("bluetooth", "󰂯"); font.pixelSize: 14; font.family: Style.fontFamilyNerdIcons; color: bar.colors.primary }
        Text {
          text: bluetoothRoot.overrideLabel !== "" ? bluetoothRoot.overrideLabel : bluetoothInfo.batteryText
          font.pixelSize: 12; font.weight: Font.Medium; font.family: Style.fontFamily; color: bar.colors.tertiary
        }
      }

      MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: bar._openDropdown("bluetooth", parent)
      }
    }
  }

  Component {
    id: _wifiComp
    Item {
      id: wifiRoot
      implicitWidth: wifiRow.implicitWidth
      implicitHeight: wifiRow.implicitHeight
      visible: Config.wifiEnabled && (wifiInfo.ssid !== "" || Config.barWidgetLabel("wifi", "") !== "")

      property string overrideIcon:  Config.barWidgetIcon("wifi", "")
      property string overrideLabel: Config.barWidgetLabel("wifi", "")

      Row {
        id: wifiRow
        spacing: 4
        Text {
          text: wifiRoot.overrideIcon !== "" ? wifiRoot.overrideIcon : (function() {
            let s = wifiInfo.signalStrength
            if (s < 25) return "󰤟"
            if (s < 50) return "󰤢"
            if (s < 75) return "󰤥"
            return "󰤨"
          })()
          font.pixelSize: 14
          font.family: Style.fontFamilyNerdIcons
          color: bar.colors.primary
        }
        Text {
          text: wifiRoot.overrideLabel !== "" ? wifiRoot.overrideLabel : wifiInfo.ssid
          font.pixelSize: 12; font.weight: Font.Medium
          font.family: Style.fontFamily
          color: bar.colors.tertiary
        }
      }

      MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: bar._openDropdown("wifi", parent)
      }
    }
  }

  Component {
    id: _volumeComp
    Item {
      id: volumeRoot
      visible: Config.volumeEnabled
      implicitWidth: volumeRow.implicitWidth
      implicitHeight: volumeRow.implicitHeight

      property string overrideIcon:  Config.barWidgetIcon("volume", "")
      property string overrideLabel: Config.barWidgetLabel("volume", "")

      Row {
        id: volumeRow
        spacing: 4
        Text {
          text: volumeRoot.overrideIcon !== "" ? volumeRoot.overrideIcon : (function() {
            let vol = Pipewire.defaultAudioSink?.audio?.volume ?? 0
            if (vol === 0) return "󰖁"
            if (vol < 0.33) return "󰕿"
            if (vol < 0.66) return "󰖀"
            return "󰕾"
          })()
          font.pixelSize: 14
          font.family: Style.fontFamilyNerdIcons
          color: bar.colors.primary
          width: 16
          horizontalAlignment: Text.AlignHCenter
        }
        Text {
          text: volumeRoot.overrideLabel !== "" ? volumeRoot.overrideLabel : Math.round((Pipewire.defaultAudioSink?.audio?.volume ?? 0) * 100) + "%"
          font.pixelSize: 12; font.weight: Font.Medium
          font.family: Style.fontFamily
          color: bar.colors.tertiary
          width: Math.max(implicitWidth, 28)
        }
      }

      MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: bar._openDropdown("volume", parent)
      }
    }
  }

  Component {
    id: _clockComp
    Item {
      id: clockRoot
      visible: Config.calendarEnabled
      implicitWidth: clockRow.implicitWidth
      implicitHeight: clockRow.implicitHeight

      property string overrideIcon:  Config.barWidgetIcon("clock", "")
      property string overrideLabel: Config.barWidgetLabel("clock", "")

      Row {
        id: clockRow
        spacing: 4
        Text {
          visible: clockRoot.overrideIcon !== ""
          text: clockRoot.overrideIcon
          font.pixelSize: 14
          font.family: Style.fontFamilyNerdIcons
          color: bar.colors.primary
          anchors.verticalCenter: parent.verticalCenter
        }
        Row {
          spacing: 0
          anchors.verticalCenter: parent.verticalCenter
          visible: clockRoot.overrideLabel === ""
          Text { text: Qt.formatTime(bar.clock.date, "HH"); font.pixelSize: 13; font.weight: Font.DemiBold; font.family: Style.fontFamily; color: bar.colors.primary }
          Text { text: ":";                                  font.pixelSize: 13; font.weight: Font.DemiBold; font.family: Style.fontFamily; color: bar.colors.tertiary }
          Text { text: Qt.formatTime(bar.clock.date, "mm"); font.pixelSize: 13; font.weight: Font.DemiBold; font.family: Style.fontFamily; color: bar.colors.tertiary }
        }
        Text {
          visible: clockRoot.overrideLabel !== ""
          text: clockRoot.overrideLabel
          font.pixelSize: 13; font.weight: Font.DemiBold; font.family: Style.fontFamily; color: bar.colors.primary
          anchors.verticalCenter: parent.verticalCenter
        }
      }

      MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: bar._openDropdown("clock", parent)
      }
    }
  }

  Component {
    id: _brightnessComp
    Item {
      id: brightnessRoot
      visible: Config.brightnessEnabled && brightnessInfo.percent >= 0
      implicitWidth: brightnessRow.implicitWidth
      implicitHeight: brightnessRow.implicitHeight

      property string overrideIcon:  Config.barWidgetIcon("brightness", "")
      property string overrideLabel: Config.barWidgetLabel("brightness", "")

      Row {
        id: brightnessRow
        spacing: 4
        Text {
          text: brightnessRoot.overrideIcon !== "" ? brightnessRoot.overrideIcon : (function() {
            var p = brightnessInfo.percent
            if (p < 25) return "󰃞"
            if (p < 50) return "󰃟"
            if (p < 75) return "󰃝"
            return "󰃠"
          })()
          font.pixelSize: 14
          font.family: Style.fontFamilyNerdIcons
          color: bar.colors.primary
        }
        Text {
          text: brightnessRoot.overrideLabel !== "" ? brightnessRoot.overrideLabel : (brightnessInfo.percent + "%")
          font.pixelSize: 12; font.weight: Font.Medium
          font.family: Style.fontFamily
          color: bar.colors.tertiary
        }
      }

      MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onWheel: function(wheel) {
          var step = wheel.angleDelta.y > 0 ? "+5%" : "5%-"
          brightnessAdjust.command = ["brightnessctl", "set", step]
          brightnessAdjust.running = true
        }
        onClicked: bar._openDropdown("brightness", parent)
      }
    }
  }

  Component {
    id: _batteryComp
    Item {
      id: batteryRoot
      visible: Config.batteryEnabled && batteryInfo.present
      implicitWidth: batteryRow.implicitWidth
      implicitHeight: batteryRow.implicitHeight

      property string overrideIcon:  Config.barWidgetIcon("battery", "")
      property string overrideLabel: Config.barWidgetLabel("battery", "")

      Row {
        id: batteryRow
        spacing: 4
        Text {
          text: batteryRoot.overrideIcon !== "" ? batteryRoot.overrideIcon : batteryInfo.icon
          font.pixelSize: 14
          font.family: Style.fontFamilyNerdIcons
          color: batteryInfo.charging
            ? Qt.rgba(0.4, 0.95, 0.6, 1)
            : (batteryInfo.percentage < 15 ? Qt.rgba(0.95, 0.5, 0.4, 1) : bar.colors.primary)
        }
        Text {
          text: batteryRoot.overrideLabel !== "" ? batteryRoot.overrideLabel : (Math.round(batteryInfo.percentage) + "%")
          font.pixelSize: 12; font.weight: Font.Medium
          font.family: Style.fontFamily
          color: bar.colors.tertiary
        }
      }

      MouseArea {
        anchors.fill: parent
        enabled: bar.activeDropdown !== ""
        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: bar.activeDropdown = ""
      }
    }
  }

  Process { id: brightnessAdjust; command: ["true"] }

  ListModel { id: notificationsHistory }

  property var _notificationsDismissedTs: ({})
  property real _notificationsClearedAt: 0

  FileView {
    id: notificationsHistoryFile
    path: (Quickshell.env("XDG_RUNTIME_DIR") || "/tmp") + "/skwd/notifications.json"
    preload: true
    watchChanges: true
    onLoaded: bar._reloadNotificationsHistory()
    onFileChanged: { reload(); bar._reloadNotificationsHistory() }
  }

  FileView {
    id: notificationsDismissedFile
    path: (Quickshell.env("XDG_RUNTIME_DIR") || "/tmp") + "/skwd/notifications-dismissed.json"
    preload: true
    watchChanges: true
    onLoaded: bar._reloadNotificationsDismissed()
    onFileChanged: { reload(); bar._reloadNotificationsDismissed() }
  }

  function _reloadNotificationsDismissed() {
    var raw = notificationsDismissedFile.text() || ""
    if (raw) {
      try {
        var obj = JSON.parse(raw) || {}
        bar._notificationsClearedAt = obj.clearedAt || 0
        var map = {}
        var arr = Array.isArray(obj.dismissed) ? obj.dismissed : []
        for (var i = 0; i < arr.length; i++) map[arr[i]] = true
        bar._notificationsDismissedTs = map
      } catch (e) {
        bar._notificationsClearedAt = 0
        bar._notificationsDismissedTs = {}
      }
    }
    bar._reloadNotificationsHistory()
  }

  function _writeNotificationsDismissed() {
    var dismissed = Object.keys(bar._notificationsDismissedTs)
      .map(function(k) { return Number(k) })
      .filter(function(n) { return n > bar._notificationsClearedAt })
    notificationsDismissedFile.setText(JSON.stringify({
      clearedAt: bar._notificationsClearedAt,
      dismissed: dismissed
    }))
  }

  function _reloadNotificationsHistory() {
    var raw = notificationsHistoryFile.text() || ""
    var arr = []
    if (raw) { try { arr = JSON.parse(raw) || [] } catch (e) { arr = [] } }
    notificationsHistory.clear()
    var max = Math.max(1, Config.notificationsHistoryMax)
    var count = 0
    for (var i = 0; i < arr.length && count < max; i++) {
      var entry = arr[i] || {}
      var ts = entry.ts || 0
      if (ts <= bar._notificationsClearedAt) continue
      if (bar._notificationsDismissedTs[ts]) continue
      notificationsHistory.append({
        ts:       ts,
        appName:  entry.appName  || "",
        summary:  entry.summary  || "",
        body:     entry.body     || "",
        timeText: entry.timeText || ""
      })
      count++
    }
  }

  function _dismissNotification(index) {
    if (index < 0 || index >= notificationsHistory.count) return
    var ts = notificationsHistory.get(index).ts
    if (ts) {
      bar._notificationsDismissedTs[ts] = true
      bar._writeNotificationsDismissed()
    }
    notificationsHistory.remove(index)
  }

  function _clearAllNotifications() {
    bar._notificationsClearedAt = Date.now()
    bar._notificationsDismissedTs = {}
    bar._writeNotificationsDismissed()
    notificationsHistory.clear()
  }

  Component {
    id: _notificationsComp
    Item {
      id: notificationsRoot
      visible: Config.notificationsEnabled
      implicitWidth: notificationsRow.implicitWidth
      implicitHeight: notificationsRow.implicitHeight

      property string overrideIcon:  Config.barWidgetIcon("notifications", "")
      property string overrideLabel: Config.barWidgetLabel("notifications", "")

      Row {
        id: notificationsRow
        spacing: 4
        Text {
          text: notificationsRoot.overrideIcon !== "" ? notificationsRoot.overrideIcon : "󰂚"
          font.pixelSize: 14
          font.family: Style.fontFamilyNerdIcons
          color: bar.colors.primary
        }
        Text {
          text: notificationsRoot.overrideLabel !== "" ? notificationsRoot.overrideLabel : notificationsHistory.count.toString()
          font.pixelSize: 12; font.weight: Font.Medium
          font.family: Style.fontFamily
          color: bar.colors.tertiary
        }
      }

      MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: bar._openDropdown("notifications", parent)
      }
    }
  }

  QtObject {
    id: wifiInfo
    property string ssid: ""
    property int signalStrength: 0
  }

  Process {
    id: wifiStatusProcess
    property string pendingSsid: ""
    command: ["sh", "-c", "iwctl station " + Config.wifiInterface + " show 2>/dev/null | awk '/Connected network/{print $3} /^[[:space:]]*RSSI/{gsub(/-| dBm/,\"\"); print $2}'"]
    running: Config.wifiEnabled && Config.wifiInterface !== ""
    onExited: {
      wifiInfo.ssid = pendingSsid !== "" ? pendingSsid : ""
      pendingSsid = ""
      wifiPollTimer.start()
    }
    stdout: SplitParser {
      onRead: data => {
        let trimmed = data.trim()
        if (trimmed && !trimmed.match(/^-?[0-9]+$/)) {
          wifiStatusProcess.pendingSsid = trimmed
        } else if (trimmed.match(/^-?[0-9]+$/)) {
          let rssi = -parseInt(trimmed)
          wifiInfo.signalStrength = Math.max(0, Math.min(100, (rssi + 90) * 100 / 60))
        }
      }
    }
  }

  Timer {
    id: wifiPollTimer
    interval: Config.wifiPollMs
    onTriggered: wifiStatusProcess.running = true
  }

  QtObject {
    id: brightnessInfo
    property int realPercent: -1
    property int mockPercent: 70
    readonly property int percent: Config.devMode ? mockPercent : realPercent
  }

  Process {
    id: brightnessProcess
    command: ["sh", "-c", "brightnessctl -m 2>/dev/null"]
    running: Config.brightnessEnabled && !Config.devMode
    stdout: SplitParser {
      onRead: data => {
        var fields = data.trim().split(",")
        if (fields.length >= 4) {
          var pct = fields[3].replace("%", "").trim()
          var n = parseInt(pct)
          if (!isNaN(n)) brightnessInfo.realPercent = n
        }
      }
    }
    onExited: brightnessPollTimer.start()
  }

  Timer {
    id: brightnessPollTimer
    interval: 5000
    onTriggered: if (Config.brightnessEnabled && !Config.devMode) brightnessProcess.running = true
  }

  QtObject {
    id: batteryInfo
    readonly property var device: UPower.displayDevice
    readonly property bool realPresent: device && device.isPresent
    readonly property real realPercentage: device ? device.percentage * 100 : 0
    readonly property int realState: device ? device.state : 0

    property real mockPercentage: 72
    property int mockState: UPowerDeviceState.Discharging

    readonly property bool present: Config.devMode ? true : realPresent
    readonly property real percentage: Config.devMode ? mockPercentage : realPercentage
    readonly property int state: Config.devMode ? mockState : realState
    readonly property bool charging: state === UPowerDeviceState.Charging || state === UPowerDeviceState.FullyCharged
    readonly property string icon: {
      if (!present) return ""
      var p = percentage
      var icons = ["󰂎", "󰁻", "󰁽", "󰁿", "󰂁", "󰂂", "󰁹"]
      var chargingIcons = ["󰢜", "󰂆", "󰂇", "󰂈", "󰢝", "󰂉", "󰂋", "󰂅"]
      var idx = Math.min(icons.length - 1, Math.floor(p / (100.0 / icons.length)))
      return charging ? chargingIcons[Math.min(chargingIcons.length - 1, Math.floor(p / (100.0 / chargingIcons.length)))] : icons[idx]
    }
  }

  Timer {
    id: devMockTimer
    interval: 2000
    repeat: true
    running: Config.devMode
    onTriggered: {
      var delta = batteryInfo.charging ? 1 : -1
      batteryInfo.mockPercentage = Math.max(1, Math.min(100, batteryInfo.mockPercentage + delta))
      if (batteryInfo.mockPercentage <= 5) batteryInfo.mockState = UPowerDeviceState.Charging
      else if (batteryInfo.mockPercentage >= 100) batteryInfo.mockState = UPowerDeviceState.Discharging
      brightnessInfo.mockPercent = Math.max(0, Math.min(100, brightnessInfo.mockPercent + (Math.random() > 0.5 ? 2 : -2)))
    }
  }

  Item {
    id: barRoot
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.top: parent.top
    anchors.topMargin: bar.slideOffset + bar.topMargin
    anchors.leftMargin: bar._pillSideMargin
    anchors.rightMargin: bar._pillSideMargin
    height: bar.barHeight

    Rectangle {
      id: pillShadow
      visible: bar._pill
      anchors.fill: pillBg
      anchors.topMargin: 4
      anchors.leftMargin: -2
      anchors.rightMargin: -2
      radius: height / 2
      color: Qt.rgba(0, 0, 0, 0.18)
      z: -3
    }

    Rectangle {
      id: pillBg
      visible: bar._pill
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.top: parent.top
      height: bar.barHeight
      radius: height / 2
      color: Qt.rgba(bar.colors.surface.r, bar.colors.surface.g, bar.colors.surface.b, 0.88)
      z: -2
    }

    Row {
      id: leftMeasureRow
      anchors.left: parent.left
      anchors.top: parent.top
      anchors.leftMargin: 12
      anchors.topMargin: bar._pill ? 0 : bar.leftDropdownHeight
      height: bar.barHeight
      spacing: 8
      opacity: 0
      enabled: false
      z: -10

      Repeater {
        model: Config.barLeftLayout
        delegate: Loader {
          required property string modelData
          sourceComponent: bar._widgetComponent(modelData)
          visible: bar._widgetHasData(modelData)
          anchors.verticalCenter: parent ? parent.verticalCenter : undefined
        }
      }
    }

    Row {
      id: rightMeasureRow
      anchors.right: parent.right
      anchors.top: parent.top
      anchors.rightMargin: 12
      anchors.topMargin: bar._pill ? 0 : bar.rightDropdownHeight
      height: bar.barHeight
      spacing: 14
      opacity: 0
      enabled: false
      z: -10

      Repeater {
        model: Config.barRightLayout
        delegate: Loader {
          required property string modelData
          sourceComponent: bar._widgetComponent(modelData)
          visible: bar._widgetHasData(modelData)
          anchors.verticalCenter: parent ? parent.verticalCenter : undefined
        }
      }
    }

    Item {
      id: leftHoverZone
      anchors.left: parent.left
      anchors.top: parent.top
      anchors.topMargin: bar._pill ? 0 : bar.leftDropdownHeight
      height: bar.barHeight
      width: Math.max(leftPanel.width, leftMeasureRow.implicitWidth + bar.diagSlant + 24)
      z: 6
      HoverHandler {
        acceptedDevices: PointerDevice.AllDevices
        onHoveredChanged: bar._leftHovered = hovered
      }
    }

    Item {
      id: rightHoverZone
      anchors.right: parent.right
      anchors.top: parent.top
      anchors.topMargin: bar._pill ? 0 : bar.rightDropdownHeight
      height: bar.barHeight
      width: Math.max(rightPanel.width, rightMeasureRow.implicitWidth + bar.diagSlant + 24)
      z: 6
      HoverHandler {
        acceptedDevices: PointerDevice.AllDevices
        onHoveredChanged: bar._rightHovered = hovered
      }
    }


    Item {
      id: leftPanel
      visible: leftContent.implicitWidth > 0
      anchors.left: parent.left
      anchors.top: parent.top
      anchors.topMargin: bar._pill ? 0 : bar.leftDropdownHeight
      height: bar.barHeight
      width: leftContent.implicitWidth + bar.diagSlant + 24

      Canvas {
        id: leftBg
        visible: !bar._pill
        anchors.fill: parent
        onPaint: {
          var ctx = getContext("2d")
          ctx.clearRect(0, 0, width, height)
          ctx.beginPath()
          ctx.moveTo(0, 0)
          ctx.lineTo(width, 0)
          ctx.lineTo(width - bar.diagSlant, height)
          ctx.lineTo(0, height)
          ctx.closePath()
          ctx.fillStyle = Qt.rgba(bar.colors.surface.r, bar.colors.surface.g, bar.colors.surface.b, 0.88)
          ctx.fill()
        }
        Connections {
          target: bar.colors
          function onSurfaceChanged() { leftBg.requestPaint() }
          function onPrimaryChanged() { leftBg.requestPaint() }
        }
      }


      Row {
        id: leftContent
        anchors.left: parent.left
        anchors.leftMargin: bar._pill ? bar.barHeight / 2 + 4 : 12
        anchors.verticalCenter: parent.verticalCenter
        spacing: 8

        Repeater {
          model: Config.barLeftLayout
          delegate: Loader {
            id: leftLoader
            required property string modelData
            sourceComponent: bar._widgetComponent(modelData)
            readonly property bool _shown: bar._widgetShouldShow(modelData)
            width: _shown ? implicitWidth : 0
            opacity: _shown ? 1 : 0
            visible: _shown || width > 0.5
            clip: true
            Behavior on width   { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
            Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
            anchors.verticalCenter: parent ? parent.verticalCenter : undefined
          }
        }
      }
    }


    LyricsIsland {
      id: lyricsIsland
      visible: Config.musicEnabled && (!Config.musicAutohide || (bar.activePlayer && bar.activePlayer.isPlaying) || Config.musicAlwaysHoverable)
      anchors.horizontalCenter: parent.horizontalCenter
      anchors.top: parent.top
      anchors.bottom: parent.bottom
      colors: bar.colors
      activePlayer: bar.activePlayer
      diagSlant: bar.diagSlant
      barHeight: bar.barHeight
      waveformHeight: bar.waveformHeight
    }

    Item {
      id: rightPanel
      z: 1
      anchors.right: parent.right
      anchors.top: parent.top
      anchors.topMargin: bar._pill ? 0 : bar.rightDropdownHeight
      height: bar.barHeight
      width: rightContent.implicitWidth + bar.diagSlant + 24

      Canvas {
        id: rightBg
        visible: !bar._pill
        anchors.fill: parent
        onPaint: {
          var ctx = getContext("2d")
          ctx.clearRect(0, 0, width, height)
          ctx.beginPath()
          ctx.moveTo(0, 0)
          ctx.lineTo(width, 0)
          ctx.lineTo(width, height)
          ctx.lineTo(bar.diagSlant, height)
          ctx.closePath()
          ctx.fillStyle = Qt.rgba(bar.colors.surface.r, bar.colors.surface.g, bar.colors.surface.b, 0.88)
          ctx.fill()
        }
        Connections {
          target: bar.colors
          function onSurfaceChanged() { rightBg.requestPaint() }
          function onPrimaryChanged() { rightBg.requestPaint() }
        }
      }


      Row {
        id: rightContent
        anchors.right: parent.right
        anchors.rightMargin: bar._pill ? bar.barHeight / 2 + 4 : 12
        anchors.verticalCenter: parent.verticalCenter
        spacing: 14

        Repeater {
          model: Config.barRightLayout
          delegate: Loader {
            id: rightLoader
            required property string modelData
            sourceComponent: bar._widgetComponent(modelData)
            readonly property bool _shown: bar._widgetShouldShow(modelData)
            width: _shown ? implicitWidth : 0
            opacity: _shown ? 1 : 0
            visible: _shown || width > 0.5
            clip: true
            Behavior on width   { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
            Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
            anchors.verticalCenter: parent ? parent.verticalCenter : undefined
          }
        }
      }
    }
  }

  WiFiDropdown {
    id: wifiDropdown
    readonly property string sideOf: bar._widgetSide("wifi")
    side: sideOf
    x: Math.max(bar._pillSideMargin + bar.barHeight / 2, Math.min(bar.width - bar._pillSideMargin - bar.barHeight / 2 - width, bar.dropdownCenterX - width / 2))
    anchors.top: parent.top
    width: contentWidth
    anchors.topMargin: bar._dropTopMargin(0)
    contentWidth: bar.dropdownContentWidth
    colors: bar.colors
    active: Config.wifiEnabled && bar.activeDropdown === "wifi"
    wifiSsid: wifiInfo.ssid
    wifiSignalStrength: wifiInfo.signalStrength
  }

  VolumeDropdown {
    id: volumeDropdown
    readonly property string sideOf: bar._widgetSide("volume")
    side: sideOf
    x: Math.max(bar._pillSideMargin + bar.barHeight / 2, Math.min(bar.width - bar._pillSideMargin - bar.barHeight / 2 - width, bar.dropdownCenterX - width / 2))
    anchors.top: parent.top
    width: contentWidth
    anchors.topMargin: bar._dropTopMargin(bar._wifiH)
    contentWidth: bar.dropdownContentWidth
    colors: bar.colors
    active: Config.volumeEnabled && bar.activeDropdown === "volume"
  }

  CalendarDropdown {
    id: calendarDropdown
    readonly property string sideOf: bar._widgetSide("clock")
    side: sideOf
    x: Math.max(bar._pillSideMargin + bar.barHeight / 2, Math.min(bar.width - bar._pillSideMargin - bar.barHeight / 2 - width, bar.dropdownCenterX - width / 2))
    anchors.top: parent.top
    width: contentWidth
    anchors.topMargin: bar._dropTopMargin(bar._wifiH + bar._volumeH)
    contentWidth: bar.dropdownContentWidth
    colors: bar.colors
    active: Config.calendarEnabled && bar.activeDropdown === "clock"
    clock: bar.clock
  }

  BluetoothDropdown {
    id: bluetoothDropdown
    readonly property string sideOf: bar._widgetSide("bluetooth")
    side: sideOf
    x: Math.max(bar._pillSideMargin + bar.barHeight / 2, Math.min(bar.width - bar._pillSideMargin - bar.barHeight / 2 - width, bar.dropdownCenterX - width / 2))
    anchors.top: parent.top
    width: contentWidth
    anchors.topMargin: bar._dropTopMargin(bar._wifiH + bar._volumeH + bar._calendarH)
    contentWidth: bar.dropdownContentWidth
    colors: bar.colors
    active: Config.bluetoothEnabled && bar.activeDropdown === "bluetooth"
    connectedDevices: bluetoothInfo.connectedDevices
  }

  WeatherDropdown {
    id: weatherDropdown
    readonly property string sideOf: bar._widgetSide("weather")
    side: sideOf
    x: Math.max(bar._pillSideMargin + bar.barHeight / 2, Math.min(bar.width - bar._pillSideMargin - bar.barHeight / 2 - width, bar.dropdownCenterX - width / 2))
    anchors.top: parent.top
    width: contentWidth
    anchors.topMargin: bar._dropTopMargin(bar._wifiH + bar._volumeH + bar._calendarH + bar._bluetoothH)
    contentWidth: bar.dropdownContentWidth
    colors: bar.colors
    active: Config.weatherEnabled && bar.activeDropdown === "weather"
    weatherCity: bar.weatherCity
    weatherForecast: bar.weatherForecast
  }

  BrightnessDropdown {
    id: brightnessDropdown
    readonly property string sideOf: bar._widgetSide("brightness")
    side: sideOf
    x: Math.max(bar._pillSideMargin + bar.barHeight / 2, Math.min(bar.width - bar._pillSideMargin - bar.barHeight / 2 - width, bar.dropdownCenterX - width / 2))
    anchors.top: parent.top
    width: contentWidth
    anchors.topMargin: bar._dropTopMargin(bar._wifiH + bar._volumeH + bar._calendarH + bar._bluetoothH + bar._weatherH)
    contentWidth: bar.dropdownContentWidth
    colors: bar.colors
    active: Config.brightnessEnabled && bar.activeDropdown === "brightness"
    currentPercent: brightnessInfo.percent < 0 ? 0 : brightnessInfo.percent
    onRequestSet: function(p) {
      if (Config.devMode) {
        brightnessInfo.mockPercent = p
      } else {
        brightnessAdjust.command = ["brightnessctl", "set", p + "%"]
        brightnessAdjust.running = true
      }
    }
  }

  NotificationCenterDropdown {
    id: notificationsDropdown
    readonly property string sideOf: bar._widgetSide("notifications")
    side: sideOf
    x: Math.max(bar._pillSideMargin + bar.barHeight / 2, Math.min(bar.width - bar._pillSideMargin - bar.barHeight / 2 - width, bar.dropdownCenterX - width / 2))
    anchors.top: parent.top
    width: contentWidth
    anchors.topMargin: bar._dropTopMargin(bar._wifiH + bar._volumeH + bar._calendarH + bar._bluetoothH + bar._weatherH + bar._brightnessH)
    contentWidth: bar.dropdownContentWidth
    colors: bar.colors
    active: Config.notificationsEnabled && bar.activeDropdown === "notifications"
    historyModel: notificationsHistory
    onDismissRequested: function(idx) { bar._dismissNotification(idx) }
    onClearAllRequested: bar._clearAllNotifications()
  }

  QsMemDropdown {
    id: qsmemDropdown
    readonly property string sideOf: bar._widgetSide("qsmem")
    side: sideOf
    x: Math.max(bar._pillSideMargin + bar.barHeight / 2, Math.min(bar.width - bar._pillSideMargin - bar.barHeight / 2 - width, bar.dropdownCenterX - width / 2))
    anchors.top: parent.top
    width: contentWidth
    anchors.topMargin: bar._dropTopMargin(bar._wifiH + bar._volumeH + bar._calendarH + bar._bluetoothH + bar._weatherH + bar._brightnessH + bar._notifsH)
    contentWidth: bar.dropdownContentWidth
    colors: bar.colors
    active: bar.activeDropdown === "qsmem"
    processes: qsmemInfo.processes
    totalMb: qsmemInfo.totalMb
    totalRssMb: qsmemInfo.totalRssMb
  }
}
