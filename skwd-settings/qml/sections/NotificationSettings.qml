import QtQuick
import ".."
import "../components"
import "../services"


Item {
  id: root
  property var colors
  property string activeCategory: "behavior"

  readonly property var categories: [
    { key: "behavior", label: "BEHAVIOR" },
    { key: "popup",    label: "POPUP" },
    { key: "daemon",   label: "DAEMON" }
  ]

  function _save(key, value) { SettingsService.setPath("notifications." + key, value) }

  implicitHeight: _stack.implicitHeight

  Item {
    id: _stack
    width: parent.width
    implicitHeight: childrenRect.height

    Column {
      visible: root.activeCategory === "behavior"
      width: parent.width
      spacing: 14 * Config.uiScale

      SettingsCard {
        colors: root.colors
        title: "Timing"
        RowInput {
          colors: root.colors
          title: "Auto-dismiss after"
          description: "Time before a popup automatically fades, in milliseconds. 0 keeps it visible until dismissed."
          value: Config.notifExpireMs
          min: 0; max: 60000
          suffix: "ms"
          onCommit: function(v) { root._save("expireMs", v) }
        }
      }

      SettingsCard {
        colors: root.colors
        title: "Stack"
        RowInput {
          colors: root.colors
          title: "Max popups visible"
          description: "How many notifications can show at once before older ones queue."
          value: Config.notifPopupMaxVisible
          min: 1; max: 10
          onCommit: function(v) { root._save("popupMaxVisible", v) }
        }
      }
    }

    Column {
      visible: root.activeCategory === "popup"
      width: parent.width
      spacing: 14 * Config.uiScale

      SettingsCard {
        colors: root.colors
        title: "Geometry"
        RowInput { colors: root.colors; title: "Popup width";  description: "Width of each notification in pixels."; value: Config.notifPopupWidth;  min: 0; max: 9999; suffix: "px"; onCommit: function(v) { root._save("popupWidth", v) } }
        RowInput { colors: root.colors; title: "Right margin"; description: "Distance from the right edge of the screen."; value: Config.notifPopupRightMargin; min: 0; max: 9999; suffix: "px"; onCommit: function(v) { root._save("popupRightMargin", v) } }
        RowInput { colors: root.colors; title: "Left margin";  description: "Distance from the left edge of the screen.";  value: Config.notifPopupLeftMargin;  min: 0; max: 9999; suffix: "px"; onCommit: function(v) { root._save("popupLeftMargin", v) } }
        RowInput { colors: root.colors; title: "Top margin";   description: "Distance from the top of the screen.";        value: Config.notifPopupTopMargin;   min: 0; max: 9999; suffix: "px"; onCommit: function(v) { root._save("popupTopMargin", v) } }
      }

      SettingsCard {
        colors: root.colors
        title: "Side"
        RowDropdown {
          colors: root.colors
          title: "Pop-up side"
          description: "Which edge of the screen notifications stack against."
          value: Config.notifPopupSide
          model: [
            { mode: "left",  label: "Left"  },
            { mode: "right", label: "Right" }
          ]
          onSelect: function(v) { root._save("popupSide", v) }
        }
      }
    }


    Column {
      visible: root.activeCategory === "daemon"
      width: parent.width
      spacing: 14 * Config.uiScale

      SettingsCard {
        colors: root.colors
        title: "Built-in notification daemon"
        subtitle: "Restart skwd-daemon for changes to apply."
        RowDropdown {
          colors: root.colors
          title: "Daemon mode"
          value: Config.notifBuiltIn
          model: [
            { mode: "auto",   label: "Auto - run only if no other daemon is active" },
            { mode: "always", label: "Always run (may conflict with mako/dunst)" },
            { mode: "never",  label: "Never run (use your own)" }
          ]
          onSelect: function(v) { root._save("builtIn", v) }
        }
      }
    }
  }
}
