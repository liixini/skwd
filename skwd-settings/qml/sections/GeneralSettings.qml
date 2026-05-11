import QtQuick
import Quickshell
import ".."
import "../components"
import "../services"


Item {
  id: root
  property var colors
  property string activeCategory: "general"

  readonly property var categories: [
    { key: "general", label: "GENERAL" }
  ]

  property var _screens: Quickshell.screens
  readonly property var _monitorModel: {
    var result = [{ mode: "", label: "Auto (first connected)" }]
    for (var i = 0; i < _screens.length; i++) {
      var s = _screens[i]
      var dim = (s.width && s.height) ? "  " + s.width + "×" + s.height : ""
      result.push({ mode: s.name, label: s.name + dim })
    }
    var current = Config.mainMonitor
    if (current && !_screens.find(function(s) { return s.name === current })) {
      result.push({ mode: current, label: current + "  (not connected)" })
    }
    return result
  }

  implicitHeight: _col.implicitHeight

  Column {
    id: _col
    width: parent.width
    spacing: 8 * Config.uiScale

    Text {
      text: "GENERAL"
      font.family: Style.fontFamily; font.pixelSize: 13 * Config.uiScale; font.weight: Font.Bold; font.letterSpacing: 1.5
      color: root.colors ? root.colors.tertiary : Qt.rgba(1, 1, 1, 0.5)
    }

    SettingsDropdown {
      colors: root.colors
      label: "Main monitor"
      value: Config.mainMonitor
      model: root._monitorModel
      onSelect: function(v) { SettingsService.setPath("monitor", v === "" ? undefined : v) }
    }

    Text {
      width: parent.width
      text: "Screen used by the bar, launcher, switcher, power menu and settings panel. Auto picks the first connected screen."
      wrapMode: Text.WordWrap
      font.family: Style.fontFamily; font.pixelSize: 11 * Config.uiScale; font.italic: true
      color: root.colors ? Qt.rgba(root.colors.outline.r, root.colors.outline.g, root.colors.outline.b, 0.7) : Qt.rgba(1, 1, 1, 0.4)
    }
  }
}
