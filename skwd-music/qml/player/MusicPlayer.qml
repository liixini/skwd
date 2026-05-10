import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell.Services.Mpris

import ".." as Root
import "../components" as Components
import "../services" as Services

Item {
    id: musicPlayer

    property var player: null
    property var librespotService: null
    property var spotifyAuth: null
    property var spotifyApi: null
    property bool showing: false

    width: 380
    height: 480

    property bool playlistOpen: false
    property bool playlistsOpen: false
    property bool artistSearchOpen: false
    property bool playlistSearchOpen: false

    function togglePlaylist() {
        playlistsOpen = false
        artistSearchOpen = false
        playlistSearchOpen = false
        playlistOpen = !playlistOpen
    }

    function togglePlaylists() {
        playlistOpen = false
        artistSearchOpen = false
        playlistSearchOpen = false
        playlistsOpen = !playlistsOpen
    }

    function toggleArtistSearch() {
        playlistOpen = false
        playlistsOpen = false
        playlistSearchOpen = false
        artistSearchOpen = !artistSearchOpen
    }

    function togglePlaylistSearch() {
        playlistOpen = false
        playlistsOpen = false
        artistSearchOpen = false
        playlistSearchOpen = !playlistSearchOpen
    }

    function toggleLike() {
        if (spotifyApi) spotifyApi.toggleLike()
    }

    Services.MprisService {
        id: mpris
        player: musicPlayer.player
    }

    property string _artKey: mpris.trackTitle + "|" + mpris.trackArtist
    on_ArtKeyChanged: {
        if (spotifyApi && mpris.trackTitle) {
            spotifyApi.fetchArt(mpris.trackTitle, mpris.trackArtist)
        } else if (spotifyApi) {
            spotifyApi.clearArt()
        }
    }

    Connections {
        target: spotifyApi
        function onArtTrackIdChanged() {
            if (spotifyApi.artTrackId) spotifyApi.checkLiked(spotifyApi.artTrackId)
        }
    }

    readonly property url _bestArtUrl: {
        if (spotifyApi && spotifyApi.artUrl != "") return spotifyApi.artUrl
        return mpris.trackArtUrl
    }


    opacity: 0
    onShowingChanged: {
        if (showing) {
            fadeIn.stop(); opacity = 0; fadeIn.start()
        } else {
            playlistOpen = false
            playlistsOpen = false
            artistSearchOpen = false
            playlistSearchOpen = false
        }
    }
    NumberAnimation {
        id: fadeIn; target: musicPlayer; property: "opacity"
        from: 0; to: 1; duration: 400; easing.type: Easing.OutCubic
    }

    
    Rectangle {
        id: card
        anchors.fill: parent
        radius: Root.Style.radiusXLarge
        color: Root.Colors.surfaceContainer
        clip: true
        layer.enabled: true
        layer.smooth: true
        layer.effect: MultiEffect {
            maskEnabled: true
            maskSource: mask
            shadowEnabled: true
            shadowColor: Qt.rgba(0, 0, 0, 0.55)
            shadowHorizontalOffset: 0
            shadowVerticalOffset: 8
            shadowBlur: 1.0
            shadowScale: 1.02
        }

        
        MouseArea {
            anchors.fill: parent
            onClicked: function(mouse) { mouse.accepted = true }
        }

        
        Image {
            id: artImage
            anchors.fill: parent
            source: musicPlayer._bestArtUrl
            fillMode: Image.PreserveAspectCrop
            smooth: true
        }

        
        Text {
            anchors.centerIn: parent
            text: "\u{F075A}"
            font.family: Root.Style.iconFont
            font.pixelSize: 80
            color: Root.Colors.surfaceVariantText
            visible: artImage.status !== Image.Ready
        }

        
        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: parent.height * 0.65
            gradient: Gradient {
                GradientStop { position: 0.0; color: "transparent" }
                GradientStop { position: 0.35; color: Qt.rgba(0, 0, 0, 0.55) }
                GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.85) }
            }
        }

        
        ColumnLayout {
            anchors {
                left: parent.left
                right: parent.right
                bottom: parent.bottom
                margins: Root.Style.spacingXLarge
            }
            spacing: Root.Style.spacingMedium

            
            RowLayout {
                Layout.fillWidth: true
                spacing: Root.Style.spacingSmall

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    Text {
                        Layout.fillWidth: true
                        text: mpris.trackTitle || "No track playing"
                        font.family: Root.Style.fontFamily
                        font.pixelSize: Root.Style.fontLarge
                        font.weight: Font.DemiBold
                        color: "#ffffff"
                        elide: Text.ElideRight
                        horizontalAlignment: Text.AlignHCenter
                    }

                    Text {
                        Layout.fillWidth: true
                        text: mpris.trackArtist || "\u2014"
                        font.family: Root.Style.fontFamily
                        font.pixelSize: Root.Style.fontNormal
                        color: Qt.rgba(1, 1, 1, 0.7)
                        elide: Text.ElideRight
                        horizontalAlignment: Text.AlignHCenter
                    }

                    Text {
                        Layout.fillWidth: true
                        text: mpris.trackAlbum
                        font.family: Root.Style.fontFamily
                        font.pixelSize: Root.Style.fontSmall
                        color: Qt.rgba(1, 1, 1, 0.5)
                        elide: Text.ElideRight
                        horizontalAlignment: Text.AlignHCenter
                        visible: mpris.trackAlbum !== ""
                    }
                }

                
                Text {
                    text: spotifyApi?.currentTrackLiked ? "\u{F02D1}" : "\u{F02D5}"
                    font.family: Root.Style.iconFont
                    font.pixelSize: Root.Style.fontLarge
                    color: spotifyApi?.currentTrackLiked ? Root.Colors.primary : Qt.rgba(1, 1, 1, 0.6)
                    visible: spotifyApi?.artTrackId ? true : false

                    Behavior on color { ColorAnimation { duration: 200 } }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: { if (spotifyApi) spotifyApi.toggleLike() }
                    }
                }
            }

            
            Components.ProgressBar {
                Layout.fillWidth: true
                position: mpris.position
                duration: mpris.trackLength
                canSeek: mpris.canSeek
                onSeekRequested: pos => mpris.seek(pos)
            }

            
            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: Root.Style.spacingSmall

                Components.IconButton {
                    icon: "\u{F049D}"
                    iconSize: Root.Style.fontMedium
                    active: mpris.shuffle
                    onClicked: mpris.toggleShuffle()
                }

                Components.IconButton {
                    icon: "\u{F04AE}"
                    iconSize: Root.Style.fontXLarge
                    enabled: mpris.canGoPrevious
                    onClicked: mpris.previous()
                }

                
                Rectangle {
                    width: 52; height: 52; radius: 26
                    color: Qt.rgba(1, 1, 1, 0.15)

                    Text {
                        anchors.centerIn: parent
                        text: mpris.isPlaying ? "\u{F03E4}" : "\u{F040A}"
                        font.family: Root.Style.iconFont
                        font.pixelSize: Root.Style.fontXLarge
                        color: "#ffffff"
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: mpris.playPause()
                    }
                }

                Components.IconButton {
                    icon: "\u{F04AD}"
                    iconSize: Root.Style.fontXLarge
                    enabled: mpris.canGoNext
                    onClicked: mpris.next()
                }

                Components.IconButton {
                    icon: {
                        switch (mpris.loopStatus) {
                            case MprisLoopState.Track:    return "\u{F0458}"
                            case MprisLoopState.Playlist: return "\u{F0456}"
                            default:                      return "\u{F0456}"
                        }
                    }
                    iconSize: Root.Style.fontMedium
                    active: mpris.loopStatus !== MprisLoopState.None
                    onClicked: mpris.cycleLoop()
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Root.Style.spacingSmall

                property real _localVolume: mpris.volume
                property bool _dragging: false

                Connections {
                    target: mpris
                    function onVolumeChanged() {
                        if (!parent._dragging) parent._localVolume = mpris.volume
                    }
                }

                Text {
                    text: parent._localVolume < 0.01 ? "\u{F075F}"
                        : (parent._localVolume < 0.5 ? "\u{F0580}" : "\u{F057E}")
                    font.family: Root.Style.iconFont
                    font.pixelSize: Root.Style.fontMedium
                    color: Qt.rgba(1, 1, 1, 0.6)
                }

                Item {
                    id: volumeBar
                    Layout.fillWidth: true
                    height: 18

                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.right: parent.right
                        height: 4
                        radius: 2
                        color: Qt.rgba(1, 1, 1, 0.15)
                    }

                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        height: 4
                        radius: 2
                        width: parent.width * Math.max(0, Math.min(1, parent.parent._localVolume))
                        color: Root.Colors.primary
                    }

                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        x: Math.max(0, Math.min(parent.width - width, parent.width * parent.parent._localVolume - width / 2))
                        width: 12; height: 12; radius: 6
                        color: "#ffffff"
                        border.color: Root.Colors.primary
                        border.width: 1
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        property real _pendingVolume: 0
                        onPressed: function(ev) {
                            parent.parent._dragging = true
                            var v = Math.max(0, Math.min(1, ev.x / parent.width))
                            parent.parent._localVolume = v
                            _pendingVolume = v
                        }
                        onPositionChanged: function(ev) {
                            if (!pressed) return
                            var v = Math.max(0, Math.min(1, ev.x / parent.width))
                            parent.parent._localVolume = v
                            _pendingVolume = v
                        }
                        onReleased: {
                            mpris.setVolume(_pendingVolume)
                            parent.parent._dragging = false
                        }
                    }
                }
            }


            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: Root.Style.spacingSmall
                visible: spotifyAuth !== null

                Rectangle {
                    width: 6; height: 6; radius: 3
                    color: spotifyAuth.authenticated ? Root.Colors.primary : Qt.rgba(1, 1, 1, 0.4)
                }

                Text {
                    text: spotifyAuth.authenticated ? "Spotify linked" : "Spotify API not linked"
                    font.family: Root.Style.fontFamily
                    font.pixelSize: Root.Style.fontTiny
                    color: Qt.rgba(1, 1, 1, 0.5)
                }

                Components.IconButton {
                    icon: spotifyAuth.authenticated ? "\u{F0453}" : "\u{F0338}"
                    iconSize: Root.Style.fontSmall
                    onClicked: {
                        spotifyAuth.logout()
                        spotifyAuth.authorize()
                    }
                }
            }
        }

        
        PlaylistPanel {
            id: playlistPanel
            anchors.fill: parent
            spotifyApi: musicPlayer.spotifyApi
            open: musicPlayer.playlistOpen
            currentTrackTitle: mpris.trackTitle
            onTrackClicked: uri => {
                if (spotifyApi) spotifyApi.playTrack(uri, spotifyApi._contextUri)
            }
            onCloseRequested: musicPlayer.playlistOpen = false
        }

        
        PlaylistsPanel {
            id: playlistsPanel
            anchors.fill: parent
            spotifyApi: musicPlayer.spotifyApi
            open: musicPlayer.playlistsOpen
            onPlaylistSelected: (uri, id, name) => {
                if (spotifyApi) spotifyApi.playContext(uri)
                musicPlayer.playlistsOpen = false
                musicPlayer.playlistOpen = true
            }
            onCloseRequested: musicPlayer.playlistsOpen = false
        }

        
        ArtistSearchPanel {
            id: artistSearchPanel
            anchors.fill: parent
            spotifyApi: musicPlayer.spotifyApi
            open: musicPlayer.artistSearchOpen
            onArtistSelected: (uri, name) => {
                if (spotifyApi) spotifyApi.playArtist(uri)
                musicPlayer.artistSearchOpen = false
            }
            onCloseRequested: musicPlayer.artistSearchOpen = false
        }

        
        PlaylistSearchPanel {
            id: playlistSearchPanel
            anchors.fill: parent
            spotifyApi: musicPlayer.spotifyApi
            open: musicPlayer.playlistSearchOpen
            onPlaylistSelected: (uri, id, name) => {
                if (spotifyApi) spotifyApi.playContext(uri)
                musicPlayer.playlistSearchOpen = false
                musicPlayer.playlistOpen = true
            }
            onCloseRequested: musicPlayer.playlistSearchOpen = false
        }
    }

    
    Item {
        id: mask
        width: card.width
        height: card.height
        layer.enabled: true
        visible: false

        Rectangle {
            anchors.fill: parent
            radius: Root.Style.radiusXLarge
            color: "white"
        }
    }

    
    Rectangle {
        anchors.fill: parent
        radius: Root.Style.radiusXLarge
        color: "transparent"
        border.color: Qt.rgba(1, 1, 1, 0.08)
        border.width: 1
    }
}
