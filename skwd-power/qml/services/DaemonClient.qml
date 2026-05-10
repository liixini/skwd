pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: client

    readonly property bool connected: _socket.connected
    property bool ready: false

    signal eventReceived(string event, var data)

    function call(method, params, callback) {
        if (!_socket.connected) {
            if (callback) callback(null, {code: -1, message: "not connected"})
            return
        }
        var id = _nextId++
        if (callback) _pending[id] = { cb: callback, ts: Date.now() }
        var line = JSON.stringify({method: method, params: params || {}, id: id})
        _socket.write(line + "\n")
        _socket.flush()
    }

    function subscribe(events) { call("subscribe", {events: events}) }

    property int _nextId: 1
    property var _pending: ({})

    function _handleLine(line) {
        line = line.trim()
        if (!line) return

        var msg
        try { msg = JSON.parse(line) }
        catch (e) { console.warn("DaemonClient: invalid JSON:", line); return }

        if (msg.event) {
            client.eventReceived(msg.event, msg.data || {})
            return
        }

        if (msg.id !== undefined) {
            var entry = _pending[msg.id]
            if (entry) {
                delete _pending[msg.id]
                if (msg.error) entry.cb(null, msg.error)
                else entry.cb(msg.result, null)
            }
        }
    }

    property var _socket: Socket {
        path: (Quickshell.env("XDG_RUNTIME_DIR") || "/tmp") + "/skwd/daemon.sock"

        connected: false

        parser: SplitParser {
            onRead: data => client._handleLine(data)
        }

        onConnectionStateChanged: {
            if (connected) {
                console.log("DaemonClient: connected")
                client.subscribe(["skwd."])
                client.ready = true
            } else {
                console.log("DaemonClient: disconnected")
                client.ready = false
                client._pending = {}
                client._reconnectTimer.restart()
            }
        }
    }

    property var _reconnectTimer: Timer {
        interval: 2000
        repeat: false
        onTriggered: {
            if (!client.connected)
                client._socket.connected = true
        }
    }

    property var _cleanupTimer: Timer {
        interval: 30000
        running: true
        repeat: true
        onTriggered: {
            var now = Date.now()
            var stale = []
            for (var id in client._pending) {
                if (now - client._pending[id].ts > 30000) stale.push(id)
            }
            for (var i = 0; i < stale.length; i++) {
                var entry = client._pending[stale[i]]
                delete client._pending[stale[i]]
                if (entry && entry.cb) entry.cb(null, {code: -2, message: "timeout"})
            }
        }
    }

    Component.onCompleted: {
        _socket.connected = true
    }
}
