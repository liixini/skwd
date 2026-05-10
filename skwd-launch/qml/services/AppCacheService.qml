pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import ".."


QtObject {
    id: service

    readonly property string homeDir: Config.homeDir
    readonly property string configDir: Config.configDir
    readonly property string cacheDir: Config.cacheDir
    readonly property string steamDir: Config.steamDir || (homeDir + "/.local/share/Steam")
    readonly property string splashDir: Config.splashDir
    readonly property string cacheFile: cacheDir + "/app-launcher/list.jsonl"
    readonly property string thumbDir: cacheDir + "/app-launcher/thumbs"
    readonly property string appsJsonPath: configDir + "/data/apps.json"
    readonly property int thumbSize: 256
    readonly property int maxJobs: 4

    
    property bool running: false
    property int progress: 0
    property int total: 0

    signal cacheReady()

    
    function rebuild() {
        if (running) return
        running = true
        progress = 0
        total = 0
        _scanStdout = []
        _mkdirs.running = true
    }

    
    property var _mkdirs: Process {
        command: ["mkdir", "-p", service.thumbDir]
        onExited: service._loadSplashIndex()
    }

    
    property var _splashIndex: ({})
    property var _splashStdout: []

    function _loadSplashIndex() {
        _splashStdout = []
        _splashLister.command = ["sh", "-c",
            "[ -d " + _sq(splashDir) + " ] && " +
            "find " + _sq(splashDir) + " -maxdepth 1 -type f " +
            "\\( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' -o -iname '*.avif' \\) " +
            "2>/dev/null || true"
        ]
        _splashLister.running = true
    }

    property var _splashLister: Process {
        stdout: SplitParser { onRead: line => service._splashStdout.push(line) }
        onExited: {
            var idx = {}
            for (var i = 0; i < service._splashStdout.length; i++) {
                var path = service._splashStdout[i].trim()
                if (!path) continue
                var slash = path.lastIndexOf("/")
                var base = slash >= 0 ? path.substring(slash + 1) : path
                var dot = base.lastIndexOf(".")
                var stem = dot > 0 ? base.substring(0, dot) : base
                idx[stem.toLowerCase()] = path
            }
            service._splashIndex = idx
            service._runScan()
        }
    }

    function _splashLookup(name) {
        if (!name) return ""
        var key = name.toLowerCase()
        var idx = _splashIndex
        if (idx[key]) return idx[key]
        
        var variants = [key.replace(/ /g, "_"), key.replace(/ /g, "-"), key.replace(/ /g, "")]
        for (var i = 0; i < variants.length; i++) {
            if (idx[variants[i]]) return idx[variants[i]]
        }
        
        
        var simple = key.replace(/[^a-z0-9]/g, "")
        if (simple.length < 3) return ""
        for (var stem in idx) {
            var s = stem.replace(/[^a-z0-9]/g, "")
            if (s.length >= 3 && (s.indexOf(simple) !== -1 || simple.indexOf(s) !== -1))
                return idx[stem]
        }
        return ""
    }

    
    property var _scanStdout: []

    function _runScan() {
        _scanStdout = []
        _scanProcess.running = true
    }

    property var _scanProcess: Process {
        command: ["sh", "-c", service._buildScanScript()]
        stdout: SplitParser {
            onRead: data => service._scanStdout.push(data)
        }
        onExited: service._onScanDone()
    }

    function _buildScanScript() {
        var home = _sq(homeDir)
        var steamD = _sq(steamDir)

        
        return 'set -e\n' +
            'HOME_DIR=' + home + '\n' +
            'STEAM_DIR=' + steamD + '\n' +
            
            'find_icon() {\n' +
            '  local name="$1"\n' +
            '  [ -z "$name" ] && return\n' +
            '  [ "${name:0:1}" = "/" ] && [ -f "$name" ] && echo "$name" && return\n' +
            '  local dirs="$HOME_DIR/.local/share/icons /usr/share/icons/hicolor /usr/share/icons/Adwaita /usr/share/icons/breeze /usr/share/icons/breeze-dark /usr/share/pixmaps /usr/share/icons"\n' +
            '  local sizes="512x512 256x256 128x128 96x96 64x64 48x48 scalable"\n' +
            '  for d in $dirs; do\n' +
            '    [ -d "$d" ] || continue\n' +
            '    for s in $sizes; do\n' +
            '      for cat in apps applications; do\n' +
            '        for ext in .png .svg .xpm; do\n' +
            '          [ -f "$d/$s/$cat/${name}${ext}" ] && echo "$d/$s/$cat/${name}${ext}" && return\n' +
            '        done\n' +
            '      done\n' +
            '    done\n' +
            '    for ext in .png .svg .xpm ""; do\n' +
            '      [ -f "$d/${name}${ext}" ] && echo "$d/${name}${ext}" && return\n' +
            '    done\n' +
            '  done\n' +
            '}\n' +
            
            'parse_desktop() {\n' +
            '  local file="$1"\n' +
            '  local name="" exec="" icon="" cats="" nodisplay="" hidden="" terminal="" type=""\n' +
            '  local in_entry=0\n' +
            '  while IFS= read -r line || [ -n "$line" ]; do\n' +
            '    case "$line" in\n' +
            '      "[Desktop Entry]") in_entry=1; continue ;;\n' +
            '      "["*"]") in_entry=0; continue ;;\n' +
            '    esac\n' +
            '    [ "$in_entry" = "0" ] && continue\n' +
            '    case "$line" in\n' +
            '      Name=*) [ -z "$name" ] && name="${line#Name=}" ;;\n' +
            '      Exec=*) exec="${line#Exec=}" ;;\n' +
            '      Icon=*) icon="${line#Icon=}" ;;\n' +
            '      Categories=*) cats="${line#Categories=}" ;;\n' +
            '      NoDisplay=*) nodisplay="${line#NoDisplay=}" ;;\n' +
            '      Hidden=*) hidden="${line#Hidden=}" ;;\n' +
            '      Terminal=*) terminal="${line#Terminal=}" ;;\n' +
            '      Type=*) type="${line#Type=}" ;;\n' +
            '    esac\n' +
            '  done < "$file"\n' +
            '  [ -z "$name" ] || [ -z "$exec" ] && return\n' +
            '  [ "$type" != "" ] && [ "$type" != "Application" ] && return\n' +
            '  [ "$nodisplay" = "true" ] || [ "$hidden" = "true" ] && return\n' +
            '  exec=$(echo "$exec" | sed -E \'s/ %[fFuUdDnNickvm]//g\')\n' +
            '  local icon_path=$(find_icon "$icon")\n' +
            '  # JSON-safe name/exec\n' +
            '  name=$(echo "$name" | sed \'s/\\\\/\\\\\\\\/g; s/"/\\\\"/g\')\n' +
            '  exec=$(echo "$exec" | sed \'s/\\\\/\\\\\\\\/g; s/"/\\\\"/g\')\n' +
            '  cats=$(echo "$cats" | sed \'s/"/\\\\"/g\')\n' +
            '  icon=$(echo "$icon" | sed \'s/"/\\\\"/g\')\n' +
            '  icon_path=$(echo "$icon_path" | sed \'s/"/\\\\"/g\')\n' +
            '  local term=false; [ "$terminal" = "true" ] && term=true\n' +
            '  echo "{\\"name\\":\\"$name\\",\\"exec\\":\\"$exec\\",\\"icon\\":\\"$icon\\",\\"iconPath\\":\\"$icon_path\\",\\"categories\\":\\"$cats\\",\\"source\\":\\"desktop\\",\\"terminal\\":$term,\\"steamAppId\\":\\"\\"}"\n' +
            '}\n' +
            
            'seen_names=""\n' +
            'for dir in /usr/share/applications "$HOME_DIR/.local/share/applications" /var/lib/flatpak/exports/share/applications "$HOME_DIR/.local/share/flatpak/exports/share/applications"; do\n' +
            '  [ -d "$dir" ] || continue\n' +
            '  for f in "$dir"/*.desktop; do\n' +
            '    [ -f "$f" ] || continue\n' +
            '    parse_desktop "$f"\n' +
            '  done\n' +
            'done\n' +
            
            'parse_steam() {\n' +
            '  local steam="$STEAM_DIR"\n' +
            '  [ -d "$steam" ] || return\n' +
            '  local lib_dirs="$steam/steamapps"\n' +
            '  local vdf="$steam/steamapps/libraryfolders.vdf"\n' +
            '  if [ -f "$vdf" ]; then\n' +
            '    while IFS= read -r line; do\n' +
            '      case "$line" in\n' +
            '        *\\"path\\"*) local p=$(echo "$line" | sed -n \'s/.*"path"\\s*"\\([^"]*\\)".*/\\1/p\'); [ -d "$p/steamapps" ] && lib_dirs="$lib_dirs $p/steamapps" ;;\n' +
            '      esac\n' +
            '    done < "$vdf"\n' +
            '  fi\n' +
            '  local seen_ids=""\n' +
            '  for lib in $lib_dirs; do\n' +
            '    for manifest in "$lib"/appmanifest_*.acf; do\n' +
            '      [ -f "$manifest" ] || continue\n' +
            '      local appid=$(sed -n \'s/.*"appid"\\s*"\\([0-9]*\\)".*/\\1/p\' "$manifest")\n' +
            '      local gname=$(sed -n \'s/.*"name"\\s*"\\([^"]*\\)".*/\\1/p\' "$manifest")\n' +
            '      [ -z "$appid" ] || [ -z "$gname" ] && continue\n' +
            '      case "${gname,,}" in *proton*|*redistribut*|*steamworks*|*"steam linux runtime"*|*"wallpaper engine"*|*steamvr*) continue ;; esac\n' +
            '      case "$seen_ids" in *":$appid:"*) continue ;; esac\n' +
            '      seen_ids="$seen_ids:$appid:"\n' +
            '      gname=$(echo "$gname" | sed \'s/\\\\/\\\\\\\\/g; s/"/\\\\"/g\')\n' +
            '      echo "{\\"name\\":\\"$gname\\",\\"exec\\":\\"steam steam://rungameid/$appid\\",\\"icon\\":\\"\\",\\"iconPath\\":\\"\\",\\"categories\\":\\"Game;\\",\\"source\\":\\"steam\\",\\"terminal\\":false,\\"steamAppId\\":\\"$appid\\"}"\n' +
            '    done\n' +
            '  done\n' +
            '}\n' +
            'parse_steam\n'
    }

    function _onScanDone() {
        
        var entries = []
        var seen = {}
        for (var i = 0; i < _scanStdout.length; i++) {
            try {
                var obj = JSON.parse(_scanStdout[i])
                var key = obj.name.toLowerCase()
                if (!seen[key]) {
                    seen[key] = true
                    entries.push(obj)
                }
            } catch(e) {}
        }

        
        var desktopApps = entries.filter(function(e) { return e.source === "desktop" })
            .sort(function(a, b) { return a.name.toLowerCase().localeCompare(b.name.toLowerCase()) })
        var steamGames = entries.filter(function(e) { return e.source === "steam" })
            .sort(function(a, b) { return a.name.toLowerCase().localeCompare(b.name.toLowerCase()) })

        
        var steamNames = {}
        for (var s = 0; s < steamGames.length; s++)
            steamNames[steamGames[s].name.toLowerCase()] = true
        desktopApps = desktopApps.filter(function(a) { return !steamNames[a.name.toLowerCase()] })

        
        _appsConfig = _loadAppsConfig()

        
        _syncAppsConfig(desktopApps, steamGames)

        
        _allEntries = desktopApps.concat(steamGames)
        total = _allEntries.length
        progress = 0
        _completedEntries = []
        _thumbQueue = []
        _activeJobs = 0
        _thumbIndex = 0

        for (var k = 0; k < _allEntries.length; k++) {
            var entry = _allEntries[k]
            var slug = (entry.source === "steam")
                ? "steam_" + entry.steamAppId
                : entry.name.replace(/[^a-zA-Z0-9_-]/g, '_')
            var ext = (entry.source === "steam") ? ".jpg" : ".png"
            entry._thumbPath = thumbDir + "/" + slug + ext
            entry._slug = slug
            _thumbQueue.push(k)
        }
        _startThumbWorkers()
    }

    property var _allEntries: []
    property var _completedEntries: []
    property var _appsConfig: ({})
    property var _thumbQueue: []
    property int _activeJobs: 0
    property int _thumbIndex: 0

    
    function _startThumbWorkers() {
        while (_activeJobs < maxJobs && _thumbIndex < _thumbQueue.length) {
            var idx = _thumbQueue[_thumbIndex]
            _launchThumbWorker(_allEntries[idx])
            _thumbIndex++
            _activeJobs++
        }
        if (_activeJobs === 0 && _thumbIndex >= _thumbQueue.length)
            _writeCache()
    }

    function _launchThumbWorker(entry) {
        var cmd = _buildThumbCmd(entry)
        var proc = _thumbComponent.createObject(service, { command: cmd, _entry: entry })
        proc.running = true
    }

    property var _thumbComponent: Component {
        Process {
            property var _entry
            onExited: {
                service._finalizeEntry(_entry)
                service.progress++
                service._activeJobs--
                service._startThumbWorkers()
                destroy()
            }
        }
    }

    function _buildThumbCmd(entry) {
        var thumb = _sq(entry._thumbPath)
        if (entry.source === "steam") {
            return ["sh", "-c", _buildSteamThumbScript(entry.steamAppId, entry._thumbPath)]
        }
        
        if (!entry.iconPath) return ["true"]
        var icon = _sq(entry.iconPath)
        var sz = thumbSize
        
        return ["sh", "-c",
            "[ -f " + thumb + " ] && exit 0; " +
            "magick " + icon + " -resize " + sz + "x" + sz + " -background none -gravity center -extent " + sz + "x" + sz + " " + thumb + " 2>/dev/null || cp " + icon + " " + thumb + " 2>/dev/null || true"
        ]
    }

    function _buildSteamThumbScript(appid, thumbPath) {
        var thumb = _sq(thumbPath)
        var steamCache = _sq(steamDir + "/appcache/librarycache/" + appid)
        return '[ -f ' + thumb + ' ] && exit 0\n' +
            'app_cache=' + steamCache + '\n' +
            '[ -d "$app_cache" ] || exit 0\n' +
            'for name in library_hero.jpg header.jpg library_600x900.jpg logo.png; do\n' +
            '  if [ -f "$app_cache/$name" ]; then\n' +
            '    magick "$app_cache/$name" -resize 460x215^ -gravity center -extent 460x215 ' + thumb + ' 2>/dev/null && exit 0\n' +
            '  fi\n' +
            '  for dir in "$app_cache"/*/; do\n' +
            '    [ -d "$dir" ] || continue\n' +
            '    [ -f "$dir/$name" ] && magick "$dir/$name" -resize 460x215^ -gravity center -extent 460x215 ' + thumb + ' 2>/dev/null && exit 0\n' +
            '  done\n' +
            'done\n' +
            '# Fallback: any jpg > 1KB\n' +
            'find "$app_cache" -name "*.jpg" -size +1k -print -quit 2>/dev/null | while read -r f; do cp "$f" ' + thumb + ' 2>/dev/null; done\n'
    }

    function _finalizeEntry(entry) {
        var conf = _findAppConfig(entry.name, _appsConfig)
        var bg = conf.background || ""
        if (bg) {
            bg = bg.replace("~", homeDir)
        }

        _completedEntries.push({
            name: entry.name,
            exec: entry.exec,
            icon: entry.icon || "",
            thumb: entry._thumbPath,
            iconPath: entry.iconPath || "",
            categories: entry.categories || "",
            source: entry.source,
            steamAppId: entry.steamAppId || "",
            terminal: entry.terminal || false,
            background: bg,
            customIcon: conf.icon || "",
            displayName: conf.displayName || "",
            hidden: !!conf.hidden,
            tags: conf.tags || ""
        })
    }

    
    property var _appsJsonFile: FileView { preload: false }

    function _loadAppsConfig() {
        _appsJsonFile.path = appsJsonPath
        _appsJsonFile.reload()
        var text = _appsJsonFile.text()
        if (!text) return {}
        try {
            var data = JSON.parse(text)
            var result = {}
            for (var k in data) {
                if (k.charAt(0) === '_') continue
                var v = data[k]
                if (typeof v === "string")
                    result[k.toLowerCase()] = v ? { background: v } : {}
                else if (typeof v === "object" && v !== null)
                    result[k.toLowerCase()] = v
            }
            return result
        } catch(e) { return {} }
    }

    function _syncAppsConfig(desktopApps, steamGames) {
        _appsJsonFile.path = appsJsonPath
        _appsJsonFile.reload()
        var text = _appsJsonFile.text()
        var existing = {}
        var comments = {}
        if (text) {
            try {
                var raw = JSON.parse(text)
                for (var k in raw) {
                    if (k.charAt(0) === '_') { comments[k] = raw[k]; continue }
                    var v = raw[k]
                    if (typeof v === "string")
                        existing[k.toLowerCase()] = v ? { background: v } : {}
                    else if (typeof v === "object" && v !== null)
                        existing[k.toLowerCase()] = v
                    else
                        existing[k.toLowerCase()] = {}
                }
            } catch(e) {}
        }

        
        for (var i = 0; i < desktopApps.length; i++) {
            var name = desktopApps[i].name.toLowerCase()
            if (!(name in existing)) existing[name] = {}
        }
        for (var j = 0; j < steamGames.length; j++) {
            var gname = steamGames[j].name.toLowerCase()
            if (!(gname in existing)) existing[gname] = {}
        }

        
        var output = {}
        output["_comment"] = comments["_comment"] ||
            "App customization for the launcher and window switcher. Each key is matched case-insensitively."
        output["_usage"] = comments["_usage"] ||
            "Each value is an object with optional fields: background (image path), icon (nerd font glyph), displayName (custom name shown in UI), hidden (true to hide from launcher/switcher), tags (space-separated searchable tags)."
        if (comments["_example"]) output["_example"] = comments["_example"]

        var keys = Object.keys(existing).sort()
        for (var m = 0; m < keys.length; m++)
            output[keys[m]] = existing[keys[m]]

        _appsJsonFile.setText(JSON.stringify(output, null, 2) + "\n")
    }

    function _findAppConfig(name, configMap) {
        var lower = name.toLowerCase()
        if (configMap[lower]) return configMap[lower]
        for (var key in configMap) {
            if (lower.indexOf(key) !== -1) return configMap[key]
        }
        return {}
    }

    
    property var _cacheWriter: FileView {}

    function _writeCache() {
        
        _completedEntries.sort(function(a, b) {
            if (a.source !== b.source) return a.source === "desktop" ? -1 : 1
            return a.name.toLowerCase().localeCompare(b.name.toLowerCase())
        })

        var jsonl = _completedEntries.map(function(e) { return JSON.stringify(e) }).join("\n")
        _cacheWriter.path = cacheFile
        _cacheWriter.setText(jsonl + "\n")

        running = false
        cacheReady()
    }

    
    function _sq(s) {
        return "'" + String(s).replace(/'/g, "'\\''") + "'"
    }
}
