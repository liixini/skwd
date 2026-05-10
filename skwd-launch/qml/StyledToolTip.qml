import QtQuick
import QtQuick.Controls

ToolTip {
    id: root

    property int maxWidth: 300

    TextMetrics {
        id: metrics
        text: root.text
        font: root.font
    }

    contentWidth: Math.min(Math.ceil(metrics.advanceWidth), maxWidth)

    property var colors: null
    property color textColor: colors ? colors.tertiary : "#8bceff"

    contentItem: Text {
        text: root.text
        font: root.font
        wrapMode: Text.WordWrap
        color: root.textColor
    }
}
