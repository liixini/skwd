
import Quickshell.Services.Pipewire
import QtQuick
import "../.."

Rectangle {
  id: root

  required property var colors

  property real contentWidth: 320
  property string side: "right"

  property bool active: false
  readonly property real animatedHeight: _animatedHeight

  property real _targetHeight: 0
  property real _animatedHeight: _targetHeight
  Behavior on _animatedHeight {
    NumberAnimation {
      duration: 320
      easing.type: Easing.BezierSpline
      easing.bezierCurve: [0.05, 0.7, 0.1, 1.0, 1.0, 1.0]
    }
  }

  height: _animatedHeight
  visible: _animatedHeight > 0
  clip: true
  color: Qt.rgba(root.colors.surface.r, root.colors.surface.g, root.colors.surface.b, 0.88)
  radius: Config.barStyle === "pill" ? 16 : 0
  topLeftRadius: 0
  topRightRadius: 0


  onActiveChanged: {
    if (active) {
      _targetHeight = volumeColumn.implicitHeight + 24
    } else {
      _targetHeight = 0
    }
  }


  Rectangle {
    visible: Config.barStyle !== "pill"
    anchors.bottom: parent.bottom
    anchors.left: parent.left
    anchors.right: parent.right
    height: 2
    color: root.colors.primary
    property real animatedWidth: root.visible ? parent.width : 0
    width: animatedWidth
    Behavior on animatedWidth {
      NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
    }
  }

  
  Column {
    id: volumeColumn
    anchors.left:  root.side === "left"  ? parent.left  : undefined
    anchors.right: root.side === "right" ? parent.right : undefined
    anchors.leftMargin:  root.side === "left"  ? 12 : 0
    anchors.rightMargin: root.side === "right" ? 12 : 0
    anchors.bottom: parent.bottom
    anchors.bottomMargin: 12
    spacing: 10
    width: root.contentWidth - 24

    onImplicitHeightChanged: {
      if (root.active) {
        root._targetHeight = volumeColumn.implicitHeight + 24
      }
    }

    
    opacity: root.active && root._animatedHeight > (volumeColumn.implicitHeight * 0.5) ? 1 : 0
    transform: Translate {
      y: root.active && root._animatedHeight > (volumeColumn.implicitHeight * 0.5) ? 0 : -15
    }
    Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
    Behavior on y { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

    
    PwObjectTracker {
      id: volumeNodeTracker
      objects: {
        let allNodes = Pipewire.nodes.values
        let audioDevices = allNodes.filter(n => n && !n.isStream && n.audio)
        return audioDevices
      }
    }

    
    Text {
      text: "OUTPUT"
      color: root.colors.primary
      font.pixelSize: 14
      font.family: Style.fontFamily
      font.weight: Font.DemiBold
    }

    
    Repeater {
      model: Pipewire.nodes.values.filter(n => n && n.isSink && !n.isStream && n.audio)

      delegate: Column {
        width: volumeColumn.width
        spacing: 4

        Item {
          width: parent.width
          height: sinkRow.implicitHeight

          Row {
            id: sinkRow
            spacing: 12

            Text {
              text: modelData === Pipewire.defaultAudioSink ? "󰕾" : "󰖀"
              font.pixelSize: 12
              font.family: Style.fontFamilyNerdIcons
              color: root.colors.primary
              width: 14
              horizontalAlignment: Text.AlignHCenter
            }

            Text {
              text: modelData.description || modelData.name || "Unknown Output"
              color: root.colors.backgroundText
              font.pixelSize: 12
              font.family: Style.fontFamily
              font.weight: Font.Medium
              width: 120
              elide: Text.ElideRight
            }

            Text {
              text: Math.round((modelData.audio?.volume ?? 0) * 100) + "%"
              color: root.colors.tertiary
              font.pixelSize: 12
              font.family: Style.fontFamily
              font.weight: Font.Medium
              width: 32
              horizontalAlignment: Text.AlignRight
            }
          }

          MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: { Pipewire.preferredDefaultAudioSink = modelData }
          }
        }

        VolumeSlider {
          width: parent.width
          colors: root.colors
          node: modelData
        }
      }
    }

    
    Text {
      text: "INPUT"
      color: root.colors.primary
      font.pixelSize: 14
      font.family: Style.fontFamily
      font.weight: Font.DemiBold
      topPadding: 8
    }

    
    Repeater {
      model: Pipewire.nodes.values.filter(n => n && !n.isSink && !n.isStream && n.audio)

      delegate: Column {
        width: volumeColumn.width
        spacing: 4

        Item {
          width: parent.width
          height: sourceRow.implicitHeight

          Row {
            id: sourceRow
            spacing: 12

            Text {
              text: modelData === Pipewire.defaultAudioSource ? "󰍬" : "󰍭"
              font.pixelSize: 12
              font.family: Style.fontFamilyNerdIcons
              color: root.colors.primary
              width: 14
              horizontalAlignment: Text.AlignHCenter
            }

            Text {
              text: modelData.description || modelData.name || "Unknown Input"
              color: root.colors.backgroundText
              font.pixelSize: 12
              font.family: Style.fontFamily
              font.weight: Font.Medium
              width: 120
              elide: Text.ElideRight
            }

            Text {
              text: Math.round((modelData.audio?.volume ?? 0) * 100) + "%"
              color: root.colors.tertiary
              font.pixelSize: 12
              font.family: Style.fontFamily
              font.weight: Font.Medium
              width: 32
              horizontalAlignment: Text.AlignRight
            }
          }

          MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: { Pipewire.preferredDefaultAudioSource = modelData }
          }
        }

        VolumeSlider {
          width: parent.width
          colors: root.colors
          node: modelData
        }
      }
    }
  }
}
