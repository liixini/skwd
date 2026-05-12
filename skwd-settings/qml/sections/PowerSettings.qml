import QtQuick
import QtQuick.Shapes
import ".."
import "../components"
import "../services"


Item {
  id: root
  property var colors
  property string activeCategory: "items"

  readonly property var categories: [
    { key: "items", label: "ITEMS" }
  ]

  readonly property var _knownActions: [
    { key: "",         label: "Custom",   cmd: "" },
    { key: "lock",     label: "Lock",     cmd: "loginctl lock-session" },
    { key: "logout",   label: "Logout",   cmd: "__wm_quit__" },
    { key: "reboot",   label: "Reboot",   cmd: "systemctl reboot" },
    { key: "poweroff", label: "Poweroff", cmd: "systemctl poweroff" },
    { key: "suspend",  label: "Suspend",  cmd: "systemctl suspend" },
    { key: "hibernate",label: "Hibernate",cmd: "systemctl hibernate" }
  ]

  function _actionCmd(key) {
    for (var a = 0; a < _knownActions.length; a++) {
      if (_knownActions[a].key === key) return _knownActions[a].cmd
    }
    return ""
  }

  function _options() {
    var src = Config.powerOptions
    return Array.isArray(src) ? JSON.parse(JSON.stringify(src)) : []
  }
  function _saveOptions(arr) { SettingsService.setPath("power.options", arr) }

  function _updateItem(i, patch) {
    var arr = _options()
    if (i < 0 || i >= arr.length) return
    var entry = arr[i] || {}
    for (var k in patch) {
      if (patch[k] === undefined || patch[k] === null || patch[k] === "") delete entry[k]
      else entry[k] = patch[k]
    }
    arr[i] = entry
    _saveOptions(arr)
  }

  function _moveItem(i, delta) {
    var arr = _options()
    var j = i + delta
    if (i < 0 || i >= arr.length || j < 0 || j >= arr.length) return
    var tmp = arr[i]; arr[i] = arr[j]; arr[j] = tmp
    _saveOptions(arr)
  }

  function _removeItem(i) {
    var arr = _options()
    if (i < 0 || i >= arr.length) return
    arr.splice(i, 1)
    _saveOptions(arr)
  }

  function _addItem() {
    var arr = _options()
    arr.push({ label: "New", icon: "", action: "lock", enabled: true })
    _saveOptions(arr)
  }

  function _resetDefaults() {
    _saveOptions(Config._powerDefaults)
  }

  property int _iconPickIndex: -1
  property string _iconPickCurrent: ""
  function _openIconPicker(i, currentGlyph) {
    _iconPickIndex = i
    _iconPickCurrent = currentGlyph
    _iconPicker.visible = true
  }
  function _selectIcon(glyph) {
    if (_iconPickIndex >= 0) _updateItem(_iconPickIndex, { icon: glyph })
    _iconPicker.visible = false
    _iconPickIndex = -1
  }

  implicitHeight: itemsSection.implicitHeight

  Column {
    id: itemsSection
    width: parent.width
    spacing: 14 * Config.uiScale

    SettingsCard {
      colors: root.colors
      title: "Power menu items"
      subtitle: "Pick a built-in action or choose Custom and supply your own command. Disabled items are hidden from the menu."
      titleAction: FilterButton {
        colors: root.colors
        label: "RESET"
        skew: 8; height: 22
        tooltip: "Restore the default Lock / Logout / Reboot / Poweroff items"
        onClicked: root._resetDefaults()
      }

      Column {
        width: parent.width
        spacing: 8

        Repeater {
          model: Config.powerOptions

          delegate: Item {
            id: itemRow
            required property int index
            required property var modelData

            property string itemLabel:   modelData.label   || ""
            property string itemIcon:    modelData.icon    || ""
            property string itemAction:  modelData.action  || ""
            property string itemCommand: modelData.command || ""
            property bool   itemEnabled: modelData.enabled !== false
            readonly property int _ch: 8

            width: parent.width
            height: rowContent.implicitHeight + 16
            opacity: itemRow.itemEnabled ? 1.0 : 0.55

            Shape {
              anchors.fill: parent
              antialiasing: true
              preferredRendererType: Shape.CurveRenderer
              layer.enabled: true
              layer.samples: 4
              layer.smooth: true
              ShapePath {
                fillColor: root.colors ? Qt.rgba(root.colors.surfaceContainer.r, root.colors.surfaceContainer.g, root.colors.surfaceContainer.b, 0.55) : Qt.rgba(0.1, 0.12, 0.18, 0.55)
                strokeColor: root.colors ? Qt.rgba(root.colors.outline.r, root.colors.outline.g, root.colors.outline.b, 0.22) : Qt.rgba(1, 1, 1, 0.08)
                strokeWidth: 1
                startX: itemRow._ch; startY: 0
                PathLine { x: itemRow.width;               y: 0 }
                PathLine { x: itemRow.width;               y: itemRow.height - itemRow._ch }
                PathLine { x: itemRow.width - itemRow._ch; y: itemRow.height }
                PathLine { x: 0;                            y: itemRow.height }
                PathLine { x: 0;                            y: itemRow._ch }
                PathLine { x: itemRow._ch;                  y: 0 }
              }
            }

            Column {
              id: rowContent
              anchors.left: parent.left
              anchors.right: parent.right
              anchors.top: parent.top
              anchors.leftMargin: 12
              anchors.rightMargin: 12
              anchors.topMargin: 8
              spacing: 6

              Row {
                width: parent.width
                spacing: 8

                Item {
                  id: iconBox
                  width: 32; height: 32
                  readonly property int _ch: 5
                  anchors.verticalCenter: parent.verticalCenter

                  Shape {
                    anchors.fill: parent
                    antialiasing: true
                    preferredRendererType: Shape.CurveRenderer
                    layer.enabled: true
                    layer.samples: 4
                    layer.smooth: true
                    ShapePath {
                      fillColor: root.colors ? Qt.rgba(root.colors.surfaceContainer.r, root.colors.surfaceContainer.g, root.colors.surfaceContainer.b, 0.85) : Qt.rgba(0.1, 0.12, 0.18, 0.85)
                      strokeColor: root.colors ? Qt.rgba(root.colors.primary.r, root.colors.primary.g, root.colors.primary.b, 0.3) : Qt.rgba(1, 1, 1, 0.15)
                      strokeWidth: 1
                      startX: iconBox._ch; startY: 0
                      PathLine { x: iconBox.width;               y: 0 }
                      PathLine { x: iconBox.width;               y: iconBox.height - iconBox._ch }
                      PathLine { x: iconBox.width - iconBox._ch; y: iconBox.height }
                      PathLine { x: 0;                            y: iconBox.height }
                      PathLine { x: 0;                            y: iconBox._ch }
                      PathLine { x: iconBox._ch;                  y: 0 }
                    }
                  }

                  Text {
                    anchors.centerIn: parent
                    text: itemRow.itemIcon
                    font.family: Style.fontFamilyIcons
                    font.pixelSize: 18
                    color: root.colors ? root.colors.primary : "#ffb4ab"
                    visible: itemRow.itemIcon !== ""
                  }
                  Text {
                    anchors.centerIn: parent
                    text: "?"
                    font.pixelSize: 14
                    color: root.colors ? Qt.rgba(root.colors.surfaceText.r, root.colors.surfaceText.g, root.colors.surfaceText.b, 0.3) : Qt.rgba(1, 1, 1, 0.2)
                    visible: itemRow.itemIcon === ""
                  }
                }

                FilterButton {
                  colors: root.colors
                  label: "PICK"
                  skew: 8; height: 22
                  anchors.verticalCenter: parent.verticalCenter
                  onClicked: root._openIconPicker(itemRow.index, itemRow.itemIcon)
                }

                SettingsTextInput {
                  colors: root.colors
                  label: ""
                  value: itemRow.itemLabel
                  placeholder: "Label"
                  width: 180
                  onCommit: function(v) { root._updateItem(itemRow.index, { label: v }) }
                  anchors.verticalCenter: parent.verticalCenter
                }

                Item { width: Math.max(0, parent.width - 470); height: 1 }

                Row {
                  spacing: 4
                  anchors.verticalCenter: parent.verticalCenter

                  FilterButton {
                    colors: root.colors
                    label: "↑"
                    skew: 4; height: 22
                    onClicked: root._moveItem(itemRow.index, -1)
                  }
                  FilterButton {
                    colors: root.colors
                    label: "↓"
                    skew: 4; height: 22
                    onClicked: root._moveItem(itemRow.index, 1)
                  }
                  FilterButton {
                    colors: root.colors
                    label: "DEL"
                    skew: 8; height: 22
                    onClicked: root._removeItem(itemRow.index)
                  }
                }
              }

              Row {
                width: parent.width
                spacing: 8

                Text {
                  text: "ACTION"
                  font.family: Style.fontFamily; font.pixelSize: 10 * Config.uiScale; font.weight: Font.Bold; font.letterSpacing: 0.8
                  color: root.colors ? root.colors.tertiary : Qt.rgba(1, 1, 1, 0.35)
                  anchors.verticalCenter: parent.verticalCenter
                }

                Row {
                  spacing: -4
                  anchors.verticalCenter: parent.verticalCenter

                  Repeater {
                    model: root._knownActions

                    delegate: FilterButton {
                      required property var modelData
                      colors: root.colors
                      label: modelData.label
                      skew: 8; height: 22
                      isActive: itemRow.itemAction === modelData.key
                      onClicked: root._updateItem(itemRow.index, { action: modelData.key || null })
                    }
                  }
                }
              }

              Row {
                width: parent.width
                spacing: 8

                SettingsTextInput {
                  colors: root.colors
                  label: "Custom command"
                  value: itemRow.itemCommand
                  placeholder: itemRow.itemAction
                    ? "(uses built-in: " + root._actionCmd(itemRow.itemAction) + ")"
                    : "e.g. systemctl suspend"
                  width: parent.width - 110
                  onCommit: function(v) { root._updateItem(itemRow.index, { command: v }) }
                }

                SettingsToggle {
                  width: 100
                  colors: root.colors
                  label: "Enabled"
                  checked: itemRow.itemEnabled
                  onToggle: function(v) { root._updateItem(itemRow.index, { enabled: v }) }
                }
              }
            }
          }
        }

        Item {
          id: addItemBox
          width: parent.width
          height: 32 * Config.uiScale
          readonly property int _ch: 7

          Shape {
            anchors.fill: parent
            antialiasing: true
            preferredRendererType: Shape.CurveRenderer
            layer.enabled: true
            layer.samples: 4
            layer.smooth: true
            ShapePath {
              fillColor: addItemMouse.containsMouse
                ? Qt.rgba(root.colors.primary.r, root.colors.primary.g, root.colors.primary.b, 0.18)
                : Qt.rgba(root.colors.surfaceContainer.r, root.colors.surfaceContainer.g, root.colors.surfaceContainer.b, 0.45)
              strokeColor: addItemMouse.containsMouse
                ? Qt.rgba(root.colors.primary.r, root.colors.primary.g, root.colors.primary.b, 0.55)
                : Qt.rgba(root.colors.outline.r, root.colors.outline.g, root.colors.outline.b, 0.22)
              strokeWidth: 1
              startX: addItemBox._ch; startY: 0
              PathLine { x: addItemBox.width;                  y: 0 }
              PathLine { x: addItemBox.width;                  y: addItemBox.height - addItemBox._ch }
              PathLine { x: addItemBox.width - addItemBox._ch; y: addItemBox.height }
              PathLine { x: 0;                                  y: addItemBox.height }
              PathLine { x: 0;                                  y: addItemBox._ch }
              PathLine { x: addItemBox._ch;                     y: 0 }
            }
          }

          Text {
            anchors.centerIn: parent
            text: "+ ADD ITEM"
            font.family: Style.fontFamily; font.pixelSize: 10 * Config.uiScale
            font.weight: Font.Bold; font.letterSpacing: 0.8
            color: addItemMouse.containsMouse
              ? root.colors.primary
              : (root.colors ? root.colors.tertiary : Qt.rgba(1, 1, 1, 0.7))
          }

          MouseArea {
            id: addItemMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root._addItem()
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
    currentGlyph: root._iconPickCurrent
    onIconSelected: function(glyph) { root._selectIcon(glyph) }
    onCancelled: { _iconPicker.visible = false; root._iconPickIndex = -1 }
  }
}
