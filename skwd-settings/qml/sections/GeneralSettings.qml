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
    spacing: 14 * Config.uiScale

    SettingsCard {
      colors: root.colors
      title: "Display"
      subtitle: "Where Skwd's panels and popups appear."
      RowDropdown {
        colors: root.colors
        title: "Main monitor"
        description: "Screen used by the bar, launcher, switcher, power menu and settings panel. Auto picks the first connected screen."
        value: Config.mainMonitor
        model: root._monitorModel
        onSelect: function(v) { SettingsService.setPath("monitor", v === "" ? undefined : v) }
      }
    }
  }
}
