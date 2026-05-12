import QtQuick
import ".."
import "../components"
import "../services"


Item {
  id: root
  property var colors
  property string activeCategory: "programs"

  readonly property var categories: [
    { key: "programs", label: "PROGRAMS" }
  ]

  function _set(key, value) { SettingsService.setPath("programs." + key, value) }

  implicitHeight: _col.implicitHeight

  Column {
    id: _col
    width: parent.width
    spacing: 14 * Config.uiScale

    SettingsCard {
      colors: root.colors
      title: "Quickshell programs"
      subtitle: "Disable a program to unload its QML entirely - the process dies and its UI vanishes until you enable it again. Settings is intentionally excluded so you can always recover from here."

      RowToggle {
        colors: root.colors
        title: "Launcher"
        description: "Application launcher (skwd-launch). Triggered by the launcher keybind."
        checked: Config.progLaunchEnabled
        onToggle: function(v) { root._set("launch", v) }
      }
      RowToggle {
        colors: root.colors
        title: "Bar"
        description: "Top bar (skwd-bar) with widgets, music, notifications."
        checked: Config.progBarEnabled
        onToggle: function(v) { root._set("bar", v) }
      }
      RowToggle {
        colors: root.colors
        title: "Window switcher"
        description: "Alt-Tab style window switcher (skwd-switch)."
        checked: Config.progSwitchEnabled
        onToggle: function(v) { root._set("switch", v) }
      }
      RowToggle {
        colors: root.colors
        title: "Notifications"
        description: "Notification daemon (skwd-notification) - only active when no other notification daemon owns the FDO bus."
        checked: Config.progNotificationEnabled
        onToggle: function(v) { root._set("notification", v) }
      }
      RowToggle {
        colors: root.colors
        title: "Power menu"
        description: "Power menu (skwd-power) - triggered by the power keybind."
        checked: Config.progPowerEnabled
        onToggle: function(v) { root._set("power", v) }
      }
    }
  }
}
