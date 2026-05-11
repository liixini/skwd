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
  property bool useDesktopIcon: false
  property bool hidden: false
  property string tags: ""

  property bool _expanded: false

  signal saveField(string field, var value)
  signal browseRequested()
  signal iconPickRequested()

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
        visible: row.customIcon !== "" && !row.useDesktopIcon
        text: row.customIcon
        font.family: Style.fontFamilyIcons
        font.pixelSize: 14
        color: row.colors ? row.colors.primary : Qt.rgba(1, 1, 1, 0.7)
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
        visible: row.useDesktopIcon
        text: ".desktop"
        font.family: Style.fontFamilyCode
        font.pixelSize: 9
        color: row.colors ? row.colors.tertiary : "#8bceff"
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

      Text {
        text: "BACKGROUND"
        font.family: Style.fontFamily; font.pixelSize: 10; font.weight: Font.Bold; font.letterSpacing: 1.2
        color: row.colors ? Qt.rgba(row.colors.surfaceText.r, row.colors.surfaceText.g, row.colors.surfaceText.b, 0.5) : Qt.rgba(1, 1, 1, 0.4)
      }

      Row {
        width: parent.width
        spacing: 8

        Rectangle {
          width: 120
          height: 68
          radius: 4
          color: row.colors ? Qt.rgba(row.colors.surfaceContainer.r, row.colors.surfaceContainer.g, row.colors.surfaceContainer.b, 0.6) : Qt.rgba(0.1, 0.12, 0.18, 0.6)
          border.width: 1
          border.color: row.colors ? Qt.rgba(row.colors.outline.r, row.colors.outline.g, row.colors.outline.b, 0.2) : Qt.rgba(1, 1, 1, 0.08)
          clip: true

          Image {
            id: _splashPreview
            anchors.fill: parent
            anchors.margins: 1
            source: row.backgroundPath ? "file://" + row.backgroundPath : ""
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            smooth: true
            cache: true
            sourceSize.width: 240
            sourceSize.height: 136
            visible: status === Image.Ready
          }

          Text {
            visible: !_splashPreview.visible
            anchors.centerIn: parent
            text: row.backgroundPath ? "…" : "no splash"
            font.family: Style.fontFamily
            font.pixelSize: 9
            color: row.colors ? Qt.rgba(row.colors.surfaceText.r, row.colors.surfaceText.g, row.colors.surfaceText.b, 0.4) : Qt.rgba(1, 1, 1, 0.3)
          }
        }

        Column {
          spacing: 4
          width: parent.width - 128

          SettingsTextInput {
            colors: row.colors
            label: "Path"
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
      }
    }

    SettingsTextInput {
      colors: row.colors
      label: "Display name override"
      value: row.displayName
      placeholder: "(default)"
      onCommit: function(v) { row.saveField("displayName", v) }
    }

    Column {
      width: parent.width
      spacing: 4

      Text {
        text: "CUSTOM ICON"
        font.family: Style.fontFamily; font.pixelSize: 10; font.weight: Font.Bold; font.letterSpacing: 1.2
        color: row.colors ? Qt.rgba(row.colors.surfaceText.r, row.colors.surfaceText.g, row.colors.surfaceText.b, 0.5) : Qt.rgba(1, 1, 1, 0.4)
      }

      Row {
        width: parent.width
        spacing: 8

        Rectangle {
          width: 36; height: 36
          radius: 4
          color: row.colors ? Qt.rgba(row.colors.surfaceContainer.r, row.colors.surfaceContainer.g, row.colors.surfaceContainer.b, 0.7) : Qt.rgba(0.1, 0.12, 0.18, 0.7)
          border.width: 1
          border.color: row.colors ? Qt.rgba(row.colors.primary.r, row.colors.primary.g, row.colors.primary.b, 0.25) : Qt.rgba(1, 1, 1, 0.15)
          opacity: row.useDesktopIcon ? 0.4 : 1.0

          Text {
            anchors.centerIn: parent
            text: row.customIcon
            font.family: Style.fontFamilyIcons
            font.pixelSize: 20
            color: row.colors ? row.colors.primary : "#ffb4ab"
            visible: row.customIcon !== ""
          }
          Text {
            anchors.centerIn: parent
            text: "?"
            font.family: Style.fontFamily; font.pixelSize: 14
            color: row.colors ? Qt.rgba(row.colors.surfaceText.r, row.colors.surfaceText.g, row.colors.surfaceText.b, 0.3) : Qt.rgba(1, 1, 1, 0.2)
            visible: row.customIcon === ""
          }
        }

        Row {
          spacing: 4
          anchors.verticalCenter: parent.verticalCenter

          FilterButton {
            colors: row.colors
            label: "PICK"
            skew: 8
            height: 22
            onClicked: row.iconPickRequested()
          }

          FilterButton {
            colors: row.colors
            label: "CLEAR"
            skew: 8
            height: 22
            visible: row.customIcon !== ""
            onClicked: row.saveField("icon", "")
          }
        }
      }

      SettingsToggle {
        width: parent.width
        colors: row.colors
        label: "Always use .desktop icon if available"
        checked: row.useDesktopIcon
        onToggle: function(v) { row.saveField("useDesktopIcon", v) }
      }
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
