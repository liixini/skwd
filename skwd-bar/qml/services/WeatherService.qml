pragma Singleton
import QtQuick
import ".."


QtObject {
    id: service

    readonly property var cities: Config.weatherCities
    readonly property string defaultCity: Config.weatherDefaultCity
    readonly property bool enabled: Config.weatherEnabled
    readonly property int pollMs: Config.weatherPollMs

    property string currentCity: ""
    property var dataByCity: ({})
    property var coordsByCity: ({})

    readonly property var current: dataByCity[currentCity] || ({})
    readonly property string temp: current.temp || "--"
    readonly property string description: current.description || ""
    readonly property var forecast: current.forecast || []

    function selectCity(name) {
        if (!name) return
        if (cities.indexOf(name) === -1) return
        currentCity = name
    }

    function advance(direction) {
        if (!cities || cities.length === 0) return
        var idx = cities.indexOf(currentCity)
        if (idx < 0) idx = 0
        idx = (idx + direction + cities.length) % cities.length
        currentCity = cities[idx]
    }

    function selectNext() { advance(1) }
    function selectPrev() { advance(-1) }

    function refresh() {
        if (!enabled || !cities || cities.length === 0) return
        for (var i = 0; i < cities.length; i++) _fetchOne(cities[i])
    }

    function _fetchOne(city) {
        if (!city) return
        var cached = coordsByCity[city]
        if (cached && typeof cached.lat === "number" && typeof cached.lon === "number") {
            _fetchForecast(city, cached.lat, cached.lon)
        } else {
            _geocode(city)
        }
    }

    function _geocode(city) {
        var xhr = new XMLHttpRequest()
        var url = "https://geocoding-api.open-meteo.com/v1/search?count=1&language=en&format=json&name="
            + encodeURIComponent(city)
        xhr.onreadystatechange = function() {
            if (xhr.readyState !== XMLHttpRequest.DONE) return
            if (xhr.status !== 200) return
            try {
                var json = JSON.parse(xhr.responseText)
                var hit = json && json.results && json.results[0]
                if (!hit) return
                var next = service._cloneObj(service.coordsByCity)
                next[city] = { lat: hit.latitude, lon: hit.longitude }
                service.coordsByCity = next
                service._fetchForecast(city, hit.latitude, hit.longitude)
            } catch (e) {
                console.log("WeatherService: geocode parse error:", e)
            }
        }
        xhr.open("GET", url)
        xhr.send()
    }

    function _fetchForecast(city, lat, lon) {
        var xhr = new XMLHttpRequest()
        var url = "https://api.open-meteo.com/v1/forecast"
            + "?latitude=" + lat
            + "&longitude=" + lon
            + "&current=temperature_2m,weather_code"
            + "&daily=temperature_2m_max,temperature_2m_min,weather_code"
            + "&timezone=auto&forecast_days=3"
        xhr.onreadystatechange = function() {
            if (xhr.readyState !== XMLHttpRequest.DONE) return
            if (xhr.status === 200) service._parseInto(city, xhr.responseText)
        }
        xhr.open("GET", url)
        xhr.send()
    }

    Component.onCompleted: {
        _resetCurrentCity()
        if (enabled) {
            refresh()
            _pollTimer.interval = pollMs > 0 ? pollMs : 600000
            _pollTimer.start()
        }
    }
    onEnabledChanged: {
        if (enabled) {
            refresh()
            _pollTimer.interval = pollMs > 0 ? pollMs : 600000
            _pollTimer.start()
        } else {
            _pollTimer.stop()
            service.dataByCity = ({})
        }
    }
    onCitiesChanged: {
        _pruneStale()
        _resetCurrentCity()
        if (enabled) refresh()
    }
    onDefaultCityChanged: {
        if (!currentCity || cities.indexOf(currentCity) === -1) _resetCurrentCity()
    }

    function _resetCurrentCity() {
        if (defaultCity && cities.indexOf(defaultCity) !== -1) {
            currentCity = defaultCity
        } else if (cities.length > 0) {
            currentCity = cities[0]
        } else {
            currentCity = ""
        }
    }

    function _pruneStale() {
        var nextData = ({})
        var nextCoords = ({})
        for (var i = 0; i < cities.length; i++) {
            var c = cities[i]
            if (dataByCity[c]) nextData[c] = dataByCity[c]
            if (coordsByCity[c]) nextCoords[c] = coordsByCity[c]
        }
        service.dataByCity = nextData
        service.coordsByCity = nextCoords
    }


    property var _pollTimer: Timer {
        repeat: true
        onTriggered: { if (service.enabled) service.refresh() }
    }

    function _parseInto(city, text) {
        if (!text) return
        try {
            var json = JSON.parse(text)
            if (!json) return

            var result = { temp: "--", description: "", forecast: [] }

            if (json.current) {
                var t = json.current.temperature_2m
                if (typeof t === "number") result.temp = Math.round(t) + "°"
                result.description = service._codeToDesc(json.current.weather_code)
            }

            var d = json.daily
            if (d && Array.isArray(d.time)) {
                var fc = []
                for (var i = 0; i < Math.min(3, d.time.length); i++) {
                    var date = new Date(d.time[i])
                    var dayName = i === 0 ? "Today" : date.toLocaleDateString('en-US', {weekday: 'short'})
                    fc.push({
                        day: dayName,
                        high: Math.round(d.temperature_2m_max[i]) + "°",
                        low:  Math.round(d.temperature_2m_min[i]) + "°",
                        desc: service._codeToDesc(d.weather_code[i])
                    })
                }
                result.forecast = fc
            }

            var next = service._cloneObj(service.dataByCity)
            next[city] = result
            service.dataByCity = next
        } catch (e) {
            console.log("WeatherService: parse error:", e)
        }
    }

    function _codeToDesc(code) {
        switch (code) {
            case 0:  return "Clear"
            case 1:  return "Mostly clear"
            case 2:  return "Partly cloudy"
            case 3:  return "Overcast"
            case 45: case 48: return "Fog"
            case 51: case 53: case 55: return "Drizzle"
            case 56: case 57: return "Freezing drizzle"
            case 61: return "Light rain"
            case 63: return "Rain"
            case 65: return "Heavy rain"
            case 66: case 67: return "Freezing rain"
            case 71: return "Light snow"
            case 73: return "Snow"
            case 75: return "Heavy snow"
            case 77: return "Snow grains"
            case 80: return "Rain showers"
            case 81: return "Heavy showers"
            case 82: return "Violent showers"
            case 85: return "Snow showers"
            case 86: return "Heavy snow showers"
            case 95: return "Thunderstorm"
            case 96: case 99: return "Thunderstorm w/ hail"
            default: return ""
        }
    }

    function _cloneObj(o) {
        try { return JSON.parse(JSON.stringify(o)) } catch (e) { return {} }
    }
}
