pragma Singleton
import QtQuick

QtObject {
    
    readonly property string fontFamily: "Roboto Condensed"
    readonly property string fontFamilyMono: "Roboto Mono"
    readonly property string fontFamilyIcons: "Material Design Icons Desktop"
    readonly property string fontFamilyNerdIcons: "Symbols Nerd Font"
    readonly property string iconFont: fontFamilyNerdIcons

    
    readonly property int fontTiny: 9
    readonly property int fontSmall: 11
    readonly property int fontNormal: 13
    readonly property int fontMedium: 15
    readonly property int fontLarge: 18
    readonly property int fontXLarge: 24
    readonly property int fontTitle: 32
    readonly property int fontDisplay: 48

    
    readonly property int radiusTiny: 2
    readonly property int radiusSmall: 4
    readonly property int radiusMedium: 8
    readonly property int radiusLarge: 12
    readonly property int radiusXLarge: 16
    readonly property int radiusRound: 40

    
    readonly property int spacingTiny: 2
    readonly property int spacingSmall: 4
    readonly property int spacingMedium: 8
    readonly property int spacingLarge: 12
    readonly property int spacingXLarge: 16
    readonly property int spacingXXLarge: 20

    
    readonly property int animFast: 150
    readonly property int animNormal: 200
    readonly property int animSlow: 400

    
    readonly property real opacityDim: 0.35
    readonly property real opacityMuted: 0.50
    readonly property real opacitySubtle: 0.60
}
