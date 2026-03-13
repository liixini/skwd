import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Notifications
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import "components"

// Notification popup toasts and sliding notification center panel
Scope {
  id: notifScope

  // State and layout properties
  property var colors
  property var notifications
  property string mainMonitor: Config.mainMonitor
  property bool barVisible: false
  property int barHeight: 32


  property int effectiveTopMargin: barVisible ? popupTopMargin + barHeight : popupTopMargin


  // Center panel toggle and dismiss-all helper
  property bool centerOpen: false
  function toggleCenter() { centerOpen = !centerOpen }
  function dismissAll() {
    if (!notifications) return
    var vals = notifications.values
    for (var i = vals.length - 1; i >= 0; i--) {
      vals[i].dismiss()
    }
  }


  property int popupWidth: 320
  property int popupSpacing: 8
  property int popupMaxVisible: 4
  property int popupRightMargin: 16
  property int popupTopMargin: 12


  property int notifCount: notifications ? notifications.values.length : 0
  property bool hasNotifs: notifCount > 0


  // Overlay panel (full-screen when center open, popup-sized otherwise)
  PanelWindow {
    id: notifPanel

    screen: Quickshell.screens.find(s => s.name === notifScope.mainMonitor) ?? Quickshell.screens[0]

    anchors {
      top: true
      right: true
    }


    implicitWidth: notifScope.centerOpen
      ? (screen ? screen.width : 1920)
      : notifScope.popupWidth + notifScope.popupRightMargin * 2
    implicitHeight: notifScope.centerOpen
      ? (screen ? screen.height : 1080)
      : Math.max(1, notifScope.effectiveTopMargin + popupColumn.childrenRect.height + notifScope.popupSpacing * 2)

    color: "transparent"

    visible: notifScope.centerOpen || popupColumn.childrenRect.height > 0

    WlrLayershell.namespace: "notifications"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: notifScope.centerOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    exclusionMode: ExclusionMode.Ignore


    // Dim background when center panel is open
    DimOverlay {
      active: notifScope.centerOpen
      visible: notifScope.centerOpen
      onClicked: notifScope.centerOpen = false

      Item {
        focus: notifScope.centerOpen
        Keys.onEscapePressed: notifScope.centerOpen = false
      }
    }


    // Notification center slide-in card
    Item {
      id: centerCard
      visible: notifScope.centerOpen
      anchors.right: parent.right
      anchors.rightMargin: notifScope.popupRightMargin
      anchors.top: parent.top
      anchors.topMargin: notifScope.popupTopMargin
      anchors.bottom: parent.bottom
      anchors.bottomMargin: notifScope.popupTopMargin
      width: notifScope.popupWidth

      property bool animateIn: notifScope.centerOpen

      onAnimateInChanged: {
        if (animateIn) {
          centerBorderBox.animate()
          centerBg.opacity = 0
          centerBgFadeIn.start()
        } else {
          centerBorderBox.reset()
          centerBg.opacity = 0
        }
      }

      property color lineColor: notifScope.colors ? notifScope.colors.primary : "#ffb4ab"
      property real slant: 28

      Canvas {
        id: centerBg
        anchors.fill: parent
        opacity: 0
        onPaint: {
          var ctx = getContext("2d")
          ctx.clearRect(0, 0, width, height)
          var s = centerCard.slant
          ctx.beginPath()
          ctx.moveTo(0, 0)
          ctx.lineTo(width - s, 0)
          ctx.lineTo(width, height)
          ctx.lineTo(s, height)
          ctx.closePath()
          var c = notifScope.colors
          ctx.fillStyle = c
            ? Qt.rgba(c.surface.r, c.surface.g, c.surface.b, 0.88)
            : Qt.rgba(0.1, 0.12, 0.18, 0.88)
          ctx.fill()
        }
        Connections {
          target: notifScope
          function onColorsChanged() { centerBg.requestPaint() }
        }
      }

      NumberAnimation { id: centerBgFadeIn; target: centerBg; property: "opacity"; from: 0; to: 1; duration: 600; easing.type: Easing.OutCubic }

      Canvas {
        id: centerBorderBox
        anchors.fill: parent
        property real progress: 0
        function animate() { centerBorderAnim.restart() }
        function reset() { centerBorderAnim.stop(); progress = 0; requestPaint() }
        onPaint: {
          var ctx = getContext("2d")
          ctx.clearRect(0, 0, width, height)
          var s = centerCard.slant
          var p = progress
          if (p <= 0) return
          ctx.strokeStyle = centerCard.lineColor
          ctx.lineWidth = 2
          ctx.lineCap = "round"
          var perim = width * 2 + height * 2
          var len = perim * p
          var segments = [
            {x1: 0, y1: 0, x2: width - s, y2: 0, len: width - s},
            {x1: width - s, y1: 0, x2: width, y2: height, len: Math.sqrt(s*s + height*height)},
            {x1: width, y1: height, x2: s, y2: height, len: width - s},
            {x1: s, y1: height, x2: 0, y2: 0, len: Math.sqrt(s*s + height*height)}
          ]
          ctx.beginPath()
          var remain = len
          var started = false
          for (var i = 0; i < segments.length && remain > 0; i++) {
            var seg = segments[i]
            if (!started) { ctx.moveTo(seg.x1, seg.y1); started = true }
            var frac = Math.min(1, remain / seg.len)
            var ex = seg.x1 + (seg.x2 - seg.x1) * frac
            var ey = seg.y1 + (seg.y2 - seg.y1) * frac
            ctx.lineTo(ex, ey)
            remain -= seg.len
          }
          ctx.stroke()
        }
        onProgressChanged: requestPaint()
        NumberAnimation {
          id: centerBorderAnim
          target: centerBorderBox
          property: "progress"
          from: 0; to: 1
          duration: 600
          easing.type: Easing.OutCubic
        }
      }


      MouseArea { anchors.fill: parent }


      // Center header with title and clear-all button
      RowLayout {
        id: centerHeader
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: centerCard.slant + 8
        anchors.rightMargin: centerCard.slant + 8
        anchors.topMargin: 16
        height: 36

        Text {
          text: "NOTIFICATIONS"
          font.family: Style.fontFamily
          font.weight: Font.Medium
          font.pixelSize: 14
          color: notifScope.colors ? notifScope.colors.primary : "#ffb4ab"
          Layout.fillWidth: true
        }


        Rectangle {
          width: dismissAllText.implicitWidth + 16
          height: 24
          radius: 12
          color: dismissAllMouse.containsMouse
            ? (notifScope.colors ? notifScope.colors.primary : "#ffb4ab")
            : "transparent"
          border.width: 1
          border.color: notifScope.colors ? notifScope.colors.primary : "#ffb4ab"

          Text {
            id: dismissAllText
            anchors.centerIn: parent
            text: "CLEAR ALL"
            font.family: Style.fontFamily
            font.weight: Font.Medium
            font.pixelSize: 11
            color: dismissAllMouse.containsMouse
              ? (notifScope.colors ? notifScope.colors.primaryForeground : "#690005")
              : (notifScope.colors ? notifScope.colors.primary : "#ffb4ab")
          }

          MouseArea {
            id: dismissAllMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: notifScope.dismissAll()
          }
        }
      }


      // Scrollable notification list
      Flickable {
        anchors.top: centerHeader.bottom
        anchors.topMargin: 8
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.leftMargin: centerCard.slant + 4
        anchors.rightMargin: centerCard.slant + 4
        anchors.bottomMargin: 12
        clip: true
        contentHeight: centerColumn.implicitHeight
        flickableDirection: Flickable.VerticalFlick
        boundsBehavior: Flickable.StopAtBounds

        Column {
          id: centerColumn
          width: parent.width
          spacing: notifScope.popupSpacing

          Repeater {
            model: notifScope.notifications

            delegate: NotificationCard {
              required property var modelData
              notification: modelData
              colors: notifScope.colors
              cardWidth: centerColumn.width
              isPopup: false
            }
          }
        }


        Text {
          anchors.centerIn: parent
          visible: !notifScope.hasNotifs
          text: "NO NOTIFICATIONS"
          font.family: Style.fontFamily
          font.weight: Font.Bold
          font.pixelSize: 16
          color: notifScope.colors ? notifScope.colors.outline : "#666666"
        }
      }
    }


    // Popup toast stack (top-right corner)
    Column {
      id: popupColumn
      visible: !notifScope.centerOpen
      anchors.right: parent.right
      anchors.rightMargin: notifScope.popupRightMargin
      anchors.top: parent.top
      anchors.topMargin: notifScope.effectiveTopMargin
      width: notifScope.popupWidth
      spacing: notifScope.popupSpacing


      Repeater {
        id: popupRepeater
        model: notifScope.notifications

        delegate: NotificationCard {
          required property var modelData
          required property int index
          notification: modelData
          colors: notifScope.colors
          cardWidth: notifScope.popupWidth
          isPopup: true

          visible: index >= notifScope.notifCount - notifScope.popupMaxVisible
        }
      }
    }
  }


  // Inline notification card component
  component NotificationCard: Item {
    id: card

    // Card properties
    property var notification
    property var colors
    property int cardWidth: 320
    property bool isPopup: true

    width: cardWidth

    property real cardNaturalHeight: contentColumn.implicitHeight + 26
    height: cardNaturalHeight
    clip: true


    property bool dismissing: false


    opacity: 0
    transform: Translate { id: cardTranslate; x: 40 }

    Component.onCompleted: {
      cardEntryAnim.start()
      if (isPopup) autoExpireTimer.start()
    }


    // Entry slide-in animation
    ParallelAnimation {
      id: cardEntryAnim
      NumberAnimation { target: card; property: "opacity"; from: 0; to: 1; duration: 350; easing.type: Easing.OutCubic }
      NumberAnimation { target: cardTranslate; property: "x"; from: 40; to: 0; duration: 350; easing.type: Easing.OutCubic }
      NumberAnimation { target: cardBg; property: "opacity"; from: 0; to: 1; duration: 350; easing.type: Easing.OutCubic }
      NumberAnimation { target: card; property: "lineProgress"; from: 0; to: 1; duration: 600; easing.type: Easing.OutCubic }
    }

    // Exit slide-out and collapse animation
    SequentialAnimation {
      id: cardExitAnim

      ParallelAnimation {
        NumberAnimation { target: card; property: "opacity"; to: 0; duration: 300; easing.type: Easing.InCubic }
        NumberAnimation { target: cardTranslate; property: "x"; to: 40; duration: 300; easing.type: Easing.InCubic }
        NumberAnimation { target: cardBg; property: "opacity"; to: 0; duration: 300; easing.type: Easing.InCubic }
        NumberAnimation { target: card; property: "lineProgress"; to: 0; duration: 400; easing.type: Easing.InCubic }
      }


      NumberAnimation { target: card; property: "height"; to: 0; duration: 200; easing.type: Easing.InOutCubic }

      ScriptAction {
        script: {
          if (card.notification) card.notification.dismiss()
        }
      }
    }


    function animateDismiss() {
      if (dismissing) return
      dismissing = true
      autoExpireTimer.stop()
      cardEntryAnim.stop()
      cardExitAnim.start()
    }

    // Auto-expire timer (pauses on hover)
    Timer {
      id: autoExpireTimer
      interval: {
        if (card.notification && card.notification.expireTimeout > 0)
          return card.notification.expireTimeout
        return Config.notificationExpireMs
      }
      running: false
      onTriggered: card.animateDismiss()
    }


    // Pause auto-expire on hover
    property bool hovered: cardMouse.containsMouse
    onHoveredChanged: {
      if (!isPopup) return
      if (hovered) {
        autoExpireTimer.stop()
      } else if (!dismissing) {
        autoExpireTimer.restart()
      }
    }

    property real lineProgress: 0
    property color lineColor: colors ? colors.primary : "#ffb4ab"
    property real slant: 28

    Canvas {
      id: cardBg
      anchors.fill: parent
      opacity: 0
      onPaint: {
        var ctx = getContext("2d")
        ctx.clearRect(0, 0, width, height)
        var s = card.slant
        ctx.beginPath()
        ctx.moveTo(0, 0)
        ctx.lineTo(width - s, 0)
        ctx.lineTo(width, height)
        ctx.lineTo(s, height)
        ctx.closePath()
        var c = card.colors
        ctx.fillStyle = c
          ? Qt.rgba(c.surface.r, c.surface.g, c.surface.b, 0.88)
          : Qt.rgba(0.1, 0.12, 0.18, 0.88)
        ctx.fill()
      }
      Connections {
        target: card
        function onColorsChanged() { cardBg.requestPaint() }
      }
    }

    Canvas {
      id: cardBorder
      anchors.fill: parent
      opacity: card.lineProgress
      onPaint: {
        var ctx = getContext("2d")
        ctx.clearRect(0, 0, width, height)
        var s = card.slant
        var p = card.lineProgress
        if (p <= 0) return
        ctx.strokeStyle = card.lineColor
        ctx.lineWidth = 2
        ctx.lineCap = "round"
        var perim = width * 2 + height * 2
        var len = perim * p
        var segments = [
          {x1: 0, y1: 0, x2: width - s, y2: 0, len: width - s},
          {x1: width - s, y1: 0, x2: width, y2: height, len: Math.sqrt(s*s + height*height)},
          {x1: width, y1: height, x2: s, y2: height, len: width - s},
          {x1: s, y1: height, x2: 0, y2: 0, len: Math.sqrt(s*s + height*height)}
        ]
        ctx.beginPath()
        var remain = len
        var started = false
        for (var i = 0; i < segments.length && remain > 0; i++) {
          var seg = segments[i]
          if (!started) { ctx.moveTo(seg.x1, seg.y1); started = true }
          var frac = Math.min(1, remain / seg.len)
          var ex = seg.x1 + (seg.x2 - seg.x1) * frac
          var ey = seg.y1 + (seg.y2 - seg.y1) * frac
          ctx.lineTo(ex, ey)
          remain -= seg.len
        }
        ctx.stroke()
      }
      Connections {
        target: card
        function onLineProgressChanged() { cardBorder.requestPaint() }
        function onLineColorChanged() { cardBorder.requestPaint() }
      }
    }


    // Card content layout (app name, summary, body, actions)
    Item {
      id: cardContent
      anchors.fill: parent
      anchors.leftMargin: card.slant + 1
      anchors.rightMargin: card.slant + 1

      ColumnLayout {
        id: contentColumn
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 12
        spacing: 4


        RowLayout {
          Layout.fillWidth: true
          spacing: 6

          Text {
            text: card.notification ? (card.notification.appName || "Notification") : "Notification"
            font.family: Style.fontFamily
            font.weight: Font.Medium
            font.pixelSize: 12
            color: card.colors ? card.colors.primary : "#ffb4ab"
          }

          Text {
            text: "·"
            font.pixelSize: 12
            font.weight: Font.Medium
            color: card.colors ? card.colors.outline : "#666"
            visible: summaryLabel.text !== ""
          }

          Text {
            id: summaryLabel
            text: card.notification ? (card.notification.summary || "") : ""
            font.family: Style.fontFamily
            font.weight: Font.Medium
            font.pixelSize: 12
            color: card.colors ? card.colors.tertiary : "#8bceff"
            elide: Text.ElideRight
            Layout.fillWidth: true
            visible: text !== ""
          }

          Text {
            text: "✕"
            font.pixelSize: 12
            color: closeMouse.containsMouse
              ? (card.colors ? card.colors.primary : "#ffb4ab")
              : (card.colors ? card.colors.outline : "#666")

            MouseArea {
              id: closeMouse
              anchors.fill: parent
              anchors.margins: -4
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: card.animateDismiss()
            }
          }
        }


        Text {
          text: card.notification ? (card.notification.body || "") : ""
          font.family: Style.fontFamily
          font.pixelSize: 12
          color: card.colors ? card.colors.surfaceVariantText : "#e2beba"
          wrapMode: Text.Wrap
          Layout.fillWidth: true
          visible: text !== ""
          maximumLineCount: card.isPopup ? 3 : 6
          elide: Text.ElideRight
        }


        // Action buttons row
        RowLayout {
          Layout.fillWidth: true
          spacing: 6
          visible: card.notification && card.notification.actions && card.notification.actions.length > 0

          Repeater {
            model: card.notification ? card.notification.actions : []

            delegate: Rectangle {
              required property var modelData
              property var action: modelData

              width: actionLabel.implicitWidth + 16
              height: 24
              radius: 12
              color: actionMouse.containsMouse
                ? (card.colors ? card.colors.primary : "#ffb4ab")
                : (card.colors ? Qt.rgba(card.colors.secondaryContainer.r, card.colors.secondaryContainer.g, card.colors.secondaryContainer.b, 0.5) : "#333")

              Text {
                id: actionLabel
                anchors.centerIn: parent
                text: action.text || ""
                font.family: Style.fontFamily
                font.weight: Font.Medium
                font.pixelSize: 11
                color: actionMouse.containsMouse
                  ? (card.colors ? card.colors.primaryForeground : "#690005")
                  : (card.colors ? card.colors.tertiary : "#8bceff")
              }

              MouseArea {
                id: actionMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: action.invoke()
              }
            }
          }
        }
      }
    }


    MouseArea {
      id: cardMouse
      anchors.fill: parent
      z: -1
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onClicked: card.animateDismiss()
    }
  }
}
