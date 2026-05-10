import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Mpris
import Quickshell.Io

import "qml"
import "qml/services" as Services
import "qml/player" as Player

ShellRoot {
    id: root

    property bool showing: false

    property var activePlayer: {
        if (!Mpris.players) return null
        let preferred = null
        let fallback = null
        for (let i = 0; i < Mpris.players.values.length; i++) {
            let player = Mpris.players.values[i]
            let id = (player.identity || "").toLowerCase()
            if (id.includes("librespot") || id.includes("spotify")) {
                if (player.isPlaying) return player
                preferred = player
            } else if (player.isPlaying && !fallback) {
                fallback = player
            }
        }
        return preferred || fallback || null
    }

    Services.LibrespotService { id: librespotService }

    Services.SpotifyAuth {
        id: spotifyAuth
        clientId: Config.spotifyClientId
    }

    Services.SpotifyApi {
        id: spotifyApi
        auth: spotifyAuth
    }

    IpcHandler {
        target: "music"

        function toggle() {
            root.showing = !root.showing
        }

        function open() {
            root.showing = true
        }

        function close() {
            root.showing = false
        }
    }

    PanelWindow {
        id: panel

        screen: Quickshell.screens.find(s => s.name === "DP-1") ?? Quickshell.screens[0]
        visible: root.showing
        color: "transparent"

        WlrLayershell.namespace: "skwd-music"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: root.showing ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }
        margins {
            top: 0
            bottom: 0
            left: 0
            right: 0
        }
        exclusionMode: ExclusionMode.Ignore

        
        Rectangle {
            anchors.fill: parent
            color: Qt.rgba(0, 0, 0, 0.5)
            opacity: root.showing ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 300 } }
        }

        
        MouseArea {
            anchors.fill: parent
            onClicked: root.showing = false
        }

        
        Shortcut {
            sequence: "Escape"
            onActivated: root.showing = false
        }

        
        Shortcut {
            sequence: "Space"
            onActivated: if (musicPlayer.player) musicPlayer.player.togglePlaying()
        }

        
        FocusScope {
            id: keyHandler
            anchors.fill: parent
            focus: root.showing

            Connections {
                target: musicPlayer
                function onPlaylistOpenChanged() { if (!musicPlayer.playlistOpen) keyHandler.forceActiveFocus() }
                function onPlaylistsOpenChanged() { if (!musicPlayer.playlistsOpen) keyHandler.forceActiveFocus() }
                function onArtistSearchOpenChanged() { if (!musicPlayer.artistSearchOpen) keyHandler.forceActiveFocus() }
                function onPlaylistSearchOpenChanged() { if (!musicPlayer.playlistSearchOpen) keyHandler.forceActiveFocus() }
            }

            Keys.onPressed: event => {
                let shift = event.modifiers & Qt.ShiftModifier
                if (event.key === Qt.Key_Left) {
                    if (shift) {
                        musicPlayer.togglePlaylist()
                    } else if (musicPlayer.player) {
                        musicPlayer.player.previous()
                    }
                    event.accepted = true
                } else if (event.key === Qt.Key_Right) {
                    if (shift) {
                        musicPlayer.togglePlaylists()
                    } else if (musicPlayer.player) {
                        musicPlayer.player.next()
                    }
                    event.accepted = true
                } else if (event.key === Qt.Key_Down && shift) {
                    musicPlayer.togglePlaylistSearch()
                    event.accepted = true
                } else if (event.key === Qt.Key_Up && shift) {
                    musicPlayer.toggleArtistSearch()
                    event.accepted = true
                } else if (event.key === Qt.Key_Space && shift) {
                    musicPlayer.toggleLike()
                    event.accepted = true
                }
            }
        }


        Player.MusicPlayer {
            id: musicPlayer
            anchors.centerIn: parent
            player: root.activePlayer
            librespotService: librespotService
            spotifyAuth: spotifyAuth
            spotifyApi: spotifyApi
            showing: root.showing
        }
    }
}
