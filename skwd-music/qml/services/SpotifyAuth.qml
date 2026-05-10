import QtQuick

QtObject {
    id: auth

    property string clientId: ""

    property bool authenticated: false
    property bool authorizing: false
    property real expiresAtSecs: 0

    readonly property string accessToken: authenticated ? "daemon" : ""

    function authorize() {
        if (!clientId) {
            console.warn("skwd-music: SpotifyAuth.clientId not set")
            return
        }
        auth.authorizing = true
        DaemonClient.call("music.auth.start", { clientId: clientId }, function(result, err) {
            if (err) {
                console.warn("auth.start error:", JSON.stringify(err))
                auth.authorizing = false
                return
            }
            if (result && result.authorizeUrl) Qt.openUrlExternally(result.authorizeUrl)
        })
    }

    function logout() {
        DaemonClient.call("music.auth.logout", {}, function() {
            auth.authenticated = false
            auth.expiresAtSecs = 0
        })
    }

    function _refreshStatus() {
        DaemonClient.call("music.auth.status", {}, function(result, err) {
            if (err || !result) return
            auth.authenticated = !!result.authenticated
            auth.expiresAtSecs = result.expiresAtSecs || 0
        })
    }

    property var _events: Connections {
        target: DaemonClient
        function onEventReceived(event, data) {
            if (event === "skwd.music.auth.done") {
                auth.authenticated = !!(data && data.authenticated)
                auth.authorizing = false
                if (data && data.expires_at_secs) auth.expiresAtSecs = data.expires_at_secs
            }
        }
    }

    property var _pollTimer: Timer {
        interval: 1500
        repeat: true
        running: !auth.authenticated
        onTriggered: auth._refreshStatus()
    }

    Component.onCompleted: _refreshStatus()
}
