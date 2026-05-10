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
    spacing: 12 * Config.uiScale

    Text {
      text: "DAEMON MODULES"
      font.family: Style.fontFamily; font.pixelSize: 13 * Config.uiScale; font.weight: Font.Bold; font.letterSpacing: 1.5
      color: root.colors ? root.colors.tertiary : Qt.rgba(1, 1, 1, 0.5)
    }

    Text {
      width: parent.width
      text: "Toggle features on or off in skwd-daemon. Disabling a module stops its background work, hides its UI, and makes its RPC return errors. Restart the daemon for some changes to fully apply."
      wrapMode: Text.WordWrap
      font.family: Style.fontFamily; font.pixelSize: 11 * Config.uiScale; font.italic: true
      color: root.colors ? Qt.rgba(root.colors.outline.r, root.colors.outline.g, root.colors.outline.b, 0.7) : Qt.rgba(1, 1, 1, 0.4)
    }

    Item { width: 1; height: 4 }

    Rectangle {
      width: parent.width
      height: _wipCol.implicitHeight + 16 * Config.uiScale
      radius: 6
      color: root.colors
        ? Qt.rgba(root.colors.error.r, root.colors.error.g, root.colors.error.b, 0.08)
        : Qt.rgba(1, 0.42, 0.42, 0.08)
      border.width: 1
      border.color: root.colors
        ? Qt.rgba(root.colors.error.r, root.colors.error.g, root.colors.error.b, 0.35)
        : Qt.rgba(1, 0.42, 0.42, 0.35)

      Column {
        id: _wipCol
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 8 * Config.uiScale
        spacing: 6 * Config.uiScale

        Row {
          spacing: 6 * Config.uiScale
          Text {
            text: "\u{F0026}"
            font.family: Style.fontFamilyNerdIcons
            font.pixelSize: 13 * Config.uiScale
            color: root.colors ? root.colors.error : "#ff6b6b"
            anchors.verticalCenter: parent.verticalCenter
          }
          Text {
            text: "WIP - Super unstable, use for curiosity only"
            font.family: Style.fontFamily; font.pixelSize: 11 * Config.uiScale; font.weight: Font.Bold; font.letterSpacing: 0.5
            color: root.colors ? root.colors.error : "#ff6b6b"
            anchors.verticalCenter: parent.verticalCenter
          }
        }

        SettingsToggle {
          colors: root.colors
          label: "Music (Spotify Connect via librespot)"
          checked: Config.featMusic
          onToggle: function(v) { root._set("music", v) }
        }
      }
    }

    SettingsToggle {
      colors: root.colors
      label: "Lyrics (LRClib + Musixmatch fallback)"
      checked: Config.featLyrics
      onToggle: function(v) { root._set("lyrics", v) }
    }

    SettingsToggle {
      colors: root.colors
      label: "Wallpaper analysis (required for Skwd-wall)"
      checked: Config.featAnalysis
      onToggle: function(v) { root._set("analysis", v) }
    }

    SettingsToggle {
      colors: root.colors
      label: "Video wallpapers"
      checked: Config.featVideo
      onToggle: function(v) { root._set("video", v) }
    }

    SettingsToggle {
      colors: root.colors
      label: "Matugen (theme generation from wallpaper)"
      checked: Config.featMatugen
      onToggle: function(v) { root._set("matugen", v) }
    }

    SettingsToggle {
      colors: root.colors
      label: "Ollama (AI tagging)"
      checked: Config.featOllama
      onToggle: function(v) { root._set("ollama", v) }
    }

    SettingsToggle {
      colors: root.colors
      label: "Wallpaper Engine Steam Browsing"
      checked: Config.featSteam
      onToggle: function(v) { root._set("steam", v) }
    }

    SettingsToggle {
      colors: root.colors
      label: "Wallhaven integration"
      checked: Config.featWallhaven
      onToggle: function(v) { root._set("wallhaven", v) }
    }
  }
}
