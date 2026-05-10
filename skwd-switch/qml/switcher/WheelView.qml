import QtQuick
import QtQuick.Shapes
import ".."

Item {
  id: wheel

  property var model
  property int currentIndex: 0
  property var colors
  property var service
  property string fontFamily: ""
  property string fontFamilyIcons: ""

  property int outerRadius: 320
  property int innerRadius: 90
  property int iconSize: 80
  property int gap: 4
  property real startAngle: -90.0

  signal wheelClicked(int index)

  width: outerRadius * 2
  height: outerRadius * 2

  readonly property real _cx: width / 2
  readonly property real _cy: height / 2
  readonly property int _count: model ? model.count : 0
  readonly property real _arcDeg: _count > 0 ? 360.0 / _count : 360.0
  readonly property real _gapDeg: _count > 1 ? Math.min(_arcDeg * 0.18, gap) : 0
  readonly property real _midRadius: (outerRadius + innerRadius) / 2

  function _toRad(deg) { return deg * Math.PI / 180.0 }
  function _itemAngleStart(i) { return startAngle + i * _arcDeg + _gapDeg / 2 }
  function _itemAngleEnd(i)   { return startAngle + (i + 1) * _arcDeg - _gapDeg / 2 }
  function _itemMidAngle(i)   { return startAngle + (i + 0.5) * _arcDeg }

  function _arcPath(ctx, angStart, angEnd) {
    var a0 = _toRad(angStart)
    var a1 = _toRad(angEnd)
    var p0x = _cx + outerRadius * Math.cos(a0)
    var p0y = _cy + outerRadius * Math.sin(a0)
    ctx.beginPath()
    ctx.moveTo(p0x, p0y)
    ctx.arc(_cx, _cy, outerRadius, a0, a1, false)
    var p1x = _cx + innerRadius * Math.cos(a1)
    var p1y = _cy + innerRadius * Math.sin(a1)
    ctx.lineTo(p1x, p1y)
    ctx.arc(_cx, _cy, innerRadius, a1, a0, true)
    ctx.closePath()
  }


  Canvas {
    id: arcs
    anchors.fill: parent
    onPaint: {
      var ctx = getContext("2d")
      ctx.reset()
      var n = wheel._count
      for (var i = 0; i < n; i++) {
        var startA = wheel._itemAngleStart(i)
        var endA = wheel._itemAngleEnd(i)
        ctx.fillStyle = wheel.colors
          ? Qt.rgba(wheel.colors.surfaceContainer.r, wheel.colors.surfaceContainer.g, wheel.colors.surfaceContainer.b, 0.85)
          : Qt.rgba(0.1, 0.11, 0.18, 0.85)
        wheel._arcPath(ctx, startA, endA)
        ctx.fill()
        ctx.strokeStyle = Qt.rgba(0, 0, 0, 0.45)
        ctx.lineWidth = 1
        wheel._arcPath(ctx, startA, endA)
        ctx.stroke()
      }
    }
    Connections {
      target: wheel
      function onOuterRadiusChanged()  { arcs.requestPaint() }
      function onInnerRadiusChanged()  { arcs.requestPaint() }
      function onGapChanged()          { arcs.requestPaint() }
      function onStartAngleChanged()   { arcs.requestPaint() }
    }
    Connections {
      target: wheel.model
      function onCountChanged() { arcs.requestPaint() }
    }
    Component.onCompleted: requestPaint()
  }


  Repeater {
    model: wheel.model
    delegate: Item {
      anchors.fill: parent
      property int idx: index
      property bool isCurrent: idx === wheel.currentIndex

      readonly property real _angStartRad: wheel._toRad(wheel._itemAngleStart(idx))
      readonly property real _angEndRad: wheel._toRad(wheel._itemAngleEnd(idx))
      readonly property real _arcSpan: wheel._arcDeg - wheel._gapDeg

      opacity: isCurrent ? 1.0 : 0.0
      Behavior on opacity { NumberAnimation { duration: 220; easing.type: Easing.OutQuad } }

      Shape {
        anchors.fill: parent
        antialiasing: true
        preferredRendererType: Shape.CurveRenderer
        ShapePath {
          fillColor: wheel.colors
            ? Qt.rgba(wheel.colors.primary.r, wheel.colors.primary.g, wheel.colors.primary.b, 0.85)
            : Qt.rgba(0.31, 0.76, 0.97, 0.85)
          strokeColor: wheel.colors ? wheel.colors.primary : "#4fc3f7"
          strokeWidth: 2
          startX: wheel._cx + wheel.outerRadius * Math.cos(_angStartRad)
          startY: wheel._cy + wheel.outerRadius * Math.sin(_angStartRad)
          PathArc {
            x: wheel._cx + wheel.outerRadius * Math.cos(_angEndRad)
            y: wheel._cy + wheel.outerRadius * Math.sin(_angEndRad)
            radiusX: wheel.outerRadius
            radiusY: wheel.outerRadius
            direction: PathArc.Clockwise
            useLargeArc: _arcSpan > 180
          }
          PathLine {
            x: wheel._cx + wheel.innerRadius * Math.cos(_angEndRad)
            y: wheel._cy + wheel.innerRadius * Math.sin(_angEndRad)
          }
          PathArc {
            x: wheel._cx + wheel.innerRadius * Math.cos(_angStartRad)
            y: wheel._cy + wheel.innerRadius * Math.sin(_angStartRad)
            radiusX: wheel.innerRadius
            radiusY: wheel.innerRadius
            direction: PathArc.Counterclockwise
            useLargeArc: _arcSpan > 180
          }
          PathLine {
            x: wheel._cx + wheel.outerRadius * Math.cos(_angStartRad)
            y: wheel._cy + wheel.outerRadius * Math.sin(_angStartRad)
          }
        }
      }
    }
  }


  Repeater {
    model: wheel.model
    delegate: Item {
      id: cell
      property int idx: index
      property string cellAppId: model.appId
      property bool cellFocused: model.isFocused
      property bool isActive: cell.idx === wheel.currentIndex

      readonly property real _angDeg: wheel._itemMidAngle(idx)
      readonly property real _angRad: wheel._toRad(_angDeg)
      readonly property real _x: wheel._cx + wheel._midRadius * Math.cos(_angRad)
      readonly property real _y: wheel._cy + wheel._midRadius * Math.sin(_angRad)

      x: _x - width / 2
      y: _y - height / 2
      width: Math.round(wheel.iconSize * 1.5)
      height: Math.round(wheel.iconSize * 1.5)


      Image {
        id: iconImg
        anchors.centerIn: parent
        width: wheel.iconSize
        height: wheel.iconSize
        source: wheel.service ? wheel.service.getIconSource(cell.cellAppId) : ""
        visible: status === Image.Ready
        fillMode: Image.PreserveAspectFit
        smooth: true
        asynchronous: true
        sourceSize.width: 192
        sourceSize.height: 192
        opacity: cell.isActive ? 1.0 : 0.85
        Behavior on opacity { NumberAnimation { duration: 150 } }
      }

      Text {
        anchors.centerIn: parent
        visible: !iconImg.visible
        text: wheel.service ? wheel.service.getIcon(cell.cellAppId) : "?"
        font.pixelSize: wheel.iconSize
        font.family: wheel.fontFamilyIcons
        color: cell.isActive
          ? (wheel.colors ? wheel.colors.primaryText : "#000")
          : Qt.rgba(wheel.colors ? wheel.colors.tertiary.r : 0.55,
                    wheel.colors ? wheel.colors.tertiary.g : 0.79,
                    wheel.colors ? wheel.colors.tertiary.b : 1.0, 0.85)
      }


      Rectangle {
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 4
        width: 8; height: 8; radius: 4
        color: wheel.colors ? wheel.colors.primary : "#4fc3f7"
        visible: cell.cellFocused
      }
    }
  }


  Item {
    id: hub
    width: wheel.innerRadius * 2 - 8
    height: width
    anchors.centerIn: parent

    readonly property var _activeRow: wheel.currentIndex >= 0 && wheel.model && wheel.model.get && wheel._count > 0
      ? wheel.model.get(wheel.currentIndex)
      : null

    Rectangle {
      anchors.fill: parent
      radius: width / 2
      color: wheel.colors
        ? Qt.rgba(wheel.colors.surface.r, wheel.colors.surface.g, wheel.colors.surface.b, 0.96)
        : Qt.rgba(0.05, 0.06, 0.09, 0.96)
      border.color: wheel.colors ? wheel.colors.primary : "#4fc3f7"
      border.width: 2
    }

    Column {
      anchors.centerIn: parent
      width: hub.width - 24
      spacing: 4

      Text {
        anchors.horizontalCenter: parent.horizontalCenter
        width: parent.width
        horizontalAlignment: Text.AlignHCenter
        elide: Text.ElideRight
        visible: hub._activeRow !== null
        text: hub._activeRow ? wheel.service.getName(hub._activeRow.appId) : ""
        font.family: wheel.fontFamily
        font.pixelSize: 14
        font.weight: Font.Bold
        font.letterSpacing: 0.5
        color: wheel.colors ? wheel.colors.primary : "#4fc3f7"
      }

      Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        width: parent.width * 0.6
        height: 1
        color: wheel.colors ? Qt.rgba(wheel.colors.primary.r, wheel.colors.primary.g, wheel.colors.primary.b, 0.4) : Qt.rgba(1, 1, 1, 0.2)
        visible: hub._activeRow !== null
      }

      Text {
        anchors.horizontalCenter: parent.horizontalCenter
        width: parent.width
        horizontalAlignment: Text.AlignHCenter
        elide: Text.ElideRight
        wrapMode: Text.NoWrap
        visible: hub._activeRow !== null
        text: hub._activeRow ? (hub._activeRow.title || "") : ""
        font.family: wheel.fontFamily
        font.pixelSize: 10
        color: Qt.rgba(1, 1, 1, 0.7)
      }

      Text {
        anchors.horizontalCenter: parent.horizontalCenter
        visible: hub._activeRow === null
        text: "NO WINDOWS"
        font.family: wheel.fontFamily
        font.pixelSize: 12
        font.weight: Font.Bold
        font.letterSpacing: 1.5
        color: wheel.colors ? wheel.colors.outline : "#666666"
      }
    }
  }


  MouseArea {
    anchors.fill: parent
    hoverEnabled: true
    acceptedButtons: Qt.LeftButton
    onPositionChanged: {
      if (wheel._count <= 0) return
      var dx = mouseX - wheel._cx
      var dy = mouseY - wheel._cy
      if (dx === 0 && dy === 0) return
      var ang = Math.atan2(dy, dx) * 180.0 / Math.PI
      var rel = ang - wheel.startAngle
      while (rel < 0) rel += 360
      while (rel >= 360) rel -= 360
      var idx = Math.floor(rel / wheel._arcDeg)
      if (idx >= 0 && idx < wheel._count) wheel.currentIndex = idx
    }
    onClicked: {
      if (wheel.currentIndex >= 0 && wheel.currentIndex < wheel._count)
        wheel.wheelClicked(wheel.currentIndex)
    }
  }
}
