pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import ".."


QtObject {
  id: service

  property var data: ({})
  property var wallData: ({})
  property bool ready: false
  property bool _wallWriting: false

  property var _wallSelfWriteTimer: Timer {
    interval: 1500
    repeat: false
    onTriggered: service._wallWriting = false
  }

  property var _file: FileView {
    path: Config.configFilePath
    preload: true
    onLoaded: service._reparseSelf()
  }

  property var _wallFile: FileView {
    path: Config.wallConfigFilePath
    preload: true
    watchChanges: true
    onLoaded: service._reparseWall()
    onFileChanged: { reload(); service._reparseWall() }
  }

  function _reparseSelf() {
    var raw = _file.text() || ""
    if (!raw) { service.ready = true; return }
    try {
      service.data = JSON.parse(raw)
      service.ready = true
    } catch (e) {
      console.warn("SettingsService: parse error in", Config.configFilePath, e)
    }
  }

  function _reparseWall() {
    if (service._wallWriting) return
    var raw = _wallFile.text() || ""
    if (!raw) return
    try {
      var parsed = JSON.parse(raw)
      if (JSON.stringify(parsed) === JSON.stringify(service.wallData)) return
      service.wallData = parsed
    } catch (e) {}
  }

  function _clone(obj) {
    try { return JSON.parse(JSON.stringify(obj)) } catch (e) { return {} }
  }

  function _setOn(rootObj, dottedPath, value) {
    var parts = dottedPath.split(".")
    var obj = rootObj
    for (var i = 0; i < parts.length - 1; i++) {
      var k = parts[i]
      if (typeof obj[k] !== "object" || obj[k] === null) obj[k] = {}
      obj = obj[k]
    }
    var leaf = parts[parts.length - 1]
    if (value === null || value === undefined) delete obj[leaf]
    else obj[leaf] = value
  }

  function _readPath(rootObj, dottedPath, fallback) {
    var parts = dottedPath.split(".")
    var obj = rootObj
    for (var i = 0; i < parts.length; i++) {
      if (obj === null || typeof obj !== "object") return fallback
      obj = obj[parts[i]]
      if (obj === undefined) return fallback
    }
    return obj
  }

  function setPath(dottedPath, value) {
    if (!service.ready) return
    var d = service._clone(service.data)
    service._setOn(d, dottedPath, value)
    service.data = d
    _file.setText(JSON.stringify(d, null, 2) + "\n")
  }

  function getPath(dottedPath, fallback) { return service._readPath(service.data, dottedPath, fallback) }

  function setWallPath(dottedPath, value) {
    _wallFile.reload()
    var raw = _wallFile.text() || ""
    var fresh = {}
    if (raw) { try { fresh = JSON.parse(raw) } catch (e) {} }
    service._setOn(fresh, dottedPath, value)
    service.wallData = fresh
    service._wallWriting = true
    _wallSelfWriteTimer.restart()
    _wallFile.setText(JSON.stringify(fresh, null, 2) + "\n")
  }

  function getWallPath(dottedPath, fallback) { return service._readPath(service.wallData, dottedPath, fallback) }

  function setKey(section, key, value) { setPath(section + "." + key, value) }

  function setSwitcherKey(key, value)     { setKey("switcher",     key, value) }
  function setLauncherKey(key, value)     { setKey("launcher",     key, value) }
  function setMusicKey(key, value)        { setKey("music",        key, value) }
  function setNotificationKey(key, value) { setKey("notification", key, value) }
  function setBarKey(key, value)          { setKey("bar",          key, value) }
}
