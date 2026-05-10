import QtQuick

import ".." as Root


Rectangle {
    id: btn

    property string icon: ""
    property bool active: false
    property real iconSize: Root.Style.fontLarge
    signal clicked()

    width: iconSize + Root.Style.spacingLarge * 2
    height: width
    radius: width / 2
    color: mouseArea.containsMouse
        ? Qt.rgba(Root.Colors.surfaceText.r, Root.Colors.surfaceText.g, Root.Colors.surfaceText.b, 0.08)
        : "transparent"
    opacity: btn.enabled ? 1.0 : Root.Style.opacityDim

    Behavior on color {
        ColorAnimation { duration: Root.Style.animFast }
    }

    Text {
        anchors.centerIn: parent
        text: btn.icon
        font.family: Root.Style.iconFont
        font.pixelSize: btn.iconSize
        color: btn.active ? Root.Colors.primary : Root.Colors.surfaceText
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: btn.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: if (btn.enabled) btn.clicked()
    }
}
