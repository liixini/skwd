import QtQuick
import "../.."

Item {
  id: root

  required property var colors
  required property var node

  height: 14

  property real _localValue: 0
  property bool _dragging: false
  readonly property real _ext: node && node.audio ? node.audio.volume : 0
  readonly property real _displayValue: Math.max(0, Math.min(1.5, _dragging ? _localValue : _ext))

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
      width: parent.width * Math.min(1, root._displayValue)
      radius: 2
      color: root.colors.primary
    }
  }

  Rectangle {
    width: 10
    height: 10
    radius: 5
    color: root.colors.primary
    border.width: 1
    border.color: Qt.rgba(root.colors.surface.r, root.colors.surface.g, root.colors.surface.b, 0.85)
    anchors.verticalCenter: parent.verticalCenter
    x: track.x + (track.width * Math.min(1, root._displayValue)) - width / 2
    scale: dragArea.containsMouse || root._dragging ? 1.25 : 1
    Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
  }

  MouseArea {
    id: dragArea
    anchors.fill: parent
    anchors.margins: -6
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    preventStealing: true

    onPressed: function(mouse) {
      root._dragging = true
      _commit(mouse.x)
    }
    onPositionChanged: function(mouse) {
      if (root._dragging) _commit(mouse.x)
    }
    onReleased: root._dragging = false
    onCanceled: root._dragging = false

    function _commit(localX) {
      var w = track.width
      if (w <= 0) return
      var trackX = localX - 6
      var v = Math.max(0, Math.min(1, trackX / w))
      root._localValue = v
      if (root.node && root.node.audio) root.node.audio.volume = v
    }
  }
}
