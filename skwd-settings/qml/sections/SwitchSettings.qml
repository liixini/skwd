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

  property string _selectedMode: Config.switchDisplayMode

  Connections {
    target: Config
    function onSwitchDisplayModeChanged() {
      if (Config.switchDisplayMode !== root._selectedMode)
        root._selectedMode = Config.switchDisplayMode
    }
  }

  implicitHeight: _stack.implicitHeight

  Item {
    id: _stack
    width: parent.width
    implicitHeight: childrenRect.height


    Column {
      visible: root.activeCategory === "layout"
      width: parent.width
      spacing: 8 * Config.uiScale

      Text {
        text: "DISPLAY MODE"
        font.family: Style.fontFamily; font.pixelSize: 13 * Config.uiScale; font.weight: Font.Bold; font.letterSpacing: 1.5
        color: root.colors ? root.colors.tertiary : Qt.rgba(1, 1, 1, 0.5)
      }

      Row {
        width: parent.width; spacing: -4
        Repeater {
          model: [
            { mode: "slice",   label: "SLICE",   icon: "" },
            { mode: "grid",    label: "GRID",    icon: "" },
            { mode: "compact", label: "COMPACT", icon: "" },
            { mode: "wheel",   label: "WHEEL",   icon: "" }
          ]
          FilterButton {
            colors: root.colors
            label: modelData.label
            icon: modelData.icon
            skew: 8 * Config.uiScale
            height: 26 * Config.uiScale
            isActive: root._selectedMode === modelData.mode
            onClicked: {
              root._selectedMode = modelData.mode
              SettingsService.setSwitcherKey("displayMode", modelData.mode)
            }
          }
        }
      }

      Item { width: 1; height: 6 }


      Column {
        visible: root._selectedMode === "slice"
        width: parent.width
        spacing: 8 * Config.uiScale

        Text {
          text: "SLICE GEOMETRY"
          font.family: Style.fontFamily; font.pixelSize: 13 * Config.uiScale; font.weight: Font.Bold; font.letterSpacing: 1.5
          color: root.colors ? root.colors.tertiary : Qt.rgba(1, 1, 1, 0.5)
        }

        SettingsInput { colors: root.colors; label: "Slice width";       value: Config.switchSliceWidth;        min: 60;  max: 300;  onCommit: function(v) { SettingsService.setSwitcherKey("sliceWidth", v) } }
        SettingsInput { colors: root.colors; label: "Expanded width";    value: Config.switchSliceExpandedWidth; min: 400; max: 1600; onCommit: function(v) { SettingsService.setSwitcherKey("sliceExpandedWidth", v) } }
        SettingsInput { colors: root.colors; label: "Slice height";      value: Config.switchSliceHeight;       min: 200; max: 800;  onCommit: function(v) { SettingsService.setSwitcherKey("sliceHeight", v) } }
        SettingsInput { colors: root.colors; label: "Skew offset";       value: Config.switchSliceSkewOffset;   min: 0;   max: 80;   onCommit: function(v) { SettingsService.setSwitcherKey("sliceSkewOffset", v) } }
        SettingsInput { colors: root.colors; label: "Slice spacing";     value: Config.switchSliceSpacing;      min: -60; max: 30;   onCommit: function(v) { SettingsService.setSwitcherKey("sliceSpacing", v) } }
        SettingsInput { colors: root.colors; label: "Visible count";     value: Config.switchSliceVisibleCount; min: 4;   max: 24;   onCommit: function(v) { SettingsService.setSwitcherKey("sliceVisibleCount", v) } }
        SettingsInput { colors: root.colors; label: "Card width";        value: Config.switchCardWidth;         min: 800; max: 3200; onCommit: function(v) { SettingsService.setSwitcherKey("cardWidth", v) } }
        SettingsInput { colors: root.colors; label: "Card height pad";   value: Config.switchCardHeightPad;     min: 0;   max: 200;  onCommit: function(v) { SettingsService.setSwitcherKey("cardHeightPad", v) } }
      }


      Column {
        visible: root._selectedMode === "grid"
        width: parent.width
        spacing: 8 * Config.uiScale

        Text {
          text: "GRID GEOMETRY"
          font.family: Style.fontFamily; font.pixelSize: 13 * Config.uiScale; font.weight: Font.Bold; font.letterSpacing: 1.5
          color: root.colors ? root.colors.tertiary : Qt.rgba(1, 1, 1, 0.5)
        }

        SettingsInput { colors: root.colors; label: "Columns";           value: Config.switchGridColumns;     min: 1;  max: 12;  onCommit: function(v) { SettingsService.setSwitcherKey("gridColumns", v) } }
        SettingsInput { colors: root.colors; label: "Rows";              value: Config.switchGridRows;        min: 1;  max: 12;  onCommit: function(v) { SettingsService.setSwitcherKey("gridRows", v) } }
        SettingsInput { colors: root.colors; label: "Cell width";        value: Config.switchGridCellWidth;   min: 120; max: 480; onCommit: function(v) { SettingsService.setSwitcherKey("gridCellWidth", v) } }
        SettingsInput { colors: root.colors; label: "Cell height";       value: Config.switchGridCellHeight;  min: 90;  max: 360; onCommit: function(v) { SettingsService.setSwitcherKey("gridCellHeight", v) } }
        SettingsInput { colors: root.colors; label: "Spacing";           value: Config.switchGridSpacing;     min: 0;   max: 40;  onCommit: function(v) { SettingsService.setSwitcherKey("gridSpacing", v) } }
        SettingsInput { colors: root.colors; label: "Icon size";         value: Config.switchGridIconSize;    min: 32;  max: 144; onCommit: function(v) { SettingsService.setSwitcherKey("gridIconSize", v) } }
      }


      Column {
        visible: root._selectedMode === "compact"
        width: parent.width
        spacing: 8 * Config.uiScale

        Text {
          text: "COMPACT GEOMETRY"
          font.family: Style.fontFamily; font.pixelSize: 13 * Config.uiScale; font.weight: Font.Bold; font.letterSpacing: 1.5
          color: root.colors ? root.colors.tertiary : Qt.rgba(1, 1, 1, 0.5)
        }

        SettingsInput { colors: root.colors; label: "Cell width";        value: Config.switchCompactCellWidth;   min: 60;  max: 200; onCommit: function(v) { SettingsService.setSwitcherKey("compactCellWidth", v) } }
        SettingsInput { colors: root.colors; label: "Cell height";       value: Config.switchCompactCellHeight;  min: 70;  max: 200; onCommit: function(v) { SettingsService.setSwitcherKey("compactCellHeight", v) } }
        SettingsInput { colors: root.colors; label: "Spacing";           value: Config.switchCompactSpacing;     min: 0;   max: 30;  onCommit: function(v) { SettingsService.setSwitcherKey("compactSpacing", v) } }
        SettingsInput { colors: root.colors; label: "Icon size";         value: Config.switchCompactIconSize;    min: 24;  max: 96;  onCommit: function(v) { SettingsService.setSwitcherKey("compactIconSize", v) } }
        SettingsInput { colors: root.colors; label: "Card padding";      value: Config.switchCompactCardPad;     min: 0;   max: 80;  onCommit: function(v) { SettingsService.setSwitcherKey("compactCardPad", v) } }
      }


      Column {
        visible: root._selectedMode === "wheel"
        width: parent.width
        spacing: 8 * Config.uiScale

        Text {
          text: "WHEEL GEOMETRY"
          font.family: Style.fontFamily; font.pixelSize: 13 * Config.uiScale; font.weight: Font.Bold; font.letterSpacing: 1.5
          color: root.colors ? root.colors.tertiary : Qt.rgba(1, 1, 1, 0.5)
        }

        SettingsInput { colors: root.colors; label: "Outer radius";      value: Config.switchWheelOuterRadius; min: 160; max: 640; onCommit: function(v) { SettingsService.setSwitcherKey("wheelOuterRadius", v) } }
        SettingsInput { colors: root.colors; label: "Inner radius";      value: Config.switchWheelInnerRadius; min: 40;  max: 240; onCommit: function(v) { SettingsService.setSwitcherKey("wheelInnerRadius", v) } }
        SettingsInput { colors: root.colors; label: "Icon size";         value: Config.switchWheelIconSize;    min: 32;  max: 144; onCommit: function(v) { SettingsService.setSwitcherKey("wheelIconSize", v) } }
        SettingsInput { colors: root.colors; label: "Section gap (deg)"; value: Config.switchWheelGap;         min: 0;   max: 12;  onCommit: function(v) { SettingsService.setSwitcherKey("wheelGap", v) } }
        SettingsInput { colors: root.colors; label: "Start angle (deg)"; value: Math.round(Config.switchWheelStartAngle); min: -180; max: 180; onCommit: function(v) { SettingsService.setSwitcherKey("wheelStartAngle", v) } }
      }
    }


    Column {
      visible: root.activeCategory === "background"
      width: parent.width
      spacing: 8 * Config.uiScale

      Text {
        text: "OVERLAY"
        font.family: Style.fontFamily; font.pixelSize: 13 * Config.uiScale; font.weight: Font.Bold; font.letterSpacing: 1.5
        color: root.colors ? root.colors.tertiary : Qt.rgba(1, 1, 1, 0.5)
      }

      SettingsInput { colors: root.colors; label: "Fade-in duration (ms)"; value: Config.switchAnimFadeIn; min: 0; max: 1500; onCommit: function(v) { SettingsService.setSwitcherKey("animFadeIn", v) } }
      SettingsInput {
        colors: root.colors; label: "Dim opacity (%)"
        value: Math.round(Config.switchDimOpacity * 100); min: 0; max: 100
        onCommit: function(v) { SettingsService.setSwitcherKey("dimOpacity", v / 100.0) }
      }
    }
  }
}
