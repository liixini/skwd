import QtQuick
import ".."

Item {
  id: root
  property var colors
  property string activeCategory: "general"
  property string componentName: "?"
  property string sectionFile: "?"
  readonly property var categories: [{ key: "general", label: "GENERAL" }]

  implicitHeight: _col.implicitHeight + 8 * Config.uiScale

  Column {
    id: _col
    width: parent.width
    spacing: 8 * Config.uiScale

    Text {
      text: root.componentName.toUpperCase()
      font.family: Style.fontFamily; font.pixelSize: 13 * Config.uiScale; font.weight: Font.Bold; font.letterSpacing: 1.5
      color: root.colors ? root.colors.tertiary : Qt.rgba(1, 1, 1, 0.5)
    }

    Text {
      width: parent.width
      text: "No settings exposed yet for " + root.componentName + "."
      font.family: Style.fontFamily; font.pixelSize: 12 * Config.uiScale
      color: root.colors ? root.colors.surfaceText : "#fff"
      wrapMode: Text.Wrap
    }

    Text {
      width: parent.width
      text: "To add controls, populate qml/sections/" + root.sectionFile + " with the same pattern as SwitchSettings.qml — declare the categories list, add Config keys for each tunable, and use SettingsSlider rows wired through SettingsService."
      font.family: Style.fontFamily; font.pixelSize: 11 * Config.uiScale
      color: root.colors ? Qt.rgba(root.colors.surfaceText.r, root.colors.surfaceText.g, root.colors.surfaceText.b, 0.55) : Qt.rgba(1, 1, 1, 0.4)
      wrapMode: Text.Wrap
      lineHeight: 1.4
    }
  }
}
