import QtQuick
import Quickshell
import Quickshell.Io

// Dynamic Material Design 3 color palette. Reads matugen-generated colors.json
// from cache and watches for changes, auto-updating all bound UI components.
QtObject {
    id: colors

    // Color file watcher (hot-reloads on wallpaper change)
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
            colors.primary = d.primary ?? "#ffb4ab"
            colors.primaryText = d.primaryText ?? "#690005"
            colors.primaryContainer = d.primaryContainer ?? "#b12723"
            colors.primaryContainerText = d.primaryContainerText ?? "#ffffff"
            colors.primaryForeground = d.onPrimary ?? "#690005"
            colors.secondary = d.secondary ?? "#ffb4ab"
            colors.secondaryText = d.secondaryText ?? "#5b1915"
            colors.secondaryContainer = d.secondaryContainer ?? "#792f29"
            colors.secondaryContainerText = d.secondaryContainerText ?? "#ffd7d2"
            colors.tertiary = d.tertiary ?? "#8bceff"
            colors.tertiaryText = d.tertiaryText ?? "#00344e"
            colors.tertiaryContainer = d.tertiaryContainer ?? "#006390"
            colors.tertiaryContainerText = d.tertiaryContainerText ?? "#ffffff"
            colors.background = d.background ?? "#1d100e"
            colors.backgroundText = d.backgroundText ?? "#f7ddd9"
            colors.surface = d.surface ?? "#1d100e"
            colors.surfaceText = d.surfaceText ?? "#f7ddd9"
            colors.surfaceVariant = d.surfaceVariant ?? "#5a413e"
            colors.surfaceVariantText = d.surfaceVariantText ?? "#e2beba"
            colors.surfaceContainer = d.surfaceContainer ?? "#2c1f1d"
            colors.error = d.error ?? "#ffb4ab"
            colors.errorText = d.errorText ?? "#690005"
            colors.errorContainer = d.errorContainer ?? "#93000a"
            colors.errorContainerText = d.errorContainerText ?? "#ffdad6"
            colors.outline = d.outline ?? "#a98986"
            colors.shadow = d.shadow ?? "#000000"
            colors.inverseSurface = d.inverseSurface ?? "#f7ddd9"
            colors.inverseSurfaceText = d.inverseSurfaceText ?? "#3d2c2b"
            colors.inversePrimary = d.inversePrimary ?? "#b32824"
            console.log("Colors: Loaded colors successfully")
        } catch (e) {
            console.log("Colors: Error parsing colors.json:", e)
        }
    }


    // Color properties (Material Design 3 scheme)
    // Primary
    property color primary: "#ffb4ab"
    property color primaryText: "#690005"
    property color primaryContainer: "#b12723"
    property color primaryContainerText: "#ffffff"
    property color primaryForeground: "#690005"

    // Secondary
    property color secondary: "#ffb4ab"
    property color secondaryText: "#5b1915"
    property color secondaryContainer: "#792f29"
    property color secondaryContainerText: "#ffd7d2"

    // Tertiary
    property color tertiary: "#8bceff"
    property color tertiaryText: "#00344e"
    property color tertiaryContainer: "#006390"
    property color tertiaryContainerText: "#ffffff"

    // Background & Surface
    property color background: "#1d100e"
    property color backgroundText: "#f7ddd9"
    property color surface: "#1d100e"
    property color surfaceText: "#f7ddd9"
    property color surfaceVariant: "#5a413e"
    property color surfaceVariantText: "#e2beba"
    property color surfaceContainer: "#2c1f1d"

    // Error
    property color error: "#ffb4ab"
    property color errorText: "#690005"
    property color errorContainer: "#93000a"
    property color errorContainerText: "#ffdad6"

    // Utility
    property color outline: "#a98986"
    property color shadow: "#000000"
    property color inverseSurface: "#f7ddd9"
    property color inverseSurfaceText: "#3d2c2b"
    property color inversePrimary: "#b32824"
}
