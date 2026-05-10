import QtQuick
import ".."
import "../components"

Item {
  id: row

  property var colors
  property string appName: ""
  property string displayName: ""
  property string backgroundPath: ""
  property string customIcon: ""
  property bool hidden: false
  property string tags: ""

  property bool _expanded: false

  signal saveField(string field, var value)
  signal browseRequested()

  height: _header.height + (_expanded ? _editor.height + 12 : 0)
  Behavior on height { NumberAnimation { duration: Style.animFast; easing.type: Easing.OutCubic } }
  clip: true

  Rectangle {
    id: _header
    width: parent.width
    height: 32
    radius: 4
    color: _headerMouse.containsMouse
      ? (row.colors ? Qt.rgba(row.colors.surfaceVariant.r, row.colors.surfaceVariant.g, row.colors.surfaceVariant.b, 0.4) : Qt.rgba(1, 1, 1, 0.06))
      : (row.colors ? Qt.rgba(row.colors.surfaceContainer.r, row.colors.surfaceContainer.g, row.colors.surfaceContainer.b, 0.4) : Qt.rgba(0.1, 0.12, 0.18, 0.4))

    Row {
      anchors.left: parent.left
      anchors.leftMargin: 10
      anchors.verticalCenter: parent.verticalCenter
      spacing: 8

      Text {
        text: row._expanded ? "▼" : "▶"
        font.family: Style.fontFamily
        font.pixelSize: 9
        color: row.colors ? row.colors.tertiary : Qt.rgba(1, 1, 1, 0.5)
        anchors.verticalCenter: parent.verticalCenter
      }

      Text {
        text: row.appName
        font.family: Style.fontFamily
        font.pixelSize: 12
        font.weight: Font.Medium
        color: row.colors ? row.colors.surfaceText : "#fff"
        anchors.verticalCenter: parent.verticalCenter
      }
    }

    Row {
      anchors.right: parent.right
      anchors.rightMargin: 10
      anchors.verticalCenter: parent.verticalCenter
      spacing: 8
      visible: !row._expanded

      Text {
        visible: row.backgroundPath !== ""
        text: "splash"
        font.family: Style.fontFamilyCode
        font.pixelSize: 9
        color: row.colors ? row.colors.primary : "#aaa"
        anchors.verticalCenter: parent.verticalCenter
      }
      Text {
        visible: row.hidden
        text: "hidden"
        font.family: Style.fontFamilyCode
        font.pixelSize: 9
        color: "#e57373"
        anchors.verticalCenter: parent.verticalCenter
      }
    }

    MouseArea {
      id: _headerMouse
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onClicked: row._expanded = !row._expanded
    }
  }

  Column {
    id: _editor
    anchors.top: _header.bottom
    anchors.topMargin: 8
    anchors.left: parent.left
    anchors.leftMargin: 16
    anchors.right: parent.right
    anchors.rightMargin: 8
    spacing: 6
    visible: row._expanded

    Column {
      width: parent.width
      spacing: 4

      SettingsTextInput {
        colors: row.colors
        label: "Background image"
        value: row.backgroundPath
        placeholder: "~/appsplash/<file>.jpg"
        onCommit: function(v) { row.saveField("background", v) }
      }

      Row {
        spacing: 4

        FilterButton {
          colors: row.colors
          label: "BROWSE"
          skew: 8
          height: 22
          onClicked: row.browseRequested()
        }

        FilterButton {
          colors: row.colors
          label: "CLEAR"
          skew: 8
          height: 22
          visible: row.backgroundPath !== ""
          onClicked: row.saveField("background", "")
        }
      }
    }

    SettingsTextInput {
      colors: row.colors
      label: "Display name override"
      value: row.displayName
      placeholder: "(default)"
      onCommit: function(v) { row.saveField("displayName", v) }
    }

    SettingsTextInput {
      colors: row.colors
      label: "Custom icon (nerd font glyph)"
      value: row.customIcon
      placeholder: "e.g. \\uf269"
      onCommit: function(v) { row.saveField("icon", v) }
    }

    SettingsTextInput {
      colors: row.colors
      label: "Tags (space-separated)"
      value: row.tags
      placeholder: "browser web internet"
      onCommit: function(v) { row.saveField("tags", v) }
    }

    SettingsToggle {
      colors: row.colors
      label: "Hidden from launcher"
      checked: row.hidden
      onToggle: function(v) { row.saveField("hidden", v) }
    }
  }
}
