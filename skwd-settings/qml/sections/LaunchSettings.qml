import QtQuick
import QtQuick.Controls
import Quickshell.Io
import ".."
import "../components"
import "../services"


Item {
  id: root
  property var colors
  property string activeCategory: "layout"
  property string _appQuery: ""

  readonly property var categories: [
    { key: "layout",    label: "LAYOUT" },
    { key: "presets",   label: "PRESETS" },
    { key: "slice",     label: "SLICE" },
    { key: "hex",       label: "HEX" },
    { key: "grid",      label: "GRID" },
    { key: "mosaic",    label: "MOSAIC" },
    { key: "paths",     label: "PATHS" },
    { key: "apps",      label: "APPS" }
  ]

  function _save(key, value) { SettingsService.setPath("components.appLauncher." + key, value) }
  function _saveRoot(path, value) { SettingsService.setPath(path, value) }

  function _applyPreset(p) {
    if (p.expandedWidth !== undefined) _save("expandedWidth", p.expandedWidth)
    if (p.sliceHeight   !== undefined) _save("sliceHeight",   p.sliceHeight)
    if (p.sliceWidth    !== undefined) _save("sliceWidth",    p.sliceWidth)
    if (p.visibleCount  !== undefined) _save("visibleCount",  p.visibleCount)
    if (p.sliceSpacing  !== undefined) _save("sliceSpacing",  p.sliceSpacing)
    if (p.skewOffset    !== undefined) _save("skewOffset",    p.skewOffset)
    if (p.hexRadius     !== undefined) _save("hexRadius",     p.hexRadius)
    if (p.hexRows       !== undefined) _save("hexRows",       p.hexRows)
    if (p.hexCols       !== undefined) _save("hexCols",       p.hexCols)
    if (p.gridColumns   !== undefined) _save("gridColumns",   p.gridColumns)
    if (p.gridRows      !== undefined) _save("gridRows",      p.gridRows)
    if (p.gridThumbWidth  !== undefined) _save("gridThumbWidth",  p.gridThumbWidth)
    if (p.gridThumbHeight !== undefined) _save("gridThumbHeight", p.gridThumbHeight)
  }

  function _captureCurrentPreset() {
    if (Config.launchDisplayMode === "slice") {
      return { expandedWidth: Config.launchExpandedWidth, sliceHeight: Config.launchSliceHeight,
               sliceWidth: Config.launchSliceWidth, visibleCount: Config.launchVisibleCount,
               sliceSpacing: Config.launchSliceSpacing, skewOffset: Config.launchSkewOffset }
    }
    if (Config.launchDisplayMode === "hex") {
      return { hexRadius: Config.launchHexRadius, hexRows: Config.launchHexRows, hexCols: Config.launchHexCols }
    }
    if (Config.launchDisplayMode === "wall") {
      return { gridColumns: Config.launchGridColumns, gridRows: Config.launchGridRows,
               gridThumbWidth: Config.launchGridThumbWidth, gridThumbHeight: Config.launchGridThumbHeight }
    }
    if (Config.launchDisplayMode === "mosaic") {
      return { mosaicCells: Config.launchMosaicCells, mosaicSeed: Config.launchMosaicSeed,
               mosaicWidth: Config.launchMosaicWidth, mosaicHeight: Config.launchMosaicHeight }
    }
    return {}
  }

  function _saveCustomPreset(slot) {
    var key = slot + "_" + Config.launchDisplayMode
    var presets = JSON.parse(JSON.stringify(Config.launchCustomPresets || {}))
    presets[key] = _captureCurrentPreset()
    _save("customPresets", presets)
  }

  function _loadCustomPreset(slot) {
    var key = slot + "_" + Config.launchDisplayMode
    var p = (Config.launchCustomPresets || {})[key]
    if (p) _applyPreset(p)
  }

  property string _picking: ""
  property string _pickingCurrent: ""
  property string _pickerDir: Config.splashDir
  function _openSplashPicker(appName, currentPath) {
    _picking = appName
    _pickingCurrent = currentPath
    _pickerDir = Config.splashDir
    _splashLister.refresh()
    _splashPicker.visible = true
  }
  function _closeSplashPicker() { _splashPicker.visible = false }
  function _selectSplash(path) {
    if (_picking) _saveAppField(_picking, "background", path)
    _closeSplashPicker()
  }
  function _navigateTo(dir) {
    _pickerDir = dir
    _splashLister.refresh()
  }
  function _navigateUp() {
    var dir = _pickerDir
    if (dir.length > 1 && dir[dir.length - 1] === "/") dir = dir.substring(0, dir.length - 1)
    var slash = dir.lastIndexOf("/")
    _navigateTo(slash > 0 ? dir.substring(0, slash) : "/")
  }

  property var _appsConfigFile: FileView {
    path: Config.appsConfigPath
    preload: true
  }

  function _readAppsConfig() {
    _appsConfigFile.reload()
    try { return JSON.parse(_appsConfigFile.text()) } catch(e) { return {} }
  }

  function _saveAppField(appName, field, value) {
    var data = _readAppsConfig()
    var key = appName.toLowerCase()
    if (typeof data[key] !== "object" || data[key] === null) data[key] = {}
    if (value === "" || value === false || value === null || value === undefined) {
      delete data[key][field]
    } else {
      data[key][field] = value
    }
    _appsConfigFile.setText(JSON.stringify(data, null, 2) + "\n")
  }

  property var _appCacheList: ListModel { id: _appCacheList }
  property var _appCacheFile: FileView {
    path: Config.appLauncherCachePath
    preload: true
    onLoaded: root._reloadAppCache()
    onFileChanged: { reload(); root._reloadAppCache() }
  }
  function _reloadAppCache() {
    var raw = _appCacheFile.text() || ""
    var apps = _readAppsConfig()
    var rows = []
    if (raw) {
      var lines = raw.split("\n")
      for (var i = 0; i < lines.length; i++) {
        var line = lines[i].trim()
        if (!line) continue
        try {
          var entry = JSON.parse(line)
          var override = apps[(entry.name || "").toLowerCase()] || {}
          rows.push({
            name: entry.name || "",
            displayName: override.displayName || "",
            background: override.background || "",
            customIcon: override.icon || "",
            hidden: override.hidden === true,
            tags: override.tags || ""
          })
        } catch (e) {}
      }
    }

    var sameStructure = rows.length === _appCacheList.count
    if (sameStructure) {
      for (var k = 0; k < rows.length; k++) {
        if (_appCacheList.get(k).name !== rows[k].name) { sameStructure = false; break }
      }
    }
    if (sameStructure) {
      for (var u = 0; u < rows.length; u++) {
        var existing = _appCacheList.get(u)
        var r = rows[u]
        if (existing.displayName !== r.displayName) _appCacheList.setProperty(u, "displayName", r.displayName)
        if (existing.background  !== r.background)  _appCacheList.setProperty(u, "background",  r.background)
        if (existing.customIcon  !== r.customIcon)  _appCacheList.setProperty(u, "customIcon",  r.customIcon)
        if (existing.hidden      !== r.hidden)      _appCacheList.setProperty(u, "hidden",      r.hidden)
        if (existing.tags        !== r.tags)        _appCacheList.setProperty(u, "tags",        r.tags)
      }
      return
    }

    _appCacheList.clear()
    for (var j = 0; j < rows.length; j++) _appCacheList.append(rows[j])
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
            { mode: "slice",  label: "Slices" },
            { mode: "hex",    label: "Hex" },
            { mode: "wall",   label: "Wall" },
            { mode: "mosaic", label: "Mosaic" }
          ]
          FilterButton {
            colors: root.colors
            label: modelData.label
            skew: 8 * Config.uiScale
            height: 26 * Config.uiScale
            isActive: Config.launchDisplayMode === modelData.mode
            onClicked: root._save("displayMode", modelData.mode)
          }
        }
      }
    }

    Column {
      visible: root.activeCategory === "presets"
      width: parent.width
      spacing: 8 * Config.uiScale

      Text {
        text: "SIZE PRESETS"
        font.family: Style.fontFamily; font.pixelSize: 13 * Config.uiScale; font.weight: Font.Bold; font.letterSpacing: 1.5
        color: root.colors ? root.colors.tertiary : Qt.rgba(1, 1, 1, 0.5)
        visible: Config.launchDisplayMode === "slice"
      }
      Row {
        width: parent.width; spacing: -4
        visible: Config.launchDisplayMode === "slice"
        Repeater {
          model: [
            { label: "XS", expandedWidth: 360,  sliceHeight: 200, sliceWidth: 52,  visibleCount: 20, sliceSpacing: -30, skewOffset: 16 },
            { label: "S",  expandedWidth: 480,  sliceHeight: 270, sliceWidth: 68,  visibleCount: 18, sliceSpacing: -30, skewOffset: 20 },
            { label: "M",  expandedWidth: 768,  sliceHeight: 432, sliceWidth: 108, visibleCount: 14, sliceSpacing: -30, skewOffset: 28 },
            { label: "L",  expandedWidth: 924,  sliceHeight: 520, sliceWidth: 135, visibleCount: 12, sliceSpacing: -30, skewOffset: 35 },
            { label: "XL", expandedWidth: 1280, sliceHeight: 720, sliceWidth: 180, visibleCount: 9,  sliceSpacing: -30, skewOffset: 45 }
          ]
          FilterButton {
            colors: root.colors
            label: modelData.label
            skew: 8 * Config.uiScale
            height: 26 * Config.uiScale
            isActive: Config.launchExpandedWidth === modelData.expandedWidth && Config.launchSliceHeight === modelData.sliceHeight
            tooltip: modelData.expandedWidth + "×" + modelData.sliceHeight + " (16:9)"
            onClicked: root._applyPreset(modelData)
          }
        }
      }

      Item { height: 8; width: 1 }

      Text {
        text: "CUSTOM SLOTS"
        font.family: Style.fontFamily; font.pixelSize: 13 * Config.uiScale; font.weight: Font.Bold; font.letterSpacing: 1.5
        color: root.colors ? root.colors.tertiary : Qt.rgba(1, 1, 1, 0.5)
      }
      Row {
        width: parent.width; spacing: -4
        Repeater {
          model: ["C1", "C2", "C3", "C4"]
          FilterButton {
            property string presetKey: modelData + "_" + Config.launchDisplayMode
            property var presetData: (Config.launchCustomPresets || {})[presetKey] || null
            property bool isEmpty: !presetData
            colors: root.colors
            label: modelData
            skew: 8 * Config.uiScale
            height: 26 * Config.uiScale
            isActive: {
              if (isEmpty) return false
              if (Config.launchDisplayMode === "slice")  return Config.launchExpandedWidth === presetData.expandedWidth && Config.launchSliceHeight === presetData.sliceHeight
              if (Config.launchDisplayMode === "hex")    return Config.launchHexRadius === presetData.hexRadius && Config.launchHexRows === presetData.hexRows && Config.launchHexCols === presetData.hexCols
              if (Config.launchDisplayMode === "wall")   return Config.launchGridColumns === presetData.gridColumns && Config.launchGridRows === presetData.gridRows
              if (Config.launchDisplayMode === "mosaic") return Config.launchMosaicCells === presetData.mosaicCells && Config.launchMosaicWidth === presetData.mosaicWidth
              return false
            }
            activeOpacity: isEmpty ? 0.35 : 1.0
            tooltip: isEmpty ? "Click to save current" : "Click to apply  ·  Right-click to overwrite"
            onClicked: {
              if (isEmpty) root._saveCustomPreset(modelData)
              else root._loadCustomPreset(modelData)
            }
            MouseArea {
              anchors.fill: parent; acceptedButtons: Qt.RightButton
              cursorShape: Qt.PointingHandCursor
              onClicked: root._saveCustomPreset(modelData)
            }
          }
        }
      }
    }

    Column {
      visible: root.activeCategory === "slice"
      width: parent.width
      spacing: 8 * Config.uiScale

      Text {
        text: "SLICE GEOMETRY"
        font.family: Style.fontFamily; font.pixelSize: 13 * Config.uiScale; font.weight: Font.Bold; font.letterSpacing: 1.5
        color: root.colors ? root.colors.tertiary : Qt.rgba(1, 1, 1, 0.5)
      }
      SettingsInput { colors: root.colors; label: "Slice width";    value: Config.launchSliceWidth;    min: 60;  max: 300;  onCommit: function(v) { root._save("sliceWidth", v) } }
      SettingsInput { colors: root.colors; label: "Expanded width"; value: Config.launchExpandedWidth; min: 400; max: 1600; onCommit: function(v) { root._save("expandedWidth", v) } }
      SettingsInput { colors: root.colors; label: "Slice height";   value: Config.launchSliceHeight;   min: 200; max: 800;  onCommit: function(v) { root._save("sliceHeight", v) } }
      SettingsInput { colors: root.colors; label: "Skew offset";    value: Config.launchSkewOffset;    min: 0;   max: 80;   onCommit: function(v) { root._save("skewOffset", v) } }
      SettingsInput { colors: root.colors; label: "Slice spacing";  value: Config.launchSliceSpacing;  min: -60; max: 30;   onCommit: function(v) { root._save("sliceSpacing", v) } }
      SettingsInput { colors: root.colors; label: "Visible count";  value: Config.launchVisibleCount;  min: 4;   max: 24;   onCommit: function(v) { root._save("visibleCount", v) } }

      Item { width: 1; height: 6 }

      Text {
        text: "ROUNDED CORNERS"
        font.family: Style.fontFamily; font.pixelSize: 13 * Config.uiScale; font.weight: Font.Bold; font.letterSpacing: 1.5
        color: root.colors ? root.colors.tertiary : Qt.rgba(1, 1, 1, 0.5)
      }
      SettingsToggle { colors: root.colors; label: "Round corners"; checked: Config.launchSliceRoundCorners; onToggle: function(v) { root._save("roundCorners", v) } }
      SettingsInput {
        colors: root.colors; label: "Corner radius"; value: Config.launchSliceCornerRadius
        min: 0; max: 60; enabled: Config.launchSliceRoundCorners
        onCommit: function(v) { root._save("cornerRadius", v) }
      }
    }

    Column {
      visible: root.activeCategory === "hex"
      width: parent.width
      spacing: 8 * Config.uiScale

      Text {
        text: "HEX GEOMETRY"
        font.family: Style.fontFamily; font.pixelSize: 13 * Config.uiScale; font.weight: Font.Bold; font.letterSpacing: 1.5
        color: root.colors ? root.colors.tertiary : Qt.rgba(1, 1, 1, 0.5)
      }
      SettingsInput { colors: root.colors; label: "Hex radius";  value: Config.launchHexRadius; min: 60; max: 300; onCommit: function(v) { root._save("hexRadius", v) } }
      SettingsInput { colors: root.colors; label: "Rows";        value: Config.launchHexRows;   min: 1;  max: 7;   onCommit: function(v) { root._save("hexRows", v) } }
      SettingsInput { colors: root.colors; label: "Columns";     value: Config.launchHexCols;   min: 3;  max: 15;  onCommit: function(v) { root._save("hexCols", v) } }
      SettingsInput { colors: root.colors; label: "Scroll step"; value: Config.launchHexScrollStep; min: 1; max: 5; onCommit: function(v) { root._save("hexScrollStep", v) } }

      Item { width: 1; height: 6 }

      Text {
        text: "ARC EFFECT"
        font.family: Style.fontFamily; font.pixelSize: 13 * Config.uiScale; font.weight: Font.Bold; font.letterSpacing: 1.5
        color: root.colors ? root.colors.tertiary : Qt.rgba(1, 1, 1, 0.5)
      }
      SettingsToggle { colors: root.colors; label: "Enable arc"; checked: Config.launchHexArc; onToggle: function(v) { root._save("hexArc", v) } }
      SettingsInput {
        colors: root.colors; label: "Arc intensity (×100)"
        value: Math.round(Config.launchHexArcIntensity * 100); min: 0; max: 300
        enabled: Config.launchHexArc
        onCommit: function(v) { root._save("hexArcIntensity", v / 100.0) }
      }
    }

    Column {
      visible: root.activeCategory === "grid"
      width: parent.width
      spacing: 8 * Config.uiScale

      Text {
        text: "GRID GEOMETRY"
        font.family: Style.fontFamily; font.pixelSize: 13 * Config.uiScale; font.weight: Font.Bold; font.letterSpacing: 1.5
        color: root.colors ? root.colors.tertiary : Qt.rgba(1, 1, 1, 0.5)
      }
      SettingsInput { colors: root.colors; label: "Columns";       value: Config.launchGridColumns;     min: 2; max: 16; onCommit: function(v) { root._save("gridColumns", v) } }
      SettingsInput { colors: root.colors; label: "Rows";          value: Config.launchGridRows;        min: 1; max: 12; onCommit: function(v) { root._save("gridRows", v) } }
      SettingsInput { colors: root.colors; label: "Thumb width";   value: Config.launchGridThumbWidth;  min: 100; max: 600; onCommit: function(v) { root._save("gridThumbWidth", v) } }
      SettingsInput { colors: root.colors; label: "Thumb height";  value: Config.launchGridThumbHeight; min: 60;  max: 400; onCommit: function(v) { root._save("gridThumbHeight", v) } }
    }

    Column {
      visible: root.activeCategory === "mosaic"
      width: parent.width
      spacing: 8 * Config.uiScale

      Text {
        text: "MOSAIC LAYOUT"
        font.family: Style.fontFamily; font.pixelSize: 13 * Config.uiScale; font.weight: Font.Bold; font.letterSpacing: 1.5
        color: root.colors ? root.colors.tertiary : Qt.rgba(1, 1, 1, 0.5)
      }
      SettingsInput { colors: root.colors; label: "Cell count";     value: Config.launchMosaicCells;      min: 8;  max: 200;  onCommit: function(v) { root._save("mosaicCells", v) } }
      SettingsInput { colors: root.colors; label: "Seed";           value: Config.launchMosaicSeed;       min: 0;  max: 999;  onCommit: function(v) { root._save("mosaicSeed", v) } }
      SettingsInput { colors: root.colors; label: "Relaxation";     value: Config.launchMosaicRelaxation; min: 0;  max: 8;    onCommit: function(v) { root._save("mosaicRelaxation", v) } }
      SettingsInput { colors: root.colors; label: "Total width";    value: Config.launchMosaicWidth;      min: 600; max: 3000; onCommit: function(v) { root._save("mosaicWidth", v) } }
      SettingsInput { colors: root.colors; label: "Total height";   value: Config.launchMosaicHeight;     min: 400; max: 1800; onCommit: function(v) { root._save("mosaicHeight", v) } }
    }

    Column {
      visible: root.activeCategory === "paths"
      width: parent.width
      spacing: 8 * Config.uiScale

      Text {
        text: "DIRECTORIES"
        font.family: Style.fontFamily; font.pixelSize: 13 * Config.uiScale; font.weight: Font.Bold; font.letterSpacing: 1.5
        color: root.colors ? root.colors.tertiary : Qt.rgba(1, 1, 1, 0.5)
      }

      SettingsTextInput {
        colors: root.colors
        label: "Splash art directory"
        value: Config.splashDir
        placeholder: "~/appsplash"
        onCommit: function(v) { root._saveRoot("paths.splash", v) }
      }
      SettingsTextInput {
        colors: root.colors
        label: "Steam directory"
        value: Config.steamDir
        placeholder: "~/.local/share/Steam"
        onCommit: function(v) { root._saveRoot("paths.steam", v) }
      }
      SettingsTextInput {
        colors: root.colors
        label: "Terminal"
        value: Config.terminal
        placeholder: "kitty"
        onCommit: function(v) { root._saveRoot("terminal", v) }
      }
    }

    Column {
      visible: root.activeCategory === "apps"
      width: parent.width
      spacing: 8 * Config.uiScale

      Text {
        text: "APP CUSTOMIZATION"
        font.family: Style.fontFamily; font.pixelSize: 13 * Config.uiScale; font.weight: Font.Bold; font.letterSpacing: 1.5
        color: root.colors ? root.colors.tertiary : Qt.rgba(1, 1, 1, 0.5)
      }

      Rectangle {
        width: parent.width
        height: 28
        radius: 4
        color: root.colors ? Qt.rgba(root.colors.surfaceContainer.r, root.colors.surfaceContainer.g, root.colors.surfaceContainer.b, 0.6) : Qt.rgba(0.15, 0.15, 0.2, 0.6)
        border.width: _appSearchInput.activeFocus ? 1 : 0
        border.color: root.colors ? Qt.rgba(root.colors.primary.r, root.colors.primary.g, root.colors.primary.b, 0.5) : Qt.rgba(1, 1, 1, 0.3)

        TextInput {
          id: _appSearchInput
          anchors.fill: parent
          anchors.leftMargin: 10
          anchors.rightMargin: 10
          verticalAlignment: TextInput.AlignVCenter
          font.family: Style.fontFamily
          font.pixelSize: 12
          color: root.colors ? root.colors.surfaceText : "#fff"
          clip: true
          selectByMouse: true
          onTextChanged: root._appQuery = text.toLowerCase()

          Text {
            anchors.fill: parent
            verticalAlignment: Text.AlignVCenter
            text: "Filter apps by name…"
            font: parent.font
            color: root.colors ? Qt.rgba(root.colors.surfaceText.r, root.colors.surfaceText.g, root.colors.surfaceText.b, 0.3) : Qt.rgba(1, 1, 1, 0.2)
            visible: !_appSearchInput.text && !_appSearchInput.activeFocus
          }
        }
      }

      Flickable {
        width: parent.width
        height: 320
        contentHeight: appList.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

        Column {
          id: appList
          width: parent.width
          spacing: 4

          Repeater {
            model: root._appCacheList

            delegate: AppEditorRow {
              colors: root.colors
              appName: model.name || ""
              displayName: model.displayName || ""
              backgroundPath: model.background || ""
              customIcon: model.customIcon || ""
              hidden: model.hidden || false
              tags: model.tags || ""
              width: appList.width
              visible: root._appQuery === "" || ((model.name || "").toLowerCase().indexOf(root._appQuery) !== -1)
              onSaveField: function(field, value) {
                root._saveAppField(model.name, field, value)
                root._reloadAppCache()
              }
              onBrowseRequested: root._openSplashPicker(model.name, model.background || "")
            }
          }
        }
      }
    }
  }

  ListModel { id: _splashModel }

  Process {
    id: _splashLister
    function refresh() {
      _splashModel.clear()
      command = ["sh", "-c",
        "DIR=" + JSON.stringify(root._pickerDir) + "; " +
        "[ -d \"$DIR\" ] || exit 0; " +
        "find \"$DIR\" -mindepth 1 -maxdepth 1 -type d -printf 'D\\t%f\\t%p\\n' 2>/dev/null | sort -k2; " +
        "find \"$DIR\" -mindepth 1 -maxdepth 1 -type f " +
        "\\( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' -o -iname '*.avif' \\) " +
        "-printf 'F\\t%f\\t%p\\n' 2>/dev/null | sort -k2"
      ]
      running = true
    }
    stdout: SplitParser {
      onRead: line => {
        var trimmed = line.trim()
        if (!trimmed) return
        var parts = trimmed.split("\t")
        if (parts.length < 3) return
        _splashModel.append({ kind: parts[0], name: parts[1], path: parts[2] })
      }
    }
  }

  Rectangle {
    id: _splashPicker
    visible: false
    parent: root
    anchors.fill: parent
    z: 200
    color: root.colors ? Qt.rgba(root.colors.surface.r, root.colors.surface.g, root.colors.surface.b, 0.97) : Qt.rgba(0.05, 0.05, 0.08, 0.97)
    radius: 12

    MouseArea { anchors.fill: parent; onClicked: function(mouse) { mouse.accepted = true } }

    Column {
      anchors.fill: parent
      anchors.margins: 16
      spacing: 10

      Row {
        width: parent.width
        spacing: 8

        Text {
          text: "SELECT SPLASH FOR " + (root._picking || "").toUpperCase()
          font.family: Style.fontFamily; font.pixelSize: 13; font.weight: Font.Bold; font.letterSpacing: 1.5
          color: root.colors ? root.colors.primary : "#ffb4ab"
          anchors.verticalCenter: parent.verticalCenter
        }

        Item { width: parent.width - 240; height: 1 }

        Row {
          spacing: 4
          FilterButton {
            colors: root.colors
            label: "REFRESH"
            skew: 8; height: 22
            onClicked: _splashLister.refresh()
          }
          FilterButton {
            colors: root.colors
            label: "CLEAR"
            skew: 8; height: 22
            onClicked: root._selectSplash("")
          }
          FilterButton {
            colors: root.colors
            label: "CANCEL"
            skew: 8; height: 22
            onClicked: root._closeSplashPicker()
          }
        }
      }

      Row {
        width: parent.width
        spacing: 6

        FilterButton {
          colors: root.colors
          label: "↑ UP"
          skew: 8; height: 22
          onClicked: root._navigateUp()
        }

        FilterButton {
          colors: root.colors
          label: "~/appsplash"
          skew: 8; height: 22
          isActive: root._pickerDir === Config.splashDir
          onClicked: root._navigateTo(Config.splashDir)
        }

        FilterButton {
          colors: root.colors
          label: "~"
          skew: 8; height: 22
          isActive: root._pickerDir === Config.homeDir
          onClicked: root._navigateTo(Config.homeDir)
        }

        Text {
          anchors.verticalCenter: parent.verticalCenter
          text: root._pickerDir + "  ·  " + _splashModel.count + " items"
          font.family: Style.fontFamily; font.pixelSize: 10
          color: root.colors ? Qt.rgba(root.colors.surfaceText.r, root.colors.surfaceText.g, root.colors.surfaceText.b, 0.6) : Qt.rgba(1, 1, 1, 0.4)
          elide: Text.ElideMiddle
        }
      }

      GridView {
        width: parent.width
        height: parent.height - 80
        cellWidth: 180
        cellHeight: 130
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        model: _splashModel

        delegate: Rectangle {
          width: 172
          height: 122
          radius: 4
          property bool isDir: kind === "D"
          color: _spMouse.containsMouse
            ? (root.colors ? Qt.rgba(root.colors.primary.r, root.colors.primary.g, root.colors.primary.b, 0.2) : Qt.rgba(1, 1, 1, 0.15))
            : (root.colors ? Qt.rgba(root.colors.surfaceContainer.r, root.colors.surfaceContainer.g, root.colors.surfaceContainer.b, 0.6) : Qt.rgba(0.1, 0.12, 0.18, 0.85))
          border.width: !isDir && root._pickingCurrent === path ? 2 : 1
          border.color: !isDir && root._pickingCurrent === path
            ? (root.colors ? root.colors.primary : "#ffb4ab")
            : (root.colors ? Qt.rgba(root.colors.outline.r, root.colors.outline.g, root.colors.outline.b, 0.3) : Qt.rgba(1, 1, 1, 0.1))

          Text {
            visible: isDir
            anchors.centerIn: parent
            anchors.verticalCenterOffset: -8
            text: "\u{f024b}"
            font.family: Style.fontFamilyNerdIcons
            font.pixelSize: 48
            color: root.colors ? root.colors.tertiary : "#8bceff"
          }

          Image {
            visible: !isDir
            anchors.fill: parent
            anchors.margins: 4
            anchors.bottomMargin: 22
            source: !isDir ? "file://" + path : ""
            fillMode: Image.PreserveAspectFit
            asynchronous: true
            smooth: true
            sourceSize.width: 320
            sourceSize.height: 200
          }

          Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: 4
            height: 16
            color: Qt.rgba(0, 0, 0, 0.7)
            radius: 2
            Text {
              anchors.fill: parent
              anchors.leftMargin: 4
              anchors.rightMargin: 4
              verticalAlignment: Text.AlignVCenter
              text: name
              font.family: Style.fontFamily; font.pixelSize: 9
              color: "#fff"
              elide: Text.ElideMiddle
            }
          }

          MouseArea {
            id: _spMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
              if (isDir) root._navigateTo(path)
              else root._selectSplash(path)
            }
          }
        }
      }
    }
  }
}
