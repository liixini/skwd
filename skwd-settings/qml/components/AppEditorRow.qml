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

  width: parent ? parent.width : 0
  height: _expanded ? _card.implicitHeight : _collapsedRow.height
  Behavior on height { NumberAnimation { duration: Style.animNormal; easing.type: Easing.OutCubic } }
  clip: true

  Rectangle {
    id: _collapsedRow
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.top: parent.top
    height: 44
    radius: 6
    z: 1
    opacity: row._expanded ? 0 : 1
    Behavior on opacity { NumberAnimation { duration: Style.animFast; easing.type: Easing.OutCubic } }

    color: !row._expanded && _rowMouse.containsMouse
      ? (row.colors ? Qt.rgba(row.colors.surfaceVariant.r, row.colors.surfaceVariant.g, row.colors.surfaceVariant.b, 0.35) : Qt.rgba(1, 1, 1, 0.05))
      : "transparent"

    Rectangle {
      id: _iconBadge
      width: 30; height: 30; radius: 5
      anchors.left: parent.left
      anchors.leftMargin: 10
      anchors.verticalCenter: parent.verticalCenter
      color: row.colors ? Qt.rgba(row.colors.surfaceContainer.r, row.colors.surfaceContainer.g, row.colors.surfaceContainer.b, 0.6) : Qt.rgba(0.1, 0.12, 0.18, 0.6)
      border.width: 1
      border.color: row.colors ? Qt.rgba(row.colors.outline.r, row.colors.outline.g, row.colors.outline.b, 0.15) : Qt.rgba(1, 1, 1, 0.06)

      Text {
        anchors.centerIn: parent
        visible: row.customIcon !== "" && !row.useDesktopIcon
        text: row.customIcon
        font.family: Style.fontFamilyIcons
        font.pixelSize: 17
        color: row.colors ? row.colors.primary : Qt.rgba(0.6, 0.8, 1.0, 0.9)
      }
      Text {
        anchors.centerIn: parent
        visible: row.customIcon === "" || row.useDesktopIcon
        text: row.appName.length > 0 ? row.appName.charAt(0).toUpperCase() : "?"
        font.family: Style.fontFamily
        font.pixelSize: 14
        font.weight: Font.Medium
        color: row.colors ? Qt.rgba(row.colors.surfaceText.r, row.colors.surfaceText.g, row.colors.surfaceText.b, 0.45) : Qt.rgba(1, 1, 1, 0.35)
      }
    }

    Text {
      id: _nameText
      anchors.left: _iconBadge.right
      anchors.leftMargin: 12
      anchors.right: _badges.left
      anchors.rightMargin: 10
      anchors.verticalCenter: parent.verticalCenter
      elide: Text.ElideRight
      text: row.displayName !== "" ? (row.displayName + "  ·  " + row.appName) : row.appName
      font.family: Style.fontFamily
      font.pixelSize: 13
      font.weight: Font.Medium
      color: row.colors ? row.colors.surfaceText : "#fff"
    }

    Row {
      id: _badges
      anchors.right: _chevron.left
      anchors.rightMargin: 10
      anchors.verticalCenter: parent.verticalCenter
      spacing: 6

      Text {
        visible: row.backgroundPath !== ""
        text: "splash"
        font.family: Style.fontFamilyCode
        font.pixelSize: 9
        color: row.colors ? row.colors.primary : "#8bceff"
        anchors.verticalCenter: parent.verticalCenter
      }
      Text {
        visible: row.useDesktopIcon
        text: ".desktop"
        font.family: Style.fontFamilyCode
        font.pixelSize: 9
        color: row.colors ? row.colors.tertiary : "#aaa"
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

    Text {
      id: _chevron
      anchors.right: parent.right
      anchors.rightMargin: 12
      anchors.verticalCenter: parent.verticalCenter
      text: "▶"
      font.family: Style.fontFamily
      font.pixelSize: 10
      color: row.colors ? Qt.rgba(row.colors.surfaceText.r, row.colors.surfaceText.g, row.colors.surfaceText.b, 0.4) : Qt.rgba(1, 1, 1, 0.3)
    }

    MouseArea {
      id: _rowMouse
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onClicked: row._expanded = !row._expanded
    }
  }

  SettingsCard {
    id: _card
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.top: parent.top
    colors: row.colors
    title: row.displayName !== "" ? row.displayName : row.appName
    subtitle: row.displayName !== "" ? row.appName : ""
    opacity: row._expanded ? 1 : 0
    enabled: row._expanded
    Behavior on opacity { NumberAnimation { duration: Style.animNormal; easing.type: Easing.OutCubic } }

    titleAction: Rectangle {
      width: 28; height: 22; radius: 4
      color: _closeMouse.containsMouse
        ? (row.colors ? Qt.rgba(row.colors.surfaceVariant.r, row.colors.surfaceVariant.g, row.colors.surfaceVariant.b, 0.4) : Qt.rgba(1, 1, 1, 0.06))
        : "transparent"

      Text {
        anchors.centerIn: parent
        text: "▼"
        font.family: Style.fontFamily
        font.pixelSize: 10
        color: row.colors ? row.colors.tertiary : Qt.rgba(1, 1, 1, 0.5)
      }
      MouseArea {
        id: _closeMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: row._expanded = false
      }
    }

    Row {
      width: parent.width
      spacing: 16

      Column {
        id: _leftCol
        width: 220
        spacing: 8

        Rectangle {
          width: parent.width
          height: 124
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
            sourceSize.width: 440
            sourceSize.height: 248
            visible: status === Image.Ready
          }

          Text {
            visible: !_splashPreview.visible
            anchors.centerIn: parent
            text: row.backgroundPath ? "…" : "no splash"
            font.family: Style.fontFamily
            font.pixelSize: 10
            color: row.colors ? Qt.rgba(row.colors.surfaceText.r, row.colors.surfaceText.g, row.colors.surfaceText.b, 0.4) : Qt.rgba(1, 1, 1, 0.3)
          }
        }

        SettingsTextInput {
          width: parent.width
          colors: row.colors
          label: "Splash path"
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

      Column {
        width: parent.width - _leftCol.width - 16
        spacing: 12

        SettingsTextInput {
          width: parent.width
          colors: row.colors
          label: "Display name"
          value: row.displayName
          placeholder: "(default)"
          onCommit: function(v) { row.saveField("displayName", v) }
        }

        Row {
          width: parent.width
          spacing: 10

          Rectangle {
            width: 38; height: 38; radius: 5
            anchors.verticalCenter: parent.verticalCenter
            color: row.colors ? Qt.rgba(row.colors.surfaceContainer.r, row.colors.surfaceContainer.g, row.colors.surfaceContainer.b, 0.7) : Qt.rgba(0.1, 0.12, 0.18, 0.7)
            border.width: 1
            border.color: row.colors ? Qt.rgba(row.colors.primary.r, row.colors.primary.g, row.colors.primary.b, 0.25) : Qt.rgba(1, 1, 1, 0.15)
            opacity: row.useDesktopIcon ? 0.4 : 1.0

            Text {
              anchors.centerIn: parent
              visible: row.customIcon !== ""
              text: row.customIcon
              font.family: Style.fontFamilyIcons
              font.pixelSize: 20
              color: row.colors ? row.colors.primary : "#ffb4ab"
            }
            Text {
              anchors.centerIn: parent
              visible: row.customIcon === ""
              text: "?"
              font.family: Style.fontFamily; font.pixelSize: 14
              color: row.colors ? Qt.rgba(row.colors.surfaceText.r, row.colors.surfaceText.g, row.colors.surfaceText.b, 0.3) : Qt.rgba(1, 1, 1, 0.2)
            }
          }

          Column {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 4
            Text {
              text: "ICON"
              font.family: Style.fontFamily; font.pixelSize: 10; font.weight: Font.Bold; font.letterSpacing: 0.5
              color: row.colors ? Qt.rgba(row.colors.surfaceText.r, row.colors.surfaceText.g, row.colors.surfaceText.b, 0.5) : Qt.rgba(1, 1, 1, 0.4)
            }
            Row {
              spacing: 4
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
        }

        SettingsToggle {
          width: parent.width
          colors: row.colors
          label: "Always use .desktop icon"
          checked: row.useDesktopIcon
          onToggle: function(v) { row.saveField("useDesktopIcon", v) }
        }

        SettingsTextInput {
          width: parent.width
          colors: row.colors
          label: "Tags"
          value: row.tags
          placeholder: "browser web internet"
          onCommit: function(v) { row.saveField("tags", v) }
        }

        SettingsToggle {
          width: parent.width
          colors: row.colors
          label: "Hidden from launcher"
          checked: row.hidden
          onToggle: function(v) { row.saveField("hidden", v) }
        }
      }
    }
  }
}
