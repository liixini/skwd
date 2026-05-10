import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: colors

    property string colorFilePath: Config.cacheDir + "/colors.json"

    property var colorFileView: FileView {
        path: colors.colorFilePath
        watchChanges: true
        preload: true
        onFileChanged: reload()
        onLoaded: colors._applyColors()
    }

    function _applyColors() {
        var text = colorFileView.text().trim()
        if (!text) return
        try {
            var d = JSON.parse(text)
            if (d.primary) colors.primary = d.primary
            if (d.onPrimary) colors.primaryForeground = d.onPrimary
            if (d.tertiary) colors.tertiary = d.tertiary
            if (d.surface) colors.surface = d.surface
            if (d.surfaceText) colors.surfaceText = d.surfaceText
            if (d.surfaceVariantText) colors.surfaceVariantText = d.surfaceVariantText
            if (d.outline) colors.outline = d.outline
            if (d.secondaryContainer) colors.secondaryContainer = d.secondaryContainer
        } catch (e) {
            console.log("Colors: error parsing colors.json:", e)
        }
    }

    property color primary: "#ffb4ab"
    property color primaryForeground: "#690005"
    property color tertiary: "#8bceff"
    property color surface: "#1d100e"
    property color surfaceText: "#f7ddd9"
    property color surfaceVariantText: "#e2beba"
    property color outline: "#a98986"
    property color secondaryContainer: "#792f29"
}
