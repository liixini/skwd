import QtQuick
import QtQuick.Controls
import "../.."

Rectangle {
  id: root

  required property var colors
  required property var historyModel

  property real contentWidth: 360
  property string side: "right"

  property bool active: false

  signal dismissRequested(int index)
  signal clearAllRequested()

  readonly property real animatedHeight: _animatedHeight
  property real _targetHeight: 0
  property real _animatedHeight: _targetHeight
  Behavior on _animatedHeight {
    NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
  }

  readonly property int desiredHeight: Math.min(420, 60 + 84 * Math.max(1, historyModel ? historyModel.count : 1))

  height: _animatedHeight
  visible: _animatedHeight > 0
  color: Qt.rgba(root.colors.surface.r, root.colors.surface.g, root.colors.surface.b, 0.92)

  onActiveChanged: _targetHeight = active ? desiredHeight : 0
  onDesiredHeightChanged: if (active) _targetHeight = desiredHeight

  Rectangle {
    anchors.bottom: parent.bottom
    anchors.left: parent.left
    anchors.right: parent.right
    height: 2
    color: root.colors.primary
    property real animatedWidth: root.visible ? parent.width : 0
    width: animatedWidth
    Behavior on animatedWidth { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
  }

  Item {
    id: pane
    anchors.left:  root.side === "left"  ? parent.left  : undefined
    anchors.right: root.side === "right" ? parent.right : undefined
    anchors.leftMargin:  root.side === "left"  ? 12 : 0
    anchors.rightMargin: root.side === "right" ? 12 : 0
    anchors.top: parent.top
    anchors.bottom: parent.bottom
    anchors.topMargin: 10
    anchors.bottomMargin: 10
    width: root.contentWidth - 24

    opacity: root.active && root._animatedHeight > 80 ? 1 : 0
    transform: Translate {
      y: root.active && root._animatedHeight > 80 ? 0 : -15
    }
    Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
    Behavior on y { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

    Column {
      anchors.fill: parent
      spacing: 8

      Row {
        width: parent.width
        spacing: 8

        Text {
          text: "NOTIFICATIONS"
          color: root.colors.primary
          font.pixelSize: 14
          font.family: Style.fontFamily
          font.weight: Font.DemiBold
          anchors.verticalCenter: parent.verticalCenter
        }

        Text {
          text: (root.historyModel ? root.historyModel.count : 0) + " in session"
          color: Qt.rgba(root.colors.tertiary.r, root.colors.tertiary.g, root.colors.tertiary.b, 0.6)
          font.pixelSize: 11
          font.family: Style.fontFamily
          anchors.verticalCenter: parent.verticalCenter
        }

        Item { width: Math.max(0, parent.width - 240); height: 1 }

        Rectangle {
          width: clearLabel.implicitWidth + 14
          height: 22
          radius: 4
          color: clearMouse.containsMouse
            ? Qt.rgba(root.colors.primary.r, root.colors.primary.g, root.colors.primary.b, 0.25)
            : Qt.rgba(root.colors.primary.r, root.colors.primary.g, root.colors.primary.b, 0.10)
          visible: (root.historyModel ? root.historyModel.count : 0) > 0
          anchors.verticalCenter: parent.verticalCenter

          Text {
            id: clearLabel
            anchors.centerIn: parent
            text: "CLEAR ALL"
            color: root.colors.primary
            font.family: Style.fontFamily; font.pixelSize: 10
            font.weight: Font.Bold; font.letterSpacing: 0.5
          }
          MouseArea {
            id: clearMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.clearAllRequested()
          }
        }
      }

      Text {
        visible: !root.historyModel || root.historyModel.count === 0
        width: parent.width
        text: "No notifications yet this session."
        color: Qt.rgba(root.colors.tertiary.r, root.colors.tertiary.g, root.colors.tertiary.b, 0.55)
        font.family: Style.fontFamily
        font.pixelSize: 12
        font.italic: true
        horizontalAlignment: Text.AlignHCenter
        topPadding: 18
      }

      ListView {
        width: parent.width
        height: parent.height - 40
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
        spacing: 6
        model: root.historyModel
        visible: root.historyModel && root.historyModel.count > 0

        delegate: Rectangle {
          required property int index
          required property var model
          width: ListView.view ? ListView.view.width : 0
          height: contentCol.implicitHeight + 14
          radius: 6
          color: Qt.rgba(root.colors.surfaceContainer.r, root.colors.surfaceContainer.g, root.colors.surfaceContainer.b, 0.55)
          border.width: 1
          border.color: Qt.rgba(root.colors.outline.r, root.colors.outline.g, root.colors.outline.b, 0.15)

          Column {
            id: contentCol
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 7
            spacing: 2

            Row {
              width: parent.width
              spacing: 6

              Text {
                text: (model.appName || "Notification").toUpperCase()
                color: root.colors.primary
                font.family: Style.fontFamily; font.pixelSize: 10
                font.weight: Font.Bold; font.letterSpacing: 0.8
                anchors.verticalCenter: parent.verticalCenter
              }

              Text {
                text: model.timeText || ""
                color: Qt.rgba(root.colors.tertiary.r, root.colors.tertiary.g, root.colors.tertiary.b, 0.55)
                font.family: Style.fontFamilyCode
                font.pixelSize: 9
                anchors.verticalCenter: parent.verticalCenter
              }

              Item { width: Math.max(0, parent.width - 180); height: 1 }

              Text {
                text: "✕"
                color: closeMouse.containsMouse ? "#e57373" : Qt.rgba(root.colors.tertiary.r, root.colors.tertiary.g, root.colors.tertiary.b, 0.55)
                font.pixelSize: 13
                anchors.verticalCenter: parent.verticalCenter
                MouseArea {
                  id: closeMouse
                  anchors.fill: parent
                  anchors.margins: -4
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onClicked: root.dismissRequested(index)
                }
              }
            }

            Text {
              width: parent.width
              text: model.summary || ""
              color: root.colors.surfaceText
              font.family: Style.fontFamily
              font.pixelSize: 12
              font.weight: Font.Medium
              wrapMode: Text.WordWrap
              elide: Text.ElideRight
              maximumLineCount: 2
              visible: text.length > 0
            }

            Text {
              width: parent.width
              text: model.body || ""
              color: Qt.rgba(root.colors.surfaceText.r, root.colors.surfaceText.g, root.colors.surfaceText.b, 0.75)
              font.family: Style.fontFamily
              font.pixelSize: 11
              wrapMode: Text.WordWrap
              elide: Text.ElideRight
              maximumLineCount: 4
              visible: text.length > 0
            }
          }
        }
      }
    }
  }
}
