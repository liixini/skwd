import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

Scope {
    id: notifScope

    property var colors
    property var notifications

    readonly property int notifCount: notifications ? notifications.values.length : 0

    readonly property bool onLeft: Config.popupSide === "left"

    PanelWindow {
        id: notifPanel

        screen: Quickshell.screens.find(s => s.name === Config.mainMonitor) ?? Quickshell.screens[0]

        anchors {
            top: true
            left: notifScope.onLeft
            right: !notifScope.onLeft
        }

        implicitWidth: Config.popupWidth + (notifScope.onLeft ? Config.popupLeftMargin : Config.popupRightMargin) * 2
        implicitHeight: Math.max(1, Config.popupTopMargin + popupColumn.childrenRect.height + 8)

        color: "transparent"
        visible: popupColumn.childrenRect.height > 0

        WlrLayershell.namespace: "skwd-notifications"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None


        exclusionMode: ExclusionMode.Auto

        Column {
            id: popupColumn
            anchors.right: notifScope.onLeft ? undefined : parent.right
            anchors.left:  notifScope.onLeft ? parent.left  : undefined
            anchors.rightMargin: notifScope.onLeft ? 0 : Config.popupRightMargin
            anchors.leftMargin:  notifScope.onLeft ? Config.popupLeftMargin : 0
            anchors.top: parent.top
            anchors.topMargin: Config.popupTopMargin
            width: Config.popupWidth
            spacing: 8

            Repeater {
                model: notifScope.notifications

                delegate: NotificationCard {
                    required property var modelData
                    required property int index
                    notification: modelData
                    colors: notifScope.colors
                    cardWidth: Config.popupWidth
                    onLeft: notifScope.onLeft

                    visible: index >= notifScope.notifCount - Config.popupMaxVisible
                }
            }
        }
    }

    component NotificationCard: Item {
        id: card

        property var notification
        property var colors
        property int cardWidth: 320
        property bool onLeft: false
        readonly property real _slideFrom: card.onLeft ? -40 : 40

        width: cardWidth
        height: contentColumn.implicitHeight + 24
        clip: true

        property bool dismissing: false
        property real slant: 28
        property real lineProgress: 0

        opacity: 0
        transform: Translate { id: cardTranslate; x: card._slideFrom }

        Component.onCompleted: {
            cardEntryAnim.start()
            autoExpireTimer.start()
        }

        ParallelAnimation {
            id: cardEntryAnim
            NumberAnimation { target: card; property: "opacity"; from: 0; to: 1; duration: 350; easing.type: Easing.OutCubic }
            NumberAnimation { target: cardTranslate; property: "x"; from: card._slideFrom; to: 0; duration: 350; easing.type: Easing.OutCubic }
            NumberAnimation { target: card; property: "lineProgress"; from: 0; to: 1; duration: 600; easing.type: Easing.OutCubic }
        }

        SequentialAnimation {
            id: cardExitAnim
            ParallelAnimation {
                NumberAnimation { target: card; property: "opacity"; to: 0; duration: 250; easing.type: Easing.InCubic }
                NumberAnimation { target: cardTranslate; property: "x"; to: card._slideFrom; duration: 250; easing.type: Easing.InCubic }
            }
            NumberAnimation { target: card; property: "height"; to: 0; duration: 180; easing.type: Easing.InOutCubic }
            ScriptAction {
                script: { if (card.notification) card.notification.dismiss() }
            }
        }

        function animateDismiss() {
            if (dismissing) return
            dismissing = true
            autoExpireTimer.stop()
            cardEntryAnim.stop()
            cardExitAnim.start()
        }

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

        property bool hovered: cardMouse.containsMouse
        onHoveredChanged: {
            if (hovered) autoExpireTimer.stop()
            else if (!dismissing) autoExpireTimer.restart()
        }

        function _shapePoints(s, w, h, onLeft) {
            if (onLeft) {
                return [
                    { x: s, y: 0 },
                    { x: w, y: 0 },
                    { x: w - s, y: h },
                    { x: 0, y: h }
                ]
            }
            return [
                { x: 0, y: 0 },
                { x: w - s, y: 0 },
                { x: w, y: h },
                { x: s, y: h }
            ]
        }

        Canvas {
            id: cardBg
            anchors.fill: parent
            opacity: card.opacity
            onPaint: {
                var ctx = getContext("2d")
                ctx.clearRect(0, 0, width, height)
                var pts = card._shapePoints(card.slant, width, height, card.onLeft)
                ctx.beginPath()
                ctx.moveTo(pts[0].x, pts[0].y)
                for (var i = 1; i < pts.length; i++) ctx.lineTo(pts[i].x, pts[i].y)
                ctx.closePath()
                var c = card.colors
                ctx.fillStyle = c
                    ? Qt.rgba(c.surface.r, c.surface.g, c.surface.b, 0.92)
                    : Style.fallbackSurface
                ctx.fill()
            }
            Connections {
                target: card
                function onColorsChanged() { cardBg.requestPaint() }
                function onWidthChanged() { cardBg.requestPaint() }
                function onHeightChanged() { cardBg.requestPaint() }
                function onOnLeftChanged() { cardBg.requestPaint() }
            }
        }

        Canvas {
            id: cardBorder
            anchors.fill: parent
            opacity: card.lineProgress
            onPaint: {
                var ctx = getContext("2d")
                ctx.clearRect(0, 0, width, height)
                var p = card.lineProgress
                if (p <= 0) return
                ctx.strokeStyle = card.colors ? card.colors.primary : Style.fallbackPrimary
                ctx.lineWidth = 2
                ctx.lineCap = "round"
                var pts = card._shapePoints(card.slant, width, height, card.onLeft)
                var segments = []
                for (var i = 0; i < pts.length; i++) {
                    var next = pts[(i + 1) % pts.length]
                    var dx = next.x - pts[i].x, dy = next.y - pts[i].y
                    segments.push({
                        x1: pts[i].x, y1: pts[i].y,
                        x2: next.x,   y2: next.y,
                        len: Math.sqrt(dx*dx + dy*dy)
                    })
                }
                var perim = segments.reduce(function(a, s) { return a + s.len }, 0)
                var len = perim * p
                ctx.beginPath()
                var remain = len
                var started = false
                for (var k = 0; k < segments.length && remain > 0; k++) {
                    var seg = segments[k]
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
                function onColorsChanged() { cardBorder.requestPaint() }
                function onOnLeftChanged() { cardBorder.requestPaint() }
            }
        }

        Item {
            anchors.fill: parent
            anchors.leftMargin: card.slant + 4
            anchors.rightMargin: card.slant + 4

            ColumnLayout {
                id: contentColumn
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 10
                spacing: 4

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    Text {
                        text: card.notification ? (card.notification.appName || "Notification") : "Notification"
                        font.family: Style.fontFamily
                        font.weight: Font.Medium
                        font.pixelSize: 12
                        color: card.colors ? card.colors.primary : Style.fallbackPrimary
                    }

                    Text {
                        text: "·"
                        font.pixelSize: 12
                        color: card.colors ? card.colors.outline : Style.fallbackOutline
                        visible: summaryLabel.text !== ""
                    }

                    Text {
                        id: summaryLabel
                        text: card.notification ? (card.notification.summary || "") : ""
                        font.family: Style.fontFamily
                        font.weight: Font.Medium
                        font.pixelSize: 12
                        color: card.colors ? card.colors.tertiary : Style.fallbackTertiary
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                        visible: text !== ""
                    }

                    Text {
                        text: "✕"
                        font.pixelSize: 12
                        color: closeMouse.containsMouse
                            ? (card.colors ? card.colors.primary : Style.fallbackPrimary)
                            : (card.colors ? card.colors.outline : Style.fallbackOutline)
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
                    color: card.colors ? card.colors.surfaceVariantText : Style.fallbackSurfaceText
                    wrapMode: Text.Wrap
                    Layout.fillWidth: true
                    visible: text !== ""
                    maximumLineCount: 3
                    elide: Text.ElideRight
                }

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
                            height: 22
                            radius: 11
                            color: actionMouse.containsMouse
                                ? (card.colors ? card.colors.primary : Style.fallbackPrimary)
                                : (card.colors ? Qt.rgba(card.colors.secondaryContainer.r, card.colors.secondaryContainer.g, card.colors.secondaryContainer.b, 0.5) : "#333")
                            Text {
                                id: actionLabel
                                anchors.centerIn: parent
                                text: action.text || ""
                                font.family: Style.fontFamily
                                font.weight: Font.Medium
                                font.pixelSize: 11
                                color: actionMouse.containsMouse
                                    ? (card.colors ? card.colors.primaryForeground : Style.fallbackPrimaryFg)
                                    : (card.colors ? card.colors.tertiary : Style.fallbackTertiary)
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
