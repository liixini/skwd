import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import QtQuick.Controls
import QtQuick.Shapes
import ".."


Scope {
  id: appLauncher

  
  property var colors
  property bool showing: false

  property string mainMonitor: Config.mainMonitor

  property var appService: null

  AppLauncherService {
    id: service
    scriptsDir: Config.scriptsDir
    homeDir: Config.homeDir
    cacheDir: Config.cacheDir
    configDir: Config.configDir
    terminal: Config.terminal
    Component.onCompleted: appLauncher.appService = service

    onSearchTextChanged: {
      if (searchInput.text !== service.searchText)
        searchInput.text = service.searchText
    }

    onModelUpdated: {
      if (service.filteredModel.count > 0) {
        sliceListView.currentIndex = 0
        sliceListView.positionViewAtIndex(0, ListView.Beginning)
      }
    }
  }

  
  onShowingChanged: {
    if (showing) {
      service.searchText = ""
      searchInput.text = ""
      service.loadFreqData()
      cardShowTimer.restart()
      service.start()
    } else {
      cardVisible = false
      service.searchText = ""
      searchInput.text = ""
    }
  }

  Timer {
    id: cardShowTimer
    interval: 50
    onTriggered: appLauncher.cardVisible = true
  }

  Timer {
    id: focusTimer
    interval: 50
    onTriggered: sliceListView.forceActiveFocus()
  }

  
  property int sliceWidth: Config.sliceWidth
  property int expandedWidth: Config.expandedWidth
  property int sliceHeight: Config.sliceHeight
  property int skewOffset: Config.skewOffset
  property int sliceSpacing: Config.sliceSpacing
  property int visibleCount: Config.visibleCount

  
  property bool isSliceMode:  Config.displayMode === "slice"
  property bool isHexMode:    Config.displayMode === "hex"
  property bool isGridMode:   Config.displayMode === "wall"
  property bool isMosaicMode: Config.displayMode === "mosaic"

  
  readonly property int _hexCellW: Config.hexRadius * 2
  readonly property int _hexCellH: Math.ceil(Config.hexRadius * 1.73205)
  readonly property int hexGridWidth: _hexCellW * Config.hexCols + Config.hexRadius
  readonly property int hexGridHeight: _hexCellH * Config.hexRows + (Config.hexRows > 1 ? _hexCellH * 0.5 : 0)

  
  readonly property int _gridCellGap: 8
  readonly property int _gridTotalW: Config.gridColumns * (Config.gridThumbWidth + _gridCellGap)
  readonly property int _gridTotalH: Config.gridRows * (Config.gridThumbHeight + _gridCellGap)

  
  property int topBarHeight: 50
  property int cardWidth: {
    if (isHexMode)    return hexGridWidth + 60
    if (isGridMode)   return _gridTotalW + 40
    if (isMosaicMode) return Config.mosaicWidth + 40
    return 1600
  }
  property int cardHeight: {
    if (isHexMode)    return hexGridHeight + topBarHeight + 50
    if (isGridMode)   return _gridTotalH + topBarHeight + 50
    if (isMosaicMode) return Config.mosaicHeight + topBarHeight + 50
    return sliceHeight + topBarHeight + 60
  }

  property bool cardVisible: false

  property int lastContentX: 0
  property int lastIndex: 0

  function resetScroll() {
    lastContentX = 0
    lastIndex = 0
    sliceListView.currentIndex = 0
    if (service.filteredModel.count > 0)
      sliceListView.positionViewAtIndex(0, ListView.Beginning)
  }


  PanelWindow {
    id: launcherPanel

    screen: Quickshell.screens.find(s => s.name === appLauncher.mainMonitor) ?? Quickshell.screens[0]

    anchors {
      top: true
      bottom: true
      left: true
      right: true
    }

    visible: appLauncher.showing
    color: "transparent"

    WlrLayershell.namespace: "app-launcher-parallel"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: appLauncher.showing ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    exclusionMode: ExclusionMode.Ignore


    Rectangle {
      anchors.fill: parent
      color: Qt.rgba(0, 0, 0, 0.5)
      opacity: appLauncher.cardVisible ? 1 : 0
      Behavior on opacity { NumberAnimation { duration: 300 } }
    }

    MouseArea {
      anchors.fill: parent
      onClicked: appLauncher.showing = false
    }


    Item {
      id: cardContainer
      width: appLauncher.cardWidth
      height: appLauncher.cardHeight
      anchors.centerIn: parent
      visible: appLauncher.cardVisible

      property bool animateIn: appLauncher.cardVisible

      onAnimateInChanged: {
        fadeInAnim.stop()
        if (animateIn) {
          opacity = 0
          fadeInAnim.start()
          focusTimer.restart()
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


        Rectangle {
          id: filterBarBg
          anchors.horizontalCenter: parent.horizontalCenter
          anchors.top: parent.top
          anchors.topMargin: 10
          width: topFilterBar.width + 30
          height: topFilterBar.height + 14
          radius: height / 2
          color: appLauncher.colors ? Qt.rgba(appLauncher.colors.surfaceContainer.r,
                                               appLauncher.colors.surfaceContainer.g,
                                               appLauncher.colors.surfaceContainer.b, 0.85)
                                    : Qt.rgba(0.1, 0.12, 0.18, 0.85)
          z: 10
        }

        
        Row {
          id: topFilterBar
          anchors.centerIn: filterBarBg
          spacing: 16
          z: 11


          Row {
            id: sourceFilterRow
            spacing: 4
            anchors.verticalCenter: parent.verticalCenter

            Repeater {
              model: [
                { filter: "", icon: "󰄶", label: "All" },
                { filter: "desktop", icon: "󰀻", label: "Apps" },
                { filter: "game", icon: "󰊗", label: "Games" },
                { filter: "steam", icon: "󰓓", label: "Steam" }
              ]

              Rectangle {
                width: 32
                height: 24
                radius: 4
                property bool isSelected: service.sourceFilter === modelData.filter
                property bool isHovered: sourceMouseArea.containsMouse

                color: isSelected
                  ? (appLauncher.colors ? appLauncher.colors.primary : "#4fc3f7")
                  : (isHovered
                    ? (appLauncher.colors ? Qt.rgba(appLauncher.colors.surfaceVariant.r, appLauncher.colors.surfaceVariant.g, appLauncher.colors.surfaceVariant.b, 0.5) : Qt.rgba(1, 1, 1, 0.15))
                    : "transparent")

                border.width: isSelected ? 0 : 1
                border.color: isHovered ? (appLauncher.colors ? Qt.rgba(appLauncher.colors.primary.r, appLauncher.colors.primary.g, appLauncher.colors.primary.b, 0.4) : Qt.rgba(1, 1, 1, 0.2)) : "transparent"

                Behavior on color { ColorAnimation { duration: 100 } }

                Text {
                  anchors.centerIn: parent
                  text: modelData.icon
                  font.pixelSize: 14
                  font.family: Style.fontFamilyIcons
                  color: parent.isSelected
                    ? (appLauncher.colors ? appLauncher.colors.primaryText : "#000")
                    : (appLauncher.colors ? appLauncher.colors.tertiary : "#8bceff")
                }

                MouseArea {
                  id: sourceMouseArea
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onClicked: {
                    if (parent.isSelected) {
                      service.sourceFilter = ""
                    } else {
                      service.sourceFilter = modelData.filter
                    }
                  }
                }

                ToolTip {
                  visible: sourceMouseArea.containsMouse
                  text: modelData.label
                  delay: 500
                  contentWidth: implicitContentWidth
                }
              }
            }
          }


          Rectangle {
            width: 1; height: 20
            color: appLauncher.colors ? Qt.rgba(appLauncher.colors.primary.r, appLauncher.colors.primary.g, appLauncher.colors.primary.b, 0.3) : Qt.rgba(1, 1, 1, 0.2)
            anchors.verticalCenter: parent.verticalCenter
          }


          Text {
            text: "󰍉"
            font.family: Style.fontFamilyIcons
            font.pixelSize: 18
            color: appLauncher.colors ? appLauncher.colors.tertiary : "#8bceff"
            anchors.verticalCenter: parent.verticalCenter
          }


          TextInput {
            id: searchInput
            width: 200
            font.family: Style.fontFamily
            font.pixelSize: 14
            font.weight: Font.Medium
            color: "#ffffff"
            anchors.verticalCenter: parent.verticalCenter
            clip: true
            onTextChanged: service.searchText = text
            onAccepted: {
              if (sliceListView.currentIndex >= 0 && sliceListView.currentIndex < service.filteredModel.count) {
                var app = service.filteredModel.get(sliceListView.currentIndex)
                service.launchApp(app.exec, app.terminal, app.name)
                appLauncher.showing = false
              }
            }
            Keys.onEscapePressed: appLauncher.showing = false

            Text {
              anchors.fill: parent
              text: ""
              font: searchInput.font
              color: appLauncher.colors ? Qt.rgba(appLauncher.colors.primaryText.r, appLauncher.colors.primaryText.g, appLauncher.colors.primaryText.b, 0.4) : Qt.rgba(1, 1, 1, 0.4)
              visible: !searchInput.text
            }
          }


          Text {
            text: ""
            font.family: Style.fontFamily
            font.pixelSize: 11
            font.weight: Font.Medium
            color: appLauncher.colors ? Qt.rgba(appLauncher.colors.primaryText.r, appLauncher.colors.primaryText.g, appLauncher.colors.primaryText.b, 0.5) : Qt.rgba(1, 1, 1, 0.5)
            anchors.verticalCenter: parent.verticalCenter
          }

        }


        Rectangle {
          anchors.fill: parent
          color: appLauncher.colors ? Qt.rgba(appLauncher.colors.surfaceContainer.r,
                                               appLauncher.colors.surfaceContainer.g,
                                               appLauncher.colors.surfaceContainer.b, 0.95)
                                    : Qt.rgba(0.08, 0.1, 0.14, 0.95)
          radius: 20
          visible: service.cacheLoading
          z: 50

          Rectangle {
            anchors.centerIn: parent
            anchors.verticalCenterOffset: 12
            width: 300
            height: 4
            radius: 2
            color: Qt.rgba(1, 1, 1, 0.1)

            Rectangle {
              anchors.left: parent.left
              anchors.top: parent.top
              anchors.bottom: parent.bottom
              radius: 2
              width: service.cacheTotal > 0
                ? parent.width * (service.cacheProgress / service.cacheTotal)
                : 0
              color: appLauncher.colors ? appLauncher.colors.primary : "#4fc3f7"
              Behavior on width { NumberAnimation { duration: 100; easing.type: Easing.OutCubic } }
            }
          }

          Text {
            anchors.centerIn: parent
            anchors.verticalCenterOffset: -12
            text: service.cacheTotal > 0
              ? "LOADING APPS... " + service.cacheProgress + " / " + service.cacheTotal
              : "SCANNING..."
            color: appLauncher.colors ? appLauncher.colors.tertiary : "#8bceff"
            font.family: Style.fontFamily
            font.pixelSize: 12
            font.weight: Font.Medium
            font.letterSpacing: 0.5
          }
        }
      }
    }


    ListView {
      id: sliceListView
      visible: appLauncher.cardVisible && appLauncher.isSliceMode
      anchors.top: cardContainer.top
      anchors.topMargin: appLauncher.topBarHeight + 15
      anchors.bottom: cardContainer.bottom
      anchors.bottomMargin: 20
      anchors.horizontalCenter: parent.horizontalCenter
      property int visibleCount: appLauncher.visibleCount
      width: appLauncher.expandedWidth + (visibleCount - 1) * (appLauncher.sliceWidth + appLauncher.sliceSpacing)
      Behavior on width { NumberAnimation { duration: Style.animExpand; easing.type: Easing.OutCubic } }

      orientation: ListView.Horizontal
      model: service.filteredModel
      clip: false
      spacing: appLauncher.sliceSpacing

      flickDeceleration: 1500
      maximumFlickVelocity: 3000
      boundsBehavior: Flickable.StopAtBounds
      cacheBuffer: appLauncher.expandedWidth

      property bool keyboardNavActive: false
      property real lastMouseX: -1
      property real lastMouseY: -1

      highlightFollowsCurrentItem: true
      highlightMoveDuration: Style.animExpand
      highlight: Item {}
      preferredHighlightBegin: (width - appLauncher.expandedWidth) / 2
      preferredHighlightEnd: (width + appLauncher.expandedWidth) / 2
      highlightRangeMode: ListView.StrictlyEnforceRange
      header: Item { width: (sliceListView.width - appLauncher.expandedWidth) / 2; height: 1 }
      footer: Item { width: (sliceListView.width - appLauncher.expandedWidth) / 2; height: 1 }

      focus: appLauncher.showing
      onVisibleChanged: {
        if (visible) forceActiveFocus()
      }

      Connections {
        target: appLauncher
        function onShowingChanged() {
          if (appLauncher.showing) {
            sliceListView.forceActiveFocus()
          }
        }
      }

      add: Transition {
        NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Style.animEnter; easing.type: Easing.OutCubic }
        NumberAnimation { property: "scale"; from: 0.85; to: 1; duration: Style.animEnter; easing.type: Easing.OutCubic }
      }
      remove: Transition {
        NumberAnimation { property: "opacity"; to: 0; duration: Style.animNormal; easing.type: Easing.InCubic }
      }
      displaced: Transition {
        NumberAnimation { properties: "x,y"; duration: Style.animMedium; easing.type: Easing.OutCubic }
      }
      move: Transition {
        NumberAnimation { properties: "x,y"; duration: Style.animMedium; easing.type: Easing.OutCubic }
      }

      MouseArea {
        anchors.fill: parent
        propagateComposedEvents: true
        onWheel: function(wheel) {
          var step = 1
          if (wheel.angleDelta.y > 0 || wheel.angleDelta.x > 0) {
            sliceListView.currentIndex = Math.max(0, sliceListView.currentIndex - step)
          } else if (wheel.angleDelta.y < 0 || wheel.angleDelta.x < 0) {
            sliceListView.currentIndex = Math.min(service.filteredModel.count - 1, sliceListView.currentIndex + step)
          }
        }
        onPressed: function(mouse) { mouse.accepted = false }
        onReleased: function(mouse) { mouse.accepted = false }
        onClicked: function(mouse) { mouse.accepted = false }
      }

      Keys.onPressed: event => {
        if (event.key === Qt.Key_Escape) {
          appLauncher.showing = false
          event.accepted = true
          return
        }


        if (event.text && event.text.length > 0 && !event.modifiers) {
          var c = event.text.charCodeAt(0)
          if (c >= 32 && c < 127) {
            searchInput.text += event.text
            searchInput.forceActiveFocus()
            event.accepted = true
            return
          }
        }

        if (event.key === Qt.Key_Backspace) {
          if (searchInput.text.length > 0) {
            searchInput.text = searchInput.text.slice(0, -1)
          }
          event.accepted = true
          return
        }

        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
          if (sliceListView.currentIndex >= 0 && sliceListView.currentIndex < service.filteredModel.count) {
            var app = service.filteredModel.get(sliceListView.currentIndex)
            service.launchApp(app.exec, app.terminal, app.name)
            appLauncher.showing = false
          }
          event.accepted = true
          return
        }

        sliceListView.keyboardNavActive = true

        if (event.key === Qt.Key_Left) {
          if (currentIndex > 0) {
            currentIndex--
          }
          event.accepted = true
          return
        }
        if (event.key === Qt.Key_Right) {
          if (currentIndex < service.filteredModel.count - 1) {
            currentIndex++
          }
          event.accepted = true
          return
        }
      }


      delegate: SliceDelegate {
        colors: appLauncher.colors
        service: appLauncher.appService
        expandedWidth: appLauncher.expandedWidth
        sliceWidth: appLauncher.sliceWidth
        skewOffset: appLauncher.skewOffset
        onActivated: function(item) {
          if (item) {
            appLauncher.appService.launchApp(item.exec, item.terminal, item.name)
            appLauncher.showing = false
          }
        }
      }
    }


    ListView {
      id: hexListView
      visible: appLauncher.cardVisible && appLauncher.isHexMode
      anchors.top: cardContainer.top
      anchors.topMargin: appLauncher.topBarHeight + 15
      anchors.bottom: cardContainer.bottom
      anchors.bottomMargin: 20
      anchors.left: cardContainer.left
      anchors.right: cardContainer.right
      orientation: ListView.Horizontal
      clip: true
      property int _rows: Config.hexRows
      property real _r: Config.hexRadius
      property real _gridSpacing: 6
      property real _hexW: _r * 2
      property real _hexH: Math.ceil(_r * 1.73205)
      property real _stepX: 1.5 * _r + _gridSpacing
      property real _stepY: _hexH + _gridSpacing
      property real _gridContentH: (_rows - 1) * _stepY + _hexH + _hexH / 2
      property real _yOffset: Math.max(0, (height - _gridContentH) / 2)
      property real _visibleBand: (Config.hexCols - 1) * _stepX + _hexW
      property real _fadeZone: (width - _visibleBand) / 2

      boundsBehavior: Flickable.StopAtBounds
      flickDeceleration: 1500
      maximumFlickVelocity: 3000
      cacheBuffer: _stepX * 2

      property bool _initialSnap: true
      onVisibleChanged: {
        if (visible) {
          _initialSnap = true
          highlightMoveDuration = 0
          var startCol = Math.min(Math.floor(Config.hexCols / 2), count - 1)
          if (startCol >= 0) { currentIndex = startCol; _selectedCol = startCol; _selectedRow = 0 }
          positionViewAtIndex(currentIndex, ListView.Center)
          _snapRestoreTimer.restart()
        }
      }

      Timer {
        id: _snapRestoreTimer
        interval: 50
        onTriggered: {
          hexListView.highlightMoveDuration = Style.animExpand
          hexListView._initialSnap = false
        }
      }

      model: Math.ceil((service.filteredModel ? service.filteredModel.count : 0) / Math.max(1, _rows))

      spacing: 0
      highlightFollowsCurrentItem: true
      highlightMoveDuration: Style.animExpand
      highlight: Item {}
      preferredHighlightBegin: (width - _hexW) / 2
      preferredHighlightEnd: (width + _hexW) / 2
      highlightRangeMode: ListView.StrictlyEnforceRange

      header: Item { width: (hexListView.width - hexListView._hexW) / 2 }
      footer: Item { width: (hexListView.width - hexListView._hexW) / 2 }

      add: Transition {
        NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Style.animEnter; easing.type: Easing.OutCubic }
        NumberAnimation { property: "scale"; from: 0.9; to: 1; duration: Style.animEnter; easing.type: Easing.OutCubic }
      }
      remove: Transition {
        NumberAnimation { property: "opacity"; to: 0; duration: Style.animNormal; easing.type: Easing.InCubic }
      }
      displaced: Transition {
        NumberAnimation { properties: "x,y"; duration: Style.animMedium; easing.type: Easing.OutCubic }
      }

      MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.NoButton
        onWheel: function(wheel) {
          var step = Config.hexScrollStep
          if (wheel.angleDelta.y > 0 || wheel.angleDelta.x > 0) {
            hexListView.currentIndex = Math.max(0, hexListView.currentIndex - step)
            hexListView._selectedCol = hexListView.currentIndex
          } else if (wheel.angleDelta.y < 0 || wheel.angleDelta.x < 0) {
            hexListView.currentIndex = Math.min(hexListView.count - 1, hexListView.currentIndex + step)
            hexListView._selectedCol = hexListView.currentIndex
          }
        }
      }

      property int _selectedCol: currentIndex
      property int _selectedRow: 0

      delegate: Item {
        id: hexCol
        width: hexListView._stepX
        height: hexListView.height
        clip: false
        property int colIdx: index

        readonly property real _colCenter: (x - hexListView.contentX) + width * 0.5
        readonly property bool _insideView: _colCenter > -hexListView._hexW && _colCenter < hexListView.width + hexListView._hexW
        readonly property bool _nearEdge: _colCenter < hexListView._fadeZone || _colCenter > (hexListView.width - hexListView._fadeZone)
        readonly property bool _nearLeft: _colCenter < hexListView.width / 2
        readonly property bool _visible: _insideView && !_nearEdge
        property real _colScale: _visible ? 1 : 0
        Behavior on _colScale { enabled: !hexListView._initialSnap; NumberAnimation { duration: Style.animExpand; easing.type: Easing.OutCubic } }

        property real _arcFactor: Config.hexArc ? Config.hexArcIntensity : 0
        Behavior on _arcFactor { NumberAnimation { duration: Style.animExpand; easing.type: Easing.OutCubic } }

        readonly property real _arcOffset: {
          if (_arcFactor === 0) return 0
          var viewCenterX = hexListView.width / 2
          var normalized = (_colCenter - viewCenterX) / Math.max(1, viewCenterX)
          return -normalized * normalized * hexListView._r * _arcFactor
        }

        Repeater {
          id: hexCellRepeater
          property var _items: {
            service.filteredModel ? service.filteredModel.count : 0
            service._rev
            var arr = []
            var start = hexCol.colIdx * hexListView._rows
            var end = Math.min(start + hexListView._rows, service.filteredModel ? service.filteredModel.count : 0)
            for (var i = start; i < end; i++) {
              var r = service.filteredModel.get(i)
              if (r) arr.push({ row: r, rowIdx: i - start, flatIdx: i })
            }
            return arr
          }
          model: _items

          HexDelegate {
            required property var modelData
            readonly property int rowIdx: modelData.rowIdx
            readonly property int flatIdx: modelData.flatIdx

            hexRadius: hexListView._r
            colors: appLauncher.colors
            service: service
            itemData: modelData.row
            isSelected: hexCol.colIdx === hexListView._selectedCol && rowIdx === hexListView._selectedRow

            x: 0
            y: hexListView._yOffset + rowIdx * hexListView._stepY + (hexCol.colIdx % 2 !== 0 ? hexListView._hexH / 2 : 0) + hexCol._arcOffset

            scale: hexCol._colScale
            transformOrigin: hexCol._nearLeft ? Item.Left : Item.Right
            opacity: hexCol._colScale < 0.01 ? 0 : 1

            onHoverSelected: {
              hexListView._selectedCol = hexCol.colIdx
              hexListView._selectedRow = rowIdx
            }
            onActivated: function(item) {
              if (item) {
                service.launchApp(item.exec, item.terminal, item.name)
                appLauncher.showing = false
              }
            }
          }
        }
      }
    }


    GridView {
      id: thumbGridView
      visible: appLauncher.cardVisible && appLauncher.isGridMode
      anchors.top: cardContainer.top
      anchors.topMargin: appLauncher.topBarHeight + 15
      anchors.horizontalCenter: parent.horizontalCenter
      anchors.horizontalCenterOffset: appLauncher._gridCellGap / 2
      width: appLauncher._gridTotalW
      height: appLauncher._gridTotalH
      cellWidth: Config.gridThumbWidth + appLauncher._gridCellGap
      cellHeight: Config.gridThumbHeight + appLauncher._gridCellGap
      clip: true
      model: service.filteredModel
      cacheBuffer: 300
      boundsBehavior: Flickable.StopAtBounds
      
      
      interactive: false

      property real _scrollTarget: 0
      onContentYChanged: {
        if (!_gridScrollAnim.running) _scrollTarget = contentY
      }

      NumberAnimation {
        id: _gridScrollAnim
        target: thumbGridView
        property: "contentY"
        duration: 400
        easing.type: Easing.OutCubic
      }

      function _snapScroll(delta) {
        if (!_gridScrollAnim.running) _scrollTarget = contentY
        var step = cellHeight
        _scrollTarget += (delta > 0 ? -step : step)
        var maxY = Math.max(0, contentHeight - height)
        _scrollTarget = Math.max(0, Math.min(_scrollTarget, maxY))
        _gridScrollAnim.stop()
        _gridScrollAnim.from = contentY
        _gridScrollAnim.to = _scrollTarget
        _gridScrollAnim.start()
      }

      function _snapScrollTo(target) {
        var maxY = Math.max(0, contentHeight - height)
        _scrollTarget = Math.max(0, Math.min(target, maxY))
        _gridScrollAnim.stop()
        _gridScrollAnim.from = contentY
        _gridScrollAnim.to = _scrollTarget
        _gridScrollAnim.start()
      }

      function _ensureVisible(idx) {
        var cols = Math.max(1, Math.floor(width / cellWidth))
        var row = Math.floor(idx / cols)
        var rowTop = row * cellHeight
        var rowBottom = rowTop + cellHeight
        if (rowTop < contentY) _snapScrollTo(rowTop)
        else if (rowBottom > contentY + height) _snapScrollTo(rowBottom - height)
      }

      MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.NoButton
        onWheel: function(wheel) {
          thumbGridView._snapScroll(wheel.angleDelta.y)
        }
      }

      add: Transition {
        NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Style.animEnter; easing.type: Easing.OutCubic }
        NumberAnimation { property: "scale"; from: 0.9; to: 1; duration: Style.animEnter; easing.type: Easing.OutCubic }
      }
      remove: Transition {
        NumberAnimation { property: "opacity"; to: 0; duration: Style.animNormal; easing.type: Easing.InCubic }
      }
      displaced: Transition {
        NumberAnimation { properties: "x,y"; duration: Style.animMedium; easing.type: Easing.OutCubic }
      }

      delegate: Rectangle {
        width: Config.gridThumbWidth
        height: Config.gridThumbHeight
        radius: 6
        color: appLauncher.colors ? Qt.rgba(appLauncher.colors.surfaceContainer.r, appLauncher.colors.surfaceContainer.g, appLauncher.colors.surfaceContainer.b, 0.85) : Qt.rgba(0.1, 0.12, 0.18, 0.85)
        border.width: _gridMouse.containsMouse ? 2 : 0
        border.color: appLauncher.colors ? appLauncher.colors.primary : "#4fc3f7"
        clip: true

        Image {
          anchors.fill: parent
          source: model.background ? "file://" + model.background : (model.thumb ? "file://" + model.thumb : "")
          fillMode: model.source === "steam" || model.background ? Image.PreserveAspectCrop : Image.Pad
          horizontalAlignment: Image.AlignHCenter
          verticalAlignment: Image.AlignVCenter
          asynchronous: true
          smooth: true
        }

        Rectangle {
          anchors.fill: parent
          color: Qt.rgba(0, 0, 0, _gridMouse.containsMouse ? 0.15 : 0.4)
          Behavior on color { ColorAnimation { duration: 150 } }
        }

        Text {
          anchors.bottom: parent.bottom
          anchors.bottomMargin: 6
          anchors.horizontalCenter: parent.horizontalCenter
          text: (model.displayName || model.name || "").toUpperCase()
          font.family: Style.fontFamily
          font.pixelSize: 10
          font.weight: Font.Bold
          color: "#fff"
        }

        MouseArea {
          id: _gridMouse
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: {
            service.launchApp(model.exec, model.terminal, model.name)
            appLauncher.showing = false
          }
        }
      }
    }


    MosaicView {
      id: mosaicView
      visible: appLauncher.cardVisible && appLauncher.isMosaicMode
      active: visible
      anchors.top: cardContainer.top
      anchors.topMargin: appLauncher.topBarHeight + 15
      anchors.horizontalCenter: parent.horizontalCenter
      width: Config.mosaicWidth
      height: Config.mosaicHeight
      colors: appLauncher.colors
      service: service
      onItemActivated: function(item) {
        if (item) {
          service.launchApp(item.exec, item.terminal, item.name)
          appLauncher.showing = false
        }
      }
    }

  }


  Variants {
    model: Quickshell.screens

    Loader {
      id: secondaryLoader
      property var modelData
      readonly property var _mainScreen: Quickshell.screens.find(s => s.name === appLauncher.mainMonitor) ?? Quickshell.screens[0]
      property bool isMainMonitor: modelData === _mainScreen || Quickshell.screens.length === 1
      active: appLauncher.showing && !isMainMonitor

      sourceComponent: PanelWindow {
        screen: secondaryLoader.modelData
        visible: true
        color: "transparent"

        anchors { top: true; bottom: true; left: true; right: true }

        WlrLayershell.namespace: "app-launcher-funnel-" + (screen?.name || "x")
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

        exclusionMode: ExclusionMode.Ignore

        Rectangle {
          anchors.fill: parent
          color: Qt.rgba(0, 0, 0, 0.5)
          opacity: appLauncher.cardVisible ? 1 : 0
          Behavior on opacity { NumberAnimation { duration: 300 } }
        }

        MouseArea {
          anchors.fill: parent
          onClicked: appLauncher.showing = false
        }

        FocusScope {
          id: funnelScope
          anchors.fill: parent
          focus: true
          activeFocusOnTab: false

          Component.onCompleted: forceActiveFocus()
          onActiveFocusChanged: { if (!activeFocus) forceActiveFocus() }

          Keys.onPressed: function(event) {
            if (event.key === Qt.Key_Escape) {
              appLauncher.showing = false
              event.accepted = true
              return
            }
            if (event.text && event.text.length > 0 && !event.modifiers) {
              var c = event.text.charCodeAt(0)
              if (c >= 32 && c < 127) {
                searchInput.text += event.text
                event.accepted = true
                return
              }
            }
            if (event.key === Qt.Key_Backspace) {
              if (searchInput.text.length > 0) {
                searchInput.text = searchInput.text.slice(0, -1)
              }
              event.accepted = true
              return
            }
            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
              if (sliceListView.currentIndex >= 0 && sliceListView.currentIndex < service.filteredModel.count) {
                var app = service.filteredModel.get(sliceListView.currentIndex)
                service.launchApp(app.exec, app.terminal, app.name)
                appLauncher.showing = false
              }
              event.accepted = true
              return
            }
            if (event.key === Qt.Key_Left) {
              if (sliceListView.currentIndex > 0) sliceListView.currentIndex--
              event.accepted = true
              return
            }
            if (event.key === Qt.Key_Right) {
              if (sliceListView.currentIndex < service.filteredModel.count - 1) sliceListView.currentIndex++
              event.accepted = true
              return
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
