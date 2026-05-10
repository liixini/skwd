import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import QtQuick.Controls
import QtQuick.Shapes
import ".."
import "../components"


Scope {
  id: windowSwitcher

  
  property var colors
  property bool showing: false

  property string mainMonitor: Config.mainMonitor

  
  WindowSwitcherService {
    id: service
    scriptsDir: Config.scriptsDir
    compositor: Config.compositor
    configPath: Config.configDir + "/data/apps.json"
    homeDir: Config.homeDir
    cacheDir: Config.cacheDir
    onModelBuilt: idx => {
      sliceListView.currentIndex = idx
      gridView.currentIndex = idx
      compactListView.currentIndex = idx
      wheelView.currentIndex = idx
    }
  }

  function _activeView() {
    if (isGridMode)    return gridView
    if (isCompactMode) return compactListView
    if (isWheelMode)   return wheelView
    return sliceListView
  }


  function open() {
    service.open()
    showing = true
  }

  function next() {
    var n = service.filteredModel.count
    if (n <= 0) return
    var v = _activeView()
    v.currentIndex = (v.currentIndex + 1) % n
  }

  function prev() {
    var n = service.filteredModel.count
    if (n <= 0) return
    var v = _activeView()
    v.currentIndex = (v.currentIndex - 1 + n) % n
  }

  function confirm() {
    var v = _activeView()
    if (showing && service.filteredModel.count > 0 && v.currentIndex >= 0) {
      var win = service.filteredModel.get(v.currentIndex)
      service.focusWindow(win.winId)
    }
    showing = false
  }

  function cancel() {
    showing = false
  }

  function closeSelected() {
    var v = _activeView()
    if (service.filteredModel.count > 0 && v.currentIndex >= 0) {
      var win = service.filteredModel.get(v.currentIndex)
      service.closeWindow(win.winId)
    }
  }

  onShowingChanged: {
    if (showing) {
      cardShowTimer.restart()
    } else {
      cardVisible = false
    }
  }

  Timer {
    id: cardShowTimer
    interval: 50
    onTriggered: windowSwitcher.cardVisible = true
  }

  Timer {
    id: focusTimer
    interval: 30
    running: windowSwitcher.showing
    repeat: true
    onTriggered: {
      if (windowSwitcher.showing)
        altReleaseDetector.forceActiveFocus()
    }
  }


  property int sliceWidth:    Config.sliceWidth
  property int expandedWidth: Config.sliceExpandedWidth
  property int sliceHeight:   Config.sliceHeight
  property int skewOffset:    Config.sliceSkewOffset
  property int sliceSpacing:  Config.sliceSpacing


  property bool isSliceMode:   Config.displayMode === "slice"
  property bool isGridMode:    Config.displayMode === "grid"
  property bool isCompactMode: Config.displayMode === "compact"
  property bool isWheelMode:   Config.displayMode === "wheel"


  property int _gridCols: Math.min(Config.gridColumns, Math.max(1, service.filteredModel.count))
  property int _gridRowsCount: {
    var n = service.filteredModel.count
    if (n <= 0) return 1
    var needed = Math.ceil(n / Config.gridColumns)
    return Math.min(needed, Math.max(1, Config.gridRows))
  }
  property int _gridContentW: _gridCols * Config.gridCellWidth + Math.max(0, _gridCols - 1) * Config.gridSpacing
  property int _gridContentH: _gridRowsCount * Config.gridCellHeight + Math.max(0, _gridRowsCount - 1) * Config.gridSpacing


  property int _compactCount: service.filteredModel.count
  property int _compactContentW: Math.max(1, _compactCount) * Config.compactCellWidth + Math.max(0, _compactCount - 1) * Config.compactSpacing


  property int cardWidth: {
    if (isGridMode)    return Math.max(400, _gridContentW + 60)
    if (isCompactMode) return Math.max(400, _compactContentW + 60)
    if (isWheelMode)   return Config.wheelOuterRadius * 2 + 40
    return Config.cardWidth
  }
  property int cardHeight: {
    if (isGridMode)    return _gridContentH + 60
    if (isCompactMode) return Config.compactCellHeight + Config.compactCardPad
    if (isWheelMode)   return Config.wheelOuterRadius * 2 + 40
    return sliceHeight + Config.cardHeightPad
  }

  property bool cardVisible: false

  
  PanelWindow {
    id: switcherPanel

    screen: Quickshell.screens.find(s => s.name === windowSwitcher.mainMonitor) ?? Quickshell.screens[0]

    anchors {
      top: true
      bottom: true
      left: true
      right: true
    }
    margins {
      top: 0
      bottom: 0
      left: 0
      right: 0
    }

    visible: windowSwitcher.showing
    color: "transparent"

    WlrLayershell.namespace: "window-switcher-parallel"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: windowSwitcher.showing ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    exclusionMode: ExclusionMode.Ignore

    DimOverlay {
      active: windowSwitcher.cardVisible
      dimOpacity: Config.dimOpacity
      onClicked: windowSwitcher.cancel()
    }


    Item {
      id: cardContainer
      width: windowSwitcher.cardWidth
      height: windowSwitcher.cardHeight
      anchors.centerIn: parent
      visible: windowSwitcher.cardVisible

      opacity: 0
      property bool animateIn: windowSwitcher.cardVisible

      onAnimateInChanged: {
        fadeInAnim.stop()
        if (animateIn) {
          opacity = 0
          fadeInAnim.start()
        }
      }

      NumberAnimation {
        id: fadeInAnim
        target: cardContainer
        property: "opacity"
        from: 0; to: 1
        duration: Config.animFadeIn
        easing.type: Easing.OutCubic
      }

      MouseArea {
        anchors.fill: parent
        onClicked: {}
      }


      Item {
        id: backgroundRect
        anchors.fill: parent
      }
    }


    FocusScope {
      id: altReleaseDetector
      anchors.fill: parent
      focus: windowSwitcher.showing
      activeFocusOnTab: false

      Keys.onReleased: function(event) {
        if (event.key === Qt.Key_Alt) {
          windowSwitcher.confirm()
          event.accepted = true
        }
      }

      Keys.onPressed: function(event) {
        if (event.key === Qt.Key_Escape) {
          windowSwitcher.cancel()
          event.accepted = true
        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
          windowSwitcher.confirm()
          event.accepted = true
        }
      }
    }


    ListView {
      id: sliceListView
      anchors.top: cardContainer.top
      anchors.topMargin: 15
      anchors.bottom: cardContainer.bottom
      anchors.bottomMargin: 20
      anchors.horizontalCenter: parent.horizontalCenter
      property int visibleCount: Config.sliceVisibleCount
      width: windowSwitcher.expandedWidth + (visibleCount - 1) * (windowSwitcher.sliceWidth + windowSwitcher.sliceSpacing)

      orientation: ListView.Horizontal
      model: service.filteredModel
      clip: false
      spacing: windowSwitcher.sliceSpacing

      flickDeceleration: 1500
      maximumFlickVelocity: 3000
      boundsBehavior: Flickable.StopAtBounds
      cacheBuffer: windowSwitcher.expandedWidth * 4

      visible: windowSwitcher.cardVisible && windowSwitcher.isSliceMode

      highlightFollowsCurrentItem: true
      highlightMoveDuration: 350
      highlight: Item {}
      preferredHighlightBegin: (width - windowSwitcher.expandedWidth) / 2
      preferredHighlightEnd: (width + windowSwitcher.expandedWidth) / 2
      highlightRangeMode: ListView.StrictlyEnforceRange
      header: Item { width: (sliceListView.width - windowSwitcher.expandedWidth) / 2; height: 1 }
      footer: Item { width: (sliceListView.width - windowSwitcher.expandedWidth) / 2; height: 1 }


      Text {
        anchors.centerIn: parent
        visible: service.filteredModel.count === 0
        text: "NO WINDOWS"
        font.family: Style.fontFamily
        font.weight: Font.Bold
        font.pixelSize: 18
        font.letterSpacing: 2
        color: windowSwitcher.colors ? windowSwitcher.colors.outline : "#666666"
      }


      delegate: Item {
        id: delegateItem
        width: isCurrent ? windowSwitcher.expandedWidth : windowSwitcher.sliceWidth
        height: sliceListView.height
        property bool isCurrent: ListView.isCurrentItem
        z: isCurrent ? 100 : 50 - Math.min(Math.abs(index - sliceListView.currentIndex), 50)
        property real viewX: x - sliceListView.contentX
        property real fadeZone: windowSwitcher.sliceWidth * 1.5
        property real edgeOpacity: {
          if (fadeZone <= 0) return 1.0
          var center = viewX + width * 0.5
          var leftFade = Math.min(1.0, Math.max(0.0, center / fadeZone))
          var rightFade = Math.min(1.0, Math.max(0.0, (sliceListView.width - center) / fadeZone))
          return Math.min(leftFade, rightFade)
        }
        opacity: edgeOpacity
        Behavior on width {
          NumberAnimation { duration: 200; easing.type: Easing.OutQuad }
        }

        containmentMask: Item {
          id: hitMask
          function contains(point) {
            var w = delegateItem.width
            var h = delegateItem.height
            var sk = windowSwitcher.skewOffset
            if (h <= 0 || w <= 0) return false
            var leftX = sk * (1.0 - point.y / h)
            var rightX = w - sk * (point.y / h)
            return point.x >= leftX && point.x <= rightX && point.y >= 0 && point.y <= h
          }
        }


        Canvas {
          id: shadowCanvas
          z: -1
          anchors.fill: parent
          anchors.margins: -10
          property real shadowOffsetX: delegateItem.isCurrent ? 4 : 2
          property real shadowOffsetY: delegateItem.isCurrent ? 10 : 5
          property real shadowAlpha: delegateItem.isCurrent ? 0.6 : 0.4
          onWidthChanged: requestPaint()
          onHeightChanged: requestPaint()
          onShadowAlphaChanged: requestPaint()
          onPaint: {
            var ctx = getContext("2d")
            ctx.clearRect(0, 0, width, height)
            var ox = 10; var oy = 10
            var w = delegateItem.width
            var h = delegateItem.height
            var sk = windowSwitcher.skewOffset
            var sx = shadowOffsetX; var sy = shadowOffsetY
            var layers = [
              { dx: sx, dy: sy, alpha: shadowAlpha * 0.5 },
              { dx: sx * 0.6, dy: sy * 0.6, alpha: shadowAlpha * 0.3 },
              { dx: sx * 1.4, dy: sy * 1.4, alpha: shadowAlpha * 0.2 }
            ]
            for (var i = 0; i < layers.length; i++) {
              var l = layers[i]
              ctx.globalAlpha = l.alpha
              ctx.fillStyle = "#000000"
              ctx.beginPath()
              ctx.moveTo(ox + sk + l.dx, oy + l.dy)
              ctx.lineTo(ox + w + l.dx, oy + l.dy)
              ctx.lineTo(ox + w - sk + l.dx, oy + h + l.dy)
              ctx.lineTo(ox + l.dx, oy + h + l.dy)
              ctx.closePath()
              ctx.fill()
            }
          }
        }


        Item {
          id: imageContainer
          anchors.fill: parent


          Rectangle {
            anchors.fill: parent
            gradient: Gradient {
              GradientStop {
                position: 0.0
                color: windowSwitcher.colors
                  ? Qt.rgba(windowSwitcher.colors.surfaceContainer.r, windowSwitcher.colors.surfaceContainer.g, windowSwitcher.colors.surfaceContainer.b, 1)
                  : "#1a1c2e"
              }
              GradientStop {
                position: 1.0
                color: windowSwitcher.colors
                  ? Qt.rgba(windowSwitcher.colors.surface.r, windowSwitcher.colors.surface.g, windowSwitcher.colors.surface.b, 1)
                  : "#0e1018"
              }
            }
          }


          Rectangle {
            anchors.fill: parent
            color: Qt.rgba(0, 0, 0, delegateItem.isCurrent ? 0 : 0.4)
            Behavior on color { ColorAnimation { duration: 200 } }
          }


          Image {
            id: bigIconImage
            anchors.centerIn: parent
            anchors.verticalCenterOffset: -20
            property int iconSize: 96
            width: iconSize
            height: iconSize
            source: service.getIconSource(model.appId)
            visible: status === Image.Ready
            fillMode: Image.PreserveAspectFit
            smooth: true
            asynchronous: true
            sourceSize.width: 256
            sourceSize.height: 256
            Behavior on iconSize { NumberAnimation { duration: 200; easing.type: Easing.OutQuad } }
          }

          Text {
            id: bigIcon
            anchors.centerIn: parent
            anchors.verticalCenterOffset: -20
            visible: !bigIconImage.visible
            text: service.getIcon(model.appId)
            property int iconSize: 96
            font.pixelSize: iconSize
            font.family: Style.fontFamilyIcons
            color: delegateItem.isCurrent
              ? (windowSwitcher.colors ? windowSwitcher.colors.primary : "#4fc3f7")
              : Qt.rgba(windowSwitcher.colors ? windowSwitcher.colors.tertiary.r : 0.55,
                        windowSwitcher.colors ? windowSwitcher.colors.tertiary.g : 0.79,
                        windowSwitcher.colors ? windowSwitcher.colors.tertiary.b : 1.0, 0.5)
            Behavior on iconSize { NumberAnimation { duration: 200; easing.type: Easing.OutQuad } }
            Behavior on color { ColorAnimation { duration: 200 } }
          }

          layer.enabled: true
          layer.smooth: true
          layer.samples: 4
          layer.effect: MultiEffect {
            maskEnabled: true
            maskSource: ShaderEffectSource {
              sourceItem: Item {
                width: imageContainer.width
                height: imageContainer.height
                layer.enabled: true
                layer.smooth: true
                layer.samples: 8
                Shape {
                  anchors.fill: parent
                  antialiasing: true
                  preferredRendererType: Shape.CurveRenderer
                  ShapePath {
                    fillColor: "white"
                    strokeColor: "transparent"
                    startX: windowSwitcher.skewOffset
                    startY: 0
                    PathLine { x: delegateItem.width; y: 0 }
                    PathLine { x: delegateItem.width - windowSwitcher.skewOffset; y: delegateItem.height }
                    PathLine { x: 0; y: delegateItem.height }
                    PathLine { x: windowSwitcher.skewOffset; y: 0 }
                  }
                }
              }
            }
            maskThresholdMin: 0.3
            maskSpreadAtMin: 0.3
          }
        }


        Shape {
          id: glowBorder
          anchors.fill: parent
          antialiasing: true
          preferredRendererType: Shape.CurveRenderer
          ShapePath {
            fillColor: "transparent"
            strokeColor: delegateItem.isCurrent
              ? (windowSwitcher.colors ? windowSwitcher.colors.primary : "#8BC34A")
              : Qt.rgba(0, 0, 0, 0.6)
            Behavior on strokeColor { ColorAnimation { duration: 200 } }
            strokeWidth: delegateItem.isCurrent ? 3 : 1
            startX: windowSwitcher.skewOffset
            startY: 0
            PathLine { x: delegateItem.width; y: 0 }
            PathLine { x: delegateItem.width - windowSwitcher.skewOffset; y: delegateItem.height }
            PathLine { x: 0; y: delegateItem.height }
            PathLine { x: windowSwitcher.skewOffset; y: 0 }
          }
        }


        Rectangle {
          anchors.top: parent.top
          anchors.topMargin: 10
          anchors.left: parent.left
          anchors.leftMargin: windowSwitcher.skewOffset + 6
          width: focusedLabel.width + 12
          height: 20
          radius: 10
          color: windowSwitcher.colors ? windowSwitcher.colors.primary : "#4fc3f7"
          visible: model.isFocused
          z: 10

          Text {
            id: focusedLabel
            anchors.centerIn: parent
            text: "FOCUSED"
            font.family: Style.fontFamily
            font.pixelSize: 9
            font.weight: Font.Bold
            font.letterSpacing: 0.5
            color: windowSwitcher.colors ? windowSwitcher.colors.primaryText : "#000"
          }
        }


        Rectangle {
          id: nameLabel
          anchors.bottom: parent.bottom
          anchors.bottomMargin: 40
          anchors.horizontalCenter: parent.horizontalCenter
          width: nameLabelCol.width + 24
          height: nameLabelCol.height + 16
          radius: 6
          color: Qt.rgba(0, 0, 0, 0.75)
          border.width: 1
          border.color: windowSwitcher.colors ? Qt.rgba(windowSwitcher.colors.primary.r, windowSwitcher.colors.primary.g, windowSwitcher.colors.primary.b, 0.5) : Qt.rgba(1, 1, 1, 0.2)
          visible: delegateItem.isCurrent
          opacity: delegateItem.isCurrent ? 1 : 0
          Behavior on opacity { NumberAnimation { duration: 200 } }

          Column {
            id: nameLabelCol
            anchors.centerIn: parent
            spacing: 4

            Text {
              anchors.horizontalCenter: parent.horizontalCenter
              text: service.getName(model.appId).toUpperCase()
              font.family: Style.fontFamily
              font.pixelSize: 13
              font.weight: Font.Bold
              font.letterSpacing: 0.5
              color: windowSwitcher.colors ? windowSwitcher.colors.primary : "#4fc3f7"
            }

            Text {
              anchors.horizontalCenter: parent.horizontalCenter
              text: {
                var t = model.title || ""
                return t.length > 60 ? t.substring(0, 60) + "…" : t
              }
              font.family: Style.fontFamily
              font.pixelSize: 11
              color: Qt.rgba(1, 1, 1, 0.6)
              width: Math.min(implicitWidth, delegateItem.width - 80)
              elide: Text.ElideRight
              horizontalAlignment: Text.AlignHCenter
            }
          }
        }


        Rectangle {
          anchors.bottom: parent.bottom
          anchors.bottomMargin: 8
          anchors.right: parent.right
          anchors.rightMargin: windowSwitcher.skewOffset + 8
          width: wsBadgeText.width + 8
          height: 16
          radius: 4
          color: Qt.rgba(0, 0, 0, 0.75)
          border.width: 1
          border.color: windowSwitcher.colors ? Qt.rgba(windowSwitcher.colors.primary.r, windowSwitcher.colors.primary.g, windowSwitcher.colors.primary.b, 0.4) : Qt.rgba(1, 1, 1, 0.2)
          z: 10

          Text {
            id: wsBadgeText
            anchors.centerIn: parent
            text: "WS " + model.workspaceId
            font.family: Style.fontFamily
            font.pixelSize: 9
            font.weight: Font.Bold
            font.letterSpacing: 0.5
            color: windowSwitcher.colors ? windowSwitcher.colors.tertiary : "#8bceff"
          }
        }


        Rectangle {
          anchors.bottom: parent.bottom
          anchors.bottomMargin: 8
          anchors.left: parent.left
          anchors.leftMargin: windowSwitcher.skewOffset + 8
          width: floatLabel.width + 8
          height: 16
          radius: 4
          color: Qt.rgba(0, 0, 0, 0.75)
          border.width: 1
          border.color: windowSwitcher.colors ? Qt.rgba(windowSwitcher.colors.primary.r, windowSwitcher.colors.primary.g, windowSwitcher.colors.primary.b, 0.4) : Qt.rgba(1, 1, 1, 0.2)
          visible: model.isFloating
          z: 10

          Text {
            id: floatLabel
            anchors.centerIn: parent
            text: "FLOAT"
            font.family: Style.fontFamily
            font.pixelSize: 9
            font.weight: Font.Bold
            font.letterSpacing: 0.5
            color: windowSwitcher.colors ? windowSwitcher.colors.tertiary : "#8bceff"
          }
        }

      }
    }


    GridView {
      id: gridView
      anchors.centerIn: cardContainer
      width: windowSwitcher._gridContentW
      height: Math.min(windowSwitcher._gridContentH, cardContainer.height - 30)

      cellWidth: Config.gridCellWidth + Config.gridSpacing
      cellHeight: Config.gridCellHeight + Config.gridSpacing
      model: service.filteredModel
      clip: true
      cacheBuffer: 1000
      keyNavigationWraps: true
      flow: GridView.FlowLeftToRight

      visible: windowSwitcher.cardVisible && windowSwitcher.isGridMode

      Text {
        anchors.centerIn: parent
        visible: service.filteredModel.count === 0
        text: "NO WINDOWS"
        font.family: Style.fontFamily
        font.weight: Font.Bold
        font.pixelSize: 18
        font.letterSpacing: 2
        color: windowSwitcher.colors ? windowSwitcher.colors.outline : "#666666"
      }

      delegate: Item {
        id: gridCell
        width: gridView.cellWidth
        height: gridView.cellHeight
        property bool isCurrent: GridView.isCurrentItem
        property string cellAppId: model.appId
        property string cellTitle: model.title
        property int    cellWsId: model.workspaceId
        property bool   cellFocused: model.isFocused

        Rectangle {
          anchors.fill: parent
          anchors.margins: Config.gridSpacing / 2
          radius: 10
          gradient: Gradient {
            GradientStop {
              position: 0.0
              color: windowSwitcher.colors
                ? Qt.rgba(windowSwitcher.colors.surfaceContainer.r, windowSwitcher.colors.surfaceContainer.g, windowSwitcher.colors.surfaceContainer.b, 1)
                : "#1a1c2e"
            }
            GradientStop {
              position: 1.0
              color: windowSwitcher.colors
                ? Qt.rgba(windowSwitcher.colors.surface.r, windowSwitcher.colors.surface.g, windowSwitcher.colors.surface.b, 1)
                : "#0e1018"
            }
          }
          border.width: gridCell.isCurrent ? 3 : 1
          border.color: gridCell.isCurrent
            ? (windowSwitcher.colors ? windowSwitcher.colors.primary : "#4fc3f7")
            : Qt.rgba(0, 0, 0, 0.6)
          Behavior on border.color { ColorAnimation { duration: 200 } }


          Rectangle {
            anchors.top: parent.top
            anchors.topMargin: 8
            anchors.left: parent.left
            anchors.leftMargin: 8
            width: gFocusedLbl.width + 12
            height: 18
            radius: 9
            color: windowSwitcher.colors ? windowSwitcher.colors.primary : "#4fc3f7"
            visible: gridCell.cellFocused
            z: 5
            Text {
              id: gFocusedLbl
              anchors.centerIn: parent
              text: "FOCUSED"
              font.family: Style.fontFamily
              font.pixelSize: 8
              font.weight: Font.Bold
              color: windowSwitcher.colors ? windowSwitcher.colors.primaryText : "#000"
            }
          }


          Rectangle {
            anchors.top: parent.top
            anchors.topMargin: 8
            anchors.right: parent.right
            anchors.rightMargin: 8
            width: gWsLbl.width + 8
            height: 16
            radius: 4
            color: Qt.rgba(0, 0, 0, 0.6)
            z: 5
            Text {
              id: gWsLbl
              anchors.centerIn: parent
              text: "WS " + gridCell.cellWsId
              font.family: Style.fontFamily
              font.pixelSize: 8
              font.weight: Font.Bold
              color: windowSwitcher.colors ? windowSwitcher.colors.tertiary : "#8bceff"
            }
          }


          Image {
            id: gIconImg
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: parent.height * 0.18
            width: Config.gridIconSize
            height: Config.gridIconSize
            source: service.getIconSource(gridCell.cellAppId)
            visible: status === Image.Ready
            fillMode: Image.PreserveAspectFit
            smooth: true
            asynchronous: true
            sourceSize.width: 192
            sourceSize.height: 192
          }

          Text {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: parent.height * 0.18
            visible: !gIconImg.visible
            text: service.getIcon(gridCell.cellAppId)
            font.pixelSize: Config.gridIconSize
            font.family: Style.fontFamilyIcons
            color: gridCell.isCurrent
              ? (windowSwitcher.colors ? windowSwitcher.colors.primary : "#4fc3f7")
              : Qt.rgba(windowSwitcher.colors ? windowSwitcher.colors.tertiary.r : 0.55,
                        windowSwitcher.colors ? windowSwitcher.colors.tertiary.g : 0.79,
                        windowSwitcher.colors ? windowSwitcher.colors.tertiary.b : 1.0, 0.5)
          }


          Column {
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 10
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width - 16
            spacing: 2

            Text {
              width: parent.width
              horizontalAlignment: Text.AlignHCenter
              elide: Text.ElideRight
              text: service.getName(gridCell.cellAppId)
              font.family: Style.fontFamily
              font.pixelSize: 12
              font.weight: Font.Bold
              color: windowSwitcher.colors ? windowSwitcher.colors.primary : "#4fc3f7"
            }
            Text {
              width: parent.width
              horizontalAlignment: Text.AlignHCenter
              elide: Text.ElideRight
              text: gridCell.cellTitle
              font.family: Style.fontFamily
              font.pixelSize: 10
              color: Qt.rgba(1, 1, 1, 0.6)
            }
          }


          MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            onEntered: gridView.currentIndex = index
            onClicked: {
              gridView.currentIndex = index
              windowSwitcher.confirm()
            }
          }
        }
      }
    }


    ListView {
      id: compactListView
      anchors.centerIn: cardContainer
      width: Math.min(windowSwitcher._compactContentW, cardContainer.width - 40)
      height: Config.compactCellHeight + 4

      orientation: ListView.Horizontal
      model: service.filteredModel
      clip: true
      spacing: Config.compactSpacing
      cacheBuffer: 600
      boundsBehavior: Flickable.StopAtBounds
      keyNavigationWraps: true
      highlightFollowsCurrentItem: true
      highlightMoveDuration: 200
      preferredHighlightBegin: (width - Config.compactCellWidth) / 2
      preferredHighlightEnd: (width + Config.compactCellWidth) / 2
      highlightRangeMode: ListView.ApplyRange

      visible: windowSwitcher.cardVisible && windowSwitcher.isCompactMode

      Text {
        anchors.centerIn: parent
        visible: service.filteredModel.count === 0
        text: "NO WINDOWS"
        font.family: Style.fontFamily
        font.weight: Font.Bold
        font.pixelSize: 16
        color: windowSwitcher.colors ? windowSwitcher.colors.outline : "#666666"
      }

      delegate: Item {
        id: compactCell
        width: Config.compactCellWidth
        height: Config.compactCellHeight
        property bool isCurrent: ListView.isCurrentItem
        property string cellAppId: model.appId
        property bool   cellFocused: model.isFocused

        Rectangle {
          anchors.fill: parent
          radius: 8
          color: compactCell.isCurrent
            ? (windowSwitcher.colors ? Qt.rgba(windowSwitcher.colors.primary.r, windowSwitcher.colors.primary.g, windowSwitcher.colors.primary.b, 0.18) : Qt.rgba(0.31, 0.76, 0.97, 0.18))
            : Qt.rgba(0, 0, 0, 0.35)
          border.width: compactCell.isCurrent ? 2 : 0
          border.color: windowSwitcher.colors ? windowSwitcher.colors.primary : "#4fc3f7"
          Behavior on color { ColorAnimation { duration: 150 } }
        }


        Image {
          id: cIconImg
          anchors.horizontalCenter: parent.horizontalCenter
          anchors.top: parent.top
          anchors.topMargin: 12
          width: Config.compactIconSize
          height: Config.compactIconSize
          source: service.getIconSource(compactCell.cellAppId)
          visible: status === Image.Ready
          fillMode: Image.PreserveAspectFit
          smooth: true
          asynchronous: true
          sourceSize.width: 128
          sourceSize.height: 128
        }

        Text {
          anchors.horizontalCenter: parent.horizontalCenter
          anchors.top: parent.top
          anchors.topMargin: 12
          visible: !cIconImg.visible
          text: service.getIcon(compactCell.cellAppId)
          font.pixelSize: Config.compactIconSize
          font.family: Style.fontFamilyIcons
          color: compactCell.isCurrent
            ? (windowSwitcher.colors ? windowSwitcher.colors.primary : "#4fc3f7")
            : Qt.rgba(windowSwitcher.colors ? windowSwitcher.colors.tertiary.r : 0.55,
                      windowSwitcher.colors ? windowSwitcher.colors.tertiary.g : 0.79,
                      windowSwitcher.colors ? windowSwitcher.colors.tertiary.b : 1.0, 0.6)
        }


        Rectangle {
          anchors.top: parent.top
          anchors.right: parent.right
          anchors.margins: 6
          width: 8
          height: 8
          radius: 4
          color: windowSwitcher.colors ? windowSwitcher.colors.primary : "#4fc3f7"
          visible: compactCell.cellFocused
        }


        Text {
          anchors.bottom: parent.bottom
          anchors.bottomMargin: 8
          anchors.horizontalCenter: parent.horizontalCenter
          width: parent.width - 8
          horizontalAlignment: Text.AlignHCenter
          elide: Text.ElideRight
          text: service.getName(compactCell.cellAppId)
          font.family: Style.fontFamily
          font.pixelSize: 10
          color: compactCell.isCurrent
            ? (windowSwitcher.colors ? windowSwitcher.colors.primary : "#4fc3f7")
            : Qt.rgba(1, 1, 1, 0.7)
        }


        MouseArea {
          anchors.fill: parent
          hoverEnabled: true
          onEntered: compactListView.currentIndex = index
          onClicked: {
            compactListView.currentIndex = index
            windowSwitcher.confirm()
          }
        }
      }
    }


    WheelView {
      id: wheelView
      anchors.centerIn: cardContainer
      visible: windowSwitcher.cardVisible && windowSwitcher.isWheelMode

      model: service.filteredModel
      colors: windowSwitcher.colors
      service: service
      fontFamily: Style.fontFamily
      fontFamilyIcons: Style.fontFamilyIcons

      outerRadius: Config.wheelOuterRadius
      innerRadius: Config.wheelInnerRadius
      iconSize: Config.wheelIconSize
      gap: Config.wheelGap
      startAngle: Config.wheelStartAngle

      onWheelClicked: idx => {
        currentIndex = idx
        windowSwitcher.confirm()
      }

      Text {
        anchors.centerIn: parent
        visible: service.filteredModel.count === 0
        text: "NO WINDOWS"
        font.family: Style.fontFamily
        font.weight: Font.Bold
        font.pixelSize: 18
        color: windowSwitcher.colors ? windowSwitcher.colors.outline : "#666666"
        z: 10
      }
    }

  }


  Variants {
    model: Quickshell.screens

    Loader {
      id: secondaryLoader
      property var modelData
      readonly property var _mainScreen: Quickshell.screens.find(s => s.name === windowSwitcher.mainMonitor) ?? Quickshell.screens[0]
      property bool isMainMonitor: modelData === _mainScreen || Quickshell.screens.length === 1
      active: windowSwitcher.showing && !isMainMonitor

      sourceComponent: PanelWindow {
        screen: secondaryLoader.modelData
        visible: true
        color: "transparent"

        anchors { top: true; bottom: true; left: true; right: true }

        WlrLayershell.namespace: "window-switcher-funnel-" + (screen?.name || "x")
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

        exclusionMode: ExclusionMode.Ignore

        DimOverlay {
          active: windowSwitcher.cardVisible
          dimOpacity: Config.dimOpacity
          onClicked: windowSwitcher.cancel()
        }

        FocusScope {
          id: funnelScope
          anchors.fill: parent
          focus: true
          activeFocusOnTab: false

          Component.onCompleted: forceActiveFocus()
          onActiveFocusChanged: { if (!activeFocus) forceActiveFocus() }

          Keys.onReleased: function(event) {
            if (event.key === Qt.Key_Alt) {
              windowSwitcher.confirm()
              event.accepted = true
            }
          }

          Keys.onPressed: function(event) {
            if (event.key === Qt.Key_Escape) {
              windowSwitcher.cancel()
              event.accepted = true
            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
              windowSwitcher.confirm()
              event.accepted = true
            } else if (event.key === Qt.Key_Tab || event.key === Qt.Key_Right) {
              windowSwitcher.next()
              event.accepted = true
            } else if (event.key === Qt.Key_Backtab || event.key === Qt.Key_Left) {
              windowSwitcher.prev()
              event.accepted = true
            }
          }

          HoverHandler {
            acceptedDevices: PointerDevice.AllDevices
            onHoveredChanged: if (hovered) funnelScope.forceActiveFocus()
          }
        }
      }
    }
  }
}
