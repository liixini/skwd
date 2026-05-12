import Quickshell.Io
import QtQuick
import "../services"

QtObject {
  id: service

  
  required property string scriptsDir
  required property string homeDir
  required property string cacheDir
  required property string configDir
  required property string terminal

  property string cacheFile: cacheDir + "/app-launcher/list.jsonl"

  
  property string searchText: ""
  property string sourceFilter: ""

  function _findFilter(key) {
    var list = Config.launchFilters || []
    for (var i = 0; i < list.length; i++) if (list[i].key === key) return list[i]
    return null
  }

  function _matchesFilter(item, key) {
    var f = _findFilter(key)
    if (!f || f.type === "all") return true
    var v = f.value || ""
    if (f.type === "source")   return item.source === v
    if (f.type === "category") return v !== "" && item.categories && item.categories.indexOf(v) !== -1
    if (f.type === "tag")      return v !== "" && item.tags && item.tags.indexOf(v) !== -1
    return true
  }

  
  property bool cacheLoading: false
  property int cacheProgress: 0
  property int cacheTotal: 0

  
  property var appModel: ListModel {}
  property var filteredModel: ListModel {}

  
  signal modelUpdated()
  property int _rev: 0
  onModelUpdated: _rev++

  
  property string freqCachePath: cacheDir + "/app-launcher/freq.json"
  property var freqData: ({})

  property var _freqFile: FileView {
    path: service.freqCachePath
    preload: true
  }

  function loadFreqData() {
    try {
      service.freqData = JSON.parse(_freqFile.text())
    } catch (e) {
      service.freqData = {}
    }
  }

  function saveFreqData() {
    _freqFile.setText(JSON.stringify(freqData))
  }

  function recordSelection(appName) {
    var query = searchText.toLowerCase().trim()
    if (query === "") return

    var fd = freqData
    for (var len = 2; len <= query.length; len++) {
      var prefix = query.substring(0, len)
      if (!fd[prefix]) fd[prefix] = {}
      if (!fd[prefix][appName]) fd[prefix][appName] = 0
      fd[prefix][appName] += 1
    }
    freqData = fd
    saveFreqData()
  }

  function getFreqScore(appName) {
    var query = searchText.toLowerCase().trim()
    if (query === "" || !freqData[query]) return 0
    return freqData[query][appName] || 0
  }

  
  function updateFilteredModel() {
    var query = searchText.toLowerCase()
    var sf = sourceFilter
    var results = []
    for (var i = 0; i < appModel.count; i++) {
      var item = appModel.get(i)
      if (item.hidden) continue
      if (query !== "" &&
          item.name.toLowerCase().indexOf(query) === -1 &&
          item.categories.toLowerCase().indexOf(query) === -1 &&
          item.displayName.toLowerCase().indexOf(query) === -1 &&
          item.tags.toLowerCase().indexOf(query) === -1)
        continue
      if (sf !== "" && !_matchesFilter(item, sf)) continue
      results.push({
        name: item.name,
        exec: item.exec,
        icon: item.icon,
        thumb: item.thumb,
        iconPath: item.iconPath,
        categories: item.categories,
        source: item.source,
        steamAppId: item.steamAppId,
        terminal: item.terminal,
        background: item.background,
        backgroundThumb: item.backgroundThumb,
        customIcon: item.customIcon,
        useDesktopIcon: item.useDesktopIcon,
        displayName: item.displayName,
        tags: item.tags
      })
    }

    if (query !== "") {
      var freqMap = freqData[query] || {}
      results.sort(function(a, b) {
        var freqA = freqMap[a.name] || 0
        var freqB = freqMap[b.name] || 0
        if (freqA !== freqB) return freqB - freqA
        return a.name.toLowerCase().localeCompare(b.name.toLowerCase())
      })
    }

    if (results.length === filteredModel.count) {
      var same = true
      for (var k = 0; k < results.length; k++) {
        if (results[k].name !== filteredModel.get(k).name) {
          same = false
          break
        }
      }
      if (same) {
        var anyDelta = false
        for (var u = 0; u < results.length; u++) {
          var r = results[u]
          var f = filteredModel.get(u)
          if (f.background !== r.background) { filteredModel.setProperty(u, "background", r.background); anyDelta = true }
          if (f.displayName !== r.displayName) { filteredModel.setProperty(u, "displayName", r.displayName); anyDelta = true }
          if (f.customIcon !== r.customIcon) { filteredModel.setProperty(u, "customIcon", r.customIcon); anyDelta = true }
          if (f.useDesktopIcon !== r.useDesktopIcon) { filteredModel.setProperty(u, "useDesktopIcon", r.useDesktopIcon); anyDelta = true }
          if (f.thumb !== r.thumb) { filteredModel.setProperty(u, "thumb", r.thumb); anyDelta = true }
          if (f.tags !== r.tags) { filteredModel.setProperty(u, "tags", r.tags); anyDelta = true }
        }
        if (anyDelta) modelUpdated()
        return
      }
    }

    filteredModel.clear()
    for (var j = 0; j < results.length; j++) {
      filteredModel.append(results[j])
    }
    modelUpdated()
  }

  onSearchTextChanged: updateFilteredModel()
  onSourceFilterChanged: updateFilteredModel()

  
  property var _appRunner: Process { command: ["true"] }

  function launchApp(appExec, isTerminal, appName) {
    if (appName) recordSelection(appName)
    var cmd = appExec
    if (isTerminal) cmd = service.terminal + " " + cmd
    _appRunner.command = ["sh", "-c", "nohup setsid sh -c " + JSON.stringify(cmd) + " </dev/null >/dev/null 2>&1 &"]
    _appRunner.running = true
  }

  
  property var _appCacheConn: Connections {
    target: AppCacheService
    function onCacheReady() {
      service.cacheLoading = false
      service.appModel.clear()
      loadApps.running = true
    }
  }

  
  property var _progressBinding: Binding {
    target: service
    property: "cacheProgress"
    value: AppCacheService.progress
    when: AppCacheService.running
  }
  property var _totalBinding: Binding {
    target: service
    property: "cacheTotal"
    value: AppCacheService.total
    when: AppCacheService.running
  }

  function _startBuildCache() {
    cacheLoading = true
    cacheProgress = 0
    cacheTotal = 0
    AppCacheService.rebuild()
  }

  
  property var _loadAppsPending: []

  property var _loadApps: Process {
    id: loadApps
    command: ["bash", "-c",
      "if [ -f '" + service.cacheFile + "' ]; then cat '" + service.cacheFile + "'; fi"
    ]
    running: false
    onRunningChanged: { if (running) service._loadAppsPending = [] }
    stdout: SplitParser {
      onRead: line => {
        try {
          var obj = JSON.parse(line)
          service._loadAppsPending.push({
            name: obj.name || "",
            exec: obj.exec || "",
            icon: obj.icon || "",
            thumb: obj.thumb || "",
            iconPath: obj.iconPath || "",
            categories: obj.categories || "",
            source: obj.source || "desktop",
            steamAppId: obj.steamAppId || "",
            terminal: obj.terminal || false,
            background: obj.background || "",
            backgroundThumb: obj.backgroundThumb || "",
            customIcon: obj.customIcon || "",
            useDesktopIcon: obj.useDesktopIcon === true,
            displayName: obj.displayName || "",
            hidden: obj.hidden || false,
            tags: obj.tags || ""
          })
        } catch (e) {}
      }
    }
    onExited: {
      if (service._loadAppsPending.length > 0) {
        service.appModel.append(service._loadAppsPending)
        service._loadAppsPending = []
      }
      service._applyAppsConfig()
      service.updateFilteredModel()
    }
  }

  
  property var _desktopWatcher: Process {
    id: desktopWatcher
    running: true
    command: ["bash", "-c",
      "dirs=(); for d in /usr/share/applications " +
      "\"$HOME/.local/share/applications\" " +
      "/var/lib/flatpak/exports/share/applications " +
      "\"$HOME/.local/share/flatpak/exports/share/applications\"; do " +
      "[ -d \"$d\" ] && dirs+=(\"$d\"); done; " +
      "[ ${#dirs[@]} -eq 0 ] && exit 1; " +
      "exec inotifywait -m -r -e create,delete,modify,moved_to,moved_from " +
      "--include '\\.desktop$' \"${dirs[@]}\""
    ]
    stdout: SplitParser {
      onRead: line => {
        desktopWatcherDebounce.restart()
      }
    }
    onExited: desktopWatcherRestart.start()
  }

  property var _desktopWatcherRestart: Timer {
    id: desktopWatcherRestart
    interval: 5000
    onTriggered: desktopWatcher.running = true
  }

  property var _appsJsonWatcher: FileView {
    path: service.configDir + "/data/apps.json"
    preload: true
    watchChanges: true
    onFileChanged: reload()
    onLoaded: service._applyAppsConfig()
  }

  function _applyAppsConfig() {
    var text = _appsJsonWatcher.text().trim()
    if (!text || appModel.count === 0) return
    try {
      var data = JSON.parse(text)
    } catch (e) { return }

    
    var configMap = {}
    for (var k in data) {
      if (k.startsWith("_")) continue
      var v = data[k]
      if (typeof v === "string")
        configMap[k.toLowerCase()] = v ? { background: v } : {}
      else if (typeof v === "object" && v !== null)
        configMap[k.toLowerCase()] = v
    }

    var home = service.homeDir
    function resolve(p) { return p ? p.replace("~", home) : "" }

    var anyChanged = false
    for (var i = 0; i < appModel.count; i++) {
      var item = appModel.get(i)
      var conf = _findAppConfig(item.name, configMap)
      var bg = resolve(conf.background || "")
      var dn = conf.displayName || ""
      var ci = conf.icon || ""
      var udi = conf.useDesktopIcon === true
      var tags = conf.tags || ""
      var hidden = !!conf.hidden

      if (item.background !== bg) { appModel.setProperty(i, "background", bg); anyChanged = true }
      if (item.displayName !== dn) { appModel.setProperty(i, "displayName", dn); anyChanged = true }
      if (item.customIcon !== ci) { appModel.setProperty(i, "customIcon", ci); anyChanged = true }
      if (item.useDesktopIcon !== udi) { appModel.setProperty(i, "useDesktopIcon", udi); anyChanged = true }
      if (item.tags !== tags) { appModel.setProperty(i, "tags", tags); anyChanged = true }
      if (item.hidden !== hidden) { appModel.setProperty(i, "hidden", hidden); anyChanged = true }
    }
    if (anyChanged) _persistCache()
    updateFilteredModel()
  }

  property var _cacheWriter: FileView {}

  function _persistCache() {
    var lines = []
    for (var i = 0; i < appModel.count; i++) {
      var it = appModel.get(i)
      lines.push(JSON.stringify({
        name: it.name, exec: it.exec, icon: it.icon, thumb: it.thumb,
        iconPath: it.iconPath, categories: it.categories, source: it.source,
        steamAppId: it.steamAppId, terminal: it.terminal,
        background: it.background, backgroundThumb: it.backgroundThumb,
        customIcon: it.customIcon,
        useDesktopIcon: it.useDesktopIcon,
        displayName: it.displayName, hidden: it.hidden, tags: it.tags
      }))
    }
    _cacheWriter.path = service.cacheFile
    _cacheWriter.setText(lines.join("\n") + "\n")
  }
  
  function _findAppConfig(name, configMap) {
    var lower = name.toLowerCase()
    if (configMap[lower]) return configMap[lower]
    for (var key in configMap) {
      if (lower.indexOf(key) !== -1) return configMap[key]
    }
    return {}
  }

  property var _desktopWatcherDebounce: Timer {
    id: desktopWatcherDebounce
    interval: 2000
    onTriggered: {
      if (!AppCacheService.running) {
        service._startBuildCache()
      }
    }
  }

  
  function start() {
    if (service.appModel.count === 0) {
      _cacheCheck.running = true
    } else {
      updateFilteredModel()
    }
  }

  property var _cacheCheck: Process {
    id: cacheCheck
    command: ["sh", "-c",
      "[ -s '" + service.cacheFile + "' ] && " +
      "[ \"$(cat '" + AppCacheService.versionFile + "' 2>/dev/null)\" = \"" + AppCacheService.cacheVersion + "\" ]"
    ]
    onExited: function(exitCode) {
      if (exitCode === 0) {
        loadApps.running = true
      } else {
        service._startBuildCache()
      }
    }
  }
}
