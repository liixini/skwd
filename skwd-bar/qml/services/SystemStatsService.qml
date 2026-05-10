pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import ".."


QtObject {
    id: service

    
    property real cpuUsage: 0
    property real memUsage: 0
    property real gpuUsage: 0
    property real cpuTemp: 0
    property real gpuTemp: 0
    property real storageUsage: 0
    property string storageUsed: "0G"
    property string storageTotal: "0G"
    property string storageAvail: "0G"

    property bool running: false

    
    property real _prevIdle: 0
    property real _prevTotal: 0

    
    property string _gpuVendor: ""

    
    property string _gpuBusyPath: ""
    property string _gpuTempPath: ""
    property string _cpuTempPath: ""

    
    readonly property int _fastMs: 3000
    readonly property int _slowMs: 30000
    property int _slowCounter: 0

    
    property var _procStat: FileView { path: "/proc/stat"; preload: false }
    property var _procMem: FileView { path: "/proc/meminfo"; preload: false }

    
    property var _gpuBusyFile: FileView { path: service._gpuBusyPath; preload: false }
    property var _gpuTempFile: FileView { path: service._gpuTempPath; preload: false }
    property var _cpuTempFile: FileView { path: service._cpuTempPath; preload: false }

    
    property var _dfProcess: Process {
        id: dfProcess
        command: ["df", "-h", "/"]
        onExited: {
            var text = _dfStdout.join("")
            var lines = text.split("\n")
            if (lines.length >= 2) {
                var cols = lines[1].trim().split(/\s+/)
                if (cols.length >= 5) {
                    service.storageUsage = parseFloat(cols[4]) || 0
                    service.storageUsed = cols[2] || "0G"
                    service.storageTotal = cols[1] || "0G"
                    service.storageAvail = cols[3] || "0G"
                }
            }
        }
        stdout: SplitParser {
            splitMarker: ""
            onRead: data => _dfStdout.push(data)
        }
    }
    property var _dfStdout: []

    
    property var _nvidiaSmiProcess: Process {
        id: nvidiaSmiProcess
        command: ["nvidia-smi", "--query-gpu=utilization.gpu,temperature.gpu",
                  "--format=csv,noheader,nounits"]
        onExited: {
            var text = _nvidiaSmiStdout.join("").trim()
            if (text) {
                var parts = text.split(",")
                if (parts.length >= 2) {
                    service.gpuUsage = parseFloat(parts[0]) || 0
                    service.gpuTemp = parseFloat(parts[1]) || 0
                }
            }
        }
        stdout: SplitParser {
            splitMarker: ""
            onRead: data => _nvidiaSmiStdout.push(data)
        }
    }
    property var _nvidiaSmiStdout: []

    
    property var _gpuDetect: Process {
        id: gpuDetect
        command: ["sh", "-c",
            "if [ -d /sys/module/nvidia ]; then echo nvidia; " +
            "elif ls /sys/class/drm/card*/device/gpu_busy_percent 2>/dev/null | head -1; then echo amd; " +
            "else echo intel; fi"]
        onExited: {
            var vendor = _gpuDetectStdout.join("").trim()
            
            if (vendor.startsWith("/sys")) {
                service._gpuVendor = "amd"
                service._gpuBusyPath = vendor
            } else {
                service._gpuVendor = vendor
            }
            _discoverSensorPaths()
        }
        stdout: SplitParser {
            splitMarker: ""
            onRead: data => _gpuDetectStdout.push(data)
        }
    }
    property var _gpuDetectStdout: []

    
    property var _sensorDiscover: Process {
        id: sensorDiscover
        command: ["sh", "-c",
            
            "for f in /sys/class/drm/card*/device/gpu_busy_percent; do [ -f \"$f\" ] && echo \"gpu_busy:$f\" && break; done; " +
            "for f in /sys/class/drm/card*/device/hwmon/hwmon*/temp1_input; do [ -f \"$f\" ] && echo \"gpu_temp:$f\" && break; done; " +
            "for f in /sys/class/hwmon/hwmon*/temp1_input; do [ -f \"$f\" ] || continue; " +
            "lf=\"${f%_input}_label\"; [ -f \"$lf\" ] || continue; " +
            "l=$(cat \"$lf\" 2>/dev/null); " +
            "case \"$l\" in Tctl|Tdie|\"Package id 0\"|CPU*) echo \"cpu_temp:$f\"; break;; esac; done; " +
            "[ -f /sys/class/thermal/thermal_zone0/temp ] && echo \"cpu_temp_fallback:/sys/class/thermal/thermal_zone0/temp\""]
        onExited: {
            var text = _sensorDiscoverStdout.join("")
            var lines = text.trim().split("\n")
            var cpuFound = false
            for (var i = 0; i < lines.length; i++) {
                var kv = lines[i].split(":")
                if (kv.length < 2) continue
                var key = kv[0]
                var path = kv.slice(1).join(":")
                if (key === "gpu_busy" && !service._gpuBusyPath)
                    service._gpuBusyPath = path
                else if (key === "gpu_temp")
                    service._gpuTempPath = path
                else if (key === "cpu_temp" && !cpuFound) {
                    service._cpuTempPath = path
                    cpuFound = true
                } else if (key === "cpu_temp_fallback" && !cpuFound)
                    service._cpuTempPath = path
            }
        }
        stdout: SplitParser {
            splitMarker: ""
            onRead: data => _sensorDiscoverStdout.push(data)
        }
    }
    property var _sensorDiscoverStdout: []

    function _discoverSensorPaths() {
        _sensorDiscoverStdout = []
        sensorDiscover.running = true
    }

    
    property var _pollTimer: Timer {
        interval: service._fastMs
        repeat: true
        running: service.running
        onTriggered: service._poll()
    }

    
    property var _storagePollTimer: Timer {
        interval: service._slowMs
        repeat: true
        running: service.running
        onTriggered: service._pollStorage()
    }

    function _poll() {
        _readCpu()
        _readMem()
        _readGpu()
        _readTemps()
    }

    function _pollStorage() {
        _dfStdout = []
        dfProcess.running = true
    }

    function _readCpu() {
        _procStat.reload()
        var text = _procStat.text()
        if (!text) return
        var line = text.split("\n")[0]
        if (!line || !line.startsWith("cpu ")) return
        var fields = line.trim().split(/\s+/)
        if (fields.length < 8) return
        
        var user = parseInt(fields[1]) || 0
        var nice = parseInt(fields[2]) || 0
        var system = parseInt(fields[3]) || 0
        var idle = parseInt(fields[4]) || 0
        var iowait = parseInt(fields[5]) || 0
        var irq = parseInt(fields[6]) || 0
        var softirq = parseInt(fields[7]) || 0
        var steal = parseInt(fields[8]) || 0

        var total = user + nice + system + idle + iowait + irq + softirq + steal
        var dIdle = idle - _prevIdle
        var dTotal = total - _prevTotal
        _prevIdle = idle
        _prevTotal = total

        if (dTotal > 0)
            cpuUsage = Math.round((dTotal - dIdle) * 100 / dTotal)
        else
            cpuUsage = 0
    }

    function _readMem() {
        _procMem.reload()
        var text = _procMem.text()
        if (!text) return
        var total = 0, available = 0
        var lines = text.split("\n")
        for (var i = 0; i < lines.length; i++) {
            if (lines[i].startsWith("MemTotal:"))
                total = parseInt(lines[i].split(/\s+/)[1]) || 0
            else if (lines[i].startsWith("MemAvailable:"))
                available = parseInt(lines[i].split(/\s+/)[1]) || 0
        }
        if (total > 0)
            memUsage = Math.round((total - available) * 100 / total)
    }

    function _readGpu() {
        if (_gpuVendor === "nvidia") {
            _nvidiaSmiStdout = []
            nvidiaSmiProcess.running = true
        } else if (_gpuVendor === "amd" && _gpuBusyPath) {
            _gpuBusyFile.reload()
            var val = _gpuBusyFile.text().trim()
            if (val) gpuUsage = parseInt(val) || 0
        }
        
    }

    function _readTemps() {
        
        if (_gpuVendor === "amd" && _gpuTempPath) {
            _gpuTempFile.reload()
            var gt = _gpuTempFile.text().trim()
            if (gt) gpuTemp = Math.round((parseInt(gt) || 0) / 1000)
        }

        
        if (_cpuTempPath) {
            _cpuTempFile.reload()
            var ct = _cpuTempFile.text().trim()
            if (ct) cpuTemp = Math.round((parseInt(ct) || 0) / 1000)
        }
    }

    
    Component.onCompleted: running = true

    onRunningChanged: {
        if (running) {
            _gpuDetectStdout = []
            gpuDetect.running = true
            
            Qt.callLater(function() {
                _poll()
                _pollStorage()
            })
        }
    }
}
