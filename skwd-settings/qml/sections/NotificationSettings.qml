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
      spacing: 8 * Config.uiScale

      Text {
        text: "TIMING"
        font.family: Style.fontFamily; font.pixelSize: 13 * Config.uiScale; font.weight: Font.Bold; font.letterSpacing: 1.5
        color: root.colors ? root.colors.tertiary : Qt.rgba(1, 1, 1, 0.5)
      }
      SettingsInput {
        colors: root.colors
        label: "Auto-dismiss after (ms)"
        value: Config.notifExpireMs
        min: 0; max: 60000
        onCommit: function(v) { root._save("expireMs", v) }
      }

      Text {
        text: "STACK"
        font.family: Style.fontFamily; font.pixelSize: 13 * Config.uiScale; font.weight: Font.Bold; font.letterSpacing: 1.5
        color: root.colors ? root.colors.tertiary : Qt.rgba(1, 1, 1, 0.5)
      }
      SettingsInput {
        colors: root.colors
        label: "Max popups visible"
        value: Config.notifPopupMaxVisible
        min: 1; max: 10
        onCommit: function(v) { root._save("popupMaxVisible", v) }
      }
    }

    
    Column {
      visible: root.activeCategory === "popup"
      width: parent.width
      spacing: 8 * Config.uiScale

      Text {
        text: "GEOMETRY"
        font.family: Style.fontFamily; font.pixelSize: 13 * Config.uiScale; font.weight: Font.Bold; font.letterSpacing: 1.5
        color: root.colors ? root.colors.tertiary : Qt.rgba(1, 1, 1, 0.5)
      }
      SettingsInput { colors: root.colors; label: "Popup width";        value: Config.notifPopupWidth;       min: 200; max: 600; onCommit: function(v) { root._save("popupWidth", v) } }
      SettingsInput { colors: root.colors; label: "Right margin";       value: Config.notifPopupRightMargin; min: 0;   max: 200; onCommit: function(v) { root._save("popupRightMargin", v) } }
      SettingsInput { colors: root.colors; label: "Left margin";        value: Config.notifPopupLeftMargin;  min: 0;   max: 200; onCommit: function(v) { root._save("popupLeftMargin", v) } }
      SettingsInput { colors: root.colors; label: "Top margin";         value: Config.notifPopupTopMargin;   min: 0;   max: 200; onCommit: function(v) { root._save("popupTopMargin", v) } }

      Text {
        text: "SIDE"
        font.family: Style.fontFamily; font.pixelSize: 13 * Config.uiScale; font.weight: Font.Bold; font.letterSpacing: 1.5
        color: root.colors ? root.colors.tertiary : Qt.rgba(1, 1, 1, 0.5)
      }
      Row {
        spacing: -4
        Repeater {
          model: [
            { key: "left",  label: "Left"  },
            { key: "right", label: "Right" }
          ]
          FilterButton {
            colors: root.colors
            label: modelData.label
            skew: 8 * Config.uiScale
            height: 26 * Config.uiScale
            isActive: Config.notifPopupSide === modelData.key
            onClicked: root._save("popupSide", modelData.key)
          }
        }
      }
    }


    Column {
      visible: root.activeCategory === "daemon"
      width: parent.width
      spacing: 8 * Config.uiScale

      Text {
        text: "BUILT-IN NOTIFICATION DAEMON"
        font.family: Style.fontFamily; font.pixelSize: 13 * Config.uiScale; font.weight: Font.Bold; font.letterSpacing: 1.5
        color: root.colors ? root.colors.tertiary : Qt.rgba(1, 1, 1, 0.5)
      }

      Row {
        width: parent.width; spacing: -4
        Repeater {
          model: [
            { key: "auto",   label: "Auto",   tip: "Run skwd's notification daemon only if no other one is active" },
            { key: "always", label: "Always", tip: "Always run skwd's notification daemon (may conflict with mako/dunst/etc.)" },
            { key: "never",  label: "Never",  tip: "Never run skwd's notification daemon (use your own)" }
          ]
          FilterButton {
            colors: root.colors
            label: modelData.label
            skew: 8 * Config.uiScale
            height: 26 * Config.uiScale
            isActive: Config.notifBuiltIn === modelData.key
            onClicked: root._save("builtIn", modelData.key)
          }
        }
      }

      Text {
        width: parent.width
        text: "Restart skwd-daemon to apply"
        wrapMode: Text.WordWrap
        font.family: Style.fontFamily; font.pixelSize: 11 * Config.uiScale; font.italic: true
        color: root.colors ? Qt.rgba(root.colors.outline.r, root.colors.outline.g, root.colors.outline.b, 0.7) : Qt.rgba(1, 1, 1, 0.4)
      }
    }
  }
}
