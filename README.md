# Skwd - A skewed take on shells

### Work in progress! I have a major refactoring underway that vastly improves the functionality and removes all of the python and most of the scripts.

![Desktop view](screenshots/image.png)
<img width="2560" height="1440" alt="image" src="https://github.com/user-attachments/assets/3cf58a9b-e8f5-4bb8-8e36-ba974e08ed9d" />
![Window switcher](screenshots/image-2.png)
![App launcher](screenshots/image-4.png)

## What is Skwd?

Skwd is a platform-agnostic aesthetics-first modular group of parallelogram desktop widgets with full support for colour theming based on your wallpaper powered by Matugen replicating common Desktop Shell functionality.

If you don't speak nerd that means that it is a collection of things like wallpaper switchers, app launchers and bar that has support for large splash art for high aesthetic styling that you can select which ones you use and which ones you don't and the colours update automatically as you change your wallpaper to match.

Skwd is also built with high customisability in mind where you can configure many things extremely granularly like custom naming, icons, search groups, splash art and more.

### Supported OS:es

Support tested specifically for Arch Linux & Fedora, where fully automated Fedora support is still WIP but manual install is available.
That means working on:
- **Arch Linux** and Arch Linux-derivatives like CachyOS and EndeavourOS.
- **Fedora** and Fedora-derivatives like Bazzite and Nobara.

However it should work just fine on NixOS after some adaptations and I will specifically support NixOS when I find time for it.

### Supported compositors

Tested functional on Niri, Hyprland and KWin (KDE Plasma).

### Components

- **Top Bar** - System bar with clock, weather, Wi-Fi, Bluetooth, volume, calendar, and a music player with synced lyrics and audio visualizer. Each module is able to be enabled or disabled to suit your needs.
- **App Launcher** - Parallelogram-tiled application launcher supporting tag search. Also has frequency-based searching meaning the order of apps is based on which one you selected on that keyword the most.
- **Window Switcher** - Alt+Tab window switcher with thumbnail previews (only using Niri)
- **Wallpaper Selector** - Browse, search, and apply static/video/Wallpaper Engine wallpapers with Matugen colour theming. Has video previews for those wallpapers that are animated.
- **Power Menu** - Shutdown, reboot, suspend, logout but fully configurable to do anything you want really.
- **Notifications** - Desktop notification display and history

### Work in progress - Coming soon:

- **Lockscreen** - PAM-authenticated lockscreen
- **Smart Home** - Home Assistant panel for those that want to control their lights or blinds through a QML widget (I know I do!)
- **Greeter** - Quickshell greeter for sddm

## What is this not?

This is not a plug'n'play solution. The software will run just fine out of the box but it assumes that you will set up your keybinds the way you like them and do baseline system configuration in both apps.json and config.json. There is information about what that looks like for various systems below.

This software is also under heavy development and almost every single day I commit some change aimed to improve, fix or add something. That is not to discourage you from installing and using Skwd, just be aware that I am actively involved in improving and fixing things for Skwd to be a better experience for me personally but also other people that might want to use it.

If you have any suggestions or issues, feel free to create a GitHub issue :)

## The long story - Personal motivation and development practices

