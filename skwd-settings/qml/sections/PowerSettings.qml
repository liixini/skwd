import QtQuick
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

  implicitHeight: _stack.implicitHeight

  Item {
    id: _stack
    width: parent.width
    implicitHeight: childrenRect.height

    Column {
      id: itemsSection
      visible: root.activeCategory === "items"
      width: parent.width
      spacing: 8 * Config.uiScale

      Row {
        width: parent.width
        spacing: 8

        Text {
          text: "POWER MENU ITEMS"
          font.family: Style.fontFamily; font.pixelSize: 13 * Config.uiScale; font.weight: Font.Bold; font.letterSpacing: 1.5
          color: root.colors ? root.colors.tertiary : Qt.rgba(1, 1, 1, 0.5)
          anchors.verticalCenter: parent.verticalCenter
        }

        Item { width: Math.max(0, parent.width - 200); height: 1 }

        FilterButton {
          colors: root.colors
          label: "RESET"
          skew: 8; height: 22
          tooltip: "Restore the default Lock / Logout / Reboot / Poweroff items"
          anchors.verticalCenter: parent.verticalCenter
          onClicked: root._resetDefaults()
        }
      }

      Text {
        width: parent.width
        text: "Pick a built-in action or choose Custom and supply your own command. Disabled items are hidden from the menu."
        wrapMode: Text.WordWrap
        font.family: Style.fontFamily; font.pixelSize: 11 * Config.uiScale; font.italic: true
        color: root.colors ? Qt.rgba(root.colors.outline.r, root.colors.outline.g, root.colors.outline.b, 0.7) : Qt.rgba(1, 1, 1, 0.4)
      }

      Repeater {
        model: Config.powerOptions

        delegate: Rectangle {
          id: itemRow
          required property int index
          required property var modelData

          property string itemLabel:   modelData.label   || ""
          property string itemIcon:    modelData.icon    || ""
          property string itemAction:  modelData.action  || ""
          property string itemCommand: modelData.command || ""
          property bool   itemEnabled: modelData.enabled !== false

          width: itemsSection.width
          height: rowContent.implicitHeight + 14
          radius: 4
          color: root.colors ? Qt.rgba(root.colors.surfaceContainer.r, root.colors.surfaceContainer.g, root.colors.surfaceContainer.b, 0.4) : Qt.rgba(0.1, 0.12, 0.18, 0.4)
          border.width: 1
          border.color: root.colors ? Qt.rgba(root.colors.outline.r, root.colors.outline.g, root.colors.outline.b, 0.15) : Qt.rgba(1, 1, 1, 0.06)
          opacity: itemRow.itemEnabled ? 1.0 : 0.55

          Column {
            id: rowContent
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 7
            spacing: 6

            Row {
              width: parent.width
              spacing: 8

              Rectangle {
                width: 32; height: 32; radius: 4
                color: root.colors ? Qt.rgba(root.colors.surfaceContainer.r, root.colors.surfaceContainer.g, root.colors.surfaceContainer.b, 0.8) : Qt.rgba(0.1, 0.12, 0.18, 0.8)
                border.width: 1
                border.color: root.colors ? Qt.rgba(root.colors.primary.r, root.colors.primary.g, root.colors.primary.b, 0.25) : Qt.rgba(1, 1, 1, 0.15)
                anchors.verticalCenter: parent.verticalCenter

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
                font.family: Style.fontFamily; font.pixelSize: 10 * Config.uiScale; font.weight: Font.Bold; font.letterSpacing: 1.0
                color: root.colors ? Qt.rgba(root.colors.surfaceText.r, root.colors.surfaceText.g, root.colors.surfaceText.b, 0.5) : Qt.rgba(1, 1, 1, 0.35)
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

      Rectangle {
        width: itemsSection.width
        height: 32 * Config.uiScale
        radius: 4
        color: addItemMouse.containsMouse
          ? Qt.rgba(root.colors.primary.r, root.colors.primary.g, root.colors.primary.b, 0.18)
          : Qt.rgba(root.colors.surfaceContainer.r, root.colors.surfaceContainer.g, root.colors.surfaceContainer.b, 0.4)
        border.width: 1
        border.color: addItemMouse.containsMouse
          ? Qt.rgba(root.colors.primary.r, root.colors.primary.g, root.colors.primary.b, 0.5)
          : Qt.rgba(root.colors.outline.r, root.colors.outline.g, root.colors.outline.b, 0.2)
        Behavior on color { ColorAnimation { duration: Style.animFast } }
        Behavior on border.color { ColorAnimation { duration: Style.animFast } }

        Text {
          anchors.centerIn: parent
          text: "+ ADD ITEM"
          font.family: Style.fontFamily; font.pixelSize: 11 * Config.uiScale
          font.weight: Font.Bold; font.letterSpacing: 0.8
          color: addItemMouse.containsMouse
            ? root.colors.primary
            : Qt.rgba(root.colors.outline.r, root.colors.outline.g, root.colors.outline.b, 0.8)
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
