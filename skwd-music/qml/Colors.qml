pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: colors

    readonly property string homeDir: Quickshell.env("HOME")
    readonly property string cacheDir: Quickshell.env("SKWD_CACHE") || homeDir + "/.cache/skwd"
    readonly property string colorFilePath: cacheDir + "/colors.json"

    
    property color primary: "#dfc0b0"
    property color primaryText: "#3e2517"
    property color primaryContainer: "#a68b7d"
    property color primaryContainerText: "#ffffff"
    property color secondary: "#d3c3bc"
    property color secondaryText: "#3a2f2a"
    property color secondaryContainer: "#b0a49d"
    property color secondaryContainerText: "#ffffff"
    property color tertiary: "#b6cacb"
    property color tertiaryText: "#213435"
    property color tertiaryContainer: "#93adae"
    property color tertiaryContainerText: "#ffffff"
    property color error: "#ffb4ab"
    property color errorText: "#690005"
    property color surface: "#151312"
    property color surfaceText: "#e8e1df"
    property color surfaceDim: "#151312"
    property color surfaceContainerLowest: "#100e0d"
    property color surfaceContainerLow: "#1e1b1a"
    property color surfaceContainer: "#22201e"
    property color surfaceContainerHigh: "#2c2928"
    property color surfaceContainerHighest: "#373433"
    property color surfaceVariantText: "#d3c3bc"
    property color outline: "#9b8e88"
    property color outlineVariant: "#4f453f"

    property var _colorFile: FileView {
        path: colors.colorFilePath
        watchChanges: true
        preload: true
        onFileChanged: { _colorFile.reload(); colors._loadColors() }
    }

    function _loadColors() {
        let raw = _colorFile.text()
        if (!raw || raw.trim() === "") return
        try {
            let c = JSON.parse(raw)
            
            c = c.colors?.dark || c.colors || c
            if (c.primary) colors.primary = c.primary
            if (c.primaryText || c.onPrimary) colors.primaryText = c.primaryText || c.onPrimary
            if (c.primaryContainer) colors.primaryContainer = c.primaryContainer
            if (c.primaryContainerText || c.onPrimaryContainer) colors.primaryContainerText = c.primaryContainerText || c.onPrimaryContainer
            if (c.secondary) colors.secondary = c.secondary
            if (c.secondaryText || c.onSecondary) colors.secondaryText = c.secondaryText || c.onSecondary
            if (c.secondaryContainer) colors.secondaryContainer = c.secondaryContainer
            if (c.secondaryContainerText || c.onSecondaryContainer) colors.secondaryContainerText = c.secondaryContainerText || c.onSecondaryContainer
            if (c.tertiary) colors.tertiary = c.tertiary
            if (c.tertiaryText || c.onTertiary) colors.tertiaryText = c.tertiaryText || c.onTertiary
            if (c.tertiaryContainer) colors.tertiaryContainer = c.tertiaryContainer
            if (c.tertiaryContainerText || c.onTertiaryContainer) colors.tertiaryContainerText = c.tertiaryContainerText || c.onTertiaryContainer
            if (c.error) colors.error = c.error
            if (c.errorText || c.onError) colors.errorText = c.errorText || c.onError
            if (c.surface) colors.surface = c.surface
            if (c.surfaceText || c.onSurface) colors.surfaceText = c.surfaceText || c.onSurface
            if (c.surfaceDim) colors.surfaceDim = c.surfaceDim
            if (c.surfaceContainer) colors.surfaceContainer = c.surfaceContainer
            if (c.surfaceContainerLowest) colors.surfaceContainerLowest = c.surfaceContainerLowest
            if (c.surfaceContainerLow) colors.surfaceContainerLow = c.surfaceContainerLow
            if (c.surfaceContainerHigh) colors.surfaceContainerHigh = c.surfaceContainerHigh
            if (c.surfaceContainerHighest) colors.surfaceContainerHighest = c.surfaceContainerHighest
            if (c.surfaceVariantText || c.onSurfaceVariant) colors.surfaceVariantText = c.surfaceVariantText || c.onSurfaceVariant
            if (c.outline) colors.outline = c.outline
            if (c.outlineVariant || c.surfaceVariant) colors.outlineVariant = c.outlineVariant || c.surfaceVariant
        } catch (e) {
            console.warn("skwd-music: failed to load colors.json:", e)
        }
    }

    Component.onCompleted: _loadColors()
}
