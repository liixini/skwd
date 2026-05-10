import QtQuick
import ".."
import "../components"
import "../services"


Item {
  id: root
  property var colors
  property string activeCategory: "player"

  readonly property var categories: [
    { key: "player",    label: "PLAYER" },
    { key: "librespot", label: "LIBRESPOT" }
  ]

  function _save(key, value) { SettingsService.setPath("components.bar.music." + key, value) }

  implicitHeight: _stack.implicitHeight

  Item {
    id: _stack
    width: parent.width
    implicitHeight: childrenRect.height

    
    Column {
      visible: root.activeCategory === "player"
      width: parent.width
      spacing: 8 * Config.uiScale

      Text {
        text: "PREFERRED PLAYER"
        font.family: Style.fontFamily; font.pixelSize: 13 * Config.uiScale; font.weight: Font.Bold; font.letterSpacing: 1.5
        color: root.colors ? root.colors.tertiary : Qt.rgba(1, 1, 1, 0.5)
      }
      Row {
        width: parent.width; spacing: -4
        Repeater {
          model: [
            { id: "spotify",   label: "Spotify" },
            { id: "librespot", label: "Librespot" },
            { id: "mpd",       label: "MPD" },
            { id: "auto",      label: "Auto" }
          ]
          FilterButton {
            colors: root.colors
            label: modelData.label
            skew: 8 * Config.uiScale
            height: 26 * Config.uiScale
            isActive: Config.musicPreferredPlayer === modelData.id
            onClicked: root._save("preferredPlayer", modelData.id)
          }
        }
      }

      Item { width: 1; height: 6 }

      Text {
        text: "SPOTIFY"
        font.family: Style.fontFamily; font.pixelSize: 13 * Config.uiScale; font.weight: Font.Bold; font.letterSpacing: 1.5
        color: root.colors ? root.colors.tertiary : Qt.rgba(1, 1, 1, 0.5)
      }
      SettingsTextInput {
        colors: root.colors
        label: "Spotify client ID"
        value: Config.musicSpotifyClientId
        placeholder: "Required for Spotify Web API features"
        onCommit: function(v) { root._save("spotifyClientId", v) }
      }
    }

    
    Column {
      visible: root.activeCategory === "librespot"
      width: parent.width
      spacing: 8 * Config.uiScale

      Text {
        text: "LIBRESPOT DAEMON"
        font.family: Style.fontFamily; font.pixelSize: 13 * Config.uiScale; font.weight: Font.Bold; font.letterSpacing: 1.5
        color: root.colors ? root.colors.tertiary : Qt.rgba(1, 1, 1, 0.5)
      }
      SettingsTextInput {
        colors: root.colors
        label: "Device name"
        value: Config.musicLibrespotDevice
        placeholder: "Shown in the Spotify Connect picker"
        onCommit: function(v) { root._save("librespotDevice", v) }
      }

      Text {
        text: "AUDIO BACKEND"
        font.family: Style.fontFamily; font.pixelSize: 13 * Config.uiScale; font.weight: Font.Bold; font.letterSpacing: 1.5
        color: root.colors ? root.colors.tertiary : Qt.rgba(1, 1, 1, 0.5)
      }
      Row {
        width: parent.width; spacing: -4
        Repeater {
          model: [
            { id: "pulseaudio", label: "PulseAudio" },
            { id: "pipewire",   label: "PipeWire" },
            { id: "alsa",       label: "ALSA" }
          ]
          FilterButton {
            colors: root.colors
            label: modelData.label
            skew: 8 * Config.uiScale
            height: 26 * Config.uiScale
            isActive: Config.musicLibrespotBackend === modelData.id
            onClicked: root._save("librespotBackend", modelData.id)
          }
        }
      }

      SettingsInput {
        colors: root.colors
        label: "Bitrate"
        value: Config.musicLibrespotBitrate
        min: 96; max: 320
        onCommit: function(v) {
          
          var snapped = v < 128 ? 96 : (v < 240 ? 160 : 320)
          root._save("librespotBitrate", snapped)
        }
      }
    }
  }
}
