pragma Singleton
import QtQuick
import Quickshell.Io
import ".."


QtObject {
    id: service

    readonly property string fifoPath: Config.runtimeDir + "/cmd"

    
    signal lockRequested()
    signal powerMenuRequested()
    signal launcherRequested()
    signal toggleBarRequested()
    signal wallpaperRequested()
    signal smartHomeRequested()
    signal switcherOpen()
    signal switcherNext()
    signal switcherPrev()
    signal switcherConfirm()
    signal switcherCancel()
    signal switcherClose()
    signal notificationsRequested()
    signal configRequested()

    
    property var _setupProcess: Process {
        id: setupProcess
        command: ["sh", "-c",
            "FIFO=" + JSON.stringify(service.fifoPath) + "; " +
            "mkdir -p \"$(dirname \"$FIFO\")\"; " +
            "PIDFILE=\"${FIFO}.pid\"; " +
            "[ -f \"$PIDFILE\" ] && while IFS= read -r p; do kill \"$p\" 2>/dev/null; done < \"$PIDFILE\"; " +
            "rm -f \"$PIDFILE\"; " +
            "fuser -k \"$FIFO\" 2>/dev/null; sleep 0.1; " +
            "rm -f \"$FIFO\"; mkfifo -m 600 \"$FIFO\"; " +
            "echo $$ > \"$PIDFILE\""]
        onExited: _reader.running = true
    }

    
    property var _reader: Process {
        id: reader
        command: ["sh", "-c",
            "trap 'exit 0' TERM HUP INT; " +
            "while true; do cat " + JSON.stringify(service.fifoPath) + "; done"]
        onExited: _restartTimer.start()
        stdout: SplitParser {
            onRead: message => service._dispatch(message.trim())
        }
    }

    property var _restartTimer: Timer {
        id: restartTimer
        interval: 1000
        onTriggered: reader.running = true
    }

    function start() {
        setupProcess.running = true
    }

    function _dispatch(cmd) {
        if (!cmd) return
        console.log("IPC received:", cmd)
        switch (cmd) {
        case "lock": lockRequested(); break
        case "powermenu": powerMenuRequested(); break
        case "launcher":
        case "applauncher": launcherRequested(); break
        case "toggleBar": toggleBarRequested(); break
        case "wallpaper": wallpaperRequested(); break
        case "smarthome": smartHomeRequested(); break
        case "switcherOpen": switcherOpen(); break
        case "switcherNext": switcherNext(); break
        case "switcherPrev": switcherPrev(); break
        case "switcherConfirm": switcherConfirm(); break
        case "switcherCancel": switcherCancel(); break
        case "switcherClose": switcherClose(); break
        case "notifications": notificationsRequested(); break
        case "config": configRequested(); break
        default: console.log("IPC: unknown command:", cmd)
        }
    }
}
