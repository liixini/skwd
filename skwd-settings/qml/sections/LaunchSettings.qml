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
    { key: "filters",   label: "FILTERS" },
    { key: "paths",     label: "PATHS" },
    { key: "apps",      label: "APPS" }
  ]

  function _filters() {
    var src = Config.launchFilters
    return Array.isArray(src) ? JSON.parse(JSON.stringify(src)) : []
  }
  function _saveFilters(arr) { SettingsService.setPath("components.appLauncher.filters", arr) }
  function _updateFilter(i, patch) {
    var arr = _filters()
    if (i < 0 || i >= arr.length) return
    var entry = arr[i] || {}
    for (var k in patch) {
      if (patch[k] === undefined || patch[k] === null) delete entry[k]
      else entry[k] = patch[k]
    }
    arr[i] = entry
    _saveFilters(arr)
  }
  function _moveFilter(i, delta) {
    var arr = _filters()
    var j = i + delta
    if (i < 0 || i >= arr.length || j < 0 || j >= arr.length) return
    var tmp = arr[i]; arr[i] = arr[j]; arr[j] = tmp
    _saveFilters(arr)
  }
  function _removeFilter(i) {
    var arr = _filters()
    if (i < 0 || i >= arr.length) return
    arr.splice(i, 1)
    _saveFilters(arr)
  }
  function _addFilter() {
    var arr = _filters()
    var n = arr.length
    arr.push({ key: "filter" + (n + 1), icon: "?", label: "New", type: "all", value: "" })
    _saveFilters(arr)
  }
  function _resetFilters() { _saveFilters(Config._launchFilterDefaults) }

  property int _filterIconIdx: -1
  function _openFilterIconPicker(i, currentGlyph) {
    _filterIconIdx = i
    _iconPickingCurrent = currentGlyph
    _iconPicker.visible = true
  }

  function _save(key, value) { SettingsService.setPath("components.appLauncher." + key, value) }
  function _saveRoot(path, value) { SettingsService.setPath(path, value) }

  property bool _keep16x9: false
  property bool _keepGrid16x9: false
  property int  _sliceRatioX: 16
  property int  _sliceRatioY: 9
  property int  _gridRatioX:  16
  property int  _gridRatioY:  9

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
    if (_picking) {
      _saveAppField(_picking, "background", path)
      _reloadAppCache()
    }
    _closeSplashPicker()
  }

  property string _iconPickingApp: ""
  property string _iconPickingCurrent: ""
  function _openIconPicker(appName, currentGlyph) {
    _iconPickingApp = appName
    _iconPickingCurrent = currentGlyph
    _iconPicker.visible = true
  }
  function _closeIconPicker() { _iconPicker.visible = false; _iconPickingApp = ""; _filterIconIdx = -1 }
  function _selectIcon(glyph) {
    if (_filterIconIdx >= 0) {
      _updateFilter(_filterIconIdx, { icon: glyph })
    } else if (_iconPickingApp) {
      _saveAppField(_iconPickingApp, "icon", glyph)
      _reloadAppCache()
    }
    _closeIconPicker()
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

  property var _appsData: ({})

  property var _appsConfigFile: FileView {
    path: Config.appsConfigPath
    preload: true
    watchChanges: true
    onLoaded: {
      root._appsData = root._parseAppsConfig()
      root._reloadAppCache()
    }
    onFileChanged: reload()
  }

  function _parseAppsConfig() {
    try { return JSON.parse(_appsConfigFile.text() || "{}") } catch(e) { return {} }
  }

  function _saveAppField(appName, field, value) {
    var data = JSON.parse(JSON.stringify(root._appsData || {}))
    var key = appName.toLowerCase()
    if (typeof data[key] !== "object" || data[key] === null) data[key] = {}
    var isEmpty = (value === "" || value === false || value === null || value === undefined)
    if (isEmpty) {
      delete data[key][field]
    } else {
      data[key][field] = value
    }
    root._appsData = data
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
    var apps = root._appsData || {}
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
            useDesktopIcon: override.useDesktopIcon === true,
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
        if (existing.displayName    !== r.displayName)    _appCacheList.setProperty(u, "displayName",    r.displayName)
        if (existing.background     !== r.background)     _appCacheList.setProperty(u, "background",     r.background)
        if (existing.customIcon     !== r.customIcon)     _appCacheList.setProperty(u, "customIcon",     r.customIcon)
        if (existing.useDesktopIcon !== r.useDesktopIcon) _appCacheList.setProperty(u, "useDesktopIcon", r.useDesktopIcon)
        if (existing.hidden         !== r.hidden)         _appCacheList.setProperty(u, "hidden",         r.hidden)
        if (existing.tags           !== r.tags)           _appCacheList.setProperty(u, "tags",           r.tags)
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
      spacing: 14 * Config.uiScale

      SettingsCard {
        colors: root.colors
        title: "Display mode"
        RowDropdown {
          colors: root.colors
          title: "Layout style"
          description: "Shape of the app launcher: angled Slices, honeycomb Hex grid, or a grid of Wall thumbs."
          value: Config.launchDisplayMode
          model: [
            { mode: "slice", label: "Slices" },
            { mode: "hex",   label: "Hex" },
            { mode: "wall",  label: "Wall" }
          ]
          onSelect: function(v) { root._save("displayMode", v) }
        }
      }
    }

    Column {
      visible: root.activeCategory === "presets"
      width: parent.width
      spacing: 14 * Config.uiScale

      SettingsCard {
        visible: Config.launchDisplayMode === "slice"
        colors: root.colors
        title: "Size presets"
        SettingsRow {
          colors: root.colors
          title: "Quick sizes"
          description: "Snap slice geometry to common 16:9 dimensions."
          Row {
            spacing: -4
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
        }
      }

      SettingsCard {
        colors: root.colors
        title: "Custom slots"
        SettingsRow {
          colors: root.colors
          title: "Saved slots"
          description: "Click an empty slot to save the current size. Click a filled slot to apply. Right-click to overwrite."
          Row {
            spacing: -4
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
      }
    }

    Column {
      visible: root.activeCategory === "slice"
      width: parent.width
      spacing: 14 * Config.uiScale

      LauncherSlicePreview { colors: root.colors }

      SettingsCard {
        colors: root.colors
        title: "Slice geometry"
        RowToggle {
          colors: root.colors
          title: "Lock aspect ratio"
          description: "Keep Selected width and Height in a fixed X:Y ratio. Changing one updates the other."
          checked: root._keep16x9
          onToggle: function(v) {
            root._keep16x9 = v
            if (v && root._sliceRatioX > 0) root._save("sliceHeight", Math.round(Config.launchExpandedWidth * root._sliceRatioY / root._sliceRatioX))
          }
        }
        RowInput {
          colors: root.colors
          visible: root._keep16x9
          title: "Ratio: width"
          description: "First number of the locked ratio."
          value: root._sliceRatioX
          min: 1; max: 9999
          onCommit: function(v) {
            root._sliceRatioX = v
            if (v > 0) root._save("sliceHeight", Math.round(Config.launchExpandedWidth * root._sliceRatioY / v))
          }
        }
        RowInput {
          colors: root.colors
          visible: root._keep16x9
          title: "Ratio: height"
          description: "Second number of the locked ratio."
          value: root._sliceRatioY
          min: 1; max: 9999
          onCommit: function(v) {
            root._sliceRatioY = v
            if (root._sliceRatioX > 0) root._save("sliceHeight", Math.round(Config.launchExpandedWidth * v / root._sliceRatioX))
          }
        }
        RowInput { colors: root.colors; title: "Slice width";    value: Config.launchSliceWidth;    min: 0; max: 9999; onCommit: function(v) { root._save("sliceWidth", v) } }
        RowInput {
          colors: root.colors
          title: "Selected width"
          value: Config.launchExpandedWidth
          min: 0; max: 9999
          onCommit: function(v) {
            root._save("expandedWidth", v)
            if (root._keep16x9 && root._sliceRatioX > 0) root._save("sliceHeight", Math.round(v * root._sliceRatioY / root._sliceRatioX))
          }
        }
        RowInput {
          colors: root.colors
          title: "Height"
          value: Config.launchSliceHeight
          min: 0; max: 9999
          onCommit: function(v) {
            root._save("sliceHeight", v)
            if (root._keep16x9 && root._sliceRatioY > 0) root._save("expandedWidth", Math.round(v * root._sliceRatioX / root._sliceRatioY))
          }
        }
        RowInput { colors: root.colors; title: "Skew";          value: Config.launchSkewOffset;    min: -9999; max: 9999; onCommit: function(v) { root._save("skewOffset", v) } }
        RowInput { colors: root.colors; title: "Gap";           value: Config.launchSliceSpacing;  min: -9999; max: 9999; onCommit: function(v) { root._save("sliceSpacing", v) } }
        RowInput { colors: root.colors; title: "Visible items"; value: Config.launchVisibleCount;  min: 1; max: 999; onCommit: function(v) { root._save("visibleCount", v) } }
      }

      SettingsCard {
        colors: root.colors
        title: "Rounded corners"
        RowToggle {
          colors: root.colors
          title: "Round corners"
          description: "Soften slice edges with rounded corners."
          checked: Config.launchSliceRoundCorners
          onToggle: function(v) { root._save("roundCorners", v) }
        }
        RowInput {
          colors: root.colors
          title: "Radius"
          value: Config.launchSliceCornerRadius
          min: 0; max: 9999
          onCommit: function(v) { root._save("cornerRadius", v) }
        }
      }
    }

    Column {
      visible: root.activeCategory === "hex"
      width: parent.width
      spacing: 14 * Config.uiScale

      LauncherHexPreview { colors: root.colors }

      SettingsCard {
        colors: root.colors
        title: "Hex geometry"
        RowInput { colors: root.colors; title: "Radius";      value: Config.launchHexRadius;     min: 0; max: 9999; onCommit: function(v) { root._save("hexRadius", v) } }
        RowInput { colors: root.colors; title: "Rows";        value: Config.launchHexRows;       min: 1; max: 999;  onCommit: function(v) { root._save("hexRows", v) } }
        RowInput { colors: root.colors; title: "Columns";     value: Config.launchHexCols;       min: 1; max: 999;  onCommit: function(v) { root._save("hexCols", v) } }
        RowInput { colors: root.colors; title: "Scroll step"; value: Config.launchHexScrollStep; min: 1; max: 999;  onCommit: function(v) { root._save("hexScrollStep", v) } }
      }

      SettingsCard {
        colors: root.colors
        title: "Arc effect"
        RowToggle {
          colors: root.colors
          title: "Enable arc"
          description: "Curve the hex grid into an arc shape rather than a flat plane."
          checked: Config.launchHexArc
          onToggle: function(v) { root._save("hexArc", v) }
        }
        RowInput {
          colors: root.colors
          title: "Arc intensity"
          value: Math.round(Config.launchHexArcIntensity * 100)
          min: 0; max: 9999
          suffix: "%"
          onCommit: function(v) { root._save("hexArcIntensity", v / 100.0) }
        }
      }
    }

    Column {
      visible: root.activeCategory === "grid"
      width: parent.width
      spacing: 14 * Config.uiScale

      LauncherGridPreview { colors: root.colors }

      SettingsCard {
        colors: root.colors
        title: "Grid geometry"
        RowToggle {
          colors: root.colors
          title: "Lock aspect ratio"
          description: "Keep Thumb width and Thumb height in a fixed X:Y ratio."
          checked: root._keepGrid16x9
          onToggle: function(v) {
            root._keepGrid16x9 = v
            if (v && root._gridRatioX > 0) root._save("gridThumbHeight", Math.round(Config.launchGridThumbWidth * root._gridRatioY / root._gridRatioX))
          }
        }
        RowInput {
          colors: root.colors
          visible: root._keepGrid16x9
          title: "Ratio: width"
          description: "First number of the locked ratio."
          value: root._gridRatioX
          min: 1; max: 9999
          onCommit: function(v) {
            root._gridRatioX = v
            if (v > 0) root._save("gridThumbHeight", Math.round(Config.launchGridThumbWidth * root._gridRatioY / v))
          }
        }
        RowInput {
          colors: root.colors
          visible: root._keepGrid16x9
          title: "Ratio: height"
          description: "Second number of the locked ratio."
          value: root._gridRatioY
          min: 1; max: 9999
          onCommit: function(v) {
            root._gridRatioY = v
            if (root._gridRatioX > 0) root._save("gridThumbHeight", Math.round(Config.launchGridThumbWidth * v / root._gridRatioX))
          }
        }
        RowInput { colors: root.colors; title: "Columns"; value: Config.launchGridColumns; min: 1; max: 999; onCommit: function(v) { root._save("gridColumns", v) } }
        RowInput { colors: root.colors; title: "Rows";    value: Config.launchGridRows;    min: 1; max: 999; onCommit: function(v) { root._save("gridRows", v) } }
        RowInput {
          colors: root.colors
          title: "Thumb width"
          value: Config.launchGridThumbWidth
          min: 0; max: 9999
          onCommit: function(v) {
            root._save("gridThumbWidth", v)
            if (root._keepGrid16x9 && root._gridRatioX > 0) root._save("gridThumbHeight", Math.round(v * root._gridRatioY / root._gridRatioX))
          }
        }
        RowInput {
          colors: root.colors
          title: "Thumb height"
          value: Config.launchGridThumbHeight
          min: 0; max: 9999
          onCommit: function(v) {
            root._save("gridThumbHeight", v)
            if (root._keepGrid16x9 && root._gridRatioY > 0) root._save("gridThumbWidth", Math.round(v * root._gridRatioX / root._gridRatioY))
          }
        }
      }
    }

    Column {
      id: filtersSection
      visible: root.activeCategory === "filters"
      width: parent.width
      spacing: 14 * Config.uiScale

      SettingsCard {
        colors: root.colors
        title: "Quick filters"
        subtitle: "Buttons at the top of the launcher to narrow the app list. \"all\" shows everything; \"source\" matches the entry's source (desktop/steam); \"category\" matches a substring in its .desktop Categories; \"tag\" matches a tag you've set in the Apps editor."
        titleAction: FilterButton {
          colors: root.colors
          label: "RESET"
          skew: 8; height: 22
          tooltip: "Restore the default All / Apps / Games / Steam filters"
          onClicked: root._resetFilters()
        }
      }

      Repeater {
        model: Config.launchFilters

        delegate: SettingsCard {
          id: filterCard
          required property int index
          required property var modelData
          colors: root.colors

          property string fKey:   modelData.key   || ""
          property string fIcon:  modelData.icon  || ""
          property string fLabel: modelData.label || ""
          property string fType:  modelData.type  || "all"
          property string fValue: modelData.value || ""

          SettingsRow {
            colors: root.colors
            title: filterCard.fLabel || "(unnamed)"
            description: filterCard.fType === "all" ? "Matches every app." : (filterCard.fType + ": " + (filterCard.fValue || "(blank)"))

            Row {
              spacing: 6

              Rectangle {
                width: 28; height: 28; radius: 4
                color: root.colors ? Qt.rgba(root.colors.surfaceContainer.r, root.colors.surfaceContainer.g, root.colors.surfaceContainer.b, 0.8) : Qt.rgba(0.1, 0.12, 0.18, 0.8)
                border.width: 1
                border.color: root.colors ? Qt.rgba(root.colors.primary.r, root.colors.primary.g, root.colors.primary.b, 0.25) : Qt.rgba(1, 1, 1, 0.15)
                anchors.verticalCenter: parent.verticalCenter

                Text {
                  anchors.centerIn: parent
                  text: filterCard.fIcon || "?"
                  font.family: Style.fontFamilyIcons
                  font.pixelSize: 16
                  color: root.colors ? root.colors.primary : "#ffb4ab"
                  opacity: filterCard.fIcon === "" ? 0.3 : 1.0
                }
              }
              FilterButton { colors: root.colors; label: "PICK"; skew: 8; height: 22; anchors.verticalCenter: parent.verticalCenter; onClicked: root._openFilterIconPicker(filterCard.index, filterCard.fIcon) }
              FilterButton { colors: root.colors; label: "↑";   skew: 4; height: 22; anchors.verticalCenter: parent.verticalCenter; onClicked: root._moveFilter(filterCard.index, -1) }
              FilterButton { colors: root.colors; label: "↓";   skew: 4; height: 22; anchors.verticalCenter: parent.verticalCenter; onClicked: root._moveFilter(filterCard.index, 1)  }
              FilterButton { colors: root.colors; label: "DEL"; skew: 8; height: 22; anchors.verticalCenter: parent.verticalCenter; onClicked: root._removeFilter(filterCard.index)   }
            }
          }

          RowTextInput {
            colors: root.colors
            title: "Label"
            description: "Tooltip shown when hovering the filter button."
            value: filterCard.fLabel
            placeholder: "Apps"
            onCommit: function(v) { root._updateFilter(filterCard.index, { label: v }) }
          }

          RowTextInput {
            colors: root.colors
            title: "Key"
            description: "Stable identifier saved in config; must be unique."
            value: filterCard.fKey
            placeholder: "desktop"
            onCommit: function(v) { root._updateFilter(filterCard.index, { key: v }) }
          }

          RowDropdown {
            colors: root.colors
            title: "Match type"
            description: "What attribute of each app this filter checks."
            value: filterCard.fType
            model: [
              { mode: "all",      label: "All - matches everything" },
              { mode: "source",   label: "Source - desktop / steam" },
              { mode: "category", label: "Category - substring of .desktop Categories" },
              { mode: "tag",      label: "Tag - app tag from Apps editor" }
            ]
            onSelect: function(v) { root._updateFilter(filterCard.index, { type: v }) }
          }

          RowTextInput {
            colors: root.colors
            visible: filterCard.fType !== "all"
            title: "Match value"
            description: filterCard.fType === "source"   ? "Exact match against item.source."
                       : filterCard.fType === "category" ? "Substring inside .desktop Categories."
                       : filterCard.fType === "tag"      ? "Substring inside the app's tags."
                       : ""
            value: filterCard.fValue
            placeholder: filterCard.fType === "source"   ? "desktop"
                       : filterCard.fType === "category" ? "Game"
                       : filterCard.fType === "tag"      ? "fav"
                       : ""
            onCommit: function(v) { root._updateFilter(filterCard.index, { value: v }) }
          }
        }
      }

      Rectangle {
        width: filtersSection.width
        height: 32 * Config.uiScale
        radius: 8
        color: addFilterMouse.containsMouse
          ? Qt.rgba(root.colors.primary.r, root.colors.primary.g, root.colors.primary.b, 0.18)
          : Qt.rgba(root.colors.surfaceContainer.r, root.colors.surfaceContainer.g, root.colors.surfaceContainer.b, 0.4)
        border.width: 1
        border.color: addFilterMouse.containsMouse
          ? Qt.rgba(root.colors.primary.r, root.colors.primary.g, root.colors.primary.b, 0.5)
          : Qt.rgba(root.colors.outline.r, root.colors.outline.g, root.colors.outline.b, 0.2)
        Behavior on color { ColorAnimation { duration: Style.animFast } }
        Behavior on border.color { ColorAnimation { duration: Style.animFast } }

        Text {
          anchors.centerIn: parent
          text: "+ ADD FILTER"
          font.family: Style.fontFamily; font.pixelSize: 11 * Config.uiScale
          font.weight: Font.Bold; font.letterSpacing: 0.8
          color: addFilterMouse.containsMouse
            ? root.colors.primary
            : Qt.rgba(root.colors.outline.r, root.colors.outline.g, root.colors.outline.b, 0.8)
        }

        MouseArea {
          id: addFilterMouse
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: root._addFilter()
        }
      }
    }

    Column {
      visible: root.activeCategory === "paths"
      width: parent.width
      spacing: 14 * Config.uiScale

      SettingsCard {
        colors: root.colors
        title: "Directories"
        RowTextInput {
          colors: root.colors
          title: "Splash art directory"
          description: "Folder scanned for per-app splash images."
          value: Config.splashDir
          placeholder: "~/appsplash"
          onCommit: function(v) { root._saveRoot("paths.splash", v) }
        }
        RowTextInput {
          colors: root.colors
          title: "Steam directory"
          description: "Used for Wallpaper Engine and Steam game discovery."
          value: Config.steamDir
          placeholder: "~/.local/share/Steam"
          onCommit: function(v) { root._saveRoot("paths.steam", v) }
        }
        RowTextInput {
          colors: root.colors
          title: "Terminal"
          description: "Command run when launching terminal apps."
          value: Config.terminal
          placeholder: "kitty"
          onCommit: function(v) { root._saveRoot("terminal", v) }
        }
      }
    }

    Column {
      visible: root.activeCategory === "apps"
      width: parent.width
      spacing: 14 * Config.uiScale

      SectionTitle { text: "APP CUSTOMIZATION"; colors: root.colors }

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
            useDesktopIcon: model.useDesktopIcon || false
            hidden: model.hidden || false
            tags: model.tags || ""
            width: appList.width
            visible: root._appQuery === ""
              || ((model.name        || "").toLowerCase().indexOf(root._appQuery) !== -1)
              || ((model.displayName || "").toLowerCase().indexOf(root._appQuery) !== -1)
            onSaveField: function(field, value) {
              root._saveAppField(model.name, field, value)
              root._reloadAppCache()
            }
            onBrowseRequested: root._openSplashPicker(model.name, model.background || "")
            onIconPickRequested: root._openIconPicker(model.name, model.customIcon || "")
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

      Item {
        width: parent.width
        height: 24

        Text {
          text: "SELECT SPLASH FOR " + (root._picking || "").toUpperCase()
          font.family: Style.fontFamily; font.pixelSize: 13; font.weight: Font.Bold; font.letterSpacing: 1.5
          color: root.colors ? root.colors.primary : "#ffb4ab"
          anchors.left: parent.left
          anchors.right: splashHeaderActions.left
          anchors.rightMargin: 8
          anchors.verticalCenter: parent.verticalCenter
          elide: Text.ElideRight
        }

        Row {
          id: splashHeaderActions
          spacing: 4
          anchors.right: parent.right
          anchors.verticalCenter: parent.verticalCenter

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

  IconPicker {
    id: _iconPicker
    parent: root
    anchors.fill: parent
    z: 200
    visible: false
    colors: root.colors
    currentGlyph: root._iconPickingCurrent
    onIconSelected: function(glyph) { root._selectIcon(glyph) }
    onCancelled: root._closeIconPicker()
  }
}
