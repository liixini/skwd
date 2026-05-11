import QtQuick
import QtQuick.Shapes
import QtQuick.Effects
import Quickshell
import ".."

Item {
    id: hexItem

    property var colors
    property var service
    property int hexRadius: 140
    property var itemData
    property bool isSelected: false
    property bool isHovered: hexMouse.containsMouse

    property real parallaxX: 0
    property real parallaxY: 0

    signal hoverSelected()
    signal activated(var data)

    width: hexRadius * 2
    height: Math.ceil(hexRadius * 1.73205)

    readonly property real _r: hexRadius
    readonly property real _cx: _r
    readonly property real _cy: height / 2
    readonly property real _cos30: 0.866025
    readonly property real _sin30: 0.5

    function _fileUrl(path) {
        if (!path) return ""
        var s = String(path)
        if (s.indexOf("file://") === 0) return s
        if (s.indexOf("~/") === 0) s = Quickshell.env("HOME") + s.substr(1)
        if (s.indexOf("/") !== 0) return ""
        return "file://" + s.split("/").map(encodeURIComponent).join("/")
    }

    readonly property string _bgUrl: _fileUrl(itemData ? (itemData.backgroundThumb || itemData.background || "") : "")
    readonly property string _thumbUrl: _fileUrl(itemData ? (itemData.thumb || "") : "")
    readonly property string _label: itemData ? (itemData.displayName || itemData.name || "") : ""
    readonly property string _customIcon: itemData ? (itemData.customIcon || "") : ""
    readonly property bool   _useDesktopIcon: itemData ? (itemData.useDesktopIcon === true) : false
    readonly property bool   _preferGlyph: _customIcon !== "" && !_useDesktopIcon

    Item {
        id: hexMask
        width: hexItem.width; height: hexItem.height
        visible: false
        layer.enabled: true
        Shape {
            anchors.fill: parent
            antialiasing: true
            preferredRendererType: Shape.CurveRenderer
            ShapePath {
                fillColor: "white"
                strokeColor: "transparent"
                startX: hexItem._cx + hexItem._r;                          startY: hexItem._cy
                PathLine { x: hexItem._cx + hexItem._r * hexItem._sin30;  y: hexItem._cy - hexItem._r * hexItem._cos30 }
                PathLine { x: hexItem._cx - hexItem._r * hexItem._sin30;  y: hexItem._cy - hexItem._r * hexItem._cos30 }
                PathLine { x: hexItem._cx - hexItem._r;                   y: hexItem._cy }
                PathLine { x: hexItem._cx - hexItem._r * hexItem._sin30;  y: hexItem._cy + hexItem._r * hexItem._cos30 }
                PathLine { x: hexItem._cx + hexItem._r * hexItem._sin30;  y: hexItem._cy + hexItem._r * hexItem._cos30 }
                PathLine { x: hexItem._cx + hexItem._r;                   y: hexItem._cy }
            }
        }
    }

    Item {
        id: imageContainer
        anchors.fill: parent

        Rectangle {
            id: hexPlaceholder
            anchors.centerIn: parent
            width: hexItem.width * 1.3
            height: hexItem.height * 1.3
            color: Style.fallbackAccent
            opacity: ((bgImage.status === Image.Ready && bgImage.source != "") || (thumbImage.status === Image.Ready && thumbImage.source != "")) ? 0 : 0.08
            Behavior on opacity { NumberAnimation { duration: Style.animNormal; easing.type: Easing.OutCubic } }
            visible: opacity > 0

            Text {
                anchors.centerIn: parent
                text: "\u{f0553}"
                font.family: Style.fontFamilyNerdIcons; font.pixelSize: 22
                color: Qt.rgba(1, 1, 1, 0.1)
            }
        }

        Image {
            id: bgImage
            width: hexItem.width * 1.3
            height: hexItem.height * 1.3
            x: (hexItem.width - width) / 2 + hexItem.parallaxX
            y: (hexItem.height - height) / 2 + hexItem.parallaxY
            source: hexItem._bgUrl
            fillMode: Image.PreserveAspectCrop
            smooth: true
            asynchronous: true
            cache: false
            sourceSize.width: Math.ceil(hexItem.width * 1.3)
            sourceSize.height: Math.ceil(hexItem.height * 1.3)
            opacity: status === Image.Ready ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: Style.animNormal; easing.type: Easing.OutCubic } }
        }

        Image {
            id: thumbImage
            width: hexItem.width * 0.55
            height: hexItem.height * 0.55
            anchors.centerIn: parent
            source: (bgImage.status === Image.Ready || hexItem._preferGlyph) ? "" : hexItem._thumbUrl
            fillMode: Image.PreserveAspectFit
            smooth: true
            asynchronous: true
            sourceSize.width: 256
            sourceSize.height: 256
            opacity: status === Image.Ready ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: Style.animNormal; easing.type: Easing.OutCubic } }
        }

        Text {
            anchors.centerIn: parent
            text: hexItem._customIcon
            font.family: Style.fontFamilyIcons
            font.pixelSize: Math.max(24, hexItem.height * 0.4)
            color: hexItem.colors ? Qt.rgba(hexItem.colors.primary.r, hexItem.colors.primary.g, hexItem.colors.primary.b, 0.85) : Qt.rgba(1, 1, 1, 0.6)
            visible: hexItem._preferGlyph && bgImage.status !== Image.Ready
        }

        layer.enabled: true
        layer.smooth: true
        layer.effect: MultiEffect {
            maskEnabled: true
            maskSource: hexMask
            maskThresholdMin: 0.3
            maskSpreadAtMin: 0.3
        }
    }

    Shape {
        id: hexBorder
        anchors.fill: parent
        antialiasing: true
        preferredRendererType: Shape.CurveRenderer
        ShapePath {
            fillColor: "transparent"
            strokeColor: hexItem.isSelected
                ? (hexItem.colors ? hexItem.colors.primary : Style.fallbackAccent)
                : Qt.rgba(0, 0, 0, 0.5)
            Behavior on strokeColor { ColorAnimation { duration: Style.animFast } }
            strokeWidth: hexItem.isSelected ? 3 : 1.5
            startX: hexItem._cx + hexItem._r;                          startY: hexItem._cy
            PathLine { x: hexItem._cx + hexItem._r * hexItem._sin30;  y: hexItem._cy - hexItem._r * hexItem._cos30 }
            PathLine { x: hexItem._cx - hexItem._r * hexItem._sin30;  y: hexItem._cy - hexItem._r * hexItem._cos30 }
            PathLine { x: hexItem._cx - hexItem._r;                   y: hexItem._cy }
            PathLine { x: hexItem._cx - hexItem._r * hexItem._sin30;  y: hexItem._cy + hexItem._r * hexItem._cos30 }
            PathLine { x: hexItem._cx + hexItem._r * hexItem._sin30;  y: hexItem._cy + hexItem._r * hexItem._cos30 }
            PathLine { x: hexItem._cx + hexItem._r;                   y: hexItem._cy }
        }
    }

    Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: hexItem._r * 0.18
        width: nameLabel.implicitWidth + 14
        height: 18
        radius: 9
        color: Qt.rgba(0, 0, 0, 0.75)
        border.width: 1
        border.color: hexItem.colors ? Qt.rgba(hexItem.colors.primary.r, hexItem.colors.primary.g, hexItem.colors.primary.b, 0.4) : Qt.rgba(1,1,1,0.2)
        z: 5
        visible: hexItem._label.length > 0

        Text {
            id: nameLabel
            anchors.centerIn: parent
            text: hexItem._label
            font.family: Style.fontFamily; font.pixelSize: 10; font.weight: Font.Bold; font.letterSpacing: 0.5
            color: hexItem.colors ? hexItem.colors.tertiary : "#8bceff"
        }
    }

    MouseArea {
        id: hexMouse
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton
        cursorShape: Qt.PointingHandCursor
        function contains(point) {
            var dx = Math.abs(point.x - hexItem._cx)
            var dy = Math.abs(point.y - hexItem._cy)
            return dy <= hexItem._cos30 * hexItem._r && dx <= hexItem._r - dy * 0.57735
        }
        onContainsMouseChanged: {
            if (containsMouse) hexItem.hoverSelected()
        }
        onClicked: function(mouse) {
            if (mouse.button === Qt.LeftButton && hexItem.itemData) {
                hexItem.activated(hexItem.itemData)
            }
        }
    }
}
