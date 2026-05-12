import QtQuick
import QtQuick.Shapes
import ".."

Rectangle {
  id: preview
  property var colors

  property int previewHeight: 170
  property int sidePad: 16

  property real animScale: 0.32
  property real animSliceWidth: 45
  property real animExpandedWidth: 290
  property real animSliceHeight: 170
  property real animSkew: 11
  property real animSpacing: -7
  property real animRadius: 0
  property int  animSlices: 5

  property bool _syncing: false

  Behavior on animScale         { enabled: !preview._syncing; NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
  Behavior on animSliceWidth    { enabled: !preview._syncing; NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
  Behavior on animExpandedWidth { enabled: !preview._syncing; NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
  Behavior on animSliceHeight   { enabled: !preview._syncing; NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
  Behavior on animSkew          { enabled: !preview._syncing; NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
  Behavior on animSpacing       { enabled: !preview._syncing; NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
  Behavior on animRadius        { enabled: !preview._syncing; NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

  readonly property real _baseScale: 0.32

  function _syncFromConfig() {
    var n  = Math.max(1, Math.min(Config.launchVisibleCount, 9))
    var sw = Config.launchSliceWidth
    var ew = Config.launchExpandedWidth
    var sh = Config.launchSliceHeight
    var sk = Math.abs(Config.launchSkewOffset)
    var sp = Config.launchSliceSpacing

    var naturalH = sh * preview._baseScale
    var naturalW = (ew + (n - 1) * (sw + sp) + sk) * preview._baseScale

    var availH = preview.previewHeight
    var availW = Math.max(1, preview.width - preview.sidePad * 2)
    var fitH = naturalH > 0 ? Math.min(1.0, availH / naturalH) : 1.0
    var fitW = naturalW > 0 ? Math.min(1.0, availW / naturalW) : 1.0
    var fit  = Math.min(fitH, fitW)
    var eff  = preview._baseScale * fit

    preview.animScale         = eff
    preview.animSliceWidth    = sw * eff
    preview.animExpandedWidth = ew * eff
    preview.animSliceHeight   = sh * eff
    preview.animSkew          = Config.launchSkewOffset * eff
    preview.animSpacing       = sp * eff
    preview.animRadius        = Config.launchSliceRoundCorners ? Config.launchSliceCornerRadius * eff : 0
    preview.animSlices        = n
  }

  onWidthChanged: if (!_syncing) _settle.restart()

  Component.onCompleted: {
    preview._syncing = true
    preview._syncFromConfig()
    preview._syncing = false
  }

  Timer {
    id: _settle
    interval: 120
    onTriggered: preview._syncFromConfig()
  }

  Connections {
    target: Config
    function onLaunchSliceHeightChanged()       { _settle.restart() }
    function onLaunchSliceWidthChanged()        { _settle.restart() }
    function onLaunchExpandedWidthChanged()     { _settle.restart() }
    function onLaunchSkewOffsetChanged()        { _settle.restart() }
    function onLaunchSliceSpacingChanged()      { _settle.restart() }
    function onLaunchSliceCornerRadiusChanged() { _settle.restart() }
    function onLaunchSliceRoundCornersChanged() { _settle.restart() }
    function onLaunchVisibleCountChanged()      { _settle.restart() }
  }

  width: parent ? parent.width : 0
  height: previewHeight + preview.sidePad * 2
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

  property real _totalWidth: {
    var slices = preview.animSlices - 1
    return preview.animExpandedWidth + slices * preview.animSliceWidth + slices * preview.animSpacing
  }
  property real _centerOffset: (preview.width - _totalWidth) / 2

  Repeater {
    model: preview.animSlices

    delegate: Item {
      id: sliceItem
      required property int index

      readonly property bool _isCenter: index === Math.floor(preview.animSlices / 2)
      readonly property real _w: _isCenter ? preview.animExpandedWidth : preview.animSliceWidth
      readonly property real _h: preview.animSliceHeight

      property real _stepOffset: {
        var midIdx = Math.floor(preview.animSlices / 2)
        var offset = preview._centerOffset
        for (var i = 0; i < index; i++) {
          var sliceW = (i === midIdx) ? preview.animExpandedWidth : preview.animSliceWidth
          offset += sliceW + preview.animSpacing
        }
        return offset
      }

      x: _stepOffset
      y: preview.sidePad + Math.max(0, preview.previewHeight - _h)
      width: _w
      height: _h

      Behavior on x { enabled: !preview._syncing; NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

      readonly property real _skAbs: Math.abs(preview.animSkew)
      readonly property real _topLeft:  preview.animSkew >= 0 ? _skAbs : 0
      readonly property real _topRight: preview.animSkew >= 0 ? _w : _w - _skAbs
      readonly property real _botRight: preview.animSkew >= 0 ? _w - _skAbs : _w
      readonly property real _botLeft:  preview.animSkew >= 0 ? 0 : _skAbs
      readonly property real _slantSx: _botLeft - _topLeft
      readonly property real _slantLen: Math.max(0.001, Math.sqrt(_slantSx * _slantSx + _h * _h))
      readonly property real _flatW: Math.max(0.001, _topRight - _topLeft)
      readonly property real _rEff: Math.max(0, Math.min(preview.animRadius, _flatW / 2 - 1, _slantLen / 2 - 1))
      readonly property real _rUx: _rEff * _slantSx / _slantLen
      readonly property real _rUy: _rEff * _h / _slantLen
      readonly property real _tlInX: _topLeft + _rUx
      readonly property real _tlInY: _rUy
      readonly property real _tlOutX: _topLeft + _rEff
      readonly property real _trInX: _topRight - _rEff
      readonly property real _trOutX: _topRight + _rUx
      readonly property real _trOutY: _rUy
      readonly property real _brInX: _botRight - _rUx
      readonly property real _brInY: _h - _rUy
      readonly property real _brOutX: _botRight - _rEff
      readonly property real _blInX: _botLeft + _rEff
      readonly property real _blOutX: _botLeft - _rUx
      readonly property real _blOutY: _h - _rUy

      Shape {
        anchors.fill: parent
        antialiasing: true
        preferredRendererType: Shape.CurveRenderer
        ShapePath {
          fillColor: sliceItem._isCenter
            ? (preview.colors ? preview.colors.primary : "#7986cb")
            : (preview.colors ? Qt.rgba(preview.colors.primary.r, preview.colors.primary.g, preview.colors.primary.b, 0.35) : Qt.rgba(0.5, 0.5, 0.8, 0.35))
          strokeColor: preview.colors
            ? Qt.rgba(preview.colors.primary.r, preview.colors.primary.g, preview.colors.primary.b, 0.7)
            : Qt.rgba(0.5, 0.5, 0.8, 0.7)
          strokeWidth: 1
          startX: sliceItem._tlOutX
          startY: 0
          PathLine { x: sliceItem._trInX;  y: 0 }
          PathQuad { x: sliceItem._trOutX; y: sliceItem._trOutY; controlX: sliceItem._topRight; controlY: 0 }
          PathLine { x: sliceItem._brInX;  y: sliceItem._brInY }
          PathQuad { x: sliceItem._brOutX; y: sliceItem._h;      controlX: sliceItem._botRight; controlY: sliceItem._h }
          PathLine { x: sliceItem._blInX;  y: sliceItem._h }
          PathQuad { x: sliceItem._blOutX; y: sliceItem._blOutY; controlX: sliceItem._botLeft; controlY: sliceItem._h }
          PathLine { x: sliceItem._tlInX;  y: sliceItem._tlInY }
          PathQuad { x: sliceItem._tlOutX; y: 0;                  controlX: sliceItem._topLeft;  controlY: 0 }
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