This is my daily-driver personal desktop shell, built with [Quickshell](https://quickshell.outfoxxed.me/) (Qt6/QML).

While I am a professional at writing code I am not a professional at writing Quickshell, Bash or Python which is the main parts of this project and if something has better options for execution feel free to inform me about better solutions - there is no pride here!

This software is released in working prototype stage as it was never intended to be released to the public but there was a large interest in it so here we are.

**I use AI tooling while developing** just like I do in my professional life.
Some of the code is AI, but most of the code and terrible decisions is in fact me.
If you see something that needs fixing or can be improved feel free to reach out as most of this was made in a proof of concept manner rather than production ready and battletested and I'm always up for learning new things.

Note that there's code in this repository that uses the compositor value from the flag for compositor-specific actions, so chances are you will have to modify some things for it to work but there has been a best-effort made to isolate compositor-specific code to an abstraction layer in the form of the wm-action script, more about it further down.

## Known defects / Good to know

The only compositor that has images in the app switcher is Niri as I use Niri's screenshotting system to generate those. All others simply have nice coloured parallelograms and icons.

A lot of nice looking stuff relies on the functionality of your compositor such as blur so you'll have to set that up as your heart desires - I make no assumptions about your compositor or how you want things to work for it.

## Roadmap / TODO

I am currently in the process of standardising this project to be automatically installable for Arch Linux, Fedora and NixOS through their respective package repositories.
Arch is done and fully functional, but Fedora and NixOS remains.

However it is a lot of work and testing and I have other things to do than to customise Linux like working 😭

After that I would like to resume work on the Smarthome component and finalise the lockscreen & greeter. I am also planning on maybe creating a widget that reads the json files and allows for a more convenient form of editing. Unsure though as I feel the configuration is very set it and forget it making slightly inconvenient data editing not a big deal. Like how often do you really install new programs that need splash art and search tags?

## Dependencies

#### Core
| Dependency | Purpose |
|---|---|
| **quickshell** (+ Qt6) | QML desktop shell framework |
| **qt6-multimedia** | Media playback support |
| **qt6-connectivity** | Bluetooth support |
| **python** | Scripts |
| **python-requests** | HTTP (Ollama, Home Assistant, lrclib) |
| **python-pillow** | Image processing for wallpaper thumbnails |
| **jq** | JSON parsing in bash scripts |

#### CLI tools
| Dependency | Purpose |
|---|---|
| **matugen** | Material You color scheme generation from wallpapers |
| **ffmpeg** | Video frame extraction and thumbnailing |
| **parallel** | Parallel task execution |
| **playerctl** | Media player control (lyrics, now playing) |
| **cava** | Audio visualizer for the lyrics |
| **libnotify** | Desktop notifications (notify-send) |
| **awww** | Static wallpaper with transitions |
| **mpvpaper** | Video wallpaper rendering |
| **imagemagick** | Image manipulation |

#### Fonts
| Dependency | Purpose |
|---|---|
| **ttf-roboto** | Primary UI font |
| **ttf-roboto-mono** | Monospace font |
| **ttf-nerd-fonts-symbols** | Icon glyphs |
| **ttf-material-design-icons-desktop-git** | Material Design icons |

#### Optional
| Dependency | Purpose |
|---|---|
| **linux-wallpaperengine** | Steam Wallpaper Engine support |
| **ollama** | Local LLM for wallpaper analysis/tagging - colour sorting is much better with it. I recommend Gemma3:4b. |
| **grim** | Screenshot capture for window switcher thumbnails |
| **niri** | Recommended Wayland compositor |

## Installing

You'll need Linux and a Wayland compositor - I recommend Niri.

### Arch Linux (AUR)

```bash
yay -S skwd-git
cd /usr/share/skwd/scripts/bash/ 
./setup
skwd &
```

### Manual install

```bash
sudo git clone https://github.com/liixini/skwd /usr/share/skwd
sudo chmod +x /usr/share/skwd/scripts/bash/*
sudo chmod +x /usr/share/skwd/scripts/python/*
printf '#!/bin/sh\nexport SKWD_INSTALL=/usr/share/skwd\nexec quickshell -p /usr/share/skwd "$@"\n' | sudo tee /usr/bin/skwd > /dev/null
sudo chmod +x /usr/bin/skwd
cd /usr/share/skwd/scripts/bash
./setup
skwd &
```

Note that the setup script isn't strictly necessary and is provided as a convenience, but you will have to do some manual work to get the system running if you don't run it.

### IPC (keybindings) & Niri/Hyprland/KWin (KDE Plasma) examples

The shell reads commands from a FIFO:

```bash
echo "launcher" > "${XDG_RUNTIME_DIR}/skwd/cmd"
```

You'll want to wire this up in your compositor config.

On Niri that looks like:
```
Mod+R { spawn-sh "echo applauncher > ${XDG_RUNTIME_DIR}/skwd/cmd"; }
```

on Hyprland it looks like:
```
bind = $mainMod, R, exec, echo applauncher > ${XDG_RUNTIME_DIR}/skwd/cmd
```

On KWin (KDE Plasma) you can modify the shortcut file directly, but KDE Plasma is designed to use the Shortcut widget to add keybinds & corresponding commands like so:
```
bash -c 'echo launcher > ${XDG_RUNTIME_DIR}/skwd/cmd'
```

Commands: `lock`, `config`, `powermenu`, `launcher` (alias: `applauncher`), `toggleBar`, `wallpaper`, `smarthome`, `notifications`, `switcherOpen`, `switcherNext`, `switcherPrev`, `switcherConfirm`, `switcherCancel`, `switcherClose`.

### Provided for convenience is a full list of Niri keybinds as well as useful start configuration and layer rules:
```
# Start skwd shell
spawn-at-startup "skwd"

# Restore last wallpaper on startup
spawn-at-startup "/usr/share/skwd/scripts/bash/restore-wallpaper"

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
exec-once = /usr/share/skwd/scripts/bash/restore-wallpaper

bind = $mainMod, R, exec, echo applauncher > ${XDG_RUNTIME_DIR}/skwd/cmd
bind = $mainMod, D, exec, echo toggleBar > ${XDG_RUNTIME_DIR}/skwd/cmd
bind = $mainMod, T, exec, echo wallpaper > ${XDG_RUNTIME_DIR}/skwd/cmd
bind = $mainMod, L, exec, echo lock > ${XDG_RUNTIME_DIR}/skwd/cmd
bind = $mainMod, escape, exec, echo powermenu > ${XDG_RUNTIME_DIR}/skwd/cmd
bind = $mainMod SHIFT, L, exec, echo powermenu > ${XDG_RUNTIME_DIR}/skwd/cmd
bind = $mainMod SHIFT, S, exec, echo smarthome > ${XDG_RUNTIME_DIR}/skwd/cmd
bind = ALT, TAB, exec, echo switcherNext > ${XDG_RUNTIME_DIR}/skwd/cmd
bind = ALT SHIFT, TAB, exec, echo switcherPrev > ${XDG_RUNTIME_DIR}/skwd/cmd
bind = ALT, RETURN, exec, echo switcherConfirm > ${XDG_RUNTIME_DIR}/skwd/cmd
bind = ALT, escape, exec, echo switcherCancel > ${XDG_RUNTIME_DIR}/skwd/cmd
bind = ALT, C, exec, echo switcherClose > ${XDG_RUNTIME_DIR}/skwd/cmd
```

### KWin (KDE Plasma) support is experimental but tested as functional
Open the shortcuts app, edit and add a keybind with the following:
```
bash -c 'echo launcher > ${XDG_RUNTIME_DIR}/skwd/cmd'
```


### Disabling stuff

Every major component can be turned off in `data/config.json` under `components`. Set any to `false` and it won't load at all.

```json
"components": {
    "bar": {
        "enabled": true,
        "weather": { "enabled": true, "city": "YOUR_CITY" },
        "wifi": { "enabled": true, "interface": "wlan0" },
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
    "lockscreen": false,
    "appLauncher": true,
    "wallpaperSelector": {
        "enabled": true,
        "showColorDots": false
    },
    "windowSwitcher": true,
    "powerMenu": {
        "enabled": true,
        "items": [
            { "action": "lock", "icon": "", "label": "" },
            { "action": "logout", "icon": "", "label": "" },
            { "action": "reboot", "icon": "", "label": "" },
            { "action": "poweroff", "icon": "", "label": "" }
        ]
    },
    "smartHome": false,
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

## Questions?

Probably! Feel free to open an issue if something doesn't work or a PR if you think something should work another way. This software is quite complex and very finnicky in interoperability so the more feedback I have the better. And if you actually reached this line without scrolling to the end - you're a beast!
