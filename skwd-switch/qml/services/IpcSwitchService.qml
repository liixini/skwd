pragma Singleton
import QtQuick
import Quickshell.Io
import ".."


QtObject {
    id: service

    readonly property string fifoPath: Config.runtimeDir + "/switch-cmd"

    signal switchOpen()
    signal switchNext()
    signal switchPrev()
    signal switchConfirm()
    signal switchCancel()
    signal switchClose()

    property var _setupProcess: Process {
        id: setupProcess
        command: ["sh", "-c",
            "FIFO=" + JSON.stringify(service.fifoPath) + "; " +
            "mkdir -p \"$(dirname \"$FIFO\")\"; " +
            "rm -f \"$FIFO\"; mkfifo -m 600 \"$FIFO\""]
        onExited: _reader.running = true
    }

    property var _reader: Process {
        id: reader
        command: ["cat", service.fifoPath]
        onExited: _restartTimer.start()
        stdout: SplitParser {
            onRead: message => service._dispatch(message.trim())
        }
    }

    property var _restartTimer: Timer {
        id: restartTimer
        interval: 100
        onTriggered: reader.running = true
    }

    function start() {
        setupProcess.running = true
    }

    function _dispatch(cmd) {
        if (!cmd) return
        switch (cmd) {
        case "open": switchOpen(); break
        case "next": switchNext(); break
        case "prev": switchPrev(); break
        case "confirm": switchConfirm(); break
        case "cancel": switchCancel(); break
        case "close": switchClose(); break
        }
    }
}
