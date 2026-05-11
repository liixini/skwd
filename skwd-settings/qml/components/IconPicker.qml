import Quickshell.Io
import QtQuick
import QtQuick.Controls
import ".."

Rectangle {
  id: root

  property var colors
  property string currentGlyph: ""

  signal iconSelected(string glyph)
  signal cancelled()

  color: root.colors ? Qt.rgba(root.colors.surface.r, root.colors.surface.g, root.colors.surface.b, 0.97) : Qt.rgba(0.05, 0.05, 0.08, 0.97)
  radius: 12

  property var _allIcons: []
  property var _filteredModel: ListModel { id: _filteredModel }
  property string _searchText: ""
  property bool _generating: false
  property string _generateError: ""

  FileView {
    id: _userIconDataFile
    path: Config.mdiIconsPath
    preload: true
    watchChanges: true
    onLoaded: root._loadIcons()
    onFileChanged: { _userIconDataFile.reload() }
  }

  FileView {
    id: _systemIconDataFile
    path: Config.mdiIconsSystemPath
    preload: true
    onLoaded: root._loadIcons()
  }

  Process {
    id: _generator
    command: ["skwd", "gen-icons", "--output", Config.mdiIconsPath]
    onExited: function(exitCode) {
      root._generating = false
      if (exitCode === 0) {
        _userIconDataFile.reload()
      } else {
        root._generateError = "icon cache generation failed (exit " + exitCode + ")"
      }
    }
  }

  function _tryParse(text) {
    if (!text || !text.trim()) return false
    try {
      var arr = JSON.parse(text)
      if (!Array.isArray(arr) || arr.length === 0) return false
      _allIcons = arr
      _generateError = ""
      _rebuildFiltered()
      return true
    } catch (e) {
      return false
    }
  }

  function _loadIcons() {
    if (_tryParse(_userIconDataFile.text())) return
    if (_tryParse(_systemIconDataFile.text())) return
    _ensureIconData()
  }

  function _ensureIconData() {
    if (_generating) return
    _generating = true
    _generateError = ""
    _generator.running = true
  }

  function _rebuildFiltered() {
    _filteredModel.clear()
    var q = _searchText.toLowerCase()
    for (var i = 0; i < _allIcons.length; i++) {
      var item = _allIcons[i]
      if (!q || item.n.indexOf(q) >= 0) {
        _filteredModel.append({ name: item.n, glyph: item.g })
      }
    }
  }

  onVisibleChanged: {
    if (visible) {
      _searchInput.text = ""
      _searchInput.forceActiveFocus()
      if (_allIcons.length === 0) {
        _userIconDataFile.reload()
        _systemIconDataFile.reload()
      } else {
        _rebuildFiltered()
      }
    }
  }

  MouseArea { anchors.fill: parent; onClicked: function(mouse) { mouse.accepted = true } }

  Column {
    anchors.fill: parent
    anchors.margins: 16
    spacing: 10

    Row {
      width: parent.width
      spacing: 8

      Text {
        text: "ICON PICKER"
        font.family: Style.fontFamily; font.pixelSize: 13; font.weight: Font.Bold; font.letterSpacing: 1.5
        color: root.colors ? root.colors.primary : "#ffb4ab"
        anchors.verticalCenter: parent.verticalCenter
      }

      Rectangle {
        width: 280
        height: 26
        radius: 4
        color: root.colors ? Qt.rgba(root.colors.surfaceContainer.r, root.colors.surfaceContainer.g, root.colors.surfaceContainer.b, 0.6) : Qt.rgba(0.15, 0.15, 0.2, 0.6)
        border.width: _searchInput.activeFocus ? 1 : 0
        border.color: root.colors ? Qt.rgba(root.colors.primary.r, root.colors.primary.g, root.colors.primary.b, 0.5) : Qt.rgba(1, 1, 1, 0.3)
        anchors.verticalCenter: parent.verticalCenter

        TextInput {
          id: _searchInput
          anchors.fill: parent
          anchors.leftMargin: 10; anchors.rightMargin: 10
          verticalAlignment: TextInput.AlignVCenter
          font.family: Style.fontFamily
          font.pixelSize: 12
          color: root.colors ? root.colors.surfaceText : "#fff"
          clip: true
          selectByMouse: true
          onTextChanged: {
            root._searchText = text.trim().toLowerCase()
            root._rebuildFiltered()
          }

          Text {
            anchors.fill: parent
            verticalAlignment: Text.AlignVCenter
            text: "search icons by name..."
            font: parent.font
            color: root.colors ? Qt.rgba(root.colors.surfaceText.r, root.colors.surfaceText.g, root.colors.surfaceText.b, 0.3) : Qt.rgba(1, 1, 1, 0.2)
            visible: !parent.text && !parent.activeFocus
          }
        }
      }

      Item { width: parent.width - 580; height: 1 }

      Row {
        spacing: 4
        FilterButton {
          colors: root.colors
          label: "CLEAR"
          skew: 8; height: 22
          onClicked: root.iconSelected("")
        }
        FilterButton {
          colors: root.colors
          label: "CANCEL"
          skew: 8; height: 22
          onClicked: root.cancelled()
        }
      }
    }

    Text {
      text: root._generating
        ? "generating icon cache..."
        : root._generateError
            ? root._generateError
            : (_filteredModel.count + " icons" + (root._searchText ? " matching \"" + root._searchText + "\"" : ""))
      font.family: Style.fontFamily; font.pixelSize: 10
      color: root.colors ? Qt.rgba(root.colors.surfaceText.r, root.colors.surfaceText.g, root.colors.surfaceText.b, 0.5) : Qt.rgba(1, 1, 1, 0.4)
    }

    GridView {
      width: parent.width
      height: parent.height - 64
      cellWidth: 52
      cellHeight: 52
      clip: true
      boundsBehavior: Flickable.StopAtBounds
      ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
      model: _filteredModel

      delegate: Rectangle {
        width: 48; height: 48
        radius: 6
        color: _cellMouse.containsMouse
          ? (root.colors ? Qt.rgba(root.colors.primary.r, root.colors.primary.g, root.colors.primary.b, 0.25) : Qt.rgba(1, 1, 1, 0.15))
          : (model.glyph === root.currentGlyph
              ? (root.colors ? Qt.rgba(root.colors.primary.r, root.colors.primary.g, root.colors.primary.b, 0.18) : Qt.rgba(1, 1, 1, 0.1))
              : (root.colors ? Qt.rgba(root.colors.surfaceVariant.r, root.colors.surfaceVariant.g, root.colors.surfaceVariant.b, 0.2) : Qt.rgba(1, 1, 1, 0.05)))
        border.width: model.glyph === root.currentGlyph ? 1 : (_cellMouse.containsMouse ? 1 : 0)
        border.color: root.colors ? Qt.rgba(root.colors.primary.r, root.colors.primary.g, root.colors.primary.b, 0.5) : Qt.rgba(1, 1, 1, 0.25)

        Text {
          anchors.centerIn: parent
          anchors.verticalCenterOffset: -6
          text: model.glyph
          font.family: Style.fontFamilyIcons
          font.pixelSize: 22
          color: _cellMouse.containsMouse
            ? (root.colors ? root.colors.primary : "#ffb4ab")
            : (root.colors ? root.colors.surfaceText : "#ddd")
        }

        Text {
          anchors.horizontalCenter: parent.horizontalCenter
          anchors.bottom: parent.bottom
          anchors.bottomMargin: 3
          text: {
            var parts = model.name.split(" ")
            return parts[0].length > 8 ? parts[0].substring(0, 7) + "…" : parts[0]
          }
          font.family: Style.fontFamily
          font.pixelSize: 7
          color: root.colors ? Qt.rgba(root.colors.surfaceText.r, root.colors.surfaceText.g, root.colors.surfaceText.b, 0.35) : Qt.rgba(1, 1, 1, 0.25)
        }

        MouseArea {
          id: _cellMouse
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor

          ToolTip {
            visible: _cellMouse.containsMouse
            text: model.name
            delay: 400
          }

          onClicked: root.iconSelected(model.glyph)
        }
      }
    }
  }
}
