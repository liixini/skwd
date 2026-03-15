# Skwd - A skewed take on shells

![Desktop view](screenshots/image.png)
![Wallpaper switcher](screenshots/image-1.png)
![Window switcher](screenshots/image-2.png)
![App launcher](screenshots/image-4.png)


## Please read before continuing - It is important believe it or not

This is my daily-driver personal desktop shell, built with [Quickshell](https://quickshell.outfoxxed.me/) (Qt6/QML). I use Niri but I have added functionality for Hyprland and a best-guess stub for Sway configuration. If you're a person that is using a sane person default like say KDE Plasma on Fedora I'm sure you can figure out how to run the Quickshell components of this repository.

While I am a professional at writing code I am not a professional at writing Quickshell, Bash or Python which is the main parts of this project and if something has better options for execution feel free to inform me about better solutions - there is no pride here!

This software is released in working prototype stage as it was never intended to be released to the public but there was a large interest in it so here we are.

**I use AI tooling while developing** just like I do in my professional life.
Some of the code is AI, but most of the code and terrible decisions is in fact me.
If you see something that needs fixing or can be improved feel free to reach out as most of this was made in a proof of concept manner rather than production ready and battletested and I'm always up for learning new things.

Note that there's code in this repository that uses the compositor value from the flag for compositor-specific actions, so chances are you will have to modify some things for it to work but there has been a best-effort made to isolate compositor-specific code to an abstraction layer in the form of the wm-action script, more about it further down.

## Known defects / Good to know

I couldn't figure out how to grab pictures of the apps on Hyprland, so the app switcher is simply just nice coloured boxes with the app icon. If you figure it out give me a shout.

A lot of nice looking stuff relies on the functionality of your compositor such as blur so you'll have to set that up as your heart desires - I make no assumptions about your compositor or how you want things to work for it.

## Roadmap / TODO
I am currently in the process of standardising this project to be automatically installable for Arch Linux, Fedora and NixOS through their respective package repositories.

However it is a lot of work and testing and I have other things to do than to customise Linux like working 😭

On top of that I am almost daily refactoring the code base to follow some semblence of separation of concern as it was developed in a POC fashion.

After that I would like to resume work on the Smarthome component and finalise the lockscreen & greeter.

## Installing

You'll need Linux and a Wayland compositor - I recommend Niri.

### Dependencies

#### Core
| Dependency | Purpose |
|---|---|
| **Quickshell** (+ Qt6) | QML desktop shell framework |
| **Python 3** | Scripts |
| **jq** | JSON parsing in bash scripts |

#### CLI tools
| Dependency | Purpose |
|---|---|
| **matugen** | Material You color scheme generation from wallpapers |
| **ffmpeg** | Video frame extraction and thumbnailing |
| **playerctl** | Media player control (lyrics, now playing) |
| **cava** | Audio visualizer for the lyrics |
| **notify-send** | Desktop notifications |
| **awww** | Static wallpaper with transitions |
| **mpvpaper** | Video wallpaper rendering |
| **linux-wallpaperengine** | For Wallpaper Engine wallpapers ...duh |

#### Python packages (installed automatically via `scripts/requirements.txt`)
| Package | Purpose |
|---|---|
| **requests** ≥2.28 | HTTP (Ollama, Home Assistant, lrclib) |
| **Pillow** ≥9.0 | Image processing for wallpaper thumbnails |
| **syncedlyrics** ≥1.0 | Synced lyrics fetching |

#### Optional
| Dependency | Purpose |
|---|---|
| **ollama** | Local LLM for wallpaper analysis/tagging - optional but colour sorting is much better with it. I recommend the Gemma3:4b model which is also installed in the install script. |
| **python-pam** or **pamela** | PAM authentication for the lockscreen, currently WIP and the lockscreen is not shipped as it is very hacky and only viable as a PoC |

### Git Clone (if you're not on Arch)

WIP - Adding and testing Fedora & NixOS support

```bash
git clone https://github.com/liixini/skwd ~/.config/skwd
cd ~/.config/skwd
./scripts/bash/setup
skwd
```

### AUR (Arch Linux)

```bash
yay -S skwd-git
./usr/share/skwd/scripts/bash/setup
skwd
```

### Fedora (DNF) - WIP

```bash
git clone https://github.com/liixini/skwd ~/.config/skwd
cd ~/.config/skwd
./scripts/bash/setup          # auto-detects Fedora and installs via dnf/COPR
skwd
```

The setup script auto-detects your compositor, monitor, GPU, Wi-Fi interface, and Steam paths, then generates `config.json`. It creates a Python venv at `~/.config/skwd/.venv` and installs dependencies from `scripts/requirements.txt`.

For AUR installs, read-only files live in `/usr/share/skwd` (set via `SKWD_INSTALL` in `/etc/profile.d/skwd.sh`). User config lives in `~/.config/skwd/data/` and cache in `~/.cache/skwd/`.

### IPC (keybindings) & Niri and Hyprland configuration

The shell reads commands from a FIFO:

```bash
echo "launcher" > "${XDG_RUNTIME_DIR}/skwd/cmd"
```

You'll want to wire this up in your compositor config. On niri that looks like:

```
Mod+R { spawn-sh "echo applauncher > ${XDG_RUNTIME_DIR}/skwd/cmd"; }
```
on Hyprland it looks like:

```
bind = $mainMod, R, exec, echo applauncher > ${XDG_RUNTIME_DIR}/skwd/cmd

```

Commands: `applauncher`, `powermenu`, `wallpaper`, `smarthome`, `toggleBar`, `notifications`, `switcherOpen`, `switcherNext`, `switcherPrev`, `switcherConfirm`, `switcherCancel`, `switcherClose`.

### Provided for convenience is a full list of Niri keybinds as well as useful start configuration and layer rules:
```
# Start skwd shell (via quickshell)
spawn-at-startup "quickshell" "-p" "~/.config/skwd/shell.qml"

# Restore last wallpaper on startup
spawn-at-startup "~/.config/skwd/scripts/bash/restore-wallpaper"

layer-rule {
    match namespace="^window-switcher-parallel$"
    background-effect {
        blur true
        xray false
    }
}

layer-rule {
    match namespace="^wallpaper-selector$"
    background-effect {
        blur true
        xray false
    }
}

layer-rule {
    match namespace="^app-launcher-parallel$"
    background-effect {
        blur true
        xray false
    }
}

layer-rule {
    match namespace="^smarthome$"
    background-effect {
        blur true
        xray false
    }
}

layer-rule {
    match namespace="^topbar$"
    background-effect {
        blur false
        xray false        
    }
}

layer-rule {
    match namespace="^linux-wallpaperengine$"
    place-within-backdrop true
}

Mod+L hotkey-overlay-title="Lock Screen" { spawn-sh "echo lock > ${XDG_RUNTIME_DIR}/skwd/cmd"; }
Mod+Shift+L hotkey-overlay-title="Toggle Power Menu" { spawn-sh "echo powermenu > ${XDG_RUNTIME_DIR}/skwd/cmd"; }
Mod+T hotkey-overlay-title="Wallpaper Selector" { spawn-sh "echo wallpaper > ${XDG_RUNTIME_DIR}/skwd/cmd"; }
Mod+D hotkey-overlay-title="Toggle Top Bar" { spawn-sh "echo toggleBar > ${XDG_RUNTIME_DIR}/skwd/cmd"; }
Mod+Shift+S hotkey-overlay-title="Toggle Smart Home" { spawn-sh "echo smarthome > ${XDG_RUNTIME_DIR}/skwd/cmd"; }
Mod+Tab hotkey-overlay-title="Workspace Switcher" { spawn-sh "echo workspaces > ${XDG_RUNTIME_DIR}/skwd/cmd"; }
Alt+Tab hotkey-overlay-title="Window Switcher" { spawn-sh "echo switcherNext > ${XDG_RUNTIME_DIR}/skwd/cmd"; }
Alt+Shift+Tab { spawn-sh "echo switcherPrev > ${XDG_RUNTIME_DIR}/skwd/cmd"; }
Alt+Return { spawn-sh "echo switcherConfirm > ${XDG_RUNTIME_DIR}/skwd/cmd"; }
Alt+Escape { spawn-sh "echo switcherCancel > ${XDG_RUNTIME_DIR}/skwd/cmd"; }
Alt+C { spawn-sh "echo switcherClose > ${XDG_RUNTIME_DIR}/skwd/cmd"; }
```

### Provided for convenience is a full list of Hyprland keybinds as well as useful start configuration:
```
# Start skwd shell
exec-once = skwd

# Restore last wallpaper on startup
exec-once = ~/.config/skwd/scripts/bash/restore-wallpaper

bind = $mainMod, R, exec, echo applauncher > ${XDG_RUNTIME_DIR}/skwd/cmd
bind = $mainMod, D, exec, echo toggleBar > ${XDG_RUNTIME_DIR}/skwd/cmd
bind = $mainMod, T, exec, echo wallpaper > ${XDG_RUNTIME_DIR}/skwd/cmd
bind = $mainMod, L, exec, echo lock > ${XDG_RUNTIME_DIR}/skwd/cmd
bind = $mainMod, escape, exec, echo powermenu > ${XDG_RUNTIME_DIR}/skwd/cmd
bind = $mainMod SHIFT, L, exec, echo powermenu > ${XDG_RUNTIME_DIR}/skwd/cmd
bind = $mainMod SHIFT, S, exec, echo smarthome > ${XDG_RUNTIME_DIR}/skwd/cmd
bind = $mainMod, TAB, exec, echo workspaces > ${XDG_RUNTIME_DIR}/skwd/cmd
bind = ALT, TAB, exec, echo switcherNext > ${XDG_RUNTIME_DIR}/skwd/cmd
bind = ALT SHIFT, TAB, exec, echo switcherPrev > ${XDG_RUNTIME_DIR}/skwd/cmd
bind = ALT, RETURN, exec, echo switcherConfirm > ${XDG_RUNTIME_DIR}/skwd/cmd
bind = ALT, escape, exec, echo switcherCancel > ${XDG_RUNTIME_DIR}/skwd/cmd
bind = ALT, C, exec, echo switcherClose > ${XDG_RUNTIME_DIR}/skwd/cmd
```

### Disabling stuff

Every major component can be turned off in `data/config.json` under `components`. Set any to `false` and it won't load at all.

```json
"components": {
    "bar": {
        "enabled": true,
        "weather": { "city": "YOUR_CITY" },
        "wifi": { "interface": "wlan0" },
        "bluetooth": true,
        "volume": true,
        "calendar": true,
        "music": {
            "enabled": true,
            "preferredPlayer": "spotify",
            "visualizer": "wave",
            "visualizerTop": true,
            "visualizerBottom": true
        }
    },
  "lockscreen": true,
  "appLauncher": true,
  "wallpaperSelector": true,
  "windowSwitcher": true,
  "workspaceSwitcher": true,
  "powerMenu": true,
  "smartHome": true,
    "notifications": true
}
```

Component state changes are hot-reloaded - no restart needed.

## Architecture & decoupling

The codebase was originally tightly coupled to Niri but as I needed to decouple things so you guys can use it I've refactored to centralise system-specific code behind a few abstraction points. Here's how it's structured and what you'd need to think about for it to work for you.

### Compositor abstraction (`scripts/bash/wm-action`)

This is the main decoupling point. Every compositor call in the entire project - from QML and from bash scripts - goes through this single script. No QML file or bash script calls `niri msg` or `hyprctl` directly (except `apply-niri-colors`, which is inherently niri-specific and guards itself with a compositor check).

`wm-action` takes an action name and routes it:

```bash
wm-action focus-window <id>
wm-action close-window <id>
wm-action focus-monitor <name>
wm-action focus-workspace <id>
wm-action list-windows
wm-action list-workspaces
wm-action list-outputs
wm-action event-stream
wm-action screenshot-window <id> <path>
wm-action screenshot-output <name> <path>
wm-action quit
```

Inside it's a case statement per compositor. The niri block is complete and tested and so is the Hyprland one.

### Shared bash library (`scripts/bash/lib.sh`)

Every bash script sources this. It provides:

- **XDG paths** - `$SKWD_CONFIG`, `$SKWD_CACHE`, `$SKWD_RUNTIME`
- **`cfg_get <jq-expr>`** - reads config.json with tilde expansion (e.g. `cfg_get '.paths.wallpaper'`)
- **`require_cmd` / `has_cmd`** - tool availability checks; `require_cmd` exits with an error
- **`detect_compositor`** - reads config.json first, falls back to auto-detection
- **`detect_gpu`** - nvidia / amd / intel / unknown

### QML side

The QML components never talk to the compositor directly. They shell out to `wm-action` via Quickshell's `Process` type:

```qml
Process {
    command: [Config.scriptsDir + "/bash/wm-action", "focus-window", win.id.toString()]
}
```

Config values come from `qml/Config.qml`, a singleton that reads `data/config.json` through a FileView with hot-reload.

### What's still niri-specific

The biggest remaining coupling is the event stream parsing in `shell.qml`. The `wm-action event-stream` command outputs JSON lines, but the format differs per compositor so there's definitely work to be done there to make it work for all cases.

The QML code in `shell.qml` currently only parses niri's event format. To support another compositor, you'd need to either:

1. Normalise in `wm-action` and translate.
2. Branch in QML directly with a conditional - up to you.

The `list-windows` outputs also have compositor-specific JSON shapes. The QML component `WindowSwitcherParallel.qml` parse these directly.

## Questions?

Probably. Once again this was never meant to be released to the public, but I have as said made a best effort to decouple things for you to be able to use.
Realistically you could probably just grab one of the QML files, rip out all the interdependency and just use that standalone if that's more your vibe though.