import QtQuick
import "../.."

Rectangle {
  id: root

  required property var colors

  property real contentWidth: 320
  property string side: "right"

  property bool active: false
  property int currentPercent: 0

  signal requestSet(int percent)

  readonly property real animatedHeight: _animatedHeight
  property real _targetHeight: 0
  property real _animatedHeight: _targetHeight
  Behavior on _animatedHeight {
    NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
  }

  height: _animatedHeight
  visible: _animatedHeight > 0
  color: Qt.rgba(root.colors.surface.r, root.colors.surface.g, root.colors.surface.b, 0.88)

  onActiveChanged: {
    if (active) _targetHeight = brightnessColumn.implicitHeight + 24
    else _targetHeight = 0
  }

  Rectangle {
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
    id: brightnessColumn
    anchors.left:  root.side === "left"  ? parent.left  : undefined
    anchors.right: root.side === "right" ? parent.right : undefined
    anchors.leftMargin:  root.side === "left"  ? 12 : 0
    anchors.rightMargin: root.side === "right" ? 12 : 0
    anchors.bottom: parent.bottom
    anchors.bottomMargin: 12
    spacing: 10
    width: root.contentWidth - 24

    onImplicitHeightChanged: {
      if (root.active) root._targetHeight = brightnessColumn.implicitHeight + 24
    }

    opacity: root.active && root._animatedHeight > (brightnessColumn.implicitHeight * 0.5) ? 1 : 0
    transform: Translate {
      y: root.active && root._animatedHeight > (brightnessColumn.implicitHeight * 0.5) ? 0 : -15
    }
    Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
    Behavior on y { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

    Row {
      width: parent.width
      spacing: 8

      Text {
        text: "BRIGHTNESS"
        color: root.colors.primary
        font.pixelSize: 14
        font.family: Style.fontFamily
        font.weight: Font.DemiBold
        anchors.verticalCenter: parent.verticalCenter
      }

      Item { width: parent.width - 180; height: 1 }

      Text {
        text: Math.round(brightnessColumn._displayValue * 100) + "%"
        color: root.colors.tertiary
        font.pixelSize: 13
        font.family: Style.fontFamily
        font.weight: Font.Medium
        anchors.verticalCenter: parent.verticalCenter
      }
    }

    property real _localValue: 0
    property bool _dragging: false
    readonly property real _ext: Math.max(0, Math.min(1, root.currentPercent / 100.0))
    readonly property real _displayValue: _dragging ? _localValue : _ext

    Item {
      id: sliderHost
      width: parent.width
      height: 18

      Rectangle {
        id: track
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        height: 4
        radius: 2
        color: Qt.rgba(root.colors.primary.r, root.colors.primary.g, root.colors.primary.b, 0.18)

        Rectangle {
          anchors.left: parent.left
          anchors.verticalCenter: parent.verticalCenter
          height: parent.height
          width: parent.width * Math.max(0, Math.min(1, brightnessColumn._displayValue))
          radius: 2
          color: root.colors.primary
        }
      }

      Rectangle {
        width: 12; height: 12; radius: 6
        color: root.colors.primary
        border.width: 1
        border.color: Qt.rgba(root.colors.surface.r, root.colors.surface.g, root.colors.surface.b, 0.85)
        anchors.verticalCenter: parent.verticalCenter
        x: track.x + (track.width * Math.max(0, Math.min(1, brightnessColumn._displayValue))) - width / 2
        scale: dragArea.containsMouse || brightnessColumn._dragging ? 1.25 : 1
        Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
      }

      MouseArea {
        id: dragArea
        anchors.fill: parent
        anchors.margins: -6
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        preventStealing: true

        function _commit(localX) {
          var w = track.width
          if (w <= 0) return
          var v = Math.max(0, Math.min(1, (localX - 6) / w))
          brightnessColumn._localValue = v
          root.requestSet(Math.round(v * 100))
        }

        onPressed: function(mouse) {
          brightnessColumn._dragging = true
          _commit(mouse.x)
        }
        onPositionChanged: function(mouse) {
          if (brightnessColumn._dragging) _commit(mouse.x)
        }
        onReleased: brightnessColumn._dragging = false
        onCanceled: brightnessColumn._dragging = false
        onWheel: function(wheel) {
          var step = wheel.angleDelta.y > 0 ? 5 : -5
          var next = Math.max(0, Math.min(100, root.currentPercent + step))
          root.requestSet(next)
        }
      }
    }
  }
}
