import QtQuick
import ".."
import "../components"
import "../services"


Item {
  id: root
  property var colors
  property string activeCategory: "layout"

  readonly property var categories: [
    { key: "layout",     label: "LAYOUT" },
    { key: "background", label: "BACKGROUND" }
  ]

  implicitHeight: _stack.implicitHeight

  Item {
    id: _stack
    width: parent.width
    implicitHeight: childrenRect.height

    Column {
      visible: root.activeCategory === "layout"
      width: parent.width
      spacing: 14 * Config.uiScale

      SettingsCard {
        colors: root.colors
        title: "Display mode"
        RowDropdown {
          colors: root.colors
          title: "Switcher style"
          description: "Visual style of the alt-tab window switcher."
          value: Config.switchDisplayMode
          model: [
            { mode: "slice",   label: "Slice - angled cards" },
            { mode: "grid",    label: "Grid - rows and columns" },
            { mode: "compact", label: "Compact - small cells" },
            { mode: "wheel",   label: "Wheel - radial layout" }
          ]
          onSelect: function(v) { SettingsService.setSwitcherKey("displayMode", v) }
        }
      }

      SettingsCard {
        visible: Config.switchDisplayMode === "slice"
        colors: root.colors
        title: "Slice geometry"
        RowInput { colors: root.colors; title: "Slice width";    value: Config.switchSliceWidth;        min: 0; max: 9999; onCommit: function(v) { SettingsService.setSwitcherKey("sliceWidth", v) } }
        RowInput { colors: root.colors; title: "Expanded width"; value: Config.switchSliceExpandedWidth; min: 0; max: 9999; onCommit: function(v) { SettingsService.setSwitcherKey("sliceExpandedWidth", v) } }
        RowInput { colors: root.colors; title: "Slice height";   value: Config.switchSliceHeight;       min: 0; max: 9999; onCommit: function(v) { SettingsService.setSwitcherKey("sliceHeight", v) } }
        RowInput { colors: root.colors; title: "Skew offset";    value: Config.switchSliceSkewOffset;   min: -9999; max: 9999; onCommit: function(v) { SettingsService.setSwitcherKey("sliceSkewOffset", v) } }
        RowInput { colors: root.colors; title: "Slice spacing";  value: Config.switchSliceSpacing;      min: -9999; max: 9999; onCommit: function(v) { SettingsService.setSwitcherKey("sliceSpacing", v) } }
        RowInput { colors: root.colors; title: "Visible count";  value: Config.switchSliceVisibleCount; min: 1; max: 999;  onCommit: function(v) { SettingsService.setSwitcherKey("sliceVisibleCount", v) } }
        RowInput { colors: root.colors; title: "Card width";     value: Config.switchCardWidth;         min: 0; max: 9999; onCommit: function(v) { SettingsService.setSwitcherKey("cardWidth", v) } }
        RowInput { colors: root.colors; title: "Card height pad"; value: Config.switchCardHeightPad;    min: 0; max: 9999; onCommit: function(v) { SettingsService.setSwitcherKey("cardHeightPad", v) } }
      }

      SettingsCard {
        visible: Config.switchDisplayMode === "grid"
        colors: root.colors
        title: "Grid geometry"
        RowInput { colors: root.colors; title: "Columns";     value: Config.switchGridColumns;    min: 1; max: 999;  onCommit: function(v) { SettingsService.setSwitcherKey("gridColumns", v) } }
        RowInput { colors: root.colors; title: "Rows";        value: Config.switchGridRows;       min: 1; max: 999;  onCommit: function(v) { SettingsService.setSwitcherKey("gridRows", v) } }
        RowInput { colors: root.colors; title: "Cell width";  value: Config.switchGridCellWidth;  min: 0; max: 9999; onCommit: function(v) { SettingsService.setSwitcherKey("gridCellWidth", v) } }
        RowInput { colors: root.colors; title: "Cell height"; value: Config.switchGridCellHeight; min: 0; max: 9999; onCommit: function(v) { SettingsService.setSwitcherKey("gridCellHeight", v) } }
        RowInput { colors: root.colors; title: "Spacing";     value: Config.switchGridSpacing;    min: 0; max: 9999; onCommit: function(v) { SettingsService.setSwitcherKey("gridSpacing", v) } }
        RowInput { colors: root.colors; title: "Icon size";   value: Config.switchGridIconSize;   min: 0; max: 9999; onCommit: function(v) { SettingsService.setSwitcherKey("gridIconSize", v) } }
      }

      SettingsCard {
        visible: Config.switchDisplayMode === "compact"
        colors: root.colors
        title: "Compact geometry"
        RowInput { colors: root.colors; title: "Cell width";   value: Config.switchCompactCellWidth;  min: 0; max: 9999; onCommit: function(v) { SettingsService.setSwitcherKey("compactCellWidth", v) } }
        RowInput { colors: root.colors; title: "Cell height";  value: Config.switchCompactCellHeight; min: 0; max: 9999; onCommit: function(v) { SettingsService.setSwitcherKey("compactCellHeight", v) } }
        RowInput { colors: root.colors; title: "Spacing";      value: Config.switchCompactSpacing;    min: 0; max: 9999; onCommit: function(v) { SettingsService.setSwitcherKey("compactSpacing", v) } }
        RowInput { colors: root.colors; title: "Icon size";    value: Config.switchCompactIconSize;   min: 0; max: 9999; onCommit: function(v) { SettingsService.setSwitcherKey("compactIconSize", v) } }
        RowInput { colors: root.colors; title: "Card padding"; value: Config.switchCompactCardPad;    min: 0; max: 9999; onCommit: function(v) { SettingsService.setSwitcherKey("compactCardPad", v) } }
      }

      SettingsCard {
        visible: Config.switchDisplayMode === "wheel"
        colors: root.colors
        title: "Wheel geometry"
        RowInput { colors: root.colors; title: "Outer radius"; value: Config.switchWheelOuterRadius; min: 0; max: 9999; onCommit: function(v) { SettingsService.setSwitcherKey("wheelOuterRadius", v) } }
        RowInput { colors: root.colors; title: "Inner radius"; value: Config.switchWheelInnerRadius; min: 0; max: 9999; onCommit: function(v) { SettingsService.setSwitcherKey("wheelInnerRadius", v) } }
        RowInput { colors: root.colors; title: "Icon size";    value: Config.switchWheelIconSize;    min: 0; max: 9999; onCommit: function(v) { SettingsService.setSwitcherKey("wheelIconSize", v) } }
        RowInput { colors: root.colors; title: "Section gap";  value: Config.switchWheelGap;         min: 0; max: 999;  suffix: "°"; onCommit: function(v) { SettingsService.setSwitcherKey("wheelGap", v) } }
        RowInput { colors: root.colors; title: "Start angle";  value: Math.round(Config.switchWheelStartAngle); min: -999; max: 999; suffix: "°"; onCommit: function(v) { SettingsService.setSwitcherKey("wheelStartAngle", v) } }
      }
    }

    Column {
      visible: root.activeCategory === "background"
      width: parent.width
      spacing: 14 * Config.uiScale

      SettingsCard {
        colors: root.colors
        title: "Overlay"
        RowInput {
          colors: root.colors
          title: "Fade-in duration"
          description: "How long the dim layer takes to fade in when the switcher opens."
          value: Config.switchAnimFadeIn
          min: 0; max: 9999
          suffix: "ms"
          onCommit: function(v) { SettingsService.setSwitcherKey("animFadeIn", v) }
        }
        RowInput {
          colors: root.colors
          title: "Dim opacity"
          description: "How dark the rest of the screen gets while the switcher is open."
          value: Math.round(Config.switchDimOpacity * 100)
          min: 0; max: 100
          suffix: "%"
          onCommit: function(v) { SettingsService.setSwitcherKey("dimOpacity", v / 100.0) }
        }
      }
    }
  }
}
