
import QtQuick
import "../.."

Rectangle {
  id: root

  required property var colors
  required property var clock

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
      _targetHeight = clockColumn.implicitHeight + 24
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
    id: clockColumn
    anchors.left:  root.side === "left"  ? parent.left  : undefined
    anchors.right: root.side === "right" ? parent.right : undefined
    anchors.leftMargin:  root.side === "left"  ? 12 : 0
    anchors.rightMargin: root.side === "right" ? 12 : 0
    anchors.bottom: parent.bottom
    anchors.bottomMargin: 12
    spacing: 8
    width: root.contentWidth - 24

    property int monthOffset: 0

    onImplicitHeightChanged: {
      if (root.active) {
        root._targetHeight = clockColumn.implicitHeight + 24
      }
    }

    opacity: root.active && root._animatedHeight > (clockColumn.implicitHeight * 0.5) ? 1 : 0
    transform: Translate {
      y: root.active && root._animatedHeight > (clockColumn.implicitHeight * 0.5) ? 0 : -15
    }
    Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
    Behavior on y { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }


    Item {
      id: header
      width: parent.width
      height: 18

      Text {
        id: prevArrow
        text: "󰁍"
        font.pixelSize: 14
        font.family: Style.fontFamilyNerdIcons
        color: root.colors.primary
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        MouseArea {
          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor
          onClicked: swap.swipe(-1)
        }
      }

      Text {
        id: nextArrow
        text: "󰁔"
        font.pixelSize: 14
        font.family: Style.fontFamilyNerdIcons
        color: root.colors.primary
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        MouseArea {
          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor
          onClicked: swap.swipe(1)
        }
      }
    }


    Item {
      id: swap
      width: parent.width
      height: swapContent.implicitHeight

      property real swapX: 0
      property real swapOpacity: 1
      property bool animating: false

      function swipe(direction) {
        if (animating) return
        swapAnim.direction = direction
        swapAnim.start()
      }

      SequentialAnimation {
        id: swapAnim
        property int direction: 1

        ScriptAction { script: swap.animating = true }
        ParallelAnimation {
          NumberAnimation {
            target: swap; property: "swapX"
            to: -90 * swapAnim.direction
            duration: 180
            easing.type: Easing.InCubic
          }
          NumberAnimation {
            target: swap; property: "swapOpacity"
            to: 0
            duration: 180
            easing.type: Easing.InCubic
          }
        }
        ScriptAction {
          script: {
            clockColumn.monthOffset += swapAnim.direction
            swap.swapX = 90 * swapAnim.direction
          }
        }
        ParallelAnimation {
          NumberAnimation {
            target: swap; property: "swapX"
            to: 0
            duration: 260
            easing.type: Easing.OutCubic
          }
          NumberAnimation {
            target: swap; property: "swapOpacity"
            to: 1
            duration: 260
            easing.type: Easing.OutCubic
          }
        }
        ScriptAction { script: swap.animating = false }
      }

      Column {
        id: swapContent
        width: parent.width
        spacing: 8
        opacity: swap.swapOpacity
        transform: Translate { x: swap.swapX }

        Text {
          property date displayDate: {
            let d = new Date(root.clock.date)
            d.setMonth(d.getMonth() + clockColumn.monthOffset)
            return d
          }
          text: Qt.formatDate(displayDate, "MMMM yyyy").toUpperCase()
          color: root.colors.primary
          font.pixelSize: 14
          font.family: Style.fontFamily
          font.weight: Font.DemiBold
          anchors.horizontalCenter: parent.horizontalCenter
        }

        Row {
          spacing: 2
          anchors.horizontalCenter: parent.horizontalCenter
          Repeater {
            model: ["M", "T", "W", "T", "F", "S", "S"]
            delegate: Text {
              text: modelData
              color: root.colors.primary
              font.pixelSize: 11
              font.family: Style.fontFamily
              font.weight: Font.Medium
              width: 28
              horizontalAlignment: Text.AlignHCenter
              opacity: 0.6
            }
          }
        }

        Grid {
      anchors.horizontalCenter: parent.horizontalCenter
      columns: 7
      rows: 6
      columnSpacing: 2
      rowSpacing: 2
      width: 7 * 28 + 6 * 2
      height: 6 * 28 + 5 * 2

      property date displayDate: {
        let d = new Date(root.clock.date)
        d.setMonth(d.getMonth() + clockColumn.monthOffset)
        return d
      }
      property int year: displayDate.getFullYear()
      property int month: displayDate.getMonth()
      property int today: root.clock.date.getDate()
      property int currentMonth: root.clock.date.getMonth()
      property int currentYear: root.clock.date.getFullYear()
      property date firstOfMonth: new Date(year, month, 1)
      property int firstDayOfWeek: (firstOfMonth.getDay() + 6) % 7
      property int daysInMonth: new Date(year, month + 1, 0).getDate()
      property int totalCells: 42

      Repeater {
        model: parent.totalCells

        delegate: Item {
          width: 28
          height: 28

          property int dayNum: index - parent.firstDayOfWeek + 1
          property bool isValidDay: dayNum > 0 && dayNum <= parent.daysInMonth
          property bool isToday: isValidDay && dayNum === parent.today && parent.month === parent.currentMonth && parent.year === parent.currentYear
          property bool hasEvents: false

          Canvas {
            id: dayBg
            anchors.fill: parent
            visible: isValidDay

            onPaint: {
              var ctx = getContext("2d")
              ctx.clearRect(0, 0, width, height)

              ctx.beginPath()
              var slant = 4
              ctx.moveTo(slant, 0)
              ctx.lineTo(width, 0)
              ctx.lineTo(width - slant, height)
              ctx.lineTo(0, height)
              ctx.closePath()

              if (isToday) {
                ctx.fillStyle = Qt.rgba(root.colors.primary.r, root.colors.primary.g, root.colors.primary.b, 0.3)
              } else if (dayMouseArea.containsMouse) {
                ctx.fillStyle = Qt.rgba(root.colors.primary.r, root.colors.primary.g, root.colors.primary.b, 0.15)
              } else {
                ctx.fillStyle = Qt.rgba(root.colors.surface.r, root.colors.surface.g, root.colors.surface.b, 0.3)
              }
              ctx.fill()

              ctx.strokeStyle = isToday ? root.colors.primary : Qt.rgba(root.colors.primary.r, root.colors.primary.g, root.colors.primary.b, 0.3)
              ctx.lineWidth = isToday ? 1.5 : 1
              ctx.stroke()
            }

            Connections {
              target: dayMouseArea
              function onContainsMouseChanged() { dayBg.requestPaint() }
            }
          }

          Rectangle {
            anchors.bottom: parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottomMargin: 3
            width: 3
            height: 3
            radius: 1.5
            color: root.colors.tertiary
            visible: hasEvents
          }

          Text {
            anchors.centerIn: parent
            text: isValidDay ? dayNum : ""
            color: isToday ? root.colors.primary : root.colors.backgroundText
            font.pixelSize: 12
            font.family: Style.fontFamily
            font.weight: isToday ? Font.Bold : Font.Medium
            visible: isValidDay
          }

          MouseArea {
            id: dayMouseArea
            anchors.fill: parent
            hoverEnabled: isValidDay
            cursorShape: isValidDay ? Qt.PointingHandCursor : Qt.ArrowCursor
            enabled: isValidDay
            onEntered: if (isValidDay) dayBg.requestPaint()
            onExited: if (isValidDay) dayBg.requestPaint()
            onClicked: {}
          }
        }
      }
    }
      }
    }
  }
}
