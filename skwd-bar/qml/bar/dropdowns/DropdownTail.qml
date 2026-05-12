
import QtQuick
import "../.."

Rectangle {
  id: tail

  required property Item dropdown
  required property real barWidth
  required property real barSideMargin
  required property real tailTopMargin

  property real overlap: dropdown.radius

  property real _xPos: dropdown.side === "right"
    ? Math.max(barSideMargin, dropdown.x + dropdown.width - overlap)
    : barSideMargin

  x: _xPos
  width: dropdown.side === "right"
    ? Math.max(0, barWidth - barSideMargin - _xPos)
    : Math.max(0, dropdown.x + overlap - _xPos)

  anchors.top: parent.top
  anchors.topMargin: tail.tailTopMargin

  height: dropdown.height

  visible: dropdown.visible && width > 0.5
  color: dropdown.color
  z: dropdown.z - 0.1

  radius: dropdown.radius
  topLeftRadius: 0
  topRightRadius: 0
  bottomLeftRadius: dropdown.side === "right" ? 0 : dropdown.radius
  bottomRightRadius: dropdown.side === "left" ? 0 : dropdown.radius

  clip: true

  Rectangle {
    visible: Config.barStyle !== "pill"
    anchors.bottom: parent.bottom
    anchors.left: parent.left
    height: 2
    color: tail.dropdown.colors.primary
    property real animatedWidth: tail.visible ? tail.width : 0
    width: animatedWidth
    Behavior on animatedWidth {
      NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
    }
  }
}
