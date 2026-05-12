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
      spacing: 14 * Config.uiScale

      SettingsCard {
        colors: root.colors
        title: "Player"
        RowDropdown {
          colors: root.colors
          title: "Preferred player"
          description: "Which MPRIS player to prioritise when multiple are running. Auto picks whatever is active."
          value: Config.musicPreferredPlayer
          model: [
            { mode: "spotify",   label: "Spotify" },
            { mode: "librespot", label: "Librespot" },
            { mode: "mpd",       label: "MPD" },
            { mode: "auto",      label: "Auto" }
          ]
          onSelect: function(v) { root._save("preferredPlayer", v) }
        }
      }

      SettingsCard {
        colors: root.colors
        title: "Spotify"
        RowTextInput {
          colors: root.colors
          title: "Client ID"
          description: "Required for Spotify Web API features. Get one from developer.spotify.com."
          value: Config.musicSpotifyClientId
          placeholder: "spotify client id"
          onCommit: function(v) { root._save("spotifyClientId", v) }
        }
      }
    }

    Column {
      visible: root.activeCategory === "librespot"
      width: parent.width
      spacing: 14 * Config.uiScale

      SettingsCard {
        colors: root.colors
        title: "Librespot daemon"
        subtitle: "Embedded Spotify Connect daemon."
        RowTextInput {
          colors: root.colors
          title: "Device name"
          description: "Name shown in the Spotify Connect picker."
          value: Config.musicLibrespotDevice
          placeholder: "skwd-music"
          onCommit: function(v) { root._save("librespotDevice", v) }
        }
        RowDropdown {
          colors: root.colors
          title: "Audio backend"
          description: "Output target for librespot."
          value: Config.musicLibrespotBackend
          model: [
            { mode: "pulseaudio", label: "PulseAudio" },
            { mode: "pipewire",   label: "PipeWire" },
            { mode: "alsa",       label: "ALSA" }
          ]
          onSelect: function(v) { root._save("librespotBackend", v) }
        }
        RowDropdown {
          colors: root.colors
          title: "Bitrate"
          description: "Stream quality in kbps."
          value: String(Config.musicLibrespotBitrate)
          model: [
            { mode: "96",  label: "96 kbps" },
            { mode: "160", label: "160 kbps" },
            { mode: "320", label: "320 kbps" }
          ]
          onSelect: function(v) { root._save("librespotBitrate", parseInt(v)) }
        }
      }
    }
  }
}
