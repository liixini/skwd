import QtQuick
import "../.."

Rectangle {
  id: root

  required property var colors

  property real contentWidth: 320
  property string side: "right"

  property bool active: false
  property var processes: []
  property real totalMb: 0
  property real totalRssMb: 0

  function _fmt(mb) {
    return mb >= 1024 ? (mb / 1024).toFixed(2) + " GB" : Math.round(mb) + " MB"
  }

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
    if (active) _targetHeight = qsmemColumn.implicitHeight + 24
    else _targetHeight = 0
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
    id: qsmemColumn
    anchors.left:  root.side === "left"  ? parent.left  : undefined
    anchors.right: root.side === "right" ? parent.right : undefined
    anchors.leftMargin:  root.side === "left"  ? 12 : 0
    anchors.rightMargin: root.side === "right" ? 12 : 0
    anchors.bottom: parent.bottom
    anchors.bottomMargin: 12
    spacing: 6
    width: root.contentWidth - 24

    onImplicitHeightChanged: {
      if (root.active) root._targetHeight = qsmemColumn.implicitHeight + 24
    }

    opacity: root.active && root._animatedHeight > (qsmemColumn.implicitHeight * 0.5) ? 1 : 0
    transform: Translate {
      y: root.active && root._animatedHeight > (qsmemColumn.implicitHeight * 0.5) ? 0 : -15
    }
    Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
    Behavior on y { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

    Item {
      width: parent.width
      height: Math.max(headerLabel.implicitHeight, headerData.implicitHeight)

      Text {
        id: headerLabel
        text: "SKWD MEMORY"
        color: root.colors.primary
        font.pixelSize: 14
        font.family: Style.fontFamily
        font.weight: Font.DemiBold
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
      }

      Column {
        id: headerData
        spacing: 2
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        Text {
          text: root._fmt(root.totalMb) + " PSS"
          color: root.colors.tertiary
          font.pixelSize: 13
          font.family: Style.fontFamily
          font.weight: Font.Medium
          horizontalAlignment: Text.AlignRight
          anchors.right: parent.right
        }
        Text {
          text: root._fmt(root.totalRssMb) + " RSS"
          color: Qt.rgba(root.colors.tertiary.r, root.colors.tertiary.g, root.colors.tertiary.b, 0.5)
          font.pixelSize: 10
          font.family: Style.fontFamily
          horizontalAlignment: Text.AlignRight
          anchors.right: parent.right
        }
      }
    }

    Rectangle {
      width: parent.width
      height: 1
      color: Qt.rgba(root.colors.primary.r, root.colors.primary.g, root.colors.primary.b, 0.18)
    }

    Text {
      visible: root.processes.length === 0
      text: "no quickshell processes detected"
      color: Qt.rgba(root.colors.tertiary.r, root.colors.tertiary.g, root.colors.tertiary.b, 0.6)
      font.pixelSize: 12
      font.family: Style.fontFamily
      font.italic: true
    }

    Repeater {
      model: root.processes
      delegate: Item {
        id: procRow
        required property var modelData
        width: qsmemColumn.width
        height: Math.max(procLabel.implicitHeight, procData.implicitHeight)

        Text {
          id: procLabel
          text: procRow.modelData.label
          color: root.colors.tertiary
          font.pixelSize: 12
          font.family: Style.fontFamily
          font.weight: Font.Medium
          anchors.left: parent.left
          anchors.verticalCenter: parent.verticalCenter
        }

        Column {
          id: procData
          spacing: 1
          anchors.right: parent.right
          anchors.verticalCenter: parent.verticalCenter
          Text {
            text: root._fmt(procRow.modelData.pss)
            color: root.colors.tertiary
            font.pixelSize: 12
            font.family: Style.fontFamily
            horizontalAlignment: Text.AlignRight
            anchors.right: parent.right
          }
          Text {
            text: root._fmt(procRow.modelData.rss) + " rss"
            color: Qt.rgba(root.colors.tertiary.r, root.colors.tertiary.g, root.colors.tertiary.b, 0.45)
            font.pixelSize: 9
            font.family: Style.fontFamily
            horizontalAlignment: Text.AlignRight
            anchors.right: parent.right
          }
        }
      }
    }
  }
}
