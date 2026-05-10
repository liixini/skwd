import QtQuick

QtObject {
    id: api

    property var auth: null

    property url artUrl: ""
    property string artTrackId: ""

    property var queueTracks: []
    property string contextName: ""
    property string currentTrackUri: ""
    property bool queueLoading: false

    property var userPlaylists: []
    property bool playlistsLoading: false

    property bool currentTrackLiked: false

    property var searchArtists: []
    property bool artistSearchLoading: false
    property var searchPlaylists: []
    property bool playlistSearchLoading: false

    property string _contextUri: ""

    function _ready() { return auth && auth.authenticated }

    property var _authWatch: Connections {
        target: api.auth
        function onAuthenticatedChanged() {
            if (api.auth && api.auth.authenticated) {
                api.fetchUserPlaylists()
            } else {
                api.userPlaylists = []
                api.searchArtists = []
                api.searchPlaylists = []
                api.queueTracks = []
                api.clearArt()
            }
        }
    }

    function fetchArt(title, artist) {
        if (!_ready() || !title) return
        DaemonClient.call("music.search", {
            q: artist ? (title + " " + artist) : title,
            types: ["track"],
            limit: 1
        }, function(result, err) {
            if (err || !result) return
            var items = result.tracks && result.tracks.items ? result.tracks.items : []
            if (items.length === 0) { api.clearArt(); return }
            var t = items[0]
            api.artTrackId = t.id || ""
            var imgs = t.album && t.album.images ? t.album.images : []
            api.artUrl = imgs.length > 0 ? imgs[0].url : ""
            if (api.artTrackId) api.checkLiked(api.artTrackId)
        })
    }

    function clearArt() { api.artUrl = ""; api.artTrackId = ""; api.currentTrackLiked = false }

    function checkLiked(trackId) {
        if (!_ready() || !trackId) return
        DaemonClient.call("music.like.check", { ids: [trackId] }, function(result, err) {
            if (err || !Array.isArray(result)) return
            api.currentTrackLiked = !!result[0]
        })
    }

    function toggleLike() {
        if (!_ready() || !api.artTrackId) return
        var setLiked = !api.currentTrackLiked
        DaemonClient.call("music.like.set", { ids: [api.artTrackId], liked: setLiked }, function(result, err) {
            if (!err) api.currentTrackLiked = setLiked
        })
    }

    function playTrack(trackUri, contextUri) {
        if (!_ready()) return
        if (contextUri) {
            DaemonClient.call("music.play.context", { contextUri: contextUri, offsetUri: trackUri }, function() {})
        } else {
            DaemonClient.call("music.play.uris", { uris: [trackUri] }, function() {})
        }
    }

    function playContext(contextUri) {
        if (!_ready()) return
        DaemonClient.call("music.play.context", { contextUri: contextUri }, function() {})
    }

    function playArtist(artistUri) {
        if (!_ready()) return
        var parts = (artistUri || "").split(":")
        var id = parts[parts.length - 1]
        if (!id) return
        DaemonClient.call("music.artist.top_tracks", { id: id }, function(result, err) {
            if (err || !result) {
                console.warn("artist.top_tracks error:", JSON.stringify(err))
                return
            }
            var uris = (result.tracks || []).map(function(t) { return t.uri }).filter(function(u) { return !!u })
            if (uris.length === 0) return
            DaemonClient.call("music.play.uris", { uris: uris }, function() {})
        })
    }

    function fetchUserPlaylists() {
        if (!_ready()) return
        api.playlistsLoading = true
        DaemonClient.call("music.playlists", {}, function(result, err) {
            api.playlistsLoading = false
            if (err || !result) return
            var items = result.items || []
            var lists = []
            for (var i = 0; i < items.length; i++) {
                var p = items[i]
                if (!p) continue
                var imgs = p.images || []
                var trackCount = 0
                if (p.items && typeof p.items.total === "number") trackCount = p.items.total
                else if (p.tracks && typeof p.tracks.total === "number") trackCount = p.tracks.total
                lists.push({
                    id: p.id,
                    uri: p.uri,
                    name: p.name || "",
                    description: (p.description || "").replace(/<[^>]*>/g, ""),
                    imageUrl: imgs.length > 0 ? imgs[0].url : "",
                    trackCount: trackCount,
                    owner: p.owner && p.owner.display_name ? p.owner.display_name : ""
                })
            }
            api.userPlaylists = lists
        })
    }

    function fetchPlaybackContext(currentUri) {
        if (!_ready()) return
        api.queueLoading = true
        DaemonClient.call("music.queue", {}, function(result, err) {
            api.queueLoading = false
            if (err || !result) return

            var trackList = []
            function pushTrack(t) {
                if (!t) return
                var artists = (t.artists || []).map(function(a) { return a.name }).join(", ")
                var imgs = t.album && t.album.images ? t.album.images : []
                trackList.push({
                    uri: t.uri,
                    name: t.name,
                    artist: artists,
                    album: t.album ? (t.album.name || "") : "",
                    artUrl: imgs.length > 0 ? imgs[imgs.length - 1].url : "",
                    durationMs: t.duration_ms || 0
                })
            }
            pushTrack(result.currently_playing)
            for (var i = 0; i < (result.queue || []).length; i++) pushTrack(result.queue[i])
            api.queueTracks = trackList
            api.contextName = "Up Next"
            if (result.currently_playing && result.currently_playing.uri)
                api.currentTrackUri = result.currently_playing.uri
        })
    }

    property var _refreshOnTrack: Connections {
        target: DaemonClient
        function onEventReceived(event, data) {
            if (event === "skwd.music.track.changed" && api._ready()) {
                api.fetchPlaybackContext(data && data.uri ? data.uri : "")
            }
        }
    }

    function searchArtistsByQuery(query) {
        if (!_ready() || !query) return
        api.artistSearchLoading = true
        DaemonClient.call("music.search", { q: query, types: ["artist"], limit: 10 }, function(result, err) {
            api.artistSearchLoading = false
            if (err || !result) { api.searchArtists = []; return }
            var items = result.artists && result.artists.items ? result.artists.items : []
            api.searchArtists = items.map(function(a) {
                var imgs = a.images || []
                return {
                    id: a.id,
                    uri: a.uri,
                    name: a.name || "",
                    imageUrl: imgs.length > 0 ? imgs[imgs.length - 1].url : "",
                    genres: (a.genres || []).slice(0, 3).join(", "),
                    followers: a.followers && a.followers.total ? a.followers.total : 0
                }
            })
        })
    }

    function searchPlaylistsByQuery(query) {
        if (!_ready() || !query) return
        api.playlistSearchLoading = true
        DaemonClient.call("music.search", { q: query, types: ["playlist"], limit: 10 }, function(result, err) {
            api.playlistSearchLoading = false
            if (err || !result) { api.searchPlaylists = []; return }
            var items = result.playlists && result.playlists.items ? result.playlists.items : []
            api.searchPlaylists = items.filter(function(p) { return !!p }).map(function(p) {
                var imgs = p.images || []
                return {
                    id: p.id,
                    uri: p.uri,
                    name: p.name || "",
                    description: (p.description || "").replace(/<[^>]*>/g, ""),
                    imageUrl: imgs.length > 0 ? imgs[0].url : "",
                    trackCount: p.tracks && p.tracks.total ? p.tracks.total : 0,
                    owner: p.owner && p.owner.display_name ? p.owner.display_name : ""
                }
            })
        })
    }
}
