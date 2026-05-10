pragma Singleton
import QtQuick
import Quickshell.Io
import ".."


QtObject {
    id: service

    readonly property string compositor: Config.compositor

    
    function focusWindow(id) { _run(_focusWindowCmd(id)) }
    function closeWindow(id) { _run(_closeWindowCmd(id)) }
    function focusMonitor(name) { _run(_focusMonitorCmd(name)) }
    function focusWorkspace(id) { _run(_focusWorkspaceCmd(id)) }
    function quit() { _run(_quitCmd()) }

    
    signal windowsReady(var windows)
    signal workspacesReady(var workspaces)
    signal outputsReady(var outputs)

    function listWindows() {
        _jsonStdout = []
        _listWindowsProcess.command = listWindowsCmd()
        _listWindowsProcess.running = true
    }

    function listWorkspaces() {
        _wsJsonStdout = []
        _listWorkspacesProcess.command = _listWorkspacesCmd()
        _listWorkspacesProcess.running = true
    }

    function listOutputs() {
        _outJsonStdout = []
        _listOutputsProcess.command = _listOutputsCmd()
        _listOutputsProcess.running = true
    }

    signal wmEvent(string eventData)
    function startEventStream() {
        var cmd = _eventStreamCmd()
        if (cmd.length > 0) {
            _eventStreamProcess.command = cmd
            _eventStreamProcess.running = true
        }
    }
    function stopEventStream() { _eventStreamProcess.running = false }

    
    function _focusWindowCmd(id) {
        switch (compositor) {
        case "niri": return ["niri", "msg", "action", "focus-window", "--id", id]
        case "hyprland": return ["hyprctl", "dispatch", "focuswindow", "address:" + id]
        case "sway": return ["swaymsg", "[con_id=" + id + "] focus"]
        case "kwin": return ["kdotool", "windowactivate", id]
        }
        return []
    }

    function _closeWindowCmd(id) {
        switch (compositor) {
        case "niri": return ["niri", "msg", "action", "close-window", "--id", id]
        case "hyprland": return ["hyprctl", "dispatch", "closewindow", "address:" + id]
        case "sway": return ["swaymsg", "[con_id=" + id + "] kill"]
        case "kwin": return ["kdotool", "windowclose", id]
        }
        return []
    }

    function _focusMonitorCmd(name) {
        switch (compositor) {
        case "niri": return ["niri", "msg", "action", "focus-monitor", name]
        case "hyprland": return ["hyprctl", "dispatch", "focusmonitor", name]
        case "sway": return ["swaymsg", "focus output " + name]
        }
        return []
    }

    function _focusWorkspaceCmd(id) {
        switch (compositor) {
        case "niri": return ["niri", "msg", "action", "focus-workspace", String(id)]
        case "hyprland": return ["hyprctl", "dispatch", "workspace", String(id)]
        case "sway": return ["swaymsg", "workspace " + id]
        case "kwin": return ["kdotool", "set_desktop", String(id)]
        }
        return []
    }

    function _quitCmd() {
        switch (compositor) {
        case "niri": return ["niri", "msg", "action", "quit"]
        case "hyprland": return ["hyprctl", "dispatch", "exit"]
        case "sway": return ["swaymsg", "exit"]
        case "kwin": return ["qdbus6", "org.kde.Shutdown", "/Shutdown",
                             "org.kde.Shutdown.logout", "0", "0", "0"]
        }
        return []
    }

    function listWindowsCmd() {
        switch (compositor) {
        case "niri": return ["niri", "msg", "--json", "windows"]
        case "hyprland": return ["hyprctl", "-j", "clients"]
        case "sway": return ["swaymsg", "-t", "get_tree"]
        case "kwin": return ["sh", "-c", _kwinListWindowsSh()]
        }
        return []
    }

    function _listWorkspacesCmd() {
        switch (compositor) {
        case "niri": return ["niri", "msg", "--json", "workspaces"]
        case "hyprland": return ["hyprctl", "-j", "workspaces"]
        case "sway": return ["swaymsg", "-t", "get_workspaces"]
        case "kwin": return ["sh", "-c", _kwinListWorkspacesSh()]
        }
        return []
    }

    function _listOutputsCmd() {
        switch (compositor) {
        case "niri": return ["niri", "msg", "--json", "outputs"]
        case "hyprland": return ["sh", "-c",
            "hyprctl -j monitors | jq '[.[] | {key: .name, value: .}] | from_entries'"]
        case "sway": return ["sh", "-c",
            "swaymsg -t get_outputs | jq '[.[] | {key: .name, value: .}] | from_entries'"]
        }
        return ["echo", "{}"]
    }

    function _eventStreamCmd() {
        switch (compositor) {
        case "niri": return ["niri", "msg", "--json", "event-stream"]
        case "hyprland":
            var sig = Quickshell.env("HYPRLAND_INSTANCE_SIGNATURE")
            return ["socat", "-U", "-",
                    "UNIX-CONNECT:" + Quickshell.env("XDG_RUNTIME_DIR") +
                    "/hypr/" + sig + "/.socket2.sock"]
        case "sway": return ["swaymsg", "-t", "subscribe", "-m", "[\"workspace\",\"window\"]"]
        }
        return []
    }

    
    function _kwinListWindowsSh() {
        return 'active=$(kdotool getactivewindow 2>/dev/null); ' +
            'result="["; first=true; ' +
            'while IFS= read -r uuid; do ' +
            '[ -z "$uuid" ] && continue; ' +
            'info=$(qdbus6 org.kde.KWin /KWin org.kde.KWin.getWindowInfo "$uuid" 2>/dev/null); ' +
            '[ -z "$info" ] && continue; ' +
            'type=$(echo "$info" | sed -n "s/^type: //p"); ' +
            '[ "$type" != "0" ] && continue; ' +
            'skip=$(echo "$info" | sed -n "s/^skipSwitcher: //p"); ' +
            '[ "$skip" = "true" ] && continue; ' +
            'caption=$(echo "$info" | sed -n "s/^caption: //p"); ' +
            'resourceClass=$(echo "$info" | sed -n "s/^resourceClass: //p"); ' +
            'desktopFile=$(echo "$info" | sed -n "s/^desktopFile: //p"); ' +
            'desktop=$(kdotool get_desktop_for_window "$uuid" 2>/dev/null); ' +
            'is_focused=false; [ "$uuid" = "$active" ] && is_focused=true; ' +
            '$first || result+=","; first=false; ' +
            'result+=$(jq -n --arg id "$uuid" --arg title "$caption" ' +
            '--arg app_id "${desktopFile:-$resourceClass}" ' +
            '--argjson ws "${desktop:-0}" --argjson focused "$is_focused" ' +
            '\'{ id:$id, title:$title, app_id:$app_id, workspace_id:$ws, is_focused:$focused, is_floating:false }\'); ' +
            'done < <(kdotool search --title "" 2>/dev/null); ' +
            'result+="]"; echo "$result"'
    }

    function _kwinListWorkspacesSh() {
        return 'num=$(kdotool get_num_desktops 2>/dev/null); ' +
            'cur=$(kdotool get_desktop 2>/dev/null); ' +
            'jq -n --argjson n "${num:-1}" --argjson c "${cur:-1}" ' +
            '\'[range(1;$n+1) | {id:., name:("Desktop "+tostring), is_active:(.==$c)}]\''
    }

    
    property var _actionProcess: Process {
        id: actionProcess
    }
    function _run(cmd) {
        if (cmd.length === 0) return
        actionProcess.command = cmd
        actionProcess.running = true
    }

    
    property var _jsonStdout: []
    property var _listWindowsProcess: Process {
        id: listWindowsProcess
        onExited: {
            var text = _jsonStdout.join("")
            try {
                var data = JSON.parse(text)
                
                if (compositor === "sway" && !Array.isArray(data)) {
                    data = _extractSwayWindows(data)
                }
                service.windowsReady(data)
            } catch(e) {
                service.windowsReady([])
            }
        }
        stdout: SplitParser {
            splitMarker: ""
            onRead: data => _jsonStdout.push(data)
        }
    }

    
    property var _wsJsonStdout: []
    property var _listWorkspacesProcess: Process {
        id: listWorkspacesProcess
        onExited: {
            var text = _wsJsonStdout.join("")
            try { service.workspacesReady(JSON.parse(text)) }
            catch(e) { service.workspacesReady([]) }
        }
        stdout: SplitParser {
            splitMarker: ""
            onRead: data => _wsJsonStdout.push(data)
        }
    }

    
    property var _outJsonStdout: []
    property var _listOutputsProcess: Process {
        id: listOutputsProcess
        onExited: {
            var text = _outJsonStdout.join("")
            try { service.outputsReady(JSON.parse(text)) }
            catch(e) { service.outputsReady({}) }
        }
        stdout: SplitParser {
            splitMarker: ""
            onRead: data => _outJsonStdout.push(data)
        }
    }

    property var _eventStreamProcess: Process {
        id: eventStreamProcess
        stdout: SplitParser {
            onRead: line => service.wmEvent(line)
        }
        onExited: {
            
            _eventStreamRestart.start()
        }
    }
    property var _eventStreamRestart: Timer {
        interval: 1000
        onTriggered: {
            if (service._eventStreamProcess.command.length > 0)
                service._eventStreamProcess.running = true
        }
    }

    
    function _extractSwayWindows(node) {
        var result = []
        if (node.pid && node.pid > 0 && node.type === "con")
            result.push(node)
        if (node.nodes) {
            for (var i = 0; i < node.nodes.length; i++)
                result = result.concat(_extractSwayWindows(node.nodes[i]))
        }
        if (node.floating_nodes) {
            for (var j = 0; j < node.floating_nodes.length; j++)
                result = result.concat(_extractSwayWindows(node.floating_nodes[j]))
        }
        return result
    }
}
