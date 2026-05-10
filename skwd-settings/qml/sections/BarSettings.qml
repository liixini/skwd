import QtQuick
import ".."
import "../components"
import "../services"


Item {
  id: root
  property var colors
  property string activeCategory: "widgets"

  readonly property var categories: [
    { key: "widgets", label: "WIDGETS" },
    { key: "weather", label: "WEATHER" },
    { key: "wifi",    label: "WIFI" },
    { key: "music",   label: "MUSIC" }
  ]

  function _save(key, value) { SettingsService.setPath("components.bar." + key, value) }

  implicitHeight: _stack.implicitHeight

  Item {
    id: _stack
    width: parent.width
    implicitHeight: childrenRect.height

    
    Column {
      visible: root.activeCategory === "widgets"
      width: parent.width
      spacing: 8 * Config.uiScale

      Text {
        text: "ENABLED WIDGETS"
        font.family: Style.fontFamily; font.pixelSize: 13 * Config.uiScale; font.weight: Font.Bold; font.letterSpacing: 1.5
        color: root.colors ? root.colors.tertiary : Qt.rgba(1, 1, 1, 0.5)
      }

      SettingsToggle { colors: root.colors; label: "Bar enabled";        checked: Config.barEnabled;          onToggle: function(v) { root._save("enabled", v) } }
      SettingsToggle { colors: root.colors; label: "Calendar widget";    checked: Config.barCalendarEnabled;  onToggle: function(v) { root._save("calendar", v) } }
      SettingsToggle { colors: root.colors; label: "Volume widget";      checked: Config.barVolumeEnabled;    onToggle: function(v) { root._save("volume", v) } }
      SettingsToggle { colors: root.colors; label: "Bluetooth widget";   checked: Config.barBluetoothEnabled; onToggle: function(v) { root._save("bluetooth", v) } }
      SettingsToggle { colors: root.colors; label: "Wifi widget";        checked: Config.barWifiEnabled;      onToggle: function(v) { SettingsService.setPath("components.bar.wifi.enabled", v) } }
      SettingsToggle { colors: root.colors; label: "Weather widget";     checked: Config.barWeatherEnabled;   onToggle: function(v) { SettingsService.setPath("components.bar.weather.enabled", v) } }
      SettingsToggle { colors: root.colors; label: "Music widget";       checked: Config.barMusicEnabled;     onToggle: function(v) { SettingsService.setPath("components.bar.music.enabled", v) } }
    }


    Column {
      id: weatherSection
      visible: root.activeCategory === "weather"
      width: parent.width
      spacing: 8 * Config.uiScale

      function saveCities(arr, def) {
        SettingsService.setPath("components.bar.weather.cities", arr)
        if (def !== undefined) SettingsService.setPath("components.bar.weather.defaultCity", def)
        SettingsService.setPath("components.bar.weather.city", undefined)
      }

      function addCity(name) {
        var v = (name || "").trim()
        if (!v) return
        var arr = (Config.barWeatherCities || []).slice()
        if (arr.indexOf(v) !== -1) return
        arr.push(v)
        var def = Config.barWeatherDefaultCity || v
        weatherSection.saveCities(arr, def)
      }

      function removeCity(name) {
        var arr = (Config.barWeatherCities || []).filter(function(c) { return c !== name })
        var def = Config.barWeatherDefaultCity
        if (def === name) def = arr.length > 0 ? arr[0] : ""
        weatherSection.saveCities(arr, def)
      }

      function setDefault(name) {
        SettingsService.setPath("components.bar.weather.defaultCity", name)
      }

      function moveCity(fromIdx, toIdx) {
        var arr = (Config.barWeatherCities || []).slice()
        if (fromIdx < 0 || fromIdx >= arr.length) return
        if (toIdx < 0 || toIdx >= arr.length) return
        if (fromIdx === toIdx) return
        var item = arr.splice(fromIdx, 1)[0]
        arr.splice(toIdx, 0, item)
        weatherSection.saveCities(arr)
      }

      Text {
        text: "WEATHER"
        font.family: Style.fontFamily; font.pixelSize: 13 * Config.uiScale; font.weight: Font.Bold; font.letterSpacing: 1.5
        color: root.colors ? root.colors.tertiary : Qt.rgba(1, 1, 1, 0.5)
      }

      Text {
        width: parent.width
        text: "Add cities to flip through in the bar dropdown. Heart one as the default - that's the city shown on startup."
        wrapMode: Text.WordWrap
        font.family: Style.fontFamily; font.pixelSize: 11 * Config.uiScale; font.italic: true
        color: root.colors ? Qt.rgba(root.colors.outline.r, root.colors.outline.g, root.colors.outline.b, 0.7) : Qt.rgba(1, 1, 1, 0.4)
      }

      Repeater {
        model: Config.barWeatherCities

        delegate: Rectangle {
          id: cityRow
          width: weatherSection.width
          height: 34 * Config.uiScale
          radius: 4
          color: rowMouse.containsMouse
            ? Qt.rgba(root.colors.primary.r, root.colors.primary.g, root.colors.primary.b, 0.06)
            : "transparent"
          border.width: 1
          border.color: Qt.rgba(root.colors.outline.r, root.colors.outline.g, root.colors.outline.b, 0.2)

          property bool isDefault: modelData === Config.barWeatherDefaultCity
          property bool canMoveUp: index > 0
          property bool canMoveDown: index < (Config.barWeatherCities || []).length - 1
          property int rowIndex: index

          MouseArea { id: rowMouse; anchors.fill: parent; hoverEnabled: true; acceptedButtons: Qt.NoButton }

          Column {
            id: orderBtns
            width: 16 * Config.uiScale
            anchors.left: parent.left
            anchors.leftMargin: 4 * Config.uiScale
            anchors.verticalCenter: parent.verticalCenter
            spacing: 0

            Item {
              width: parent.width
              height: 14 * Config.uiScale

              Text {
                anchors.centerIn: parent
                text: "▴"
                font.pixelSize: 12 * Config.uiScale
                color: !cityRow.canMoveUp
                  ? Qt.rgba(root.colors.outline.r, root.colors.outline.g, root.colors.outline.b, 0.2)
                  : (upMouse.containsMouse ? root.colors.primary : Qt.rgba(root.colors.outline.r, root.colors.outline.g, root.colors.outline.b, 0.7))
              }
              MouseArea {
                id: upMouse
                anchors.fill: parent
                anchors.margins: -2
                hoverEnabled: true
                enabled: cityRow.canMoveUp
                cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                onClicked: weatherSection.moveCity(cityRow.rowIndex, cityRow.rowIndex - 1)
              }
            }

            Item {
              width: parent.width
              height: 14 * Config.uiScale

              Text {
                anchors.centerIn: parent
                text: "▾"
                font.pixelSize: 12 * Config.uiScale
                color: !cityRow.canMoveDown
                  ? Qt.rgba(root.colors.outline.r, root.colors.outline.g, root.colors.outline.b, 0.2)
                  : (downMouse.containsMouse ? root.colors.primary : Qt.rgba(root.colors.outline.r, root.colors.outline.g, root.colors.outline.b, 0.7))
              }
              MouseArea {
                id: downMouse
                anchors.fill: parent
                anchors.margins: -2
                hoverEnabled: true
                enabled: cityRow.canMoveDown
                cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                onClicked: weatherSection.moveCity(cityRow.rowIndex, cityRow.rowIndex + 1)
              }
            }
          }

          Item {
            id: starBtn
            width: 22 * Config.uiScale
            height: 22 * Config.uiScale
            anchors.left: orderBtns.right
            anchors.leftMargin: 4 * Config.uiScale
            anchors.verticalCenter: parent.verticalCenter

            Text {
              anchors.centerIn: parent
              text: cityRow.isDefault ? "♥" : "♡"
              font.pixelSize: 16 * Config.uiScale
              color: cityRow.isDefault
                ? root.colors.primary
                : Qt.rgba(root.colors.outline.r, root.colors.outline.g, root.colors.outline.b, 0.5)
            }

            MouseArea {
              anchors.fill: parent
              anchors.margins: -4
              cursorShape: Qt.PointingHandCursor
              hoverEnabled: true
              onClicked: weatherSection.setDefault(modelData)
            }
          }

          Text {
            anchors.left: starBtn.right
            anchors.right: removeBtn.left
            anchors.leftMargin: 8 * Config.uiScale
            anchors.rightMargin: 8 * Config.uiScale
            anchors.verticalCenter: parent.verticalCenter
            text: modelData
            color: root.colors ? root.colors.surfaceText : "white"
            font.family: Style.fontFamily; font.pixelSize: 12 * Config.uiScale
            elide: Text.ElideRight
          }

          Item {
            id: removeBtn
            width: 22 * Config.uiScale
            height: 22 * Config.uiScale
            anchors.right: parent.right
            anchors.rightMargin: 6 * Config.uiScale
            anchors.verticalCenter: parent.verticalCenter

            Text {
              anchors.centerIn: parent
              text: "×"
              font.pixelSize: 16 * Config.uiScale
              color: removeMouse.containsMouse
                ? root.colors.error
                : Qt.rgba(root.colors.outline.r, root.colors.outline.g, root.colors.outline.b, 0.6)
            }

            MouseArea {
              id: removeMouse
              anchors.fill: parent
              anchors.margins: -2
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: weatherSection.removeCity(modelData)
            }
          }
        }
      }

      Row {
        width: parent.width
        spacing: 6 * Config.uiScale

        Rectangle {
          width: weatherSection.width - addBtn.width - parent.spacing
          height: 28 * Config.uiScale
          radius: 4
          color: Qt.rgba(root.colors.surfaceContainer.r, root.colors.surfaceContainer.g, root.colors.surfaceContainer.b, 0.6)
          border.width: addInput.activeFocus ? 1 : 0
          border.color: Qt.rgba(root.colors.primary.r, root.colors.primary.g, root.colors.primary.b, 0.5)

          TextInput {
            id: addInput
            anchors.fill: parent
            anchors.leftMargin: 8 * Config.uiScale
            anchors.rightMargin: 8 * Config.uiScale
            verticalAlignment: TextInput.AlignVCenter
            font.family: Style.fontFamilyCode
            font.pixelSize: 12 * Config.uiScale
            color: root.colors ? root.colors.surfaceText : "white"
            clip: true
            selectByMouse: true
            onAccepted: {
              weatherSection.addCity(text)
              text = ""
            }

            Text {
              anchors.fill: parent
              verticalAlignment: Text.AlignVCenter
              font: parent.font
              color: Qt.rgba(root.colors.surfaceText.r, root.colors.surfaceText.g, root.colors.surfaceText.b, 0.3)
              text: "e.g. Stockholm, SE"
              visible: !addInput.text && !addInput.activeFocus
            }
          }
        }

        Rectangle {
          id: addBtn
          width: 60 * Config.uiScale
          height: 28 * Config.uiScale
          radius: 4
          color: addMouse.containsMouse
            ? root.colors.primary
            : Qt.rgba(root.colors.primary.r, root.colors.primary.g, root.colors.primary.b, 0.85)

          Text {
            anchors.centerIn: parent
            text: "ADD"
            color: root.colors ? root.colors.surface : "black"
            font.family: Style.fontFamily; font.pixelSize: 11 * Config.uiScale
            font.weight: Font.Bold; font.letterSpacing: 0.5
          }

          MouseArea {
            id: addMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
              weatherSection.addCity(addInput.text)
              addInput.text = ""
            }
          }
        }
      }
    }

    
    Column {
      visible: root.activeCategory === "wifi"
      width: parent.width
      spacing: 8 * Config.uiScale

      Text {
        text: "WIFI"
        font.family: Style.fontFamily; font.pixelSize: 13 * Config.uiScale; font.weight: Font.Bold; font.letterSpacing: 1.5
        color: root.colors ? root.colors.tertiary : Qt.rgba(1, 1, 1, 0.5)
      }
      SettingsTextInput {
        colors: root.colors
        label: "Linux interface name"
        value: Config.barWifiInterface
        placeholder: "e.g. wlan0 — find yours with `iwctl station list`"
        onCommit: function(v) { SettingsService.setPath("components.bar.wifi.interface", v) }
      }
    }

    
    Column {
      visible: root.activeCategory === "music"
      width: parent.width
      spacing: 8 * Config.uiScale

      Text {
        text: "MUSIC WIDGET"
        font.family: Style.fontFamily; font.pixelSize: 13 * Config.uiScale; font.weight: Font.Bold; font.letterSpacing: 1.5
        color: root.colors ? root.colors.tertiary : Qt.rgba(1, 1, 1, 0.5)
      }
      SettingsToggle { colors: root.colors; label: "Auto-hide when nothing's playing"; checked: Config.barMusicAutohide; onToggle: function(v) { SettingsService.setPath("components.bar.music.autohide", v) } }
      SettingsToggle { colors: root.colors; label: "Show artist & track";              checked: Config.barMusicShowMeta;  onToggle: function(v) { SettingsService.setPath("components.bar.music.showMeta", v) } }
      SettingsToggle { colors: root.colors; label: "Show lyrics";                       checked: Config.barMusicShowLyrics; onToggle: function(v) { SettingsService.setPath("components.bar.music.showLyrics", v) } }

      Text {
        text: "VISUALIZER"
        font.family: Style.fontFamily; font.pixelSize: 13 * Config.uiScale; font.weight: Font.Bold; font.letterSpacing: 1.5
        color: root.colors ? root.colors.tertiary : Qt.rgba(1, 1, 1, 0.5)
      }

      SettingsDropdown {
        colors: root.colors
        label: "Theme"
        value: Config.barMusicVisualizer
        model: [
          { mode: "wave",              label: "Wave" },
          { mode: "bars",              label: "Bars" },
          { mode: "neon",              label: "Neon" },
          { mode: "pulse",             label: "Pulse" },
          { mode: "vu",                label: "VU" },
          { mode: "spectrogram",       label: "Spectrogram" },
          { mode: "stardust",          label: "Stardust" },
          { mode: "liquid",            label: "Liquid" },
          { mode: "ripple",            label: "Ripple" },
          { mode: "zigzag",            label: "Zigzag" },
          { mode: "metaballs",         label: "Metaballs" },
          { mode: "comet",             label: "Comet" },
          { mode: "aurora",            label: "Aurora" },
          { mode: "aurora-responsive", label: "Aurora Responsive" },
          { mode: "spectrum",          label: "Spectrum" },
          { mode: "off",               label: "Off" }
        ]
        onSelect: function(v) { SettingsService.setPath("components.bar.music.visualizer", v) }
      }

      Column {
        visible: Config.barMusicVisualizer === "aurora"
        width: parent.width
        spacing: 4
        SettingsInput  { colors: root.colors; label: "Layer count";          value: Config.vizAuroraLayerCount; min: 1;  max: 8;  onCommit: function(v) { SettingsService.setPath("components.bar.music.viz.aurora.layerCount", v) } }
        SettingsSlider { colors: root.colors; label: "Outer layer min %";    value: Math.round(Config.vizAuroraMinAmp * 100); min: 5; max: 95; onChange: function(v) { SettingsService.setPath("components.bar.music.viz.aurora.minAmp", v / 100) } }
      }

      Column {
        visible: Config.barMusicVisualizer === "aurora-responsive"
        width: parent.width
        spacing: 4
        SettingsInput  { colors: root.colors; label: "Layer count";          value: Config.vizAuroraLayerCount; min: 1;  max: 8;  onCommit: function(v) { SettingsService.setPath("components.bar.music.viz.aurora.layerCount", v) } }
        SettingsSlider { colors: root.colors; label: "Outer layer min %";    value: Math.round(Config.vizAuroraMinAmp * 100);       min: 5;  max: 95;  onChange: function(v) { SettingsService.setPath("components.bar.music.viz.aurora.minAmp", v / 100) } }
        SettingsSlider { colors: root.colors; label: "Pump curve (lower = sharper, x100)"; value: Math.round(Config.vizAuroraRespPumpExp * 100); min: 15; max: 120; onChange: function(v) { SettingsService.setPath("components.bar.music.viz.auroraResponsive.pumpExp", v / 100) } }
        SettingsSlider { colors: root.colors; label: "Pump scale (x100)";    value: Math.round(Config.vizAuroraRespPumpScale * 100); min: 50; max: 300; onChange: function(v) { SettingsService.setPath("components.bar.music.viz.auroraResponsive.pumpScale", v / 100) } }
        SettingsSlider { colors: root.colors; label: "Attack speed (x100)";  value: Math.round(Config.vizAuroraRespAttack * 100);    min: 5;  max: 100; onChange: function(v) { SettingsService.setPath("components.bar.music.viz.auroraResponsive.attack", v / 100) } }
        SettingsSlider { colors: root.colors; label: "Decay speed (x100)";   value: Math.round(Config.vizAuroraRespDecay * 100);     min: 2;  max: 50;  onChange: function(v) { SettingsService.setPath("components.bar.music.viz.auroraResponsive.decay", v / 100) } }
      }

      Column {
        visible: Config.barMusicVisualizer === "pulse"
        width: parent.width
        spacing: 4
        SettingsInput { colors: root.colors; label: "Pill width (px)"; value: Config.vizPulsePillWidth; min: 1; max: 12; onCommit: function(v) { SettingsService.setPath("components.bar.music.viz.pulse.pillWidth", v) } }
      }

      Column {
        visible: Config.barMusicVisualizer === "vu"
        width: parent.width
        spacing: 4
        SettingsSlider { colors: root.colors; label: "Peak decay (x10)"; value: Math.round(Config.vizVuPeakDecay * 10); min: 2; max: 60; onChange: function(v) { SettingsService.setPath("components.bar.music.viz.vu.peakDecay", v / 10) } }
      }

      Column {
        visible: Config.barMusicVisualizer === "spectrogram"
        width: parent.width
        spacing: 4
        SettingsInput { colors: root.colors; label: "History columns"; value: Config.vizSpectrogramCols; min: 20; max: 200; onCommit: function(v) { SettingsService.setPath("components.bar.music.viz.spectrogram.cols", v) } }
      }

      Column {
        visible: Config.barMusicVisualizer === "stardust"
        width: parent.width
        spacing: 4
        SettingsInput { colors: root.colors; label: "Star count"; value: Config.vizStardustCount; min: 10; max: 200; onCommit: function(v) { SettingsService.setPath("components.bar.music.viz.stardust.count", v) } }
      }

      Column {
        visible: Config.barMusicVisualizer === "comet"
        width: parent.width
        spacing: 4
        SettingsInput { colors: root.colors; label: "Trail length"; value: Config.vizCometTrailLen; min: 4; max: 80; onCommit: function(v) { SettingsService.setPath("components.bar.music.viz.comet.trailLen", v) } }
      }

      Column {
        visible: Config.barMusicVisualizer === "ripple"
        width: parent.width
        spacing: 4
        SettingsSlider { colors: root.colors; label: "Bass spike threshold (x100)"; value: Math.round(Config.vizRippleThreshold * 100); min: 105; max: 300; onChange: function(v) { SettingsService.setPath("components.bar.music.viz.ripple.threshold", v / 100) } }
        SettingsInput  { colors: root.colors; label: "Ripple lifetime";              value: Config.vizRippleMaxAge;    min: 8; max: 120; onCommit: function(v) { SettingsService.setPath("components.bar.music.viz.ripple.maxAge", v) } }
      }

      SettingsToggle { colors: root.colors; label: "Render visualizer above"; checked: Config.barMusicVisualizerTop;    onToggle: function(v) { SettingsService.setPath("components.bar.music.visualizerTop", v) } }
      SettingsToggle { colors: root.colors; label: "Render visualizer below"; checked: Config.barMusicVisualizerBottom; onToggle: function(v) { SettingsService.setPath("components.bar.music.visualizerBottom", v) } }
    }
  }
}
