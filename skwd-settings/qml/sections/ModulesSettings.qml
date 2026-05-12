import QtQuick
import ".."
import "../components"
import "../services"


Item {
  id: root
  property var colors
  property string activeCategory: "modules"

  readonly property var categories: [
    { key: "modules", label: "MODULES" }
  ]

  function _set(key, value) { SettingsService.setWallPath("features." + key, value) }

  implicitHeight: _col.implicitHeight

  Column {
    id: _col
    width: parent.width
    spacing: 14 * Config.uiScale

    SettingsCard {
      colors: root.colors
      title: "Daemon modules"
      subtitle: "Toggle features in skwd-daemon. Disabling a module stops its background work and hides its UI. Restart the daemon for some changes to fully apply."
      RowToggle {
        colors: root.colors
        title: "Lyrics"
        description: "LRClib + Musixmatch fallback for synchronised lyrics in the music widget."
        checked: Config.featLyrics
        onToggle: function(v) { root._set("lyrics", v) }
      }
      RowToggle {
        colors: root.colors
        title: "Wallpaper analysis"
        description: "Required for Skwd-wall. Analyses hue / saturation / richness for sorting."
        checked: Config.featAnalysis
        onToggle: function(v) { root._set("analysis", v) }
      }
      RowToggle {
        colors: root.colors
        title: "Video wallpapers"
        description: "Enable mpv-backed animated wallpapers."
        checked: Config.featVideo
        onToggle: function(v) { root._set("video", v) }
      }
      RowToggle {
        colors: root.colors
        title: "Matugen"
        description: "Generate theme colours from the active wallpaper."
        checked: Config.featMatugen
        onToggle: function(v) { root._set("matugen", v) }
      }
      RowToggle {
        colors: root.colors
        title: "Ollama"
        description: "AI tagging of wallpapers (requires a local Ollama install)."
        checked: Config.featOllama
        onToggle: function(v) { root._set("ollama", v) }
      }
      RowToggle {
        colors: root.colors
        title: "Wallpaper Engine browsing"
        description: "Browse and apply Wallpaper Engine items from Steam."
        checked: Config.featSteam
        onToggle: function(v) { root._set("steam", v) }
      }
      RowToggle {
        colors: root.colors
        title: "Wallhaven integration"
        description: "Search and import wallpapers from wallhaven.cc."
        checked: Config.featWallhaven
        onToggle: function(v) { root._set("wallhaven", v) }
      }
    }

    SettingsCard {
      colors: root.colors
      title: "Experimental"
      subtitle: "WIP modules. Expect breakage."
      RowToggle {
        colors: root.colors
        title: "Music (Spotify Connect via librespot)"
        description: "Embedded librespot daemon for Spotify Connect playback."
        checked: Config.featMusic
        onToggle: function(v) { root._set("music", v) }
      }
    }
  }
}
