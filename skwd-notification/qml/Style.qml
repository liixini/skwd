pragma Singleton
import QtQuick

QtObject {
    id: style

    readonly property string fontFamily: "Roboto Condensed"
    readonly property string fontFamilyMono: "Roboto Mono"

    readonly property color fallbackPrimary: "#ffb4ab"
    readonly property color fallbackSurface: Qt.rgba(0.1, 0.12, 0.18, 0.88)
    readonly property color fallbackSurfaceText: "#e2beba"
    readonly property color fallbackOutline: "#666666"
    readonly property color fallbackPrimaryFg: "#690005"
    readonly property color fallbackTertiary: "#8bceff"
}
