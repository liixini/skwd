import QtQuick
import ".."
import "../components"
import "../services"


Item {
  id: root
  property var colors
  property string activeCategory: "widgets"

  readonly property var categories: [
    { key: "widgets",       label: "WIDGETS" },
    { key: "layout",        label: "LAYOUT" },
    { key: "weather",       label: "WEATHER" },
    { key: "wifi",          label: "WIFI" },
    { key: "battery",       label: "BATTERY" },
    { key: "notifications", label: "NOTIFICATIONS" },
    { key: "music",         label: "MUSIC" }
  ]

  function _setBatteryRules(arr) { SettingsService.setPath("components.bar.battery.notify", arr) }
  function _addBatteryRule() {
    var arr = (Config.barBatteryNotifyRules || []).slice()
    arr.push({ percent: 20, onDischarge: true, onCharge: false })
    _setBatteryRules(arr)
  }
  function _updateBatteryRule(idx, patch) {
    var arr = JSON.parse(JSON.stringify(Config.barBatteryNotifyRules || []))
    if (idx < 0 || idx >= arr.length) return
    for (var k in patch) arr[idx][k] = patch[k]
    _setBatteryRules(arr)
  }
  function _removeBatteryRule(idx) {
    var arr = (Config.barBatteryNotifyRules || []).slice()
    if (idx < 0 || idx >= arr.length) return
    arr.splice(idx, 1)
    _setBatteryRules(arr)
  }

  function _saveLayout(side, arr) { SettingsService.setPath("components.bar." + side + "Layout", arr) }
  function _resetLayout() {
    _saveLayout("left",  Config._defaultBarLeftLayout)
    _saveLayout("right", Config._defaultBarRightLayout)
    SettingsService.setPath("components.bar.widgets", undefined)
  }
  function _move(side, fromIdx, toIdx) {
    var src = side === "left" ? Config.barLeftLayout.slice() : Config.barRightLayout.slice()
    if (fromIdx < 0 || fromIdx >= src.length) return
    if (toIdx < 0 || toIdx >= src.length) return
    if (fromIdx === toIdx) return
    var item = src.splice(fromIdx, 1)[0]
    src.splice(toIdx, 0, item)
    _saveLayout(side, src)
  }
  function _swapSide(fromSide, idx) {
    var src = fromSide === "left" ? Config.barLeftLayout.slice() : Config.barRightLayout.slice()
    var dst = fromSide === "left" ? Config.barRightLayout.slice() : Config.barLeftLayout.slice()
    if (idx < 0 || idx >= src.length) return
    var item = src.splice(idx, 1)[0]
    dst.push(item)
    _saveLayout(fromSide,                          src)
    _saveLayout(fromSide === "left" ? "right" : "left", dst)
  }

  function _missingWidgets() {
    var all = Config.allBarWidgets || []
    var present = (Config.barLeftLayout || []).concat(Config.barRightLayout || [])
    var out = []
    for (var i = 0; i < all.length; i++) if (present.indexOf(all[i]) === -1) out.push(all[i])
    return out
  }
  function _addToSide(id, side) {
    var arr = (side === "left" ? Config.barLeftLayout : Config.barRightLayout).slice()
    if (arr.indexOf(id) !== -1) return
    arr.push(id)
    _saveLayout(side, arr)
  }

  function _setWidgetOverride(id, field, value) {
    var data = JSON.parse(JSON.stringify(Config.barWidgetOverrides || {}))
    if (typeof data[id] !== "object" || data[id] === null) data[id] = {}
    if (value === "" || value === null || value === undefined) delete data[id][field]
    else data[id][field] = value
    if (Object.keys(data[id]).length === 0) delete data[id]
    SettingsService.setPath("components.bar.widgets", data)
  }

  property string _iconPickWidget: ""
  property string _iconPickCurrent: ""
  function _openIconPicker(id) {
    _iconPickWidget = id
    _iconPickCurrent = Config.barWidgetIconOverride(id)
    _iconPicker.visible = true
  }
  function _selectIcon(glyph) {
    if (_iconPickWidget) _setWidgetOverride(_iconPickWidget, "icon", glyph)
    _iconPicker.visible = false
    _iconPickWidget = ""
  }

  function _save(key, value) { SettingsService.setPath("components.bar." + key, value) }

  implicitHeight: _stack.implicitHeight

  Item {
    id: _stack
    width: parent.width
    implicitHeight: childrenRect.height

    
    Column {
      visible: root.activeCategory === "widgets"
      width: parent.width
      spacing: 8 * Config.uiScale

      Text {
        text: "ENABLED WIDGETS"
        font.family: Style.fontFamily; font.pixelSize: 13 * Config.uiScale; font.weight: Font.Bold; font.letterSpacing: 1.5
        color: root.colors ? root.colors.tertiary : Qt.rgba(1, 1, 1, 0.5)
      }

      SettingsToggle { colors: root.colors; label: "Bar enabled";        checked: Config.barEnabled;          onToggle: function(v) { root._save("enabled", v) } }
      SettingsToggle { colors: root.colors; label: "Calendar widget";    checked: Config.barCalendarEnabled;  onToggle: function(v) { root._save("calendar", v) } }
      SettingsToggle { colors: root.colors; label: "Volume widget";      checked: Config.barVolumeEnabled;    onToggle: function(v) { root._save("volume", v) } }
      SettingsToggle { colors: root.colors; label: "Bluetooth widget";   checked: Config.barBluetoothEnabled; onToggle: function(v) { root._save("bluetooth", v) } }
      SettingsToggle { colors: root.colors; label: "Wifi widget";        checked: Config.barWifiEnabled;      onToggle: function(v) { SettingsService.setPath("components.bar.wifi.enabled", v) } }
      SettingsToggle { colors: root.colors; label: "Weather widget";     checked: Config.barWeatherEnabled;   onToggle: function(v) { SettingsService.setPath("components.bar.weather.enabled", v) } }
      SettingsToggle { colors: root.colors; label: "Music widget";       checked: Config.barMusicEnabled;     onToggle: function(v) { SettingsService.setPath("components.bar.music.enabled", v) } }
      SettingsToggle { colors: root.colors; label: "Brightness widget";  checked: Config.barBrightnessEnabled; onToggle: function(v) { SettingsService.setPath("components.bar.brightness.enabled", v) } }
      SettingsToggle { colors: root.colors; label: "Battery widget";     checked: Config.barBatteryEnabled;   onToggle: function(v) { SettingsService.setPath("components.bar.battery.enabled", v) } }
      SettingsToggle { colors: root.colors; label: "Notification widget";  checked: Config.barNotificationsEnabled; onToggle: function(v) { SettingsService.setPath("components.bar.notifications.enabled", v) } }
      SettingsToggle { colors: root.colors; label: "Mouseover reveal";   checked: Config.barMouseoverEnabled; onToggle: function(v) { root._save("mouseoverEnabled", v) } }
    }


    Column {
      id: layoutSection
      visible: root.activeCategory === "layout"
      width: parent.width
      spacing: 8 * Config.uiScale

      Row {
        width: parent.width
        spacing: 8

        Text {
          text: "BAR LAYOUT"
          font.family: Style.fontFamily; font.pixelSize: 13 * Config.uiScale; font.weight: Font.Bold; font.letterSpacing: 1.5
          color: root.colors ? root.colors.tertiary : Qt.rgba(1, 1, 1, 0.5)
          anchors.verticalCenter: parent.verticalCenter
        }
        Item { width: Math.max(0, parent.width - 200); height: 1 }
        FilterButton {
          colors: root.colors
          label: "RESET"
          skew: 8; height: 22
          tooltip: "Restore default left/right layout"
          anchors.verticalCenter: parent.verticalCenter
          onClicked: root._resetLayout()
        }
      }

      Text {
        width: parent.width
        text: "Reorder widgets within a side with ↑/↓, send to the other side with ←/→."
        wrapMode: Text.WordWrap
        font.family: Style.fontFamily; font.pixelSize: 11 * Config.uiScale; font.italic: true
        color: root.colors ? Qt.rgba(root.colors.outline.r, root.colors.outline.g, root.colors.outline.b, 0.7) : Qt.rgba(1, 1, 1, 0.4)
      }

      Row {
        width: parent.width
        spacing: 12

        Column {
          id: leftCol
          width: (parent.width - 12) / 2
          spacing: 4

          Text {
            text: "LEFT"
            font.family: Style.fontFamily; font.pixelSize: 11 * Config.uiScale; font.weight: Font.Bold; font.letterSpacing: 1.2
            color: root.colors ? Qt.rgba(root.colors.surfaceText.r, root.colors.surfaceText.g, root.colors.surfaceText.b, 0.5) : Qt.rgba(1, 1, 1, 0.4)
          }

          Repeater {
            model: Config.barLeftLayout

            delegate: Rectangle {
              id: leftCard
              required property int index
              required property string modelData
              property string overrideIcon:  Config.barWidgetIconOverride(modelData)
              property string overrideLabel: Config.barWidgetLabelOverride(modelData)
              property bool mouseover:       Config.barWidgetMouseoverEnabled(modelData)
              property bool customizable: modelData !== "weather"

              width: leftCol.width
              height: cardCol.implicitHeight + 12
              radius: 4
              color: root.colors ? Qt.rgba(root.colors.surfaceContainer.r, root.colors.surfaceContainer.g, root.colors.surfaceContainer.b, 0.4) : Qt.rgba(0.1, 0.12, 0.18, 0.4)
              border.width: 1
              border.color: root.colors ? Qt.rgba(root.colors.outline.r, root.colors.outline.g, root.colors.outline.b, 0.15) : Qt.rgba(1, 1, 1, 0.06)

              Column {
                id: cardCol
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 6
                spacing: 4

                Row {
                  width: parent.width
                  spacing: 6

                  Text {
                    text: leftCard.overrideIcon !== "" ? leftCard.overrideIcon : (Config.barWidgetIcons[leftCard.modelData] || "")
                    font.family: Style.fontFamilyIcons; font.pixelSize: 16
                    color: root.colors ? root.colors.primary : "#ffb4ab"
                    anchors.verticalCenter: parent.verticalCenter
                  }
                  Text {
                    text: Config.barWidgetLabels[leftCard.modelData] || leftCard.modelData
                    font.family: Style.fontFamily; font.pixelSize: 12
                    color: root.colors ? root.colors.surfaceText : "#fff"
                    anchors.verticalCenter: parent.verticalCenter
                  }
                  Item { width: Math.max(0, parent.width - 200); height: 1 }
                  Row {
                    spacing: 2
                    anchors.verticalCenter: parent.verticalCenter
                    FilterButton { colors: root.colors; label: "↑"; skew: 4; height: 20; onClicked: root._move("left", leftCard.index, leftCard.index - 1) }
                    FilterButton { colors: root.colors; label: "↓"; skew: 4; height: 20; onClicked: root._move("left", leftCard.index, leftCard.index + 1) }
                    FilterButton { colors: root.colors; label: "→"; skew: 4; height: 20; tooltip: "Send to right"; onClicked: root._swapSide("left", leftCard.index) }
                  }
                }

                Row {
                  width: parent.width
                  spacing: 6
                  visible: leftCard.customizable

                  FilterButton {
                    colors: root.colors
                    label: "PICK"
                    skew: 6; height: 20
                    tooltip: "Override icon"
                    onClicked: root._openIconPicker(leftCard.modelData)
                  }
                  FilterButton {
                    colors: root.colors
                    label: "✕"; skew: 4; height: 20
                    tooltip: "Clear icon override"
                    visible: leftCard.overrideIcon !== ""
                    onClicked: root._setWidgetOverride(leftCard.modelData, "icon", "")
                  }
                  SettingsTextInput {
                    colors: root.colors
                    width: parent.width - 100
                    label: ""
                    value: leftCard.overrideLabel
                    placeholder: "label override (blank = live value)"
                    onCommit: function(v) { root._setWidgetOverride(leftCard.modelData, "label", v) }
                    anchors.verticalCenter: parent.verticalCenter
                  }
                }

                SettingsToggle {
                  width: parent.width
                  colors: root.colors
                  label: "Show only on bar mouseover"
                  checked: leftCard.mouseover
                  onToggle: function(v) { root._setWidgetOverride(leftCard.modelData, "mouseover", v) }
                }
              }
            }
          }

          Text {
            visible: Config.barLeftLayout.length === 0
            text: "no widgets on this side"
            font.family: Style.fontFamily; font.pixelSize: 11 * Config.uiScale; font.italic: true
            color: root.colors ? Qt.rgba(root.colors.outline.r, root.colors.outline.g, root.colors.outline.b, 0.5) : Qt.rgba(1, 1, 1, 0.3)
          }
        }

        Column {
          id: rightCol
          width: (parent.width - 12) / 2
          spacing: 4

          Text {
            text: "RIGHT"
            font.family: Style.fontFamily; font.pixelSize: 11 * Config.uiScale; font.weight: Font.Bold; font.letterSpacing: 1.2
            color: root.colors ? Qt.rgba(root.colors.surfaceText.r, root.colors.surfaceText.g, root.colors.surfaceText.b, 0.5) : Qt.rgba(1, 1, 1, 0.4)
          }

          Repeater {
            model: Config.barRightLayout

            delegate: Rectangle {
              id: rightCard
              required property int index
              required property string modelData
              property string overrideIcon:  Config.barWidgetIconOverride(modelData)
              property string overrideLabel: Config.barWidgetLabelOverride(modelData)
              property bool mouseover:       Config.barWidgetMouseoverEnabled(modelData)
              property bool customizable: modelData !== "weather"

              width: rightCol.width
              height: rightCardCol.implicitHeight + 12
              radius: 4
              color: root.colors ? Qt.rgba(root.colors.surfaceContainer.r, root.colors.surfaceContainer.g, root.colors.surfaceContainer.b, 0.4) : Qt.rgba(0.1, 0.12, 0.18, 0.4)
              border.width: 1
              border.color: root.colors ? Qt.rgba(root.colors.outline.r, root.colors.outline.g, root.colors.outline.b, 0.15) : Qt.rgba(1, 1, 1, 0.06)

              Column {
                id: rightCardCol
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 6
                spacing: 4

                Row {
                  width: parent.width
                  spacing: 6

                  Row {
                    spacing: 2
                    anchors.verticalCenter: parent.verticalCenter
                    FilterButton { colors: root.colors; label: "←"; skew: 4; height: 20; tooltip: "Send to left"; onClicked: root._swapSide("right", rightCard.index) }
                    FilterButton { colors: root.colors; label: "↑"; skew: 4; height: 20; onClicked: root._move("right", rightCard.index, rightCard.index - 1) }
                    FilterButton { colors: root.colors; label: "↓"; skew: 4; height: 20; onClicked: root._move("right", rightCard.index, rightCard.index + 1) }
                  }
                  Item { width: Math.max(0, parent.width - 200); height: 1 }
                  Text {
                    text: Config.barWidgetLabels[rightCard.modelData] || rightCard.modelData
                    font.family: Style.fontFamily; font.pixelSize: 12
                    color: root.colors ? root.colors.surfaceText : "#fff"
                    anchors.verticalCenter: parent.verticalCenter
                  }
                  Text {
                    text: rightCard.overrideIcon !== "" ? rightCard.overrideIcon : (Config.barWidgetIcons[rightCard.modelData] || "")
                    font.family: Style.fontFamilyIcons; font.pixelSize: 16
                    color: root.colors ? root.colors.primary : "#ffb4ab"
                    anchors.verticalCenter: parent.verticalCenter
                  }
                }

                Row {
                  width: parent.width
                  spacing: 6
                  visible: rightCard.customizable

                  FilterButton {
                    colors: root.colors
                    label: "PICK"
                    skew: 6; height: 20
                    tooltip: "Override icon"
                    onClicked: root._openIconPicker(rightCard.modelData)
                  }
                  FilterButton {
                    colors: root.colors
                    label: "✕"; skew: 4; height: 20
                    tooltip: "Clear icon override"
                    visible: rightCard.overrideIcon !== ""
                    onClicked: root._setWidgetOverride(rightCard.modelData, "icon", "")
                  }
                  SettingsTextInput {
                    colors: root.colors
                    width: parent.width - 100
                    label: ""
                    value: rightCard.overrideLabel
                    placeholder: "label override (blank = live value)"
                    onCommit: function(v) { root._setWidgetOverride(rightCard.modelData, "label", v) }
                    anchors.verticalCenter: parent.verticalCenter
                  }
                }

                SettingsToggle {
                  width: parent.width
                  colors: root.colors
                  label: "Show only on bar mouseover"
                  checked: rightCard.mouseover
                  onToggle: function(v) { root._setWidgetOverride(rightCard.modelData, "mouseover", v) }
                }
              }
            }
          }

          Text {
            visible: Config.barRightLayout.length === 0
            text: "no widgets on this side"
            font.family: Style.fontFamily; font.pixelSize: 11 * Config.uiScale; font.italic: true
            color: root.colors ? Qt.rgba(root.colors.outline.r, root.colors.outline.g, root.colors.outline.b, 0.5) : Qt.rgba(1, 1, 1, 0.3)
          }
        }
      }

      Column {
        width: parent.width
        spacing: 4
        visible: root._missingWidgets().length > 0

        Text {
          text: "AVAILABLE"
          font.family: Style.fontFamily; font.pixelSize: 11 * Config.uiScale; font.weight: Font.Bold; font.letterSpacing: 1.2
          color: root.colors ? Qt.rgba(root.colors.surfaceText.r, root.colors.surfaceText.g, root.colors.surfaceText.b, 0.5) : Qt.rgba(1, 1, 1, 0.4)
        }

        Flow {
          width: parent.width
          spacing: 6

          Repeater {
            model: root._missingWidgets()

            delegate: Rectangle {
              required property string modelData
              radius: 4
              height: 28 * Config.uiScale
              width: chipRow.implicitWidth + 16
              color: root.colors ? Qt.rgba(root.colors.surfaceContainer.r, root.colors.surfaceContainer.g, root.colors.surfaceContainer.b, 0.4) : Qt.rgba(0.1, 0.12, 0.18, 0.4)
              border.width: 1
              border.color: root.colors ? Qt.rgba(root.colors.outline.r, root.colors.outline.g, root.colors.outline.b, 0.15) : Qt.rgba(1, 1, 1, 0.06)

              Row {
                id: chipRow
                anchors.fill: parent
                anchors.leftMargin: 6
                anchors.rightMargin: 6
                spacing: 6

                Text {
                  text: Config.barWidgetIcons[parent.parent.modelData] || ""
                  font.family: Style.fontFamilyIcons; font.pixelSize: 14
                  color: root.colors ? root.colors.primary : "#ffb4ab"
                  anchors.verticalCenter: parent.verticalCenter
                }
                Text {
                  text: Config.barWidgetLabels[parent.parent.modelData] || parent.parent.modelData
                  font.family: Style.fontFamily; font.pixelSize: 11
                  color: root.colors ? root.colors.surfaceText : "#fff"
                  anchors.verticalCenter: parent.verticalCenter
                }
                FilterButton {
                  colors: root.colors
                  label: "← LEFT"; skew: 6; height: 20
                  onClicked: root._addToSide(parent.parent.modelData, "left")
                  anchors.verticalCenter: parent.verticalCenter
                }
                FilterButton {
                  colors: root.colors
                  label: "RIGHT →"; skew: 6; height: 20
                  onClicked: root._addToSide(parent.parent.modelData, "right")
                  anchors.verticalCenter: parent.verticalCenter
                }
              }
            }
          }
        }
      }
    }


    Column {
      id: weatherSection
      visible: root.activeCategory === "weather"
      width: parent.width
      spacing: 8 * Config.uiScale

      function saveCities(arr, def) {
        SettingsService.setPath("components.bar.weather.cities", arr)
        if (def !== undefined) SettingsService.setPath("components.bar.weather.defaultCity", def)
        SettingsService.setPath("components.bar.weather.city", undefined)
      }

      function addCity(name) {
        var v = (name || "").trim()
        if (!v) return
        var arr = (Config.barWeatherCities || []).slice()
        if (arr.indexOf(v) !== -1) return
        arr.push(v)
        var def = Config.barWeatherDefaultCity || v
        weatherSection.saveCities(arr, def)
      }

      function removeCity(name) {
        var arr = (Config.barWeatherCities || []).filter(function(c) { return c !== name })
        var def = Config.barWeatherDefaultCity
        if (def === name) def = arr.length > 0 ? arr[0] : ""
        weatherSection.saveCities(arr, def)
      }

      function setDefault(name) {
        SettingsService.setPath("components.bar.weather.defaultCity", name)
      }

      function moveCity(fromIdx, toIdx) {
        var arr = (Config.barWeatherCities || []).slice()
        if (fromIdx < 0 || fromIdx >= arr.length) return
        if (toIdx < 0 || toIdx >= arr.length) return
        if (fromIdx === toIdx) return
        var item = arr.splice(fromIdx, 1)[0]
        arr.splice(toIdx, 0, item)
        weatherSection.saveCities(arr)
      }

      Text {
        text: "WEATHER"
        font.family: Style.fontFamily; font.pixelSize: 13 * Config.uiScale; font.weight: Font.Bold; font.letterSpacing: 1.5
        color: root.colors ? root.colors.tertiary : Qt.rgba(1, 1, 1, 0.5)
      }

      Text {
        width: parent.width
        text: "Add cities to flip through in the bar dropdown. Heart one as the default - that's the city shown on startup."
        wrapMode: Text.WordWrap
        font.family: Style.fontFamily; font.pixelSize: 11 * Config.uiScale; font.italic: true
        color: root.colors ? Qt.rgba(root.colors.outline.r, root.colors.outline.g, root.colors.outline.b, 0.7) : Qt.rgba(1, 1, 1, 0.4)
      }

      Repeater {
        model: Config.barWeatherCities

        delegate: Rectangle {
          id: cityRow
          width: weatherSection.width
          height: 34 * Config.uiScale
          radius: 4
          color: rowMouse.containsMouse
            ? Qt.rgba(root.colors.primary.r, root.colors.primary.g, root.colors.primary.b, 0.06)
            : "transparent"
          border.width: 1
          border.color: Qt.rgba(root.colors.outline.r, root.colors.outline.g, root.colors.outline.b, 0.2)

          property bool isDefault: modelData === Config.barWeatherDefaultCity
          property bool canMoveUp: index > 0
          property bool canMoveDown: index < (Config.barWeatherCities || []).length - 1
          property int rowIndex: index

          MouseArea { id: rowMouse; anchors.fill: parent; hoverEnabled: true; acceptedButtons: Qt.NoButton }

          Column {
            id: orderBtns
            width: 16 * Config.uiScale
            anchors.left: parent.left
            anchors.leftMargin: 4 * Config.uiScale
            anchors.verticalCenter: parent.verticalCenter
            spacing: 0

            Item {
              width: parent.width
              height: 14 * Config.uiScale

              Text {
                anchors.centerIn: parent
                text: "▴"
                font.pixelSize: 12 * Config.uiScale
                color: !cityRow.canMoveUp
                  ? Qt.rgba(root.colors.outline.r, root.colors.outline.g, root.colors.outline.b, 0.2)
                  : (upMouse.containsMouse ? root.colors.primary : Qt.rgba(root.colors.outline.r, root.colors.outline.g, root.colors.outline.b, 0.7))
              }
              MouseArea {
                id: upMouse
                anchors.fill: parent
                anchors.margins: -2
                hoverEnabled: true
                enabled: cityRow.canMoveUp
                cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                onClicked: weatherSection.moveCity(cityRow.rowIndex, cityRow.rowIndex - 1)
              }
            }

            Item {
              width: parent.width
              height: 14 * Config.uiScale

              Text {
                anchors.centerIn: parent
                text: "▾"
                font.pixelSize: 12 * Config.uiScale
                color: !cityRow.canMoveDown
                  ? Qt.rgba(root.colors.outline.r, root.colors.outline.g, root.colors.outline.b, 0.2)
                  : (downMouse.containsMouse ? root.colors.primary : Qt.rgba(root.colors.outline.r, root.colors.outline.g, root.colors.outline.b, 0.7))
              }
              MouseArea {
                id: downMouse
                anchors.fill: parent
                anchors.margins: -2
                hoverEnabled: true
                enabled: cityRow.canMoveDown
                cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                onClicked: weatherSection.moveCity(cityRow.rowIndex, cityRow.rowIndex + 1)
              }
            }
          }

          Item {
            id: starBtn
            width: 22 * Config.uiScale
            height: 22 * Config.uiScale
            anchors.left: orderBtns.right
            anchors.leftMargin: 4 * Config.uiScale
            anchors.verticalCenter: parent.verticalCenter

            Text {
              anchors.centerIn: parent
              text: cityRow.isDefault ? "♥" : "♡"
              font.pixelSize: 16 * Config.uiScale
              color: cityRow.isDefault
                ? root.colors.primary
                : Qt.rgba(root.colors.outline.r, root.colors.outline.g, root.colors.outline.b, 0.5)
            }

            MouseArea {
              anchors.fill: parent
              anchors.margins: -4
              cursorShape: Qt.PointingHandCursor
              hoverEnabled: true
              onClicked: weatherSection.setDefault(modelData)
            }
          }

          Text {
            anchors.left: starBtn.right
            anchors.right: removeBtn.left
            anchors.leftMargin: 8 * Config.uiScale
            anchors.rightMargin: 8 * Config.uiScale
            anchors.verticalCenter: parent.verticalCenter
            text: modelData
            color: root.colors ? root.colors.surfaceText : "white"
            font.family: Style.fontFamily; font.pixelSize: 12 * Config.uiScale
            elide: Text.ElideRight
          }

          Item {
            id: removeBtn
            width: 22 * Config.uiScale
            height: 22 * Config.uiScale
            anchors.right: parent.right
            anchors.rightMargin: 6 * Config.uiScale
            anchors.verticalCenter: parent.verticalCenter

            Text {
              anchors.centerIn: parent
              text: "×"
              font.pixelSize: 16 * Config.uiScale
              color: removeMouse.containsMouse
                ? root.colors.error
                : Qt.rgba(root.colors.outline.r, root.colors.outline.g, root.colors.outline.b, 0.6)
            }

            MouseArea {
              id: removeMouse
              anchors.fill: parent
              anchors.margins: -2
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: weatherSection.removeCity(modelData)
            }
          }
        }
      }

      Row {
        width: parent.width
        spacing: 6 * Config.uiScale

        Rectangle {
          width: weatherSection.width - addBtn.width - parent.spacing
          height: 28 * Config.uiScale
          radius: 4
          color: Qt.rgba(root.colors.surfaceContainer.r, root.colors.surfaceContainer.g, root.colors.surfaceContainer.b, 0.6)
          border.width: addInput.activeFocus ? 1 : 0
          border.color: Qt.rgba(root.colors.primary.r, root.colors.primary.g, root.colors.primary.b, 0.5)

          TextInput {
            id: addInput
            anchors.fill: parent
            anchors.leftMargin: 8 * Config.uiScale
            anchors.rightMargin: 8 * Config.uiScale
            verticalAlignment: TextInput.AlignVCenter
            font.family: Style.fontFamilyCode
            font.pixelSize: 12 * Config.uiScale
            color: root.colors ? root.colors.surfaceText : "white"
            clip: true
            selectByMouse: true
            onAccepted: {
              weatherSection.addCity(text)
              text = ""
            }

            Text {
              anchors.fill: parent
              verticalAlignment: Text.AlignVCenter
              font: parent.font
              color: Qt.rgba(root.colors.surfaceText.r, root.colors.surfaceText.g, root.colors.surfaceText.b, 0.3)
              text: "e.g. Stockholm, SE"
              visible: !addInput.text && !addInput.activeFocus
            }
          }
        }

        Rectangle {
          id: addBtn
          width: 60 * Config.uiScale
          height: 28 * Config.uiScale
          radius: 4
          color: addMouse.containsMouse
            ? root.colors.primary
            : Qt.rgba(root.colors.primary.r, root.colors.primary.g, root.colors.primary.b, 0.85)

          Text {
            anchors.centerIn: parent
            text: "ADD"
            color: root.colors ? root.colors.surface : "black"
            font.family: Style.fontFamily; font.pixelSize: 11 * Config.uiScale
            font.weight: Font.Bold; font.letterSpacing: 0.5
          }

          MouseArea {
            id: addMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
              weatherSection.addCity(addInput.text)
              addInput.text = ""
            }
          }
        }
      }
    }

    
    Column {
      visible: root.activeCategory === "wifi"
      width: parent.width
      spacing: 8 * Config.uiScale

      Text {
        text: "WIFI"
        font.family: Style.fontFamily; font.pixelSize: 13 * Config.uiScale; font.weight: Font.Bold; font.letterSpacing: 1.5
        color: root.colors ? root.colors.tertiary : Qt.rgba(1, 1, 1, 0.5)
      }
      SettingsTextInput {
        colors: root.colors
        label: "Linux interface name"
        value: Config.barWifiInterface
        placeholder: "e.g. wlan0 — find yours with `iwctl station list`"
        onCommit: function(v) { SettingsService.setPath("components.bar.wifi.interface", v) }
      }
    }


    Column {
      id: batterySection
      visible: root.activeCategory === "battery"
      width: parent.width
      spacing: 8 * Config.uiScale

      Row {
        width: parent.width
        spacing: 8

        Text {
          text: "BATTERY NOTIFICATIONS"
          font.family: Style.fontFamily; font.pixelSize: 13 * Config.uiScale; font.weight: Font.Bold; font.letterSpacing: 1.5
          color: root.colors ? root.colors.tertiary : Qt.rgba(1, 1, 1, 0.5)
          anchors.verticalCenter: parent.verticalCenter
        }
      }

      Text {
        width: parent.width
        text: "Fire a notification when the battery passes through a percentage threshold. Discharge sends when crossing down, Charge when crossing up."
        wrapMode: Text.WordWrap
        font.family: Style.fontFamily; font.pixelSize: 11 * Config.uiScale; font.italic: true
        color: root.colors ? Qt.rgba(root.colors.outline.r, root.colors.outline.g, root.colors.outline.b, 0.7) : Qt.rgba(1, 1, 1, 0.4)
      }

      Repeater {
        model: Config.barBatteryNotifyRules

        delegate: Rectangle {
          id: ruleRow
          required property int index
          required property var modelData

          property int rulePercent:    (typeof modelData.percent === "number") ? modelData.percent : 20
          property bool ruleDischarge: modelData.onDischarge !== false
          property bool ruleCharge:    modelData.onCharge === true
          property string ruleMessage: (typeof modelData.message === "string") ? modelData.message : ""

          width: batterySection.width
          height: ruleCol.implicitHeight + 14
          radius: 4
          color: root.colors ? Qt.rgba(root.colors.surfaceContainer.r, root.colors.surfaceContainer.g, root.colors.surfaceContainer.b, 0.4) : Qt.rgba(0.1, 0.12, 0.18, 0.4)
          border.width: 1
          border.color: root.colors ? Qt.rgba(root.colors.outline.r, root.colors.outline.g, root.colors.outline.b, 0.15) : Qt.rgba(1, 1, 1, 0.06)

          Column {
            id: ruleCol
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 7
            spacing: 6

            Row {
              width: parent.width
              spacing: 8

              Text {
                text: ruleRow.rulePercent + "%"
                font.family: Style.fontFamily; font.pixelSize: 13 * Config.uiScale; font.weight: Font.Bold
                color: root.colors ? root.colors.primary : "#ffb4ab"
                width: 50
                anchors.verticalCenter: parent.verticalCenter
              }

              Row {
                spacing: 2
                anchors.verticalCenter: parent.verticalCenter
                FilterButton { colors: root.colors; label: "-"; skew: 4; height: 22; onClicked: root._updateBatteryRule(ruleRow.index, { percent: Math.max(1, ruleRow.rulePercent - 5) }) }
                FilterButton { colors: root.colors; label: "+"; skew: 4; height: 22; onClicked: root._updateBatteryRule(ruleRow.index, { percent: Math.min(100, ruleRow.rulePercent + 5) }) }
              }

              FilterButton {
                colors: root.colors
                label: "DISCHARGE"
                skew: 8; height: 22
                isActive: ruleRow.ruleDischarge
                tooltip: "Notify when battery drops through this %"
                onClicked: root._updateBatteryRule(ruleRow.index, { onDischarge: !ruleRow.ruleDischarge })
                anchors.verticalCenter: parent.verticalCenter
              }
              FilterButton {
                colors: root.colors
                label: "CHARGE"
                skew: 8; height: 22
                isActive: ruleRow.ruleCharge
                tooltip: "Notify when battery rises through this % while charging"
                onClicked: root._updateBatteryRule(ruleRow.index, { onCharge: !ruleRow.ruleCharge })
                anchors.verticalCenter: parent.verticalCenter
              }

              Item { width: Math.max(0, parent.width - 380); height: 1 }

              FilterButton {
                colors: root.colors
                label: "DEL"
                skew: 8; height: 22
                onClicked: root._removeBatteryRule(ruleRow.index)
                anchors.verticalCenter: parent.verticalCenter
              }
            }

            SettingsTextInput {
              colors: root.colors
              label: ""
              value: ruleRow.ruleMessage
              placeholder: "Custom message (blank for default). Tokens: {percent}, {threshold}, {state}"
              onCommit: function(v) { root._updateBatteryRule(ruleRow.index, { message: v }) }
            }
          }
        }
      }

      Rectangle {
        width: batterySection.width
        height: 32 * Config.uiScale
        radius: 4
        color: addRuleMouse.containsMouse
          ? Qt.rgba(root.colors.primary.r, root.colors.primary.g, root.colors.primary.b, 0.18)
          : Qt.rgba(root.colors.surfaceContainer.r, root.colors.surfaceContainer.g, root.colors.surfaceContainer.b, 0.4)
        border.width: 1
        border.color: addRuleMouse.containsMouse
          ? Qt.rgba(root.colors.primary.r, root.colors.primary.g, root.colors.primary.b, 0.5)
          : Qt.rgba(root.colors.outline.r, root.colors.outline.g, root.colors.outline.b, 0.2)
        Behavior on color { ColorAnimation { duration: Style.animFast } }
        Behavior on border.color { ColorAnimation { duration: Style.animFast } }

        Text {
          anchors.centerIn: parent
          text: "+ ADD THRESHOLD"
          font.family: Style.fontFamily; font.pixelSize: 11 * Config.uiScale
          font.weight: Font.Bold; font.letterSpacing: 0.8
          color: addRuleMouse.containsMouse
            ? root.colors.primary
            : Qt.rgba(root.colors.outline.r, root.colors.outline.g, root.colors.outline.b, 0.8)
        }

        MouseArea {
          id: addRuleMouse
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: root._addBatteryRule()
        }
      }
    }


    Column {
      visible: root.activeCategory === "notifications"
      width: parent.width
      spacing: 8 * Config.uiScale

      Text {
        text: "NOTIFICATION WIDGET"
        font.family: Style.fontFamily; font.pixelSize: 13 * Config.uiScale; font.weight: Font.Bold; font.letterSpacing: 1.5
        color: root.colors ? root.colors.tertiary : Qt.rgba(1, 1, 1, 0.5)
      }

      SettingsToggle {
        colors: root.colors
        label: "Hide widget when empty"
        checked: Config.barNotificationsHideWhenEmpty
        onToggle: function(v) { SettingsService.setPath("components.bar.notifications.hideWhenEmpty", v) }
      }
      SettingsToggle {
        colors: root.colors
        label: "Always show if notifications present"
        checked: Config.barNotificationsAlwaysShowIfPresent
        onToggle: function(v) { SettingsService.setPath("components.bar.notifications.alwaysShowIfPresent", v) }
      }
      SettingsInput {
        colors: root.colors
        label: "History size"
        value: Config.barNotificationsHistoryMax
        min: 5; max: 500
        onCommit: function(v) { SettingsService.setPath("components.bar.notifications.historyMax", v) }
      }
    }


    Column {
      visible: root.activeCategory === "music"
      width: parent.width
      spacing: 8 * Config.uiScale

      Text {
        text: "MUSIC WIDGET"
        font.family: Style.fontFamily; font.pixelSize: 13 * Config.uiScale; font.weight: Font.Bold; font.letterSpacing: 1.5
        color: root.colors ? root.colors.tertiary : Qt.rgba(1, 1, 1, 0.5)
      }
      SettingsToggle { colors: root.colors; label: "Auto-hide when nothing's playing"; checked: Config.barMusicAutohide; onToggle: function(v) { SettingsService.setPath("components.bar.music.autohide", v) } }
      SettingsToggle { colors: root.colors; label: "Show artist & track";              checked: Config.barMusicShowMeta;  onToggle: function(v) { SettingsService.setPath("components.bar.music.showMeta", v) } }
      SettingsToggle { colors: root.colors; label: "Show lyrics";                       checked: Config.barMusicShowLyrics; onToggle: function(v) { SettingsService.setPath("components.bar.music.showLyrics", v) } }
      SettingsToggle { colors: root.colors; label: "Reveal controls on hover even when paused"; checked: Config.barMusicAlwaysHoverable; onToggle: function(v) { SettingsService.setPath("components.bar.music.alwaysHoverable", v) } }
      SettingsToggle { colors: root.colors; label: "Clean visualizer (hide lyrics/track)";       checked: Config.barMusicCleanVisualizer; onToggle: function(v) { SettingsService.setPath("components.bar.music.cleanVisualizer", v) } }
      SettingsToggle { colors: root.colors; label: "Display lyrics retrieval status";            checked: Config.barMusicShowLyricsStatus; onToggle: function(v) { SettingsService.setPath("components.bar.music.showLyricsStatus", v) } }

      Text {
        text: "VISUALIZER"
        font.family: Style.fontFamily; font.pixelSize: 13 * Config.uiScale; font.weight: Font.Bold; font.letterSpacing: 1.5
        color: root.colors ? root.colors.tertiary : Qt.rgba(1, 1, 1, 0.5)
      }

      SettingsDropdown {
        colors: root.colors
        label: "Theme"
        value: Config.barMusicVisualizer
        model: [
          { mode: "wave",              label: "Wave" },
          { mode: "bars",              label: "Bars" },
          { mode: "neon",              label: "Neon" },
          { mode: "pulse",             label: "Pulse" },
          { mode: "vu",                label: "VU" },
          { mode: "spectrogram",       label: "Spectrogram" },
          { mode: "stardust",          label: "Stardust" },
          { mode: "liquid",            label: "Liquid" },
          { mode: "ripple",            label: "Ripple" },
          { mode: "zigzag",            label: "Zigzag" },
          { mode: "metaballs",         label: "Metaballs" },
          { mode: "comet",             label: "Comet" },
          { mode: "aurora",            label: "Aurora" },
          { mode: "aurora-responsive", label: "Aurora Responsive" },
          { mode: "spectrum",          label: "Spectrum" },
          { mode: "off",               label: "Off" }
        ]
        onSelect: function(v) { SettingsService.setPath("components.bar.music.visualizer", v) }
      }

      Column {
        visible: Config.barMusicVisualizer === "aurora"
        width: parent.width
        spacing: 4
        SettingsInput  { colors: root.colors; label: "Layer count";          value: Config.vizAuroraLayerCount; min: 1;  max: 8;  onCommit: function(v) { SettingsService.setPath("components.bar.music.viz.aurora.layerCount", v) } }
        SettingsSlider { colors: root.colors; label: "Outer layer min %";    value: Math.round(Config.vizAuroraMinAmp * 100); min: 5; max: 95; onChange: function(v) { SettingsService.setPath("components.bar.music.viz.aurora.minAmp", v / 100) } }
      }

      Column {
        visible: Config.barMusicVisualizer === "aurora-responsive"
        width: parent.width
        spacing: 4
        SettingsInput  { colors: root.colors; label: "Layer count";          value: Config.vizAuroraLayerCount; min: 1;  max: 8;  onCommit: function(v) { SettingsService.setPath("components.bar.music.viz.aurora.layerCount", v) } }
        SettingsSlider { colors: root.colors; label: "Outer layer min %";    value: Math.round(Config.vizAuroraMinAmp * 100);       min: 5;  max: 95;  onChange: function(v) { SettingsService.setPath("components.bar.music.viz.aurora.minAmp", v / 100) } }
        SettingsSlider { colors: root.colors; label: "Pump curve (lower = sharper, x100)"; value: Math.round(Config.vizAuroraRespPumpExp * 100); min: 15; max: 120; onChange: function(v) { SettingsService.setPath("components.bar.music.viz.auroraResponsive.pumpExp", v / 100) } }
        SettingsSlider { colors: root.colors; label: "Pump scale (x100)";    value: Math.round(Config.vizAuroraRespPumpScale * 100); min: 50; max: 300; onChange: function(v) { SettingsService.setPath("components.bar.music.viz.auroraResponsive.pumpScale", v / 100) } }
        SettingsSlider { colors: root.colors; label: "Attack speed (x100)";  value: Math.round(Config.vizAuroraRespAttack * 100);    min: 5;  max: 100; onChange: function(v) { SettingsService.setPath("components.bar.music.viz.auroraResponsive.attack", v / 100) } }
        SettingsSlider { colors: root.colors; label: "Decay speed (x100)";   value: Math.round(Config.vizAuroraRespDecay * 100);     min: 2;  max: 50;  onChange: function(v) { SettingsService.setPath("components.bar.music.viz.auroraResponsive.decay", v / 100) } }
      }

      Column {
        visible: Config.barMusicVisualizer === "pulse"
        width: parent.width
        spacing: 4
        SettingsInput { colors: root.colors; label: "Pill width (px)"; value: Config.vizPulsePillWidth; min: 1; max: 12; onCommit: function(v) { SettingsService.setPath("components.bar.music.viz.pulse.pillWidth", v) } }
      }

      Column {
        visible: Config.barMusicVisualizer === "vu"
        width: parent.width
        spacing: 4
        SettingsSlider { colors: root.colors; label: "Peak decay (x10)"; value: Math.round(Config.vizVuPeakDecay * 10); min: 2; max: 60; onChange: function(v) { SettingsService.setPath("components.bar.music.viz.vu.peakDecay", v / 10) } }
      }

      Column {
        visible: Config.barMusicVisualizer === "spectrogram"
        width: parent.width
        spacing: 4
        SettingsInput { colors: root.colors; label: "History columns"; value: Config.vizSpectrogramCols; min: 20; max: 200; onCommit: function(v) { SettingsService.setPath("components.bar.music.viz.spectrogram.cols", v) } }
      }

      Column {
        visible: Config.barMusicVisualizer === "stardust"
        width: parent.width
        spacing: 4
        SettingsInput { colors: root.colors; label: "Star count"; value: Config.vizStardustCount; min: 10; max: 200; onCommit: function(v) { SettingsService.setPath("components.bar.music.viz.stardust.count", v) } }
      }

      Column {
        visible: Config.barMusicVisualizer === "comet"
        width: parent.width
        spacing: 4
        SettingsInput { colors: root.colors; label: "Trail length"; value: Config.vizCometTrailLen; min: 4; max: 80; onCommit: function(v) { SettingsService.setPath("components.bar.music.viz.comet.trailLen", v) } }
      }

      Column {
        visible: Config.barMusicVisualizer === "ripple"
        width: parent.width
        spacing: 4
        SettingsSlider { colors: root.colors; label: "Bass spike threshold (x100)"; value: Math.round(Config.vizRippleThreshold * 100); min: 105; max: 300; onChange: function(v) { SettingsService.setPath("components.bar.music.viz.ripple.threshold", v / 100) } }
        SettingsInput  { colors: root.colors; label: "Ripple lifetime";              value: Config.vizRippleMaxAge;    min: 8; max: 120; onCommit: function(v) { SettingsService.setPath("components.bar.music.viz.ripple.maxAge", v) } }
      }

      SettingsToggle { colors: root.colors; label: "Render visualizer above"; checked: Config.barMusicVisualizerTop;    onToggle: function(v) { SettingsService.setPath("components.bar.music.visualizerTop", v) } }
      SettingsToggle { colors: root.colors; label: "Render visualizer below"; checked: Config.barMusicVisualizerBottom; onToggle: function(v) { SettingsService.setPath("components.bar.music.visualizerBottom", v) } }
    }
  }

  IconPicker {
    id: _iconPicker
    parent: root
    anchors.fill: parent
    z: 200
    visible: false
    colors: root.colors
    currentGlyph: root._iconPickCurrent
    onIconSelected: function(glyph) { root._selectIcon(glyph) }
    onCancelled: { _iconPicker.visible = false; root._iconPickWidget = "" }
  }
}
