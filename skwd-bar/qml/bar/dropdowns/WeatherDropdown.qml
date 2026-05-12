
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
      _targetHeight = contentColumn.implicitHeight + 24
    } else {
      _targetHeight = 0
    }
  }

  function _iconFor(desc) {
    if (!desc) return "󰖐"
    var d = desc.toLowerCase()
    if (d.includes("thunder")) return "󰙾"
    if (d.includes("blizzard") || d.includes("blowing snow") || d.includes("heavy snow")) return "󰼶"
    if (d.includes("snow")) return "󰖘"
    if (d.includes("freezing") || d.includes("ice pellet") || d.includes("sleet")) return "󰙿"
    if (d.includes("torrential") || d.includes("heavy rain") || d.includes("violent") || d.includes("heavy shower")) return "󰖖"
    if (d.includes("rain") || d.includes("drizzle") || d.includes("shower")) return "󰖗"
    if (d.includes("fog") || d.includes("mist")) return "󰖑"
    if (d.includes("partly")) return "󰖕"
    if (d.includes("overcast") || d.includes("cloudy")) return "󰖐"
    if (d.includes("sunny") || d.includes("clear")) return "󰖙"
    return "󰖐"
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
    id: contentColumn
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
        root._targetHeight = contentColumn.implicitHeight + 24
      }
    }

    opacity: root.active && root._animatedHeight > (contentColumn.implicitHeight * 0.5) ? 1 : 0
    transform: Translate {
      y: root.active && root._animatedHeight > (contentColumn.implicitHeight * 0.5) ? 0 : -15
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
          anchors.margins: -6
          enabled: header.hasMultiple
          cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
          onClicked: swap.swipe(-1)
        }
      }

      Text {
        text: (WeatherService.currentCity || "").toUpperCase()
        color: root.colors.primary
        font.pixelSize: 13
        font.family: Style.fontFamily
        font.weight: Font.DemiBold
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
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
          anchors.margins: -6
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
          NumberAnimation { target: swap; property: "swapX"; to: -90 * swapAnim.direction; duration: 180; easing.type: Easing.InCubic }
          NumberAnimation { target: swap; property: "swapOpacity"; to: 0; duration: 180; easing.type: Easing.InCubic }
        }
        ScriptAction {
          script: {
            WeatherService.advance(swapAnim.direction)
            swap.swapX = 90 * swapAnim.direction
          }
        }
        ParallelAnimation {
          NumberAnimation { target: swap; property: "swapX"; to: 0; duration: 260; easing.type: Easing.OutCubic }
          NumberAnimation { target: swap; property: "swapOpacity"; to: 1; duration: 260; easing.type: Easing.OutCubic }
        }
        ScriptAction { script: swap.animating = false }
      }

      Column {
        id: swapContent
        width: parent.width
        spacing: 10
        opacity: swap.swapOpacity
        transform: Translate { x: swap.swapX }

        Item {
          id: nowPanel
          width: parent.width
          height: Math.max(nowIcon.implicitHeight, nowText.implicitHeight)

          Text {
            id: nowIcon
            text: root._iconFor(WeatherService.description)
            font.pixelSize: 40
            font.family: Style.fontFamilyNerdIcons
            color: root.colors.primary
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
          }

          Column {
            id: nowText
            anchors.left: nowIcon.right
            anchors.leftMargin: 10
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 1

            Text {
              text: WeatherService.temp
              font.pixelSize: 30
              font.family: Style.fontFamily
              font.weight: Font.Light
              color: root.colors.backgroundText
              lineHeight: 1.0
            }
            Text {
              text: WeatherService.description
              color: root.colors.backgroundText
              opacity: 0.75
              font.pixelSize: 12
              font.family: Style.fontFamily
              elide: Text.ElideRight
              width: parent.width
            }
          }
        }

        Row {
          id: dayCardsRow
          width: parent.width
          spacing: 4
          property int cardCount: Math.max(1, WeatherService.forecast.length)
          property real cardWidth: (width - (cardCount - 1) * spacing) / cardCount

          Repeater {
            model: WeatherService.forecast
            delegate: Rectangle {
              width: dayCardsRow.cardWidth
              height: 124
              radius: 8
              property bool isCurrent: index === 0
              color: isCurrent ? Qt.rgba(root.colors.primary.r, root.colors.primary.g, root.colors.primary.b, 0.12)
                               : "transparent"
              border.width: isCurrent ? 1 : 0
              border.color: Qt.rgba(root.colors.primary.r, root.colors.primary.g, root.colors.primary.b, 0.35)

              Column {
                anchors.fill: parent
                anchors.margins: 4
                spacing: 1

                Text {
                  text: modelData.day
                  color: root.colors.backgroundText
                  font.pixelSize: 10
                  font.family: Style.fontFamily
                  font.weight: Font.Medium
                  anchors.horizontalCenter: parent.horizontalCenter
                }
                Text {
                  text: root._iconFor(modelData.desc)
                  color: root.colors.primary
                  font.pixelSize: 20
                  font.family: Style.fontFamilyNerdIcons
                  anchors.horizontalCenter: parent.horizontalCenter
                }
                Text {
                  text: modelData.high
                  color: root.colors.backgroundText
                  font.pixelSize: 11
                  font.family: Style.fontFamily
                  font.weight: Font.DemiBold
                  anchors.horizontalCenter: parent.horizontalCenter
                }
                Text {
                  text: modelData.low
                  color: root.colors.tertiary
                  font.pixelSize: 10
                  font.family: Style.fontFamily
                  opacity: 0.7
                  anchors.horizontalCenter: parent.horizontalCenter
                }
                Row {
                  visible: typeof modelData.rain === "number" && modelData.rain >= 0.1
                  spacing: 3
                  anchors.horizontalCenter: parent.horizontalCenter
                  Text {
                    text: "󰖎"
                    color: root.colors.tertiary
                    font.pixelSize: 11
                    font.family: Style.fontFamilyNerdIcons
                    opacity: 0.85
                    anchors.verticalCenter: parent.verticalCenter
                  }
                  Text {
                    text: modelData.rain < 10 ? modelData.rain.toFixed(1) : Math.round(modelData.rain) + ""
                    color: root.colors.tertiary
                    font.pixelSize: 11
                    font.family: Style.fontFamily
                    opacity: 0.85
                    anchors.verticalCenter: parent.verticalCenter
                  }
                }
                Row {
                  visible: typeof modelData.wind === "number" && modelData.wind > 0
                  spacing: 3
                  anchors.horizontalCenter: parent.horizontalCenter
                  Text {
                    text: "󰖝"
                    color: root.colors.tertiary
                    font.pixelSize: 11
                    font.family: Style.fontFamilyNerdIcons
                    opacity: 0.85
                    anchors.verticalCenter: parent.verticalCenter
                  }
                  Text {
                    text: modelData.wind
                    color: root.colors.tertiary
                    font.pixelSize: 11
                    font.family: Style.fontFamily
                    opacity: 0.85
                    anchors.verticalCenter: parent.verticalCenter
                  }
                }
              }
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
