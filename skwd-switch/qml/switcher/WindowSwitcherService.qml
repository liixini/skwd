import Quickshell
import Quickshell.Io
import QtQuick
import "../services"

QtObject {
  id: service


  required property string scriptsDir
  required property string compositor
  required property string configPath
  required property string homeDir
  required property string cacheDir


  property var windowList: []
  property int selectedIndex: 0
  property bool preserveIndex: false

  
  property var appConfig: ({})

  property var _appConfigFile: FileView {
    path: service.configPath
    preload: true
    watchChanges: true
    onFileChanged: _appConfigFile.reload()
  }

  function loadAppConfig() {
    try {
      service.appConfig = JSON.parse(_appConfigFile.text())
    } catch (e) {
      service.appConfig = {}
    }
  }

  function _normalizeKey(s) {
    return (s || "").toLowerCase().replace(/[-_.]/g, " ").replace(/\s+/g, " ").trim()
  }

  function getAppConf(appId) {
    var lower = (appId || "").toLowerCase()
    if (appConfig[lower]) return appConfig[lower]
    var norm = _normalizeKey(appId)
    if (appConfig[norm]) return appConfig[norm]
    for (var key in appConfig) {
      if (key.startsWith("_")) continue
      if (typeof appConfig[key] !== "object") continue
      var nk = _normalizeKey(key)
      if (nk === norm) return appConfig[key]
      if (nk.indexOf(norm) !== -1 || norm.indexOf(nk) !== -1) return appConfig[key]
    }
    return {}
  }

  
  property var _mdiByName: ({})
  property var _mdiFile: FileView {
    path: service.homeDir + "/.config/skwd/data/mdi-icons.json"
    preload: true
    onLoaded: service._buildMdiMap()
  }
  function _buildMdiMap() {
    try {
      var arr = JSON.parse(_mdiFile.text())
      var m = {}
      for (var i = 0; i < arr.length; i++) {
        var e = arr[i]
        if (e && e.n && e.g) m[e.n.toLowerCase()] = e.g
      }
      service._mdiByName = m
    } catch (e) {
      service._mdiByName = {}
    }
  }

  function _mdiLookup(name) {
    if (!name) return ""
    var key = name.toLowerCase()
    if (_mdiByName[key]) return _mdiByName[key]
    
    var spaced = key.replace(/[-_.]/g, " ").trim()
    if (_mdiByName[spaced]) return _mdiByName[spaced]
    
    var tail = key.split(".").pop()
    if (_mdiByName[tail]) return _mdiByName[tail]
    return ""
  }

  function getIcon(appId) {
    var conf = getAppConf(appId)
    if (conf.icon) return conf.icon
    var glyph = _mdiLookup(appId)
    if (glyph) return glyph
    var entry = DesktopEntries.byId(appId) || DesktopEntries.byId((appId || "").toLowerCase())
    if (entry && entry.icon) {
      glyph = _mdiLookup(entry.icon)
      if (glyph) return glyph
    }
    return _mdiByName["application"] || _mdiByName["apps"] || "?"
  }

  function getIconSource(appId) {
    var conf = getAppConf(appId)
    if (conf.iconPath) return "file://" + conf.iconPath
    if (conf.iconName) {
      var pn = Quickshell.iconPath(conf.iconName, true)
      if (pn) return pn
    }

    var lower = (appId || "").toLowerCase()
    var entry = DesktopEntries.byId(appId) || DesktopEntries.byId(lower)
    if (!entry) {
      var tail = lower.split(".").pop()
      if (tail && tail !== lower) entry = DesktopEntries.byId(tail)
    }
    if (entry && entry.icon) {
      var p = Quickshell.iconPath(entry.icon, true)
      if (p) return p
    }

    var direct = Quickshell.iconPath(lower, true)
    if (direct) return direct

    var t = lower.split(".").pop()
    if (t && t !== lower) {
      var p2 = Quickshell.iconPath(t, true)
      if (p2) return p2
    }

    return ""
  }

  function getName(appId) {
    var conf = getAppConf(appId)
    if (conf.displayName) return conf.displayName
    var entry = DesktopEntries.byId(appId) || DesktopEntries.byId((appId || "").toLowerCase())
    if (entry && entry.name) return entry.name
    return appId
  }

  
  property var filteredModel: ListModel {}

  
  signal modelBuilt(int focusIndex)

  
  function buildModel() {
    var prevIdx = selectedIndex
    filteredModel.clear()
    for (var i = 0; i < windowList.length; i++) {
      var w = windowList[i]
      filteredModel.append({
        winId: w.id || 0,
        title: w.title || "",
        appId: w.app_id || "",
        workspaceId: w.workspace_id || 0,
        isFocused: w.is_focused || false,
        isFloating: w.is_floating || false
      })
    }
    var idx = 0
    if (filteredModel.count > 0) {
      if (preserveIndex) {
        idx = Math.min(prevIdx, filteredModel.count - 1)
        preserveIndex = false
      } else {
        idx = filteredModel.count > 1 ? 1 : 0
      }
    }
    modelBuilt(idx)
  }

  property var _focusProcess: Process { command: ["true"] }
  property var _closeProcess: Process { command: ["true"] }

  property var _fetchWindows: Process {
    id: fetchWindows
    command: WmService.listWindowsCmd()
    running: false
    property string buf: ""
    stdout: SplitParser {
      splitMarker: ""
      onRead: data => { fetchWindows.buf += data }
    }
    onExited: {
      try {
        var windows = JSON.parse(fetchWindows.buf)
        var comp = service.compositor

        if (comp === "hyprland") {
          for (var i = 0; i < windows.length; i++) {
            var w = windows[i]
            w.id = w.address
            w.app_id = w.class || ""
            w.workspace_id = w.workspace ? w.workspace.id : 0
            w.is_focused = w.focusHistoryID === 0
            w.is_floating = w.floating || false
          }
          windows.sort(function(a, b) {
            return (a.focusHistoryID || 0) - (b.focusHistoryID || 0)
          })
        } else if (comp === "sway") {
          for (var i = 0; i < windows.length; i++) {
            var w = windows[i]
            w.app_id = w.app_id || ""
            w.workspace_id = w.num || 0
            w.is_focused = w.focused || false
            w.is_floating = w.type === "floating_con"
          }
        } else if (comp === "kwin") {
          
          
          windows.sort(function(a, b) {
            if (a.is_focused && !b.is_focused) return -1
            if (!a.is_focused && b.is_focused) return 1
            return 0
          })
        } else {
          windows.sort(function(a, b) {
            var aTime = a.focus_timestamp ? (a.focus_timestamp.secs * 1e9 + a.focus_timestamp.nanos) : 0
            var bTime = b.focus_timestamp ? (b.focus_timestamp.secs * 1e9 + b.focus_timestamp.nanos) : 0
            return bTime - aTime
          })
        }

        service.windowList = windows
      } catch (e) {
        service.windowList = []
      }
      service.buildModel()
    }
  }

  property var _refreshTimer: Timer {
    interval: 100
    onTriggered: {
      fetchWindows.buf = ""
      fetchWindows.running = true
    }
  }

  
  function open() {
    selectedIndex = 0
    preserveIndex = false
    loadAppConfig()
    _fetchWindows.buf = ""
    _fetchWindows.running = true
  }

  function focusWindow(winId) {
    WmService.focusWindow(winId.toString())
  }

  function closeWindow(winId) {
    WmService.closeWindow(winId.toString())
    preserveIndex = true
    _refreshTimer.restart()
  }
}
