import Quickshell
import Quickshell.Io
import QtQuick

QtObject {
  id: service

  // External bindings
  required property string scriptsDir
  required property string homeDir
  required property string wallpaperDir
  required property string cacheBaseDir
  required property string weDir
  required property string weAssetsDir
  required property int ollamaStatusPollMs
  required property bool showing

  // Derived paths
  property string thumbsCacheDir: cacheBaseDir + "/wallpaper/thumbs"
  property string weCache: cacheBaseDir + "/wallpaper/we-thumbs"
  property string wallpaperListCache: cacheBaseDir + "/wallpaper/list.jsonl"
  property string tagsFile: cacheBaseDir + "/wallpaper/tags.json"
  property string colorsFile: cacheBaseDir + "/wallpaper/colors.json"
  property string matugenFile: cacheBaseDir + "/wallpaper/matugen-colors.json"

  // Cache state
  property string lastCacheMtime: ""
  property bool cacheReady: false
  property string cacheResult: ""
  property int cacheProgress: 0
  property int cacheTotal: 0
  property bool cacheLoading: false

  // Filter and sort state
  property int selectedColorFilter: -1
  property string selectedTypeFilter: ""
  property string sortMode: "color"
  property var selectedTags: []
  property int selectedTagIndex: -1
  property var popularTags: []

  // Metadata databases
  property var tagsDb: ({})
  property var colorsDb: ({})
  property var matugenDb: ({})

  property var _tagsFileView: FileView { path: service.tagsFile; preload: true }
  property var _colorsFileView: FileView { path: service.colorsFile; preload: true }
  property var _matugenFileView: FileView { path: service.matugenFile; preload: true }

  function reloadMetadata() {
    try {
      var text = _tagsFileView.text()
      if (text.length > 0) {
        service.tagsDb = JSON.parse(text)
        var tagCounts = {}
        for (var name in service.tagsDb) {
          var tags = service.tagsDb[name]
          for (var i = 0; i < tags.length; i++) {
            var tag = tags[i]
            tagCounts[tag] = (tagCounts[tag] || 0) + 1
          }
        }
        var tagArray = []
        for (var t in tagCounts) tagArray.push({tag: t, count: tagCounts[t]})
        tagArray.sort(function(a, b) { return b.count - a.count })
        service.popularTags = tagArray
      }
    } catch (e) { console.log("Error parsing tags JSON:", e) }

    try {
      var cText = _colorsFileView.text()
      if (cText.length > 0) {
        service.colorsDb = JSON.parse(cText)
        service.updateFilteredModel()
      }
    } catch (e) { console.log("Error parsing colors JSON:", e) }

    try {
      var mText = _matugenFileView.text()
      if (mText.length > 0) {
        service.matugenDb = JSON.parse(mText)
      }
    } catch (e) { console.log("Error parsing matugen JSON:", e) }
  }

  // Ollama analysis state
  property bool ollamaTaggingActive: false
  property bool ollamaColorsActive: false
  property bool ollamaActive: ollamaTaggingActive || ollamaColorsActive
  property int ollamaTotalThumbs: 0
  property int ollamaTaggedCount: 0
  property int ollamaColoredCount: 0
  property real ollamaStartTime: 0
  property int ollamaStartTagCount: 0
  property int ollamaStartColorCount: 0
  property string ollamaEta: ""
  property string ollamaLogLine: ""

  // Data models
  property var wallpaperModel: ListModel {}
  property var filteredModel: ListModel {}

  signal modelUpdated()
  signal wallpaperApplied()

  // Filter and sort wallpapers
  function updateFilteredModel() {
    function thumbKey(thumbPath) {
      var fname = thumbPath.split("/").pop()
      var dot = fname.lastIndexOf('.')
      return dot > 0 ? fname.substring(0, dot) : fname
    }

    var items = []
    for (var i = 0; i < wallpaperModel.count; i++) {
      var item = wallpaperModel.get(i)
      var lookupKey = item.weId ? item.weId : thumbKey(item.thumb)
      var hue = item.hue
      var saturation = item.saturation || 0
      var effectiveType = (item.type === "we" && item.videoFile) ? "video" : item.type
      if (selectedTypeFilter !== "" && effectiveType !== selectedTypeFilter) continue
      if (selectedColorFilter !== -1 && hue !== selectedColorFilter) continue

      if (selectedTags.length > 0) {
        var wallpaperTags = tagsDb[lookupKey]
        if (!wallpaperTags) continue
        var allTagsMatch = true
        for (var t = 0; t < selectedTags.length; t++) {
          if (wallpaperTags.indexOf(selectedTags[t]) === -1) { allTagsMatch = false; break }
        }
        if (!allTagsMatch) continue
      }

      items.push({
        name: item.name, type: item.type, thumb: item.thumb, path: item.path,
        weId: item.weId, videoFile: item.videoFile, mtime: item.mtime,
        hue: hue, saturation: saturation
      })
    }

    if (sortMode === "date") {
      items.sort(function(a, b) { return b.mtime - a.mtime })
    } else {
      items.sort(function(a, b) {
        var hueA = a.hue === 99 ? 100 : a.hue
        var hueB = b.hue === 99 ? 100 : b.hue
        if (hueA !== hueB) return hueA - hueB
        return b.saturation - a.saturation
      })
    }

    filteredModel.clear()
    for (var j = 0; j < items.length; j++) filteredModel.append(items[j])
    modelUpdated()
  }

  onSelectedColorFilterChanged: updateFilteredModel()
  onSelectedTypeFilterChanged: updateFilteredModel()

  // Start cache check
  function startCacheCheck() {
    ollamaTaggingActive = false
    ollamaColorsActive = false
    ollamaEta = ""
    ollamaStartTime = 0
    ollamaLogLine = ""
    cacheResult = ""
    _checkCache.running = true
  }

  // Apply wallpaper actions
  function applyStatic(path) {
    _applyWallpaper.command = [scriptsDir + "/bash/apply-static-wallpaper", path]
    _applyWallpaper.running = true
  }

  function applyWE(id) {
    _applyWEWallpaper.command = [scriptsDir + "/bash/apply-we-wallpaper", id]
    _applyWEWallpaper.running = true
  }

  function applyVideo(path) {
    _applyVideoWallpaper.command = [scriptsDir + "/bash/apply-video-wallpaper", path]
    _applyVideoWallpaper.running = true
  }

  function deleteWallpaperItem(type, name, weId) {
    if (type === "we") {
      _deleteWallpaper.command = ["rm", "-rf", weDir + "/" + weId]
    } else {
      _deleteWallpaper.command = ["rm", "-f", wallpaperDir + "/" + name]
    }
    _deleteWallpaper.running = true
  }

  function openSteamPage(weId) {
    _unsubscribeWE.command = ["xdg-open", "steam://url/CommunityFilePage/" + weId]
    _unsubscribeWE.running = true
  }

  // Processes
  property var _cacheStatCheck: Process {
    id: cacheStatCheck
    command: ["stat", "-c", "%Y", service.wallpaperListCache]
    property string result: ""
    onRunningChanged: { if (running) result = "" }
    stdout: SplitParser { onRead: line => { cacheStatCheck.result = line.trim() } }
    onExited: {
      var mtime = cacheStatCheck.result
      if (mtime === "") return
      if (service.wallpaperModel.count === 0 || mtime !== service.lastCacheMtime) {
        service.lastCacheMtime = mtime
        service.wallpaperModel.clear()
        listWallpapers.running = true
      }
    }
  }

  property var _checkCache: Process {
    id: checkCache
    command: [service.scriptsDir + "/bash/check-wallpaper-cache"]
    onRunningChanged: {
      if (running) {
        service.cacheLoading = true
        service.cacheProgress = 0
        service.cacheTotal = 0
      }
    }
    stdout: SplitParser {
      onRead: line => {
        if (line.startsWith("progress:")) {
          const parts = line.split(":")
          if (parts.length === 3) {
            service.cacheProgress = parseInt(parts[1])
            service.cacheTotal = parseInt(parts[2])
          }
        } else if (line === "regenerated" || line === "cached") {
          service.cacheResult = line
        }
      }
    }
    onExited: {
      service.cacheReady = true
      service.cacheLoading = false
      if (service.cacheResult === "regenerated" || service.wallpaperModel.count === 0) {
        service.wallpaperModel.clear()
        listWallpapers.running = true
      } else {
        service.reloadMetadata()
      }
    }
  }

  property var _listWallpapers: Process {
    id: listWallpapers
    command: ["bash", "-c",
      "if [ -f '" + service.wallpaperListCache + "' ]; then cat '" + service.wallpaperListCache + "'; fi"
    ]
    running: false
    onRunningChanged: {
      if (!running) service.updateFilteredModel()
    }
    stdout: SplitParser {
      onRead: line => {
        try {
          var obj = JSON.parse(line)
          service.wallpaperModel.append({
            name: obj.name, type: obj.type, thumb: obj.thumb,
            path: (obj.type === "static" || obj.type === "video") ? service.wallpaperDir + "/" + obj.name : "",
            weId: obj.type === "we" ? obj.id : "", videoFile: obj.videoFile || "",
            mtime: obj.mtime, hue: obj.group, saturation: obj.sat
          })
        } catch (e) {}
      }
    }
    onExited: service.reloadMetadata()
  }

  property var _applyWallpaper: Process {
    command: ["bash", "-c", "true"]
    onExited: function(code) { if (code === 0) service.wallpaperApplied() }
  }

  property var _applyWEWallpaper: Process { command: ["bash", "-c", "true"] }

  property var _applyVideoWallpaper: Process { command: ["bash", "-c", "true"] }

  property var _deleteWallpaper: Process {
    command: ["bash", "-c", "true"]
    onExited: _clearCache.running = true
  }

  property var _clearCache: Process {
    id: clearCache
    command: ["rm", "-f", service.cacheBaseDir + "/wallpaper/checksum.txt"]
    onExited: {
      service.cacheReady = false
      service.wallpaperModel.clear()
    }
  }

  property var _unsubscribeWE: Process { command: ["bash", "-c", "true"] }

  // Ollama status polling
  property var _ollamaStatusTimer: Timer {
    interval: service.ollamaStatusPollMs
    running: service.showing
    repeat: true
    triggeredOnStart: true
    onTriggered: {
      ollamaStatusCheck.running = true
      ollamaProgressCheck.running = true
      if (service.ollamaActive) ollamaLogCheck.running = true
    }
  }

  property var _liveReloadTimer: Timer {
    interval: 15000
    running: service.showing && service.ollamaActive
    repeat: true
    onTriggered: service.reloadMetadata()
  }

  property var _ollamaLogCheck: Process {
    id: ollamaLogCheck
    command: ["bash", "-c", "tail -n1 " + service.cacheBaseDir + "/analyze-wallpapers.log 2>/dev/null | cut -c1-120"]
    running: false
    stdout: SplitParser {
      onRead: line => {
        var trimmed = line.trim()
        if (trimmed && trimmed.length > 0) service.ollamaLogLine = trimmed
      }
    }
  }

  property var _ollamaStatusCheck: Process {
    id: ollamaStatusCheck
    command: ["bash", "-c", "pgrep -f 'analyze-wallpapers' > /dev/null && echo 'active' || echo 'idle'"]
    property string result: ""
    stdout: SplitParser { onRead: line => { ollamaStatusCheck.result = line.trim() } }
    onRunningChanged: { if (running) result = "" }
    onExited: {
      if (result === "active") {
        ollamaDetailCheck.running = true
      } else {
        service.ollamaTaggingActive = false
        service.ollamaColorsActive = false
        service.ollamaLogLine = ""
      }
    }
  }

  property var _ollamaDetailCheck: Process {
    id: ollamaDetailCheck
    command: ["bash", "-c", "pgrep -f '[a]nalyze-wallpapers' > /dev/null && echo 'tag:1:color:1' || echo 'tag:0:color:0'"]
    stdout: SplitParser {
      onRead: line => {
        var parts = line.trim().split(":")
        if (parts.length >= 4) {
          service.ollamaTaggingActive = (parts[1] === "1")
          service.ollamaColorsActive = (parts[3] === "1")
        }
      }
    }
  }

  property var _ollamaProgressCheck: Process {
    id: ollamaProgressCheck
    command: ["bash", "-c", `
      cache="` + service.cacheBaseDir + `/wallpaper"
      thumbs=$(( $(find "$cache/thumbs" -name '*.jpg' 2>/dev/null | wc -l) + $(find "$cache/we-thumbs" -name '*.jpg' 2>/dev/null | wc -l) + $(find "$cache/video-thumbs" -name '*.jpg' 2>/dev/null | wc -l) ))
      tags=$(jq 'keys | length' "$cache/tags.json" 2>/dev/null || echo 0)
      colors=$(jq 'keys | length' "$cache/colors.json" 2>/dev/null || echo 0)
      echo "$thumbs:$tags:$colors"
    `]
    stdout: SplitParser {
      onRead: line => {
        var parts = line.trim().split(":")
        if (parts.length >= 3) {
          var total = parseInt(parts[0]) || 0
          var tagged = parseInt(parts[1]) || 0
          var colored = parseInt(parts[2]) || 0
          service.ollamaTotalThumbs = total
          service.ollamaTaggedCount = tagged
          service.ollamaColoredCount = colored

          if (!service.ollamaActive) {
            service.ollamaStartTime = 0
            service.ollamaEta = ""
            return
          }

          var now = Date.now() / 1000
          if (service.ollamaStartTime === 0) {
            service.ollamaStartTime = now
            service.ollamaStartTagCount = tagged
            service.ollamaStartColorCount = colored
            service.ollamaEta = "starting..."
            return
          }

          var elapsed = now - service.ollamaStartTime
          if (elapsed < 8) { service.ollamaEta = "calculating..."; return }

          var processed = 0; var remaining = 0
          if (service.ollamaTaggingActive && service.ollamaColorsActive) {
            remaining = (total - tagged) + (total - colored)
            processed = (tagged - service.ollamaStartTagCount) + (colored - service.ollamaStartColorCount)
          } else if (service.ollamaTaggingActive) {
            processed = tagged - service.ollamaStartTagCount
            remaining = total - tagged
          } else if (service.ollamaColorsActive) {
            processed = colored - service.ollamaStartColorCount
            remaining = total - colored
          }

          if (processed > 0 && remaining > 0) {
            var rate = processed / elapsed
            var etaSeconds = remaining / rate
            if (etaSeconds < 60) service.ollamaEta = "~" + Math.round(etaSeconds) + "s"
            else if (etaSeconds < 3600) service.ollamaEta = "~" + Math.round(etaSeconds / 60) + "m"
            else {
              var hours = Math.floor(etaSeconds / 3600)
              var mins = Math.round((etaSeconds % 3600) / 60)
              service.ollamaEta = "~" + hours + "h" + mins + "m"
            }
          } else if (remaining === 0) {
            if (tagged >= total && colored >= total && total > 0) ollamaFinalCheck.running = true
            else service.ollamaEta = "finishing..."
          } else {
            service.ollamaEta = "calculating..."
          }
        }
      }
    }
  }

  property var _ollamaFinalCheck: Process {
    id: ollamaFinalCheck
    command: ["bash", "-c", "pgrep -f '[t]ag-wallpapers|[a]nalyze-wallpaper-colors' > /dev/null && echo 'active' || echo 'idle'"]
    stdout: SplitParser {
      onRead: line => {
        if (line.trim() === "idle") {
          service.ollamaTaggingActive = false
          service.ollamaColorsActive = false
          service.ollamaEta = ""
          service.ollamaStartTime = 0
          service.ollamaLogLine = ""
        } else {
          service.ollamaEta = "finishing..."
        }
      }
    }
  }
}
