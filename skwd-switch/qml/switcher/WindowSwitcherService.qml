import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import "../services"

QtObject {
  id: service


  required property string scriptsDir
  required property string compositor
  required property string configPath
  required property string homeDir
  required property string cacheDir


  readonly property bool _isKde: {
    var d = (Quickshell.env("XDG_CURRENT_DESKTOP") || "").toLowerCase()
    return d.indexOf("kde") !== -1 || d.indexOf("plasma") !== -1
  }

  readonly property string _logPath: (Quickshell.env("HOME") || "/tmp") + "/.cache/skwd-switch.log"
  Component.onCompleted: {
    if (typeof ToplevelManager !== "undefined" && ToplevelManager.toplevels) {
      var _kick = ToplevelManager.toplevels.values
    }
  }

  property var _toplevelsConn: Connections {
    target: (typeof ToplevelManager !== "undefined") ? ToplevelManager.toplevels : null
    function onValuesChanged() {
      if (service._isKde) return
      var n = ToplevelManager.toplevels.values ? ToplevelManager.toplevels.values.length : 0
      service._log("ToplevelManager.valuesChanged count=" + n)
      service._buildFromToplevels()
    }
  }

  property var _logProc: Process { command: ["true"] }
  function _log(msg) {
    var line = "[" + new Date().toISOString() + "] " + msg
    console.log(line)
    _logProc.command = ["sh", "-c", "mkdir -p \"$(dirname '" + _logPath + "')\"; printf '%s\\n' " + JSON.stringify(line) + " >> '" + _logPath + "'"]
    _logProc.running = true
  }


  property int selectedIndex: 0
  property bool preserveIndex: false


  property var appConfig: ({})

  property var _appConfigFile: FileView {
    path: service.configPath
    preload: true
    watchChanges: true
    onLoaded: service.loadAppConfig()
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
  property var _mdiUserFile: FileView {
    path: service.homeDir + "/.config/skwd/data/mdi-icons.json"
    preload: true
    onLoaded: service._buildMdiMap()
  }
  property var _mdiSystemFile: FileView {
    path: (Quickshell.env("SKWD_INSTALL") || "/usr/share/skwd") + "/data/mdi-icons.json"
    preload: true
    onLoaded: service._buildMdiMap()
  }
  function _parseMdiInto(text) {
    if (!text || !text.trim()) return null
    try {
      var arr = JSON.parse(text)
      if (!Array.isArray(arr) || arr.length === 0) return null
      var m = {}
      for (var i = 0; i < arr.length; i++) {
        var e = arr[i]
        if (e && e.n && e.g) m[e.n.toLowerCase()] = e.g
      }
      return m
    } catch (e) {
      return null
    }
  }
  function _buildMdiMap() {
    var m = _parseMdiInto(_mdiUserFile.text())
    if (!m) m = _parseMdiInto(_mdiSystemFile.text())
    service._mdiByName = m || {}
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
    if (conf.icon && !conf.useDesktopIcon) return ""
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
  property var _toplevelRefs: []
  property var _kwinUuids: []

  signal modelBuilt(int focusIndex)


  function _collectToplevels() {
    var tm = ToplevelManager.toplevels
    var out = []
    if (!tm) return out
    if (tm.values && tm.values.length !== undefined) {
      for (var i = 0; i < tm.values.length; i++) out.push(tm.values[i])
    } else if (typeof tm.count === "number") {
      for (var j = 0; j < tm.count; j++) {
        var v = tm.get ? tm.get(j) : null
        if (v) out.push(v)
      }
    }
    return out
  }

  function _buildFromToplevels() {
    var prevIdx = selectedIndex
    filteredModel.clear()
    var refs = []
    _kwinUuids = []

    var sorted = _collectToplevels().slice()
    _log("_buildFromToplevels: ToplevelManager has " + sorted.length + " toplevels")
    sorted.sort(function(a, b) {
      if (a.activated && !b.activated) return -1
      if (!a.activated && b.activated) return 1
      return 0
    })

    for (var i = 0; i < sorted.length; i++) {
      var w = sorted[i]
      refs.push(w)
      filteredModel.append({
        winId: i,
        title: w.title || "",
        appId: w.appId || "",
        workspaceId: 0,
        isFocused: w.activated || false,
        isFloating: false
      })
    }
    _toplevelRefs = refs

    _finishBuild(prevIdx)
  }

  function _finishBuild(prevIdx) {
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


  property var _kwinFetch: Process {
    id: kwinFetch
    command: ["sh", "-c", service._kwinListSh()]
    running: false
    property string buf: ""
    stdout: SplitParser {
      splitMarker: ""
      onRead: data => { kwinFetch.buf += data }
    }
    onExited: {
      var prevIdx = service.selectedIndex
      service.filteredModel.clear()
      service._toplevelRefs = []
      var uuids = []
      var text = (kwinFetch.buf || "").trim()
      service._log("kwin-fetch exited, buf-len=" + text.length + " head=" + text.substring(0, 120))
      try {
        var data = text ? JSON.parse(text) : []
        service._log("kwin-fetch parsed " + data.length + " windows")
        data.sort(function(a, b) {
          if (a.is_focused && !b.is_focused) return -1
          if (!a.is_focused && b.is_focused) return 1
          return 0
        })
        for (var i = 0; i < data.length; i++) {
          var w = data[i]
          uuids.push(w.id || "")
          service.filteredModel.append({
            winId: i,
            title: w.title || "",
            appId: w.app_id || "",
            workspaceId: w.workspace_id || 0,
            isFocused: !!w.is_focused,
            isFloating: false
          })
        }
      } catch (e) {
        service._log("kwin-fetch parse error: " + e + " | buf-head: " + text.substring(0, 200))
      }
      service._kwinUuids = uuids
      service._finishBuild(prevIdx)
    }
  }

  readonly property string _kwinListScriptBody:
    'var ws = workspace.windowList();\n' +
    'var active = workspace.activeWindow;\n' +
    'var arr = [];\n' +
    'for (var i = 0; i < ws.length; i++) {\n' +
    '  var w = ws[i];\n' +
    '  if (w.windowType !== 0) continue;\n' +
    '  if (w.skipSwitcher) continue;\n' +
    '  var did = 0;\n' +
    '  if (w.desktops && w.desktops.length > 0) {\n' +
    '    did = w.desktops[0].x11DesktopNumber || 0;\n' +
    '  }\n' +
    '  arr.push({\n' +
    '    id: w.internalId.toString(),\n' +
    '    title: w.caption || "",\n' +
    '    app_id: w.resourceClass || "",\n' +
    '    workspace_id: did,\n' +
    '    is_focused: (w === active)\n' +
    '  });\n' +
    '}\n' +
    'console.log("SKWD_SWITCH_WINDOWS:" + JSON.stringify(arr));\n'

  function _kwinListSh() {
    var marker = "SKWD_SWITCH_" + Date.now() + "_" + Math.floor(Math.random() * 1e6)
    var body = _kwinListScriptBody.replace(/SKWD_SWITCH_WINDOWS/g, marker)
    var escaped = body.replace(/'/g, "'\\''")
    var log = "'" + _logPath + "'"
    return "LOG=" + log + "; " +
      "mkdir -p \"$(dirname \"$LOG\")\"; " +
      "echo \"[$(date +%H:%M:%S.%3N)] kwin-fetch: start marker=" + marker + "\" >> \"$LOG\"; " +
      "SF=$(mktemp /tmp/skwd-switch-list-XXXXXX.js); " +
      "printf %s '" + escaped + "' > \"$SF\"; " +
      "echo \"[$(date +%H:%M:%S.%3N)]   script-file=$SF size=$(wc -c < \"$SF\")\" >> \"$LOG\"; " +
      "SINCE=$(date +%s.%N); " +
      "LOAD_OUT=$(qdbus6 org.kde.KWin /Scripting org.kde.kwin.Scripting.loadScript \"$SF\" 2>&1); " +
      "echo \"[$(date +%H:%M:%S.%3N)]   loadScript -> $LOAD_OUT\" >> \"$LOG\"; " +
      "SID=$(echo \"$LOAD_OUT\" | grep -oE '^[0-9]+$' | head -1); " +
      "if [ -z \"$SID\" ]; then echo \"[$(date +%H:%M:%S.%3N)]   ERROR no script id\" >> \"$LOG\"; rm -f \"$SF\"; echo '[]'; exit 0; fi; " +
      "RUN_OUT=$(qdbus6 org.kde.KWin /Scripting/Script$SID org.kde.kwin.Script.run 2>&1); " +
      "echo \"[$(date +%H:%M:%S.%3N)]   Script$SID.run -> $RUN_OUT\" >> \"$LOG\"; " +
      "UNLOAD_OUT=$(qdbus6 org.kde.KWin /Scripting org.kde.kwin.Scripting.unloadScript \"$SF\" 2>&1); " +
      "echo \"[$(date +%H:%M:%S.%3N)]   unloadScript -> $UNLOAD_OUT\" >> \"$LOG\"; " +
      "sleep 0.2; " +
      "JOURNAL=$(journalctl --user _COMM=kwin_wayland --since=\"@$SINCE\" -o cat 2>&1); " +
      "echo \"[$(date +%H:%M:%S.%3N)]   journal raw (last 5 lines):\" >> \"$LOG\"; " +
      "echo \"$JOURNAL\" | tail -5 | sed 's/^/    /' >> \"$LOG\"; " +
      "LINE=$(echo \"$JOURNAL\" | grep '" + marker + ":' | tail -1); " +
      "echo \"[$(date +%H:%M:%S.%3N)]   matched line: ${LINE:-<none>}\" >> \"$LOG\"; " +
      "rm -f \"$SF\"; " +
      "RESULT=\"${LINE#*" + marker + ":}\"; " +
      "echo \"[$(date +%H:%M:%S.%3N)]   result-json (first 200 chars): $(echo \"$RESULT\" | head -c 200)\" >> \"$LOG\"; " +
      "echo \"$RESULT\""
  }

  property var _kwinAction: Process { command: ["true"] }
  function _runKwinAction(args) {
    _kwinAction.command = args
    _kwinAction.running = true
  }

  function _kwinActionSh(jsBody) {
    var escaped = jsBody.replace(/'/g, "'\\''")
    return "SF=$(mktemp /tmp/skwd-switch-act-XXXXXX.js); " +
      "printf %s '" + escaped + "' > \"$SF\"; " +
      "SID=$(qdbus6 org.kde.KWin /Scripting org.kde.kwin.Scripting.loadScript \"$SF\" 2>/dev/null); " +
      "qdbus6 org.kde.KWin /Scripting/Script$SID org.kde.kwin.Script.run >/dev/null 2>&1; " +
      "qdbus6 org.kde.KWin /Scripting org.kde.kwin.Scripting.unloadScript \"$SF\" >/dev/null 2>&1; " +
      "rm -f \"$SF\""
  }


  function buildModel() {
    _log("buildModel: _isKde=" + _isKde)
    if (_isKde) {
      kwinFetch.buf = ""
      kwinFetch.running = true
    } else {
      _buildFromToplevels()
    }
  }

  function open() {
    selectedIndex = 0
    preserveIndex = false
    loadAppConfig()
    _log("open: XDG_CURRENT_DESKTOP=" + Quickshell.env("XDG_CURRENT_DESKTOP"))
    buildModel()
  }


  function focusWindow(winId) {
    if (_isKde) {
      var uuid = _kwinUuids[winId]
      if (!uuid) return
      var js =
        'var ws = workspace.windowList();\n' +
        'for (var i = 0; i < ws.length; i++) {\n' +
        '  if (ws[i].internalId.toString() === "' + uuid + '") {\n' +
        '    workspace.activeWindow = ws[i];\n' +
        '    break;\n' +
        '  }\n' +
        '}\n'
      _runKwinAction(["sh", "-c", _kwinActionSh(js)])
    } else {
      var tl = _toplevelRefs[winId]
      if (tl && typeof tl.activate === "function") tl.activate()
    }
  }

  function closeWindow(winId) {
    if (_isKde) {
      var uuid = _kwinUuids[winId]
      if (!uuid) return
      var js =
        'var ws = workspace.windowList();\n' +
        'for (var i = 0; i < ws.length; i++) {\n' +
        '  if (ws[i].internalId.toString() === "' + uuid + '") {\n' +
        '    ws[i].closeWindow();\n' +
        '    break;\n' +
        '  }\n' +
        '}\n'
      _runKwinAction(["sh", "-c", _kwinActionSh(js)])
      preserveIndex = true
      Qt.callLater(buildModel)
    } else {
      var tl = _toplevelRefs[winId]
      if (tl && typeof tl.close === "function") {
        tl.close()
        preserveIndex = true
        Qt.callLater(buildModel)
      }
    }
  }
}
