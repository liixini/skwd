import QtQuick
import ".."

Column {
  id: root
  property var panel
  property var colors
  width: parent.width
  spacing: 6

  ConfigSectionTitle { text: "APP CUSTOMIZATION"; colors: root.colors }

  Text {
    text: "Customize how apps appear in the launcher and window switcher."
    font.family: Style.fontFamily
    font.pixelSize: 11
    color: root.colors ? Qt.rgba(root.colors.surfaceText.r, root.colors.surfaceText.g, root.colors.surfaceText.b, 0.5) : Qt.rgba(1, 1, 1, 0.4)
    bottomPadding: 6
  }

  Rectangle {
    width: parent.width
    height: 36
    radius: 8
    color: root.colors ? Qt.rgba(root.colors.surfaceContainer.r, root.colors.surfaceContainer.g, root.colors.surfaceContainer.b, 0.6) : Qt.rgba(0.15, 0.15, 0.2, 0.6)
    border.width: appSearchInput.activeFocus ? 1 : 0
    border.color: root.colors ? Qt.rgba(root.colors.primary.r, root.colors.primary.g, root.colors.primary.b, 0.5) : Qt.rgba(1, 1, 1, 0.3)

    Row {
      anchors.fill: parent
      anchors.leftMargin: 12
      anchors.rightMargin: 12
      spacing: 8

      Text {
        text: "󰍉"
        font.family: Style.fontFamilyNerdIcons
        font.pixelSize: 14
        color: root.colors ? Qt.rgba(root.colors.surfaceText.r, root.colors.surfaceText.g, root.colors.surfaceText.b, 0.4) : Qt.rgba(1, 1, 1, 0.3)
        anchors.verticalCenter: parent.verticalCenter
      }

      TextInput {
        id: appSearchInput
        width: parent.width - 30
        font.family: Style.fontFamily
        font.pixelSize: 12
        color: root.colors ? root.colors.surfaceText : "#fff"
        clip: true
        anchors.verticalCenter: parent.verticalCenter
        selectByMouse: true
        onTextChanged: root.panel._appSearchFilter = text.trim().toLowerCase()

        Text {
          anchors.fill: parent
          text: "Search apps..."
          font: parent.font
          color: root.colors ? Qt.rgba(root.colors.surfaceText.r, root.colors.surfaceText.g, root.colors.surfaceText.b, 0.3) : Qt.rgba(1, 1, 1, 0.25)
          visible: !parent.text && !parent.activeFocus
        }
      }
    }
  }

  Repeater {
    id: appsRepeater
    model: root.panel._appKeys

    Rectangle {
      id: appCard
      width: root.width
      height: _matchesSearch ? appCardColumn.implicitHeight + 16 : 0
      radius: 10
      color: root.colors ? Qt.rgba(root.colors.surfaceContainer.r, root.colors.surfaceContainer.g, root.colors.surfaceContainer.b, 0.6) : Qt.rgba(0.15, 0.15, 0.2, 0.6)
      border.width: 1
      border.color: appExpanded
        ? (root.colors ? Qt.rgba(root.colors.primary.r, root.colors.primary.g, root.colors.primary.b, 0.4) : Qt.rgba(1, 1, 1, 0.2))
        : "transparent"
      visible: _matchesSearch || height > 1
      clip: true
      opacity: _matchesSearch ? 1 : 0
      Behavior on height { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
      Behavior on opacity { NumberAnimation { duration: 100 } }
      Behavior on border.color { ColorAnimation { duration: 150 } }

      property bool appExpanded: false
      property string appKey: modelData
      property var appEntry: root.panel.appsData[appKey] ?? {}

      Connections {
        target: root.panel
        function onAppsDataChanged() {
          var obj = root.panel.appsData[appCard.appKey]
          appCard.appEntry = obj ? Object.assign({}, obj) : {}
        }
      }
      property bool _matchesSearch: {
        if (!root.panel._appSearchFilter) return true
        var q = root.panel._appSearchFilter
        if (appKey.toLowerCase().indexOf(q) >= 0) return true
        var entry = appEntry
        if (entry.displayName && entry.displayName.toLowerCase().indexOf(q) >= 0) return true
        if (entry.tags && entry.tags.toLowerCase().indexOf(q) >= 0) return true
        return false
      }

      Column {
        id: appCardColumn
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 8
        spacing: 6

        Rectangle {
          width: parent.width
          height: 30
          radius: 6
          color: appHeaderMouse.containsMouse
            ? (root.colors ? Qt.rgba(root.colors.surfaceVariant.r, root.colors.surfaceVariant.g, root.colors.surfaceVariant.b, 0.3) : Qt.rgba(1, 1, 1, 0.05))
            : "transparent"

          Row {
            anchors.fill: parent
            anchors.leftMargin: 8
            spacing: 10

            Text {
              text: appCard.appExpanded ? "󰅀" : "󰅂"
              font.family: Style.fontFamilyNerdIcons
              font.pixelSize: 14
              color: root.colors ? root.colors.primary : "#4fc3f7"
              anchors.verticalCenter: parent.verticalCenter
            }

            Text {
              text: appCard.appKey.toUpperCase()
              font.family: Style.fontFamily
              font.pixelSize: 12
              font.weight: Font.Bold
              font.letterSpacing: 0.5
              color: root.colors ? root.colors.tertiary : "#8bceff"
              anchors.verticalCenter: parent.verticalCenter
            }

            Text {
              text: {
                var parts = []
                if (appCard.appEntry.displayName) parts.push(appCard.appEntry.displayName)
                if (appCard.appEntry.icon) parts.push("icon: " + appCard.appEntry.icon)
                if (appCard.appEntry.hidden) parts.push("hidden")
                return parts.length > 0 ? "— " + parts.join(", ") : ""
              }
              font.family: Style.fontFamily
              font.pixelSize: 10
              color: root.colors ? Qt.rgba(root.colors.surfaceText.r, root.colors.surfaceText.g, root.colors.surfaceText.b, 0.4) : Qt.rgba(1, 1, 1, 0.3)
              anchors.verticalCenter: parent.verticalCenter
              elide: Text.ElideRight
              width: Math.max(0, parent.width - x - 80)
            }
          }

          MouseArea {
            id: appHeaderMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: appCard.appExpanded = !appCard.appExpanded
          }
        }

        Column {
          width: parent.width
          spacing: 6
          visible: appCard.appExpanded
          leftPadding: 8

          ConfigTextField {
            label: "Display name"
            value: appCard.appEntry.displayName ?? ""
            onEdited: v => {
              if (!root.panel.appsData[appCard.appKey]) root.panel.appsData[appCard.appKey] = {}
              if (v === "") { delete root.panel.appsData[appCard.appKey].displayName }
              else { root.panel.appsData[appCard.appKey].displayName = v }
              root.panel.hasUnsavedChanges = true
              root.panel.appsDataChanged()
            }
            colors: root.colors
          }

          Item {
            width: parent.width
            height: 36

            Row {
              anchors.fill: parent
              spacing: 12

              Text {
                width: 160
                text: "Icon (nerd font)"
                font.family: Style.fontFamily
                font.pixelSize: 12
                font.weight: Font.Medium
                color: root.colors ? root.colors.surfaceText : "#ddd"
                anchors.verticalCenter: parent.verticalCenter
                elide: Text.ElideRight
              }

              Rectangle {
                width: 30; height: 30
                radius: 6
                color: root.colors ? Qt.rgba(root.colors.surfaceContainer.r, root.colors.surfaceContainer.g, root.colors.surfaceContainer.b, 0.8) : Qt.rgba(0.15, 0.15, 0.2, 0.8)
                border.width: 1
                border.color: root.colors ? Qt.rgba(root.colors.primary.r, root.colors.primary.g, root.colors.primary.b, 0.3) : Qt.rgba(1, 1, 1, 0.15)
                anchors.verticalCenter: parent.verticalCenter

                Text {
                  anchors.centerIn: parent
                  text: appCard.appEntry.icon ?? ""
                  font.family: Style.fontFamilyIcons
                  font.pixelSize: 18
                  color: root.colors ? root.colors.primary : "#4fc3f7"
                  visible: (appCard.appEntry.icon ?? "") !== ""
                }
                Text {
                  anchors.centerIn: parent
                  text: "?"
                  font.pixelSize: 12
                  color: root.colors ? Qt.rgba(root.colors.surfaceText.r, root.colors.surfaceText.g, root.colors.surfaceText.b, 0.3) : Qt.rgba(1, 1, 1, 0.2)
                  visible: (appCard.appEntry.icon ?? "") === ""
                }
              }

              Rectangle {
                width: 80
                height: 30
                radius: 6
                color: root.colors ? Qt.rgba(root.colors.surfaceContainer.r, root.colors.surfaceContainer.g, root.colors.surfaceContainer.b, 0.6) : Qt.rgba(0.15, 0.15, 0.2, 0.6)
                border.width: iconFieldInput.activeFocus ? 1 : 0
                border.color: root.colors ? Qt.rgba(root.colors.primary.r, root.colors.primary.g, root.colors.primary.b, 0.5) : Qt.rgba(1, 1, 1, 0.3)
                anchors.verticalCenter: parent.verticalCenter

                TextInput {
                  id: iconFieldInput
                  anchors.fill: parent
                  anchors.leftMargin: 10
                  anchors.rightMargin: 10
                  verticalAlignment: TextInput.AlignVCenter
                  font.family: Style.fontFamilyIcons
                  font.pixelSize: 14
                  color: root.colors ? root.colors.tertiary : "#8bceff"
                  clip: true
                  text: appCard.appEntry.icon ?? ""
                  selectByMouse: true

                  onTextEdited: {
                    if (!root.panel.appsData[appCard.appKey]) root.panel.appsData[appCard.appKey] = {}
                    if (text === "") { delete root.panel.appsData[appCard.appKey].icon }
                    else { root.panel.appsData[appCard.appKey].icon = text }
                    root.panel.hasUnsavedChanges = true
                    root.panel.appsDataChanged()
                  }

                  Text {
                    anchors.fill: parent
                    verticalAlignment: Text.AlignVCenter
                    text: "paste glyph"
                    font.family: Style.fontFamily
                    font.pixelSize: 10
                    color: root.colors ? Qt.rgba(root.colors.surfaceText.r, root.colors.surfaceText.g, root.colors.surfaceText.b, 0.25) : Qt.rgba(1, 1, 1, 0.2)
                    visible: !parent.text && !parent.activeFocus
                  }
                }
              }

              Rectangle {
                width: pickIconLabel.implicitWidth + 20
                height: 30
                radius: 6
                color: pickIconMouse.containsMouse
                  ? (root.colors ? Qt.rgba(root.colors.primary.r, root.colors.primary.g, root.colors.primary.b, 0.2) : Qt.rgba(1, 1, 1, 0.15))
                  : (root.colors ? Qt.rgba(root.colors.surfaceContainer.r, root.colors.surfaceContainer.g, root.colors.surfaceContainer.b, 0.6) : Qt.rgba(0.15, 0.15, 0.2, 0.6))
                border.width: 1
                border.color: root.colors ? Qt.rgba(root.colors.primary.r, root.colors.primary.g, root.colors.primary.b, 0.3) : Qt.rgba(1, 1, 1, 0.15)
                anchors.verticalCenter: parent.verticalCenter

                Text {
                  id: pickIconLabel
                  anchors.centerIn: parent
                  text: "PICK"
                  font.family: Style.fontFamily
                  font.pixelSize: 11
                  color: root.colors ? root.colors.tertiary : "#8bceff"
                }

                MouseArea {
                  id: pickIconMouse
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onClicked: root.panel.openIconPicker(appCard.appKey)
                }
              }
            }
          }

          ConfigTextField {
            label: "Tags"
            value: appCard.appEntry.tags ?? ""
            placeholder: "space-separated keywords"
            onEdited: v => {
              if (!root.panel.appsData[appCard.appKey]) root.panel.appsData[appCard.appKey] = {}
              if (v === "") { delete root.panel.appsData[appCard.appKey].tags }
              else { root.panel.appsData[appCard.appKey].tags = v }
              root.panel.hasUnsavedChanges = true
              root.panel.appsDataChanged()
            }
            colors: root.colors
          }

          ConfigToggle {
            label: "Hidden"
            checked: root.panel.getNested(root.panel.appsData, [appCard.appKey, "hidden"], false)
            onToggled: v => {
              if (!root.panel.appsData[appCard.appKey]) root.panel.appsData[appCard.appKey] = {}
              if (!v) { delete root.panel.appsData[appCard.appKey].hidden }
              else { root.panel.appsData[appCard.appKey].hidden = v }
              root.panel.hasUnsavedChanges = true
              root.panel.appsDataChanged()
            }
            colors: root.colors
          }

          Item {
            width: parent.width
            height: bgPreviewColumn.implicitHeight

            Column {
              id: bgPreviewColumn
              width: parent.width
              spacing: 6

              Row {
                width: parent.width
                spacing: 12

                Text {
                  width: 160
                  text: "Background"
                  font.family: Style.fontFamily
                  font.pixelSize: 12
                  font.weight: Font.Medium
                  color: root.colors ? root.colors.surfaceText : "#ddd"
                  anchors.verticalCenter: parent.verticalCenter
                  elide: Text.ElideRight
                }

                Rectangle {
                  width: parent.width - 172 - browseBtn.width - 12
                  height: 30
                  radius: 6
                  color: root.colors ? Qt.rgba(root.colors.surfaceContainer.r, root.colors.surfaceContainer.g, root.colors.surfaceContainer.b, 0.6) : Qt.rgba(0.15, 0.15, 0.2, 0.6)
                  border.width: bgPathInput.activeFocus ? 1 : 0
                  border.color: root.colors ? Qt.rgba(root.colors.primary.r, root.colors.primary.g, root.colors.primary.b, 0.5) : Qt.rgba(1, 1, 1, 0.3)
                  anchors.verticalCenter: parent.verticalCenter

                  TextInput {
                    id: bgPathInput
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    verticalAlignment: TextInput.AlignVCenter
                    font.family: Style.fontFamilyCode
                    font.pixelSize: 11
                    color: root.colors ? root.colors.tertiary : "#8bceff"
                    clip: true
                    text: root.panel.getNested(root.panel.appsData, [appCard.appKey, "background"], "")
                    selectByMouse: true

                    onTextEdited: {
                      if (!root.panel.appsData[appCard.appKey]) root.panel.appsData[appCard.appKey] = {}
                      if (text === "") { delete root.panel.appsData[appCard.appKey].background }
                      else { root.panel.appsData[appCard.appKey].background = text }
                      root.panel.hasUnsavedChanges = true
                      root.panel.appsDataChanged()
                    }

                    Text {
                      anchors.fill: parent
                      verticalAlignment: Text.AlignVCenter
                      text: "path to image"
                      font: parent.font
                      color: root.colors ? Qt.rgba(root.colors.surfaceText.r, root.colors.surfaceText.g, root.colors.surfaceText.b, 0.25) : Qt.rgba(1, 1, 1, 0.2)
                      visible: !parent.text && !parent.activeFocus
                    }
                  }
                }

                Rectangle {
                  id: browseBtn
                  width: browseBtnLabel.implicitWidth + 20
                  height: 30
                  radius: 6
                  color: browseBtnMouse.containsMouse
                    ? (root.colors ? Qt.rgba(root.colors.primary.r, root.colors.primary.g, root.colors.primary.b, 0.2) : Qt.rgba(1, 1, 1, 0.15))
                    : (root.colors ? Qt.rgba(root.colors.surfaceContainer.r, root.colors.surfaceContainer.g, root.colors.surfaceContainer.b, 0.6) : Qt.rgba(0.15, 0.15, 0.2, 0.6))
                  border.width: 1
                  border.color: root.colors ? Qt.rgba(root.colors.primary.r, root.colors.primary.g, root.colors.primary.b, 0.3) : Qt.rgba(1, 1, 1, 0.15)
                  anchors.verticalCenter: parent.verticalCenter

                  Text {
                    id: browseBtnLabel
                    anchors.centerIn: parent
                    text: "BROWSE"
                    font.family: Style.fontFamily
                    font.pixelSize: 11
                    color: root.colors ? root.colors.tertiary : "#8bceff"
                  }

                  MouseArea {
                    id: browseBtnMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.panel._openFileBrowser(appCard.appKey)
                  }
                }
              }

              Rectangle {
                width: parent.width
                height: root.panel.getNested(root.panel.appsData, [appCard.appKey, "background"], "") !== "" && bgPreviewImage.status === Image.Ready
                  ? Math.min(width * (bgPreviewImage.sourceSize.height / Math.max(1, bgPreviewImage.sourceSize.width)), 400)
                  : 60
                radius: 8
                color: bgDropArea.containsDrag
                  ? (root.colors ? Qt.rgba(root.colors.primary.r, root.colors.primary.g, root.colors.primary.b, 0.15) : Qt.rgba(1, 1, 1, 0.1))
                  : (root.colors ? Qt.rgba(root.colors.surfaceContainer.r, root.colors.surfaceContainer.g, root.colors.surfaceContainer.b, 0.4) : Qt.rgba(0.1, 0.1, 0.15, 0.4))
                border.width: 1
                border.color: bgDropArea.containsDrag
                  ? (root.colors ? root.colors.primary : "#4fc3f7")
                  : (root.colors ? Qt.rgba(root.colors.outline.r, root.colors.outline.g, root.colors.outline.b, 0.2) : Qt.rgba(1, 1, 1, 0.08))
                clip: true

                Behavior on border.color { ColorAnimation { duration: 150 } }
                Behavior on color { ColorAnimation { duration: 150 } }

                Image {
                  id: bgPreviewImage
                  anchors.fill: parent
                  anchors.margins: 2
                  source: {
                    var bg = root.panel.getNested(root.panel.appsData, [appCard.appKey, "background"], "")
                    if (!bg) return ""
                    bg = bg.replace("~", Config.homeDir)
                    return "file://" + bg
                  }
                  fillMode: Image.PreserveAspectCrop
                  visible: status === Image.Ready
                  opacity: 0.7
                  smooth: true
                  asynchronous: true
                }

                Column {
                  anchors.centerIn: parent
                  spacing: 4
                  visible: !bgPreviewImage.visible

                  Text {
                    text: "󰕒"
                    font.family: Style.fontFamilyIcons
                    font.pixelSize: 22
                    color: root.colors ? Qt.rgba(root.colors.surfaceText.r, root.colors.surfaceText.g, root.colors.surfaceText.b, 0.3) : Qt.rgba(1, 1, 1, 0.2)
                    anchors.horizontalCenter: parent.horizontalCenter
                  }
                  Text {
                    text: "Drop image here or use BROWSE"
                    font.family: Style.fontFamily
                    font.pixelSize: 10
                    color: root.colors ? Qt.rgba(root.colors.surfaceText.r, root.colors.surfaceText.g, root.colors.surfaceText.b, 0.25) : Qt.rgba(1, 1, 1, 0.15)
                    anchors.horizontalCenter: parent.horizontalCenter
                  }
                }

                Row {
                  anchors.bottom: parent.bottom
                  anchors.right: parent.right
                  anchors.margins: 6
                  spacing: 6
                  visible: bgPreviewImage.visible

                  Rectangle {
                    width: clearBgLabel.implicitWidth + 12
                    height: 20
                    radius: 4
                    color: Qt.rgba(0, 0, 0, 0.7)
                    border.width: 1
                    border.color: root.colors ? Qt.rgba(root.colors.error.r, root.colors.error.g, root.colors.error.b, 0.5) : Qt.rgba(1, 0.3, 0.3, 0.5)

                    Text {
                      id: clearBgLabel
                      anchors.centerIn: parent
                      text: "✕ CLEAR"
                      font.family: Style.fontFamily
                      font.pixelSize: 9
                      font.weight: Font.Bold
                      color: root.colors ? root.colors.error : "#ff6b6b"
                    }

                    MouseArea {
                      anchors.fill: parent
                      cursorShape: Qt.PointingHandCursor
                      onClicked: {
                        if (root.panel.appsData[appCard.appKey]) {
                          delete root.panel.appsData[appCard.appKey].background
                          root.panel.hasUnsavedChanges = true
                          root.panel.appsDataChanged()
                        }
                      }
                    }
                  }
                }

                DropArea {
                  id: bgDropArea
                  anchors.fill: parent
                  keys: ["text/uri-list", "text/plain"]

                  onDropped: drop => {
                    var path = ""
                    if (drop.hasUrls && drop.urls.length > 0) {
                      path = drop.urls[0].toString()
                    } else if (drop.hasText) {
                      path = drop.text.trim()
                    }
                    if (path.startsWith("file://")) path = path.substring(7)
                    path = decodeURIComponent(path)
                    if (path) {
                      var home = Config.homeDir
                      if (path.startsWith(home)) path = "~" + path.substring(home.length)
                      if (!root.panel.appsData[appCard.appKey]) root.panel.appsData[appCard.appKey] = {}
                      root.panel.appsData[appCard.appKey].background = path
                      root.panel.hasUnsavedChanges = true
                      root.panel.appsDataChanged()
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
  }
}
