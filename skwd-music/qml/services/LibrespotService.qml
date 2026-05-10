import QtQuick

QtObject {
    id: service

    property bool running: false

    function start() {
        DaemonClient.call("music.player.start", {}, function(result, err) {
            if (err) {
                console.warn("music.player.start error:", JSON.stringify(err))
                service.running = false
            } else {
                service.running = true
            }
        })
    }

    function stop() {
        DaemonClient.call("music.player.stop", {}, function() { service.running = false })
    }

    function restart() { stop(); _restartTimer.start() }

    property var _restartTimer: Timer {
        interval: 500
        repeat: false
        onTriggered: service.start()
    }

    property var _authEvents: Connections {
        target: DaemonClient
        function onEventReceived(event, data) {
            if (event === "skwd.music.auth.done" && !service.running) {
                _restartTimer.start()
            }
        }
    }

    Component.onCompleted: service.start()
}
