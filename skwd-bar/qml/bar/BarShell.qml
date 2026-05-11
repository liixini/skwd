import Quickshell
import Quickshell.Services.Pipewire
import Quickshell.Services.Mpris
import Quickshell.Io
import QtQuick
import ".."
import "../services"

Scope {
  id: barShell

  property bool startIpc: true

  Colors { id: colors }

  property var activePlayer: {
    if (!Mpris.players) return null
    let preferredPlaying = null
    let preferredAny = null
    let fallbackPlaying = null
    let fallbackAny = null
    for (let i = 0; i < Mpris.players.values.length; i++) {
      let player = Mpris.players.values[i]
      if (!player) continue
      let id = (player.identity || "").toLowerCase()
      let preferred = Config.preferredPlayer.toLowerCase()
      if (id.includes(preferred)) {
        if (player.isPlaying) preferredPlaying = player
        else if (!preferredAny) preferredAny = player
      }
      if (player.isPlaying && !fallbackPlaying) fallbackPlaying = player
      if (!fallbackAny) fallbackAny = player
    }
    return preferredPlaying || fallbackPlaying || preferredAny || fallbackAny
  }

  property bool barVisible: true
  property bool stateLoaded: false

  function showBar()   { barShell.barVisible = true }
  function hideBar()   { barShell.barVisible = false }
  function toggleBar() { barShell.barVisible = !barShell.barVisible }

  FileView {
    id: barStateFile
    path: Config.cacheDir + "/bar-state"
    preload: true
    onFileChanged: {
      if (!barShell.stateLoaded) {
        var text = barStateFile.text().trim()
        if (text) barShell.barVisible = (text === "true")
        barShell.stateLoaded = true
      }
    }
  }

  onBarVisibleChanged: {
    if (barShell.stateLoaded) {
      barStateFile.setText(barShell.barVisible ? "true" : "false")
    }
  }

  Component.onCompleted: {
    var text = barStateFile.text().trim()
    if (text) {
      barShell.barVisible = (text === "true")
      barShell.stateLoaded = true
    }

    if (barShell.startIpc) {
      IpcService.start()
      IpcService.toggleBarRequested.connect(function() {
        barShell.barVisible = !barShell.barVisible
      })
    }
  }

  SystemClock {
    id: clock
    precision: SystemClock.Seconds
  }

  PwObjectTracker {
    objects: [Pipewire.defaultAudioSink]
  }

  property real cpuUsage: SystemStatsService.cpuUsage
  property real memUsage: SystemStatsService.memUsage
  property real gpuUsage: SystemStatsService.gpuUsage
  property real cpuTemp: SystemStatsService.cpuTemp
  property real gpuTemp: SystemStatsService.gpuTemp

  property string weatherCity: WeatherService.currentCity
  property string weatherTemp: WeatherService.temp
  property string weatherDesc: WeatherService.description
  property var weatherForecast: WeatherService.forecast

  TopBar {
    id: topBar
    visible: Config.barEnabled
    colors: colors
    clock: clock
    barVisible: barShell.barVisible
    activePlayer: barShell.activePlayer
    cpuUsage: barShell.cpuUsage
    memUsage: barShell.memUsage
    gpuUsage: barShell.gpuUsage
    cpuTemp: barShell.cpuTemp
    gpuTemp: barShell.gpuTemp
    weatherDesc: barShell.weatherDesc
    weatherTemp: barShell.weatherTemp
    weatherCity: barShell.weatherCity
    weatherForecast: barShell.weatherForecast
  }
}
