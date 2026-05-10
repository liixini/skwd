pragma Singleton
import QtQuick
import Quickshell.Io
import ".."


QtObject {
    id: service

    property string interface_: Config.wifiInterface
    readonly property bool _enabled: Config.wifiEnabled
    property bool running: false

    
    property var networks: []
    signal networksUpdated()

    
    property string connectedSsid: ""
    property int connectedSignal: 0

    property var knownSsids: ({})

    function scan() {
        if (!_enabled || !interface_) return
        _scanProcess.command = ["iwctl", "station", interface_, "scan"]
        _scanProcess.running = true
        _knownStdout = []
        _knownProcess.command = ["iwctl", "known-networks", "list"]
        _knownProcess.running = true
    }


    property var _scanProcess: Process {
        id: scanProcess
        onExited: _scanDelay.start()
    }


    property var _knownStdout: []
    property var _knownProcess: Process {
        id: knownProcess
        onExited: {
            var raw = service._knownStdout.join("")
            service._parseKnown(raw)
        }
        stdout: SplitParser {
            splitMarker: ""
            onRead: data => service._knownStdout.push(data)
        }
    }


    property var _scanDelay: Timer {
        interval: 500
        onTriggered: {
            _getNetworksStdout = []
            _getNetworksProcess.command = ["iwctl", "station", service.interface_, "get-networks"]
            _getNetworksProcess.running = true
        }
    }

    
    property var _getNetworksStdout: []
    property var _getNetworksProcess: Process {
        id: getNetworksProcess
        onExited: {
            var raw = _getNetworksStdout.join("")
            service._parseNetworks(raw)
        }
        stdout: SplitParser {
            splitMarker: ""
            onRead: data => _getNetworksStdout.push(data)
        }
    }

    
    property var _statusStdout: []
    property var _statusProcess: Process {
        id: statusProcess
        onExited: {
            var raw = _statusStdout.join("")
            service._parseStatus(raw)
            if (service.running && service._enabled) _statusTimer.start()
        }
        stdout: SplitParser {
            splitMarker: ""
            onRead: data => _statusStdout.push(data)
        }
    }

    property var _statusTimer: Timer {
        interval: Config.wifiPollMs > 0 ? Config.wifiPollMs : 10000
        onTriggered: {
            if (!service._enabled) return
            _statusStdout = []
            statusProcess.command = ["iwctl", "station", service.interface_, "show"]
            statusProcess.running = true
        }
    }

    property var _enabledWatch: Connections {
        target: Config
        function onWifiEnabledChanged() {
            if (!Config.wifiEnabled) {
                service._statusTimer.stop()
                service.networks = []
                service.connectedSsid = ""
                service.connectedSignal = 0
                service.networksUpdated()
            } else if (service.running && service.interface_) {
                service.scan()
            }
        }
    }

    
    function _parseNetworks(raw) {
        
        var clean = raw.replace(/\x1b\[[0-9;]*m/g, "")
        var lines = clean.split("\n")
        var result = []

        for (var i = 4; i < lines.length; i++) {
            var line = lines[i]
            if (!line || line.indexOf("---") !== -1) continue

            var connected = false
            if (line.length > 4 && line.substring(0, 6).indexOf(">") !== -1)
                connected = true

            
            var stars = 0
            for (var c = 0; c < line.length; c++) {
                if (line[c] === '*') stars++
            }
            var signal = stars * 25

            
            var content = line.substring(6)
            var ssid = content.substring(0, 32).trim()
            var security = content.substring(32, 52).trim()

            if (!ssid) continue

            result.push({
                ssid: ssid,
                security: security,
                signal: signal,
                connected: connected,
                known: !!service.knownSsids[ssid]
            })
        }

        networks = result
        networksUpdated()
    }

    function _parseKnown(raw) {
        var clean = raw.replace(/\x1b\[[0-9;]*m/g, "")
        var lines = clean.split("\n")
        var seen = ({})
        for (var i = 0; i < lines.length; i++) {
            var line = lines[i]
            if (!line) continue
            if (line.indexOf("---") !== -1) continue
            if (line.indexOf("Known Networks") !== -1) continue
            if (line.indexOf("Network name") !== -1 && line.indexOf("Security") !== -1) continue
            var parts = line.trim().split(/\s{2,}/)
            if (parts.length >= 2 && parts[0]) {
                var sec = parts[1].toLowerCase()
                if (sec === "psk" || sec === "open" || sec === "8021x" || sec === "wep") {
                    seen[parts[0]] = true
                }
            }
        }
        service.knownSsids = seen

        if (service.networks && service.networks.length > 0) {
            var updated = service.networks.map(function(n) {
                return {
                    ssid: n.ssid,
                    security: n.security,
                    signal: n.signal,
                    connected: n.connected,
                    known: !!seen[n.ssid]
                }
            })
            service.networks = updated
            service.networksUpdated()
        }
    }

    function forgetNetwork(ssid) {
        if (!ssid) return
        _forgetProcess.command = ["iwctl", "known-networks", ssid, "forget"]
        _forgetProcess.running = true
    }

    property var _forgetProcess: Process {
        id: forgetProcess
        onExited: service.scan()
    }

    function _parseStatus(raw) {
        var clean = raw.replace(/\x1b\[[0-9;]*m/g, "")
        var lines = clean.split("\n")

        for (var i = 0; i < lines.length; i++) {
            var line = lines[i].trim()
            if (line.indexOf("Connected network") !== -1) {
                var parts = line.split(/\s{2,}/)
                if (parts.length >= 2) connectedSsid = parts[parts.length - 1].trim()
            }
            if (line.indexOf("RSSI") !== -1) {
                var match = line.match(/-?\d+/)
                if (match) connectedSignal = Math.abs(parseInt(match[0]))
            }
        }
    }

    
    onRunningChanged: {
        if (running && _enabled && interface_) {
            scan()
            _statusStdout = []
            statusProcess.command = ["iwctl", "station", interface_, "show"]
            statusProcess.running = true
        } else if (!running) {
            _statusTimer.stop()
        }
    }
}
