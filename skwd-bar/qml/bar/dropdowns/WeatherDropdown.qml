
import QtQuick
import "../.."
import "../../services"

Rectangle {
  id: root

  required property var colors

  property real contentWidth: 320
  property string side: "right"

  property bool active: false
  property string weatherCity: ""
  property var weatherForecast: []

  readonly property real animatedHeight: _animatedHeight

  property real _targetHeight: 0
  property real _animatedHeight: _targetHeight
  Behavior on _animatedHeight {
    NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
  }

  height: _animatedHeight
  visible: _animatedHeight > 0
  color: Qt.rgba(root.colors.surface.r, root.colors.surface.g, root.colors.surface.b, 0.88)
  radius: Config.barStyle === "pill" ? 16 : 0

  onActiveChanged: {
    if (active) {
      _targetHeight = forecastColumn.implicitHeight + 24
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
    id: forecastColumn
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
        root._targetHeight = forecastColumn.implicitHeight + 24
      }
    }


    opacity: root.active && root._animatedHeight > (forecastColumn.implicitHeight * 0.5) ? 1 : 0
    transform: Translate {
      y: root.active && root._animatedHeight > (forecastColumn.implicitHeight * 0.5) ? 0 : -15
    }
    Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
    Behavior on y { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }


    Item {
      id: header
      width: parent.width
      height: 18

      readonly property bool hasMultiple: WeatherService.cities.length > 1

      Text {
        id: prevArrow
        text: "󰁍"
        font.pixelSize: 14
        font.family: Style.fontFamilyNerdIcons
        color: header.hasMultiple ? root.colors.primary : Qt.rgba(root.colors.primary.r, root.colors.primary.g, root.colors.primary.b, 0.25)
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        MouseArea {
          anchors.fill: parent
          enabled: header.hasMultiple
          cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
          onClicked: swap.swipe(-1)
        }
      }

      Text {
        id: nextArrow
        text: "󰁔"
        font.pixelSize: 14
        font.family: Style.fontFamilyNerdIcons
        color: header.hasMultiple ? root.colors.primary : Qt.rgba(root.colors.primary.r, root.colors.primary.g, root.colors.primary.b, 0.25)
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        MouseArea {
          anchors.fill: parent
          enabled: header.hasMultiple
          cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
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
        if (WeatherService.cities.length <= 1) return
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
            WeatherService.advance(swapAnim.direction)
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
        spacing: 10
        opacity: swap.swapOpacity
        transform: Translate { x: swap.swapX }

        Text {
          text: (WeatherService.currentCity || "").toUpperCase()
          color: root.colors.primary
          font.pixelSize: 14
          font.family: Style.fontFamily
          font.weight: Font.DemiBold
        }

        Repeater {
          model: WeatherService.forecast.slice(0, 3)
          delegate: Row {
            spacing: 12

            Text {
              text: modelData.day
              color: root.colors.backgroundText
              font.pixelSize: 12
              font.family: Style.fontFamily
              font.weight: Font.Medium
              width: 60
            }

            Row {
              spacing: 6
              Text {
                text: "H: " + modelData.high
                color: root.colors.primary
                font.pixelSize: 12
                font.family: Style.fontFamily
                font.weight: Font.Medium
              }
              Text {
                text: "L: " + modelData.low
                color: root.colors.tertiary
                font.pixelSize: 12
                font.family: Style.fontFamily
                font.weight: Font.Medium
              }
            }

            Text {
              text: modelData.desc
              color: root.colors.backgroundText
              font.pixelSize: 12
              font.family: Style.fontFamily
              opacity: 0.85
              elide: Text.ElideRight
            }
          }
        }
      }
    }


    Row {
      visible: WeatherService.cities.length > 1
      spacing: 4
      anchors.horizontalCenter: parent.horizontalCenter

      Repeater {
        model: WeatherService.cities
        delegate: Rectangle {
          width: 6
          height: 6
          radius: 3
          property bool isCurrent: modelData === WeatherService.currentCity
          color: isCurrent
            ? root.colors.primary
            : Qt.rgba(root.colors.primary.r, root.colors.primary.g, root.colors.primary.b, 0.25)
          scale: isCurrent ? 1.2 : 1
          Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

          MouseArea {
            anchors.fill: parent
            anchors.margins: -4
            cursorShape: Qt.PointingHandCursor
            onClicked: WeatherService.selectCity(modelData)
          }
        }
      }
    }
  }
}
