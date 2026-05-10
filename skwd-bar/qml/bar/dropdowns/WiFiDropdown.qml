
import Quickshell.Io
import QtQuick
import "../.."
import "../../services"
Rectangle {
  id: root

  required property var colors


  property bool active: false
  property string wifiSsid: ""
  property int wifiSignalStrength: 0

  property real _expand: 0
  Behavior on _expand {
    NumberAnimation {
      duration: 420
      easing.type: Easing.InOutQuart
    }
  }

  property real _targetContentHeight: wifiColumn.implicitHeight + 24
  property real _smoothedContentHeight: _targetContentHeight
  Behavior on _smoothedContentHeight {
    NumberAnimation { duration: 260; easing.type: Easing.OutCubic }
  }

  readonly property real animatedHeight: _expand * _smoothedContentHeight

  height: animatedHeight
  visible: animatedHeight > 0.5
  color: Qt.rgba(root.colors.surface.r, root.colors.surface.g, root.colors.surface.b, 0.88)

  property string pendingSsid: ""
  property string pendingSecurity: ""
  property string statusText: ""
  readonly property string passwordText: pwInput.text

  ListModel { id: networksModel }

  function _syncNetworks() {
    var fresh = (WifiService.networks || []).filter(function(n) {
      return !(n.connected || n.ssid === root.wifiSsid)
    })

    var freshMap = ({})
    for (var i = 0; i < fresh.length; i++) freshMap[fresh[i].ssid] = fresh[i]

    for (var j = networksModel.count - 1; j >= 0; j--) {
      if (!(networksModel.get(j).ssid in freshMap)) networksModel.remove(j)
    }

    var existing = ({})
    for (var k = 0; k < networksModel.count; k++) existing[networksModel.get(k).ssid] = k

    for (var m = 0; m < fresh.length; m++) {
      var n = fresh[m]
      if (n.ssid in existing) {
        networksModel.set(existing[n.ssid], n)
      } else {
        networksModel.append(n)
      }
    }
  }

  Connections {
    target: WifiService
    function onNetworksChanged() { root._syncNetworks() }
  }
  onWifiSsidChanged: _syncNetworks()

  onPendingSsidChanged: {
    if (pendingSsid !== "") pwFocusTimer.start()
  }

  Timer {
    id: pwFocusTimer
    interval: 50
    repeat: false
    onTriggered: pwInput.forceActiveFocus()
  }

  function _findSecurity(ssid) {
    var list = WifiService.networks || []
    for (var i = 0; i < list.length; i++) {
      if (list[i].ssid === ssid) return list[i].security || ""
    }
    return ""
  }

  function _connectKnown(ssid) {
    wifiConnectProcess.targetSsid = ssid
    wifiConnectProcess.targetSecurity = _findSecurity(ssid)
    wifiConnectProcess.passphrase = ""
    wifiConnectProcess.command = ["iwctl", "station", Config.wifiInterface, "connect", ssid]
    wifiConnectProcess.running = true
    statusText = "Connecting to " + ssid + "..."
    pendingSsid = ""
    pendingSecurity = ""
    pwInput.text = ""
  }

  function _connectWithPassword() {
    if (!pendingSsid || !passwordText) return
    var pwd = passwordText
    var ssid = pendingSsid
    var sec = pendingSecurity
    wifiConnectProcess.targetSsid = ssid
    wifiConnectProcess.targetSecurity = sec
    wifiConnectProcess.passphrase = pwd
    wifiConnectProcess.command = ["iwctl", "--passphrase", pwd, "station", Config.wifiInterface, "connect", ssid]
    wifiConnectProcess.running = true
    statusText = "Connecting to " + ssid + "..."
    pendingSsid = ""
    pendingSecurity = ""
    pwInput.text = ""
  }

  function _cancelPending() {
    pendingSsid = ""
    pendingSecurity = ""
    pwInput.text = ""
  }


  onActiveChanged: {
    if (active) {
      WifiService.scan()
      _expand = 1
    } else {
      _expand = 0
      _cancelPending()
      statusText = ""
    }
  }


  Rectangle {
    anchors.bottom: parent.bottom
    anchors.left: parent.left
    anchors.right: parent.right
    height: 2
    color: root.colors.primary
    width: parent.width * root._expand
  }


  Column {
    id: wifiColumn
    anchors.right: parent.right
    anchors.rightMargin: 12
    anchors.bottom: parent.bottom
    anchors.bottomMargin: 12
    spacing: 6
    width: parent.width - 24

    opacity: root._expand
    transform: Translate {
      y: -10 * (1 - root._expand)
    }


    Process {
      id: wifiConnectProcess
      property string targetSsid: ""
      property string passphrase: ""
      property string targetSecurity: ""
      command: ["iwctl", "station", Config.wifiInterface, "connect", targetSsid]
      onExited: function(exitCode, exitStatus) {
        if (exitCode === 0) {
          root.statusText = "Connected to " + targetSsid
          WifiService.scan()
        } else {
          var sec = targetSecurity
          var isSec = sec === "psk" || sec === "8021x" || (sec !== "" && sec !== "open")
          if (isSec && targetSsid) {
            root.statusText = "Wrong password for " + targetSsid
            root.pendingSsid = targetSsid
            root.pendingSecurity = sec
            pwInput.text = ""
            WifiService.forgetNetwork(targetSsid)
          } else {
            root.statusText = "Failed to connect to " + targetSsid
          }
        }
      }
    }


    Text {
      text: "WIFI"
      color: root.colors.primary
      font.pixelSize: 14
      font.family: Style.fontFamily
      font.weight: Font.DemiBold
    }


    Row {
      spacing: 8
      visible: root.wifiSsid !== ""
      Text {
        text: "󰤨"
        font.pixelSize: 12
        font.family: Style.fontFamilyNerdIcons
        color: root.colors.primary
        width: 14
        horizontalAlignment: Text.AlignHCenter
      }
      Text {
        text: root.wifiSsid || "Not connected"
        color: root.colors.primary
        font.pixelSize: 12
        font.family: Style.fontFamily
        font.weight: Font.DemiBold
      }
      Text {
        text: root.wifiSignalStrength + "%"
        color: root.colors.tertiary
        font.pixelSize: 12
        font.family: Style.fontFamily
        font.weight: Font.Medium
        width: 28
        horizontalAlignment: Text.AlignRight
      }
    }


    Rectangle {
      width: parent.width
      height: 1
      color: Qt.rgba(root.colors.primary.r, root.colors.primary.g, root.colors.primary.b, 0.2)
    }


    Item {
      width: parent.width
      height: pwPanel.implicitHeight * pwPanel.opacity
      visible: pwPanel.opacity > 0
      clip: true

      Behavior on height { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

      Rectangle {
        id: pwPanel
        width: parent.width
        implicitHeight: pwCol.implicitHeight + 16
        radius: 4
        color: Qt.rgba(root.colors.surfaceContainer.r, root.colors.surfaceContainer.g, root.colors.surfaceContainer.b, 0.6)
        border.width: 1
        border.color: Qt.rgba(root.colors.primary.r, root.colors.primary.g, root.colors.primary.b, 0.45)

        opacity: root.pendingSsid !== "" ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

        Column {
          id: pwCol
          anchors.left: parent.left
          anchors.right: parent.right
          anchors.top: parent.top
          anchors.margins: 8
          spacing: 6

          Row {
            spacing: 6
            Text {
              text: "󰌆"
              font.pixelSize: 11
              font.family: Style.fontFamilyNerdIcons
              color: root.colors.primary
              anchors.verticalCenter: parent.verticalCenter
            }
            Text {
              text: root.pendingSsid
              color: root.colors.primary
              font.pixelSize: 11
              font.family: Style.fontFamily
              font.weight: Font.DemiBold
              elide: Text.ElideRight
              width: 200
              anchors.verticalCenter: parent.verticalCenter
            }
          }

          Rectangle {
            width: parent.width
            height: 24
            radius: 3
            color: Qt.rgba(root.colors.surface.r, root.colors.surface.g, root.colors.surface.b, 0.8)
            border.width: pwInput.activeFocus ? 1 : 0
            border.color: Qt.rgba(root.colors.primary.r, root.colors.primary.g, root.colors.primary.b, 0.6)

            TextInput {
              id: pwInput
              anchors.fill: parent
              anchors.leftMargin: 6
              anchors.rightMargin: 6
              verticalAlignment: TextInput.AlignVCenter
              font.family: Style.fontFamilyCode
              font.pixelSize: 11
              color: "transparent"
              selectionColor: "transparent"
              selectedTextColor: "transparent"
              clip: true
              selectByMouse: false
              echoMode: TextInput.NoEcho
              focus: root.pendingSsid !== ""
              onAccepted: root._connectWithPassword()
              Keys.onEscapePressed: root._cancelPending()
              cursorDelegate: Item { width: 0; height: 0 }

              ListModel { id: shapesModel }

              readonly property var _shapeChars: ["⬢", "◆", "▲", "●", "■", "⬟", "★"]

              function _syncShapes() {
                var len = pwInput.text.length
                while (shapesModel.count < len) {
                  shapesModel.append({ idx: shapesModel.count })
                }
                while (shapesModel.count > len) {
                  shapesModel.remove(shapesModel.count - 1)
                }
              }

              onTextChanged: _syncShapes()
              Component.onCompleted: _syncShapes()

              Row {
                id: shapeRow
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                spacing: 3

                Repeater {
                  model: shapesModel

                  delegate: Text {
                    text: pwInput._shapeChars[model.idx % pwInput._shapeChars.length]
                    font.pixelSize: 11
                    font.family: Style.fontFamily
                    color: {
                      var palette = [root.colors.primary, root.colors.tertiary, root.colors.secondary]
                      return palette[model.idx % palette.length] || root.colors.tertiary
                    }
                    transformOrigin: Item.Center

                    SequentialAnimation on scale {
                      running: true
                      NumberAnimation { from: 0.4; to: 1.15; duration: 90; easing.type: Easing.OutCubic }
                      NumberAnimation { to: 1.0; duration: 110; easing.type: Easing.OutCubic }
                    }
                  }
                }

                Rectangle {
                  width: 1
                  height: 12
                  color: root.colors.primary
                  visible: pwInput.activeFocus && _caretBlink.on
                  anchors.verticalCenter: parent.verticalCenter
                }
              }

              Timer {
                id: _caretBlink
                property bool on: true
                interval: 530
                repeat: true
                running: pwInput.activeFocus
                onTriggered: on = !on
                onRunningChanged: if (running) on = true
              }

              Text {
                anchors.fill: parent
                verticalAlignment: Text.AlignVCenter
                font: parent.font
                color: Qt.rgba(root.colors.surfaceText.r, root.colors.surfaceText.g, root.colors.surfaceText.b, 0.35)
                text: "Password"
                visible: !pwInput.text && !pwInput.activeFocus
              }
            }
          }

          Row {
            spacing: 6
            anchors.right: parent.right

            Rectangle {
              width: cancelTxt.implicitWidth + 14
              height: 20
              radius: 3
              color: cancelArea.containsMouse
                ? Qt.rgba(root.colors.outline.r, root.colors.outline.g, root.colors.outline.b, 0.18)
                : "transparent"
              border.width: 1
              border.color: Qt.rgba(root.colors.outline.r, root.colors.outline.g, root.colors.outline.b, 0.4)

              Text {
                id: cancelTxt
                anchors.centerIn: parent
                text: "CANCEL"
                color: root.colors.outline
                font.pixelSize: 10
                font.family: Style.fontFamily
                font.weight: Font.DemiBold
                font.letterSpacing: 0.5
              }

              MouseArea {
                id: cancelArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root._cancelPending()
              }
            }

            Rectangle {
              width: connectTxt.implicitWidth + 14
              height: 20
              radius: 3
              color: connectArea.containsMouse
                ? root.colors.primary
                : Qt.rgba(root.colors.primary.r, root.colors.primary.g, root.colors.primary.b, 0.85)
              opacity: root.passwordText.length > 0 ? 1 : 0.4

              Text {
                id: connectTxt
                anchors.centerIn: parent
                text: "CONNECT"
                color: root.colors.surface
                font.pixelSize: 10
                font.family: Style.fontFamily
                font.weight: Font.Bold
                font.letterSpacing: 0.5
              }

              MouseArea {
                id: connectArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: root.passwordText.length > 0 ? Qt.PointingHandCursor : Qt.ArrowCursor
                onClicked: {
                  if (root.passwordText.length > 0) root._connectWithPassword()
                }
              }
            }
          }
        }
      }
    }


    Text {
      text: "AVAILABLE"
      color: root.colors.tertiary
      font.pixelSize: 10
      font.family: Style.fontFamily
      font.weight: Font.DemiBold
    }


    Text {
      visible: networksList.count === 0
      text: "Scanning..."
      color: root.colors.tertiary
      font.pixelSize: 11
      font.family: Style.fontFamily
      font.italic: true
    }


    Text {
      visible: root.statusText !== ""
      text: root.statusText
      color: root.colors.tertiary
      font.pixelSize: 10
      font.family: Style.fontFamily
      font.italic: true
    }


    ListView {
      id: networksList
      width: parent.width
      height: contentHeight
      interactive: false
      spacing: 6
      model: networksModel

      add: Transition {
        ParallelAnimation {
          NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 220; easing.type: Easing.OutCubic }
          NumberAnimation { property: "x"; from: 12; to: 0; duration: 220; easing.type: Easing.OutCubic }
        }
      }
      remove: Transition {
        ParallelAnimation {
          NumberAnimation { property: "opacity"; from: 1; to: 0; duration: 180; easing.type: Easing.InCubic }
          NumberAnimation { property: "x"; from: 0; to: -12; duration: 180; easing.type: Easing.InCubic }
        }
      }
      displaced: Transition {
        NumberAnimation { properties: "y"; duration: 220; easing.type: Easing.OutCubic }
      }

      delegate: Item {
        width: ListView.view.width
        height: netRow.implicitHeight

        property bool isSecured: {
          let sec = model.security || ""
          return sec === "psk" || sec === "8021x" || (sec !== "" && sec !== "open")
        }
        property bool isKnown: model.known === true

        Row {
          id: netRow
          spacing: 8

          Text {
            text: {
              let s = model.signal || 0
              if (s <= 25) return "󰤟"
              if (s <= 50) return "󰤢"
              if (s <= 75) return "󰤥"
              return "󰤨"
            }
            font.pixelSize: 12
            font.family: Style.fontFamilyNerdIcons
            color: root.colors.tertiary
            width: 14
            horizontalAlignment: Text.AlignHCenter
          }

          Text {
            text: model.ssid
            color: root.colors.backgroundText
            font.pixelSize: 12
            font.family: Style.fontFamily
            font.weight: Font.Medium
            width: 110
            elide: Text.ElideRight
          }

          Text {
            text: {
              let sec = model.security || ""
              if (sec === "psk") return "󰌆"
              if (sec === "open") return "󰌊"
              if (sec === "8021x") return "󰌆"
              return sec !== "" ? "󰌆" : ""
            }
            font.pixelSize: 11
            font.family: Style.fontFamilyNerdIcons
            color: root.colors.tertiary
            width: 14
            horizontalAlignment: Text.AlignHCenter
          }

          Text {
            text: isKnown ? "󰸞" : ""
            font.pixelSize: 11
            font.family: Style.fontFamilyNerdIcons
            color: Qt.rgba(root.colors.primary.r, root.colors.primary.g, root.colors.primary.b, 0.7)
            width: 12
            horizontalAlignment: Text.AlignHCenter
          }
        }

        MouseArea {
          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor
          acceptedButtons: Qt.LeftButton | Qt.RightButton
          onClicked: function(mouse) {
            var ssid = model.ssid
            if (mouse.button === Qt.RightButton) {
              if (isKnown) WifiService.forgetNetwork(ssid)
              return
            }
            if (!isSecured || isKnown) {
              root._connectKnown(ssid)
              return
            }
            root.pendingSsid = ssid
            root.pendingSecurity = model.security || ""
            pwInput.text = ""
          }
        }
      }
    }
  }
}
