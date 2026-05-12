import QtQuick
import QtQuick.Shapes
import ".."

Rectangle {
  id: preview
  property var colors

  property int previewHeight: 170
  property int sidePad: 16
  readonly property real _baseScale: 0.32

  property real animScale: 0.32
  property real animRadius: 30
  property int  animRows: 3
  property int  animCols: 7
  property real animArc: 0
  property bool _syncing: false

  Behavior on animScale  { enabled: !preview._syncing; NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
  Behavior on animRadius { enabled: !preview._syncing; NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
  Behavior on animArc    { enabled: !preview._syncing; NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

  function _syncFromConfig() {
    var r  = Config.launchHexRadius
    var rs = Math.max(1, Config.launchHexRows)
    var cs = Math.max(1, Config.launchHexCols)
    var arc = Config.launchHexArc ? Config.launchHexArcIntensity : 0

    var rPx   = r * preview._baseScale
    var hexH  = rPx * 1.73205
    var stepX = rPx * 1.5
    var natH  = rs * hexH + hexH * 0.5
    var natW  = (cs - 1) * stepX + rPx * 2

    var availH = preview.previewHeight
    var availW = Math.max(1, preview.width - preview.sidePad * 2)
    var fitH = natH > 0 ? Math.min(1.0, availH / natH) : 1.0
    var fitW = natW > 0 ? Math.min(1.0, availW / natW) : 1.0
    var eff  = preview._baseScale * Math.min(fitH, fitW)

    preview.animScale  = eff
    preview.animRadius = r * eff
    preview.animRows   = rs
    preview.animCols   = cs
    preview.animArc    = arc
  }

  Component.onCompleted: { preview._syncing = true; preview._syncFromConfig(); preview._syncing = false }

  Timer {
    id: _settle
    interval: 120
    onTriggered: preview._syncFromConfig()
  }

  Connections {
    target: Config
    function onLaunchHexRadiusChanged()       { _settle.restart() }
    function onLaunchHexRowsChanged()         { _settle.restart() }
    function onLaunchHexColsChanged()         { _settle.restart() }
    function onLaunchHexArcChanged()          { _settle.restart() }
    function onLaunchHexArcIntensityChanged() { _settle.restart() }
  }

  onWidthChanged: if (!_syncing) _settle.restart()

  width: parent ? parent.width : 0
  height: previewHeight + sidePad * 2
  radius: 0
  color: "transparent"
  border.width: 0
  clip: true

  property int _frameCh: 16

  Shape {
    anchors.fill: parent
    anchors.leftMargin: 4
    anchors.rightMargin: 4
    antialiasing: true
    preferredRendererType: Shape.CurveRenderer
    z: -1
    ShapePath {
      fillColor: preview.colors ? Qt.rgba(preview.colors.surfaceContainer.r, preview.colors.surfaceContainer.g, preview.colors.surfaceContainer.b, 0.78) : Qt.rgba(0.1, 0.12, 0.18, 0.78)
      strokeColor: "transparent"
      strokeWidth: 0
      startX: preview._frameCh; startY: 0
      PathLine { x: preview.width - 8;                    y: 0 }
      PathLine { x: preview.width - 8;                    y: preview.height - preview._frameCh }
      PathLine { x: preview.width - 8 - preview._frameCh; y: preview.height }
      PathLine { x: 0;                                    y: preview.height }
      PathLine { x: 0;                                    y: preview._frameCh }
      PathLine { x: preview._frameCh;                     y: 0 }
    }
    ShapePath {
      fillColor: "transparent"
      strokeColor: preview.colors ? preview.colors.primary : Qt.rgba(0.5, 0.7, 1.0, 1.0)
      strokeWidth: 3
      startX: 0; startY: preview._frameCh
      PathLine { x: preview._frameCh; y: 0 }
    }
  }

  readonly property real _hexW: animRadius * 2
  readonly property real _hexH: animRadius * 1.73205
  readonly property real _stepX: animRadius * 1.5
  readonly property real _totalW: (animCols - 1) * _stepX + _hexW
  readonly property real _totalH: animRows * _hexH + _hexH * 0.5
  readonly property real _ox: (preview.width - _totalW) / 2
  readonly property real _oy: sidePad + Math.max(0, previewHeight - _totalH) / 2

  Repeater {
    model: preview.animCols * preview.animRows

    delegate: Item {
      id: hexCell
      required property int index
      readonly property int _col: index % preview.animCols
      readonly property int _row: Math.floor(index / preview.animCols)
      readonly property real _centerOff: preview.animArc * preview._hexH * Math.pow((_col - (preview.animCols - 1) / 2) / Math.max(1, (preview.animCols - 1) / 2), 2)

      x: preview._ox + _col * preview._stepX
      y: preview._oy + _row * preview._hexH + (_col % 2 !== 0 ? preview._hexH / 2 : 0) + _centerOff
      width: preview._hexW
      height: preview._hexH

      Behavior on x { enabled: !preview._syncing; NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
      Behavior on y { enabled: !preview._syncing; NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

      readonly property real _cx: preview.animRadius
      readonly property real _cy: height / 2

      Shape {
        anchors.fill: parent
        antialiasing: true
        preferredRendererType: Shape.CurveRenderer
        ShapePath {
          fillColor: preview.colors
            ? Qt.rgba(preview.colors.primary.r, preview.colors.primary.g, preview.colors.primary.b, 0.35)
            : Qt.rgba(0.5, 0.5, 0.8, 0.35)
          strokeColor: preview.colors
            ? Qt.rgba(preview.colors.primary.r, preview.colors.primary.g, preview.colors.primary.b, 0.7)
            : Qt.rgba(0.5, 0.5, 0.8, 0.7)
          strokeWidth: 1
          startX: hexCell._cx + preview.animRadius;       startY: hexCell._cy
          PathLine { x: hexCell._cx + preview.animRadius * 0.5; y: hexCell._cy - preview.animRadius * 0.866025 }
          PathLine { x: hexCell._cx - preview.animRadius * 0.5; y: hexCell._cy - preview.animRadius * 0.866025 }
          PathLine { x: hexCell._cx - preview.animRadius;       y: hexCell._cy }
          PathLine { x: hexCell._cx - preview.animRadius * 0.5; y: hexCell._cy + preview.animRadius * 0.866025 }
          PathLine { x: hexCell._cx + preview.animRadius * 0.5; y: hexCell._cy + preview.animRadius * 0.866025 }
          PathLine { x: hexCell._cx + preview.animRadius;       y: hexCell._cy }
        }
      }
    }
  }

  Text {
    anchors.left: parent.left
    anchors.bottom: parent.bottom
    anchors.leftMargin: 8
    anchors.bottomMargin: 4
    text: "preview"
    font.family: Style.fontFamily
    font.pixelSize: 9
    font.letterSpacing: 1.2
    color: preview.colors
      ? Qt.rgba(preview.colors.surfaceText.r, preview.colors.surfaceText.g, preview.colors.surfaceText.b, 0.35)
      : Qt.rgba(1, 1, 1, 0.25)
  }

  Text {
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    anchors.rightMargin: 8
    anchors.bottomMargin: 4
    text: "scale " + preview.animScale.toFixed(2)
    font.family: Style.fontFamilyCode
    font.pixelSize: 9
    font.letterSpacing: 0.8
    color: preview.colors
      ? Qt.rgba(preview.colors.surfaceText.r, preview.colors.surfaceText.g, preview.colors.surfaceText.b, 0.35)
      : Qt.rgba(1, 1, 1, 0.25)
  }
}
