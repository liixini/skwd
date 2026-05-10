import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Pipewire
import Quickshell.Services.Mpris
import Quickshell.Bluetooth
import Quickshell.Io
import QtQuick
import "qml"
import "qml/bar"
import "qml/services"

ShellRoot {
  id: root

  Component.onCompleted: {
    var text = barStateFile.text().trim()
    if (text) {
      root.barVisible = (text === "true")
      root.stateLoaded = true
    }

    IpcService.start()
    IpcService.toggleBarRequested.connect(function() {
      root.barVisible = !root.barVisible
    })
  }

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

  FileView {
    id: barStateFile
    path: Config.cacheDir + "/bar-state"
    preload: true
    onFileChanged: {
      if (!root.stateLoaded) {
        var text = barStateFile.text().trim()
        if (text) root.barVisible = (text === "true")
        root.stateLoaded = true
      }
    }
  }

  onBarVisibleChanged: {
    if (root.stateLoaded) {
      barStateFile.setText(root.barVisible ? "true" : "false")
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
    barVisible: root.barVisible
    activePlayer: root.activePlayer
    cpuUsage: root.cpuUsage
    memUsage: root.memUsage
    gpuUsage: root.gpuUsage
    cpuTemp: root.cpuTemp
    gpuTemp: root.gpuTemp
    weatherDesc: root.weatherDesc
    weatherTemp: root.weatherTemp
    weatherCity: root.weatherCity
    weatherForecast: root.weatherForecast
  }
}
