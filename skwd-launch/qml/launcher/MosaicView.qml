import QtQuick
import QtQuick.Shapes
import ".."


Item {
    id: mosaicView

    property var service
    property var colors
    property bool active: false
    property int requestedCount: Config.mosaicCells
    property int relaxIterations: Config.mosaicRelaxation

    property int _baseSeed: Math.floor(Math.random() * 1e9) + 1

    property real _tileW: width > 0 ? width * 4 : 4
    property int _sitesPerTile: Math.max(1, requestedCount * 4)
    property real _worldX: 0
    property real _velocity: 0
    property int _warmupCount: Math.max(0, Math.min(64,
                              service && service.filteredModel
                                  ? service.filteredModel.count : 0))

    property int hoveredIdx: -1
    property real shardGap: 0.0
    property real minShardPx: 60
    property var _tileCells: []

    property real _stripeAX: 0
    property real _stripeBX: 0
    property int _stripeAOffset: 0
    property int _stripeBOffset: 0
    property real _transitionAlpha: 1.0

    readonly property real _viewportCx: _worldX + width * 0.5
    readonly property real _viewportCy: height * 0.5
    readonly property real _cloudRx: width * 0.46
    readonly property real _cloudRy: height * 0.46
    readonly property real _cloudInnerR2: 0.55
    readonly property real _cloudOuterR2: 1.05

    signal itemActivated(var item)
    clip: false

    onWidthChanged: _hardRebuild()
    onHeightChanged: _hardRebuild()
    onRequestedCountChanged: _hardRebuild()
    onRelaxIterationsChanged: _hardRebuild()
    onActiveChanged: {
        if (active) {
            _baseSeed = Math.floor(Math.random() * 1e9) + 1
            _hardRebuild()
        }
    }

    Connections {
        target: mosaicView.service ? mosaicView.service.filteredModel : null
        function onCountChanged() {
            if (!mosaicView.active) return
            _filterFadeOut.restart()
        }
    }

    NumberAnimation {
        id: _filterFadeOut
        target: mosaicView
        property: "_transitionAlpha"
        to: 0
        duration: Style.animNormal
        easing.type: Easing.InCubic
        onFinished: {
            mosaicView._stripeAX = 0
            mosaicView._stripeBX = mosaicView._tileW
            mosaicView._stripeAOffset = 0
            mosaicView._stripeBOffset = mosaicView._sitesPerTile
            mosaicView._worldX = mosaicView._tileW * 0.5 - mosaicView.width * 0.5
            mosaicView._velocity = 0
            _filterFadeIn.restart()
        }
    }

    NumberAnimation {
        id: _filterFadeIn
        target: mosaicView
        property: "_transitionAlpha"
        to: 1
        duration: Style.animEnter
        easing.type: Easing.OutCubic
    }

    function _hardRebuild() {
        if (!active || width <= 0 || height <= 0) return
        _tileW = width * 4
        _sitesPerTile = Math.max(1, requestedCount * 4)
        _stripeAX = 0
        _stripeBX = _tileW
        _stripeAOffset = 0
        _stripeBOffset = _sitesPerTile
        _worldX = _tileW * 0.5 - width * 0.5
        _velocity = 0
        _transitionAlpha = 1.0
        _rebuildTimer.restart()
    }

    Timer {
        id: _rebuildTimer
        interval: 0
        repeat: false
        onTriggered: mosaicView._buildTile()
    }

    Timer {
        id: kineticTimer
        interval: 16
        repeat: true
        running: Math.abs(mosaicView._velocity) > 0.5 && mosaicView.active
        onTriggered: {
            var dt = 0.016
            mosaicView._applyScroll(mosaicView._velocity * dt)
            mosaicView._velocity *= 0.90
            if (Math.abs(mosaicView._velocity) < 0.5) mosaicView._velocity = 0
        }
    }

    function _applyScroll(dx) {
        _worldX += dx
        var leftCutoff  = _viewportCx - _cloudRx - 40
        var rightCutoff = _viewportCx + _cloudRx + 40

        if (_stripeAX + _tileW < leftCutoff) {
            _stripeAX = _stripeBX + _tileW
            _stripeAOffset = _stripeBOffset + _sitesPerTile
        } else if (_stripeAX > rightCutoff) {
            _stripeAX = _stripeBX - _tileW
            _stripeAOffset = _stripeBOffset - _sitesPerTile
        }

        if (_stripeBX + _tileW < leftCutoff) {
            _stripeBX = _stripeAX + _tileW
            _stripeBOffset = _stripeAOffset + _sitesPerTile
        } else if (_stripeBX > rightCutoff) {
            _stripeBX = _stripeAX - _tileW
            _stripeBOffset = _stripeAOffset - _sitesPerTile
        }
    }

    function _addImpulse(amount) {
        var maxVel = width * 4
        _velocity = Math.max(-maxVel, Math.min(maxVel, _velocity + amount))
    }

    function _mulberry32(a) {
        return function() {
            a |= 0; a = (a + 0x6D2B79F5) | 0
            var t = a
            t = Math.imul(t ^ (t >>> 15), t | 1)
            t ^= t + Math.imul(t ^ (t >>> 7), t | 61)
            return ((t ^ (t >>> 14)) >>> 0) / 4294967296
        }
    }

    function _clipPoly(poly, mx, my, nx, ny) {
        var out = []
        var len = poly.length
        for (var i = 0; i < len; i++) {
            var a = poly[i]
            var b = poly[(i + 1) % len]
            var da = (a[0] - mx) * nx + (a[1] - my) * ny
            var db = (b[0] - mx) * nx + (b[1] - my) * ny
            var ainside = da <= 0
            var binside = db <= 0
            if (ainside) out.push(a)
            if (ainside !== binside) {
                var t = da / (da - db)
                out.push([a[0] + t * (b[0] - a[0]), a[1] + t * (b[1] - a[1])])
            }
        }
        return out
    }

    function _polyBounds(poly) {
        var minX = Infinity, minY = Infinity, maxX = -Infinity, maxY = -Infinity
        for (var i = 0; i < poly.length; i++) {
            var p = poly[i]
            if (p[0] < minX) minX = p[0]
            if (p[1] < minY) minY = p[1]
            if (p[0] > maxX) maxX = p[0]
            if (p[1] > maxY) maxY = p[1]
        }
        return { x: minX, y: minY, w: Math.max(1, maxX - minX), h: Math.max(1, maxY - minY) }
    }

    function _polyCentroid(poly) {
        var a = 0, cx = 0, cy = 0
        var len = poly.length
        if (len < 3) {
            var sx = 0, sy = 0
            for (var k = 0; k < len; k++) { sx += poly[k][0]; sy += poly[k][1] }
            return [sx / Math.max(1, len), sy / Math.max(1, len)]
        }
        for (var i = 0; i < len; i++) {
            var p0 = poly[i]
            var p1 = poly[(i + 1) % len]
            var f = p0[0] * p1[1] - p1[0] * p0[1]
            a += f
            cx += (p0[0] + p1[0]) * f
            cy += (p0[1] + p1[1]) * f
        }
        a *= 0.5
        if (Math.abs(a) < 1e-6) {
            var sx2 = 0, sy2 = 0
            for (var j = 0; j < len; j++) { sx2 += poly[j][0]; sy2 += poly[j][1] }
            return [sx2 / len, sy2 / len]
        }
        return [cx / (6 * a), cy / (6 * a)]
    }

    function _voronoi(sites, bounds) {
        var n = sites.length
        var cells = new Array(n)
        for (var i = 0; i < n; i++) {
            var poly = [[bounds.x0, bounds.y0], [bounds.x1, bounds.y0],
                        [bounds.x1, bounds.y1], [bounds.x0, bounds.y1]]
            var s = sites[i]
            for (var j = 0; j < n; j++) {
                if (i === j) continue
                var t = sites[j]
                var mx = (s[0] + t[0]) * 0.5
                var my = (s[1] + t[1]) * 0.5
                var nx = t[0] - s[0]
                var ny = t[1] - s[1]
                poly = _clipPoly(poly, mx, my, nx, ny)
                if (poly.length === 0) break
            }
            cells[i] = poly
        }
        return cells
    }

    function _buildTile() {
        if (!active || width <= 0 || height <= 0) {
            _tileCells = []
            return
        }

        var tileW = _tileW
        var tileH = height
        var n = _sitesPerTile
        var topMargin = tileH * 0.10
        var botMargin = tileH * 0.10
        var bandH = tileH - topMargin - botMargin

        var rng = _mulberry32(_baseSeed || 1)
        var sites = []
        for (var i = 0; i < n; i++) {
            sites.push([rng() * tileW,
                        topMargin + rng() * bandH])
        }

        var topBottomGhosts = []
        var topBottomCount = Math.max(8, Math.floor(tileW / 70))
        var grng = _mulberry32(((_baseSeed ^ 0xa5a5a5) >>> 0) || 1)
        var topJitter = topMargin * 0.6
        var botJitter = botMargin * 0.6
        for (var g = 0; g < topBottomCount; g++) {
            var gx = (tileW * (g + 0.5)) / topBottomCount
            topBottomGhosts.push([gx + (grng() - 0.5) * 50,
                                  topMargin * 0.35 + (grng() - 0.5) * topJitter])
            topBottomGhosts.push([gx + (grng() - 0.5) * 50,
                                  tileH - botMargin * 0.35 + (grng() - 0.5) * botJitter])
        }

        function _buildWrapGhosts() {
            var wrapZone = tileW * 0.15
            var positions = []
            var sourceIdx = []
            for (var i = 0; i < sites.length; i++) {
                var sx = sites[i][0], sy = sites[i][1]
                if (sx < wrapZone) {
                    positions.push([sx + tileW, sy])
                    sourceIdx.push(i)
                }
                if (sx > tileW - wrapZone) {
                    positions.push([sx - tileW, sy])
                    sourceIdx.push(i)
                }
            }
            return { positions: positions, sourceIdx: sourceIdx }
        }

        var bounds = { x0: -tileW, y0: -2, x1: 2 * tileW, y1: tileH + 2 }
        var wrap = _buildWrapGhosts()
        var allSites = sites.concat(topBottomGhosts).concat(wrap.positions)
        var polys = _voronoi(allSites, bounds)

        for (var r = 0; r < relaxIterations; r++) {
            var newReal = []
            for (var k = 0; k < sites.length; k++) {
                var p = polys[k]
                if (p && p.length >= 3) {
                    var c = _polyCentroid(p)
                    var cx = c[0]
                    while (cx < 0) cx += tileW
                    while (cx >= tileW) cx -= tileW
                    newReal.push([cx, c[1]])
                } else {
                    newReal.push(sites[k])
                }
            }
            sites = newReal
            wrap = _buildWrapGhosts()
            allSites = sites.concat(topBottomGhosts).concat(wrap.positions)
            polys = _voronoi(allSites, bounds)
        }

        var nReal = sites.length
        var nTopBot = topBottomGhosts.length
        var sourceOfPoly = new Array(allSites.length)
        var sourcePosOfPoly = new Array(allSites.length)
        for (var si = 0; si < nReal; si++) {
            sourceOfPoly[si] = si
            sourcePosOfPoly[si] = sites[si]
        }
        for (var ti = 0; ti < nTopBot; ti++) {
            sourceOfPoly[nReal + ti] = -1
            sourcePosOfPoly[nReal + ti] = null
        }
        for (var wi = 0; wi < wrap.sourceIdx.length; wi++) {
            sourceOfPoly[nReal + nTopBot + wi] = wrap.sourceIdx[wi]
            sourcePosOfPoly[nReal + nTopBot + wi] = wrap.positions[wi]
        }

        var built = []

        for (var idx = 0; idx < nReal; idx++) {
            var srcIdx = idx
            var p2 = polys[idx]
            if (!p2 || p2.length < 3) continue

            var preBb = _polyBounds(p2)
            var preW = preBb.x1 - preBb.x0
            var preH = preBb.y1 - preBb.y0
            if (Math.min(preW, preH) < minShardPx) continue

            var centroid = _polyCentroid(p2)
            var srcPos = sourcePosOfPoly[idx]
            var shrinkX = srcPos[0]
            var shrinkY = srcPos[1]
            var outer = []

            for (var u = 0; u < p2.length; u++) outer.push([p2[u][0], p2[u][1]])
            var shrunk = []
            if (shardGap > 0) {
                for (var v = 0; v < p2.length; v++) {
                    var vx = p2[v][0] - shrinkX
                    var vy = p2[v][1] - shrinkY
                    var d = Math.sqrt(vx * vx + vy * vy)
                    if (d <= shardGap * 1.2) {
                        shrunk.push([shrinkX + vx * 0.2, shrinkY + vy * 0.2])
                    } else {
                        var f = (d - shardGap) / d
                        shrunk.push([shrinkX + vx * f, shrinkY + vy * f])
                    }
                }
            } else {
                shrunk = outer.slice()
            }

            var shardRng = _mulberry32((_baseSeed ^ Math.imul(srcIdx + 1, 2654435761)) >>> 0)
            built.push({
                idx: srcIdx,
                polygon: shrunk,
                polygonOuter: outer,
                bbox: _polyBounds(shrunk),
                outerBbox: _polyBounds(outer),
                localCx: centroid[0],
                localCy: centroid[1],
                cloudR: 0.85 + shardRng() * 0.30
            })
        }

        _tileCells = built
    }

    function _cellOpacity(localCx, localCy, stripeWX, cloudR) {
        var dxn = ((stripeWX + localCx) - _viewportCx) / _cloudRx
        var d2 = (dxn * dxn) / (cloudR * cloudR)
        if (d2 <= _cloudInnerR2) return _transitionAlpha
        if (d2 >= _cloudOuterR2) return 0.0
        var t = (_cloudOuterR2 - d2) / (_cloudOuterR2 - _cloudInnerR2)
        return t * t * (3.0 - 2.0 * t) * _transitionAlpha
    }

    MouseArea {
        anchors.fill: parent
        z: -1
        acceptedButtons: Qt.NoButton
        propagateComposedEvents: true
        onWheel: function(wheel) {
            var impulseScale = mosaicView.width * 0.012
            var dy = wheel.angleDelta.y
            var dx = wheel.angleDelta.x
            if (dy !== 0) mosaicView._addImpulse(-dy * impulseScale)
            else if (dx !== 0) mosaicView._addImpulse(dx * impulseScale)
            wheel.accepted = true
        }
    }

    Item {
        id: warmupLayer
        visible: false
        Repeater {
            model: mosaicView.active ? mosaicView._warmupCount : 0
            delegate: Image {
                asynchronous: true
                cache: true
                source: {
                    if (!mosaicView.service || !mosaicView.service.filteredModel) return ""
                    var n = mosaicView.service.filteredModel.count
                    if (n <= 0) return ""
                    var item = mosaicView.service.filteredModel.get(index % n)
                    if (!item) return ""
                    if (item.background) return "file://" + item.background
                    if (item.thumb) return "file://" + item.thumb
                    return ""
                }
                sourceSize.width: 256
                sourceSize.height: 256
            }
        }
    }

    Repeater {
        model: 2
        delegate: Item {
            id: stripe
            property int stripeIdx: index
            property real stripeWX: stripeIdx === 0 ? mosaicView._stripeAX : mosaicView._stripeBX
            property int imageOffset: stripeIdx === 0 ? mosaicView._stripeAOffset : mosaicView._stripeBOffset

            x: stripeWX - mosaicView._worldX
            y: 0
            width: mosaicView._tileW
            height: mosaicView.height

            Repeater {
                model: mosaicView._tileCells
                delegate: MosaicCell {
                    cellData: modelData
                    colors: mosaicView.colors
                    itemData: {
                        if (!mosaicView.service || !mosaicView.service.filteredModel) return null
                        var n = mosaicView.service.filteredModel.count
                        if (n === 0) return null
                        var i = ((stripe.imageOffset + modelData.idx) % n + n) % n
                        return mosaicView.service.filteredModel.get(i)
                    }
                    cellKey: stripe.stripeIdx * 100000 + modelData.idx
                    hovered: mosaicView.hoveredIdx === cellKey
                    cloudOpacity: mosaicView._cellOpacity(modelData.localCx, modelData.localCy,
                                                         stripe.stripeWX, modelData.cloudR)
                    onHoverChanged: function(isHover) {
                        if (isHover) mosaicView.hoveredIdx = cellKey
                        else if (mosaicView.hoveredIdx === cellKey) mosaicView.hoveredIdx = -1
                    }
                    onActivated: function(item) { if (item) mosaicView.itemActivated(item) }
                }
            }
        }
    }

    Component.onCompleted: _hardRebuild()
}
