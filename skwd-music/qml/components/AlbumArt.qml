import QtQuick
import QtQuick.Effects

import ".." as Root


Item {
    id: artRoot

    property url source: ""
    property int radius: Root.Style.radiusLarge

    
    Item {
        id: content
        anchors.fill: parent
        visible: false

        
        Rectangle {
            anchors.fill: parent
            color: Root.Colors.surfaceContainerHigh

            Text {
                anchors.centerIn: parent
                text: "\u{F075A}"
                font.family: Root.Style.iconFont
                font.pixelSize: parent.width * 0.4
                color: Root.Colors.surfaceVariantText
                visible: artImage.status !== Image.Ready
            }
        }

        Image {
            id: artImage
            anchors.fill: parent
            source: artRoot.source
            fillMode: Image.PreserveAspectCrop
            smooth: true
        }
    }

    
    Item {
        id: mask
        anchors.fill: parent
        visible: false
        layer.enabled: true

        Rectangle {
            anchors.fill: parent
            radius: artRoot.radius
            color: "white"
        }
    }

    
    MultiEffect {
        anchors.fill: parent
        source: content
        maskEnabled: true
        maskSource: ShaderEffectSource {
            sourceItem: mask
        }
        maskThresholdMin: 0.3
        maskSpreadAtMin: 0.3
    }

    
    Rectangle {
        anchors.fill: parent
        radius: artRoot.radius
        color: "transparent"
        border.color: Qt.rgba(
            Root.Colors.outlineVariant.r,
            Root.Colors.outlineVariant.g,
            Root.Colors.outlineVariant.b,
            0.15
        )
        border.width: 1
    }
}
