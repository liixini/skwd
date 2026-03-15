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

// Alt-Tab window switcher (parallelogram slice variant with screenshots)
Scope {
  id: windowSwitcher

  // External bindings
  property var colors
  property bool showing: false

  property string mainMonitor: Config.mainMonitor

  // Service (data/logic backend)
  WindowSwitcherService {
    id: service
    scriptsDir: Config.scriptsDir
    compositor: Config.compositor
    configPath: Config.configDir + "/data/apps.json"
    homeDir: Config.homeDir
    cacheDir: Config.cacheDir
    onModelBuilt: idx => {
      sliceListView.currentIndex = idx
    }
  }

  // Actions delegated to service
  function open() {
    service.open()
    showing = true
  }

  function next() {
    if (service.filteredModel.count > 0)
      sliceListView.currentIndex = (sliceListView.currentIndex + 1) % service.filteredModel.count
  }

  function prev() {
    if (service.filteredModel.count > 0)
      sliceListView.currentIndex = (sliceListView.currentIndex - 1 + service.filteredModel.count) % service.filteredModel.count
  }

  function confirm() {
    if (showing && service.filteredModel.count > 0 && sliceListView.currentIndex >= 0) {
      var win = service.filteredModel.get(sliceListView.currentIndex)
      service.focusWindow(win.winId)
    }
    showing = false
  }

  function cancel() {
    showing = false
  }

  function closeSelected() {
    if (service.filteredModel.count > 0 && sliceListView.currentIndex >= 0) {
      var win = service.filteredModel.get(sliceListView.currentIndex)
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


  // Slice geometry constants
  property int sliceWidth: 135
  property int expandedWidth: 924
  property int sliceHeight: 520
  property int skewOffset: 35
  property int sliceSpacing: -22

  property int cardWidth: 1600
  property int cardHeight: sliceHeight + 40

  property bool cardVisible: false

  // Full-screen overlay panel
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
      dimOpacity: 0.5
      onClicked: windowSwitcher.cancel()
    }


    // Card container with fade-in
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
        duration: 400
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


    // Alt-release detection and keyboard handler
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


    // Horizontal parallelogram slice list view
    ListView {
      id: sliceListView
      anchors.top: cardContainer.top
      anchors.topMargin: 15
      anchors.bottom: cardContainer.bottom
      anchors.bottomMargin: 20
      anchors.horizontalCenter: parent.horizontalCenter
      property int visibleCount: 12
      width: windowSwitcher.expandedWidth + (visibleCount - 1) * (windowSwitcher.sliceWidth + windowSwitcher.sliceSpacing)

      orientation: ListView.Horizontal
      model: service.filteredModel
      clip: false
      spacing: windowSwitcher.sliceSpacing

      flickDeceleration: 1500
      maximumFlickVelocity: 3000
      boundsBehavior: Flickable.StopAtBounds
      cacheBuffer: windowSwitcher.expandedWidth * 4

      visible: windowSwitcher.cardVisible

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


      // Parallelogram slice delegate
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


        // Image container (gradient bg, screenshot, icon overlay, parallelogram mask)
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


          Image {
            id: windowThumb
            anchors.fill: parent
            source: Config.compositor === "niri" && model.winId ? "file://" + service.thumbDir + "/" + model.winId + ".png?v=" + service.screenshotCounter : ""
            fillMode: Image.PreserveAspectCrop
            smooth: true
            asynchronous: true
            cache: false
            visible: status === Image.Ready
            sourceSize.width: windowSwitcher.expandedWidth
            sourceSize.height: windowSwitcher.sliceHeight
          }


          Rectangle {
            anchors.fill: parent
            color: Qt.rgba(0, 0, 0, delegateItem.isCurrent ? 0 : 0.4)
            Behavior on color { ColorAnimation { duration: 200 } }
          }


          Text {
            id: bigIcon
            anchors.centerIn: parent
            anchors.verticalCenterOffset: -20
            text: service.getIcon(model.appId)
            property int iconSize: delegateItem.isCurrent ? 96 : 48
            font.pixelSize: iconSize
            font.family: Style.fontFamilyMono
            opacity: windowThumb.visible ? 0.7 : 1.0
            Behavior on opacity { NumberAnimation { duration: 200 } }
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

  }


  // Secondary monitor overlays to capture keyboard input from any screen
  Variants {
    model: Quickshell.screens

    PanelWindow {
      id: secondarySwitcherPanel

      property var modelData
      property bool isMainMonitor: modelData.name === windowSwitcher.mainMonitor || (Quickshell.screens.length === 1)

      screen: modelData
      visible: windowSwitcher.showing && !isMainMonitor
      color: "transparent"

      anchors {
        top: true
        bottom: true
        left: true
        right: true
      }

      WlrLayershell.namespace: "window-switcher-parallel-secondary"
      WlrLayershell.layer: WlrLayer.Overlay
      WlrLayershell.keyboardFocus: (windowSwitcher.showing && !isMainMonitor) ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

      exclusionMode: ExclusionMode.Ignore

      Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.01)
      }

      DimOverlay {
        active: windowSwitcher.cardVisible
        dimOpacity: 0.5
        onClicked: windowSwitcher.cancel()
      }

      FocusScope {
        anchors.fill: parent
        focus: windowSwitcher.showing && !isMainMonitor

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
    }
  }
}
