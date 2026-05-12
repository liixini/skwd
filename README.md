# Skwd - A skewed (Quick)shell

![Stars](https://img.shields.io/github/stars/liixini/skwd?style=for-the-badge)
![License](https://img.shields.io/github/license/liixini/skwd?style=for-the-badge)
![Last Commit](https://img.shields.io/github/last-commit/liixini/skwd?style=for-the-badge)
![Repo Size](https://img.shields.io/github/repo-size/liixini/skwd?style=for-the-badge)
![Issues](https://img.shields.io/github/issues/liixini/skwd?style=for-the-badge)

![Arch Linux](https://img.shields.io/badge/Arch_Linux-1793D1?style=for-the-badge&logo=archlinux&logoColor=white)
![Fedora](https://img.shields.io/badge/Fedora-51A2DA?style=for-the-badge&logo=fedora&logoColor=white)
![NixOS](https://img.shields.io/badge/NixOS-5277C3?style=for-the-badge&logo=nixos&logoColor=white)

<img alt="image" src="https://github.com/user-attachments/assets/f66130c0-238d-47f9-8867-520af1552838" />
<img alt="image" src="https://github.com/user-attachments/assets/dd73ab27-0217-4de1-a058-826534d4bb5b" />
<img alt="image" src="https://github.com/user-attachments/assets/acaf4486-b42a-4766-bb41-e1edd2d9c835" />


## What is Skwd?

Skwd is my personal shell that also happens to have a group of platform-agnostic aesthetics-first desktop widgets (desktop shell), of which all have parallellogram designs (and many more, if you aren't into the whole skewed thing). Also works flawlessly with my wallpaper manager [Skwd-wall](https://www.github.com/liixini/skwd-wall).

Skwd works heavily with conditional display logic. That means that you control when things are and aren't shown, e.g. why show a music player if there's no music playing? Why take bar space with a sound widget unless you aim to change the volume or outputs? Skwd supports this sort of thinking out of the box.

And what programs you ask? Window switcher, launcher, music player, notification daemon, bar (with a whole slew of widgets) and power menu. There's also a settings widget for Skwd but well - who's counting. Only want to use some of them? No problem - Skwd is built to only run what you've selected by design and you waste no resources except some disk space having them all installed.

## The long story - Personal motivation and development practices

I develop Skwd because first and foremost it is my hobby but also because I was frustrated with the options on the market - there's many amazing desktop shells out there, many of which I have taken ideas from, but they always seem to fall flat on their promise of minimalism - how can something claim to be minimal and not even support simple use cases like "maybe don't show 10 workspaces if only 1 is actually in use"?

Note that **I use AI tooling** in my development just like I do in my professional life, however most of the code is mine including the quizzical design decisions.

## Skwd is still under heavy development

Developing Skwd is my hobby and I continuously refine and develop functionality for Skwd. There's many things I want to do like calendar integration with external calendars like Outlook and Gmail, but also lockscreens with facial recognition, custom grub themes, custom login screens... you name it.

So development is never really over, but at its core Skwd is really stable - this is after all the software I use every single day.

## Performance
Performance is a big consideration for Skwd. CPU-wise Skwd has options that aren't as nice to your CPU, and options that definitely are - up to you what you use.

For memory Skwd has a memory floor of about 210 MB whereas about ~20 MB of that is the Rust backend Skwd-daemon, but can routinely use up to ~400 MB depending on exactly what you're up to.

## Dependencies
<Details>
<Summary>Dependency list</Summary>

### Required

| Dependency                                                                                                                          | Why                                                                                                                                                |
|----------------------------------------------------------------------------------------------------------------------------------------------------|----------------------------------------------------------------------------------------------------------------------------------------------------|
| [skwd-daemon](https://github.com/liixini/skwd-daemon) (`skwd-daemon`)                                                                              | Skwd's Rust backend  |
| [Quickshell](https://github.com/quickshell-mirror/quickshell) (`quickshell`)                                                                       | It is written with Quickshell... so um yeah                                                                                                        |
| [Qt6 Multimedia](https://doc.qt.io/qt-6/qtmultimedia-index.html) (`qt6-multimedia`)                                                                | Powers the video previews                                                                                                                          |
| [Qt6 Declarative](https://doc.qt.io/qt-6/qtqml-index.html) (`qt6-declarative`)                                                                     | QML runtime that Quickshell builds on                                                                                                              |
| [Qt6 Image Formats](https://doc.qt.io/qt-6/qtimageformats-index.html) (`qt6-imageformats`)                                                         | Extra image formats like webp that we rely on heavily.                                       |
| [matugen](https://github.com/InioX/matugen) (`matugen`)                                                                                            | Automatic colour extraction from the wallpapers so we can theme everything nicely                                                                                                   |
| [curl](https://curl.se) (`curl`)                                                                                                                   | Qt has a built in web request function but curl just works better                                                                                  |
| [file](https://www.darwinsys.com/file/) (`file`)                                                                                                   | Used for looking at files, specially downloaded ones, so we can confirm we didn't accidentally download something that we thought was a picture, but definitely isn't                                           |
| [inotify-tools](https://github.com/inotify-tools/inotify-tools) (`inotify-tools`)                                                                  | Sometimes we need to see if there was an update in the file system of Skwd - this does that.                                                 |
| [iwd](https://iwd.wiki.kernel.org) (`iwd`)                                                                                                         | Wi-Fi management for the bar's network widget                                                                                                      |
| [cava](https://github.com/karlstav/cava) (`cava`)                                                                                                  | Drives the audio visualiser bars in the music / lyrics widget                                                                                      |
| [Nerd Fonts Symbols](https://www.nerdfonts.com) (`ttf-nerd-fonts-symbols`)                                                                         | UI icons, as they're symbols we can colour them any way we like which is good when Matugen does the colouring                                      |
| [Roboto](https://fonts.google.com/specimen/Roboto) (`ttf-roboto`)                                                                                  | The main font family (regular + condensed + mono) used across Skwd                                                                                 |
| [Material Design Icons](https://pictogrammers.com/library/mdi/) (`ttf-material-design-icons-desktop-git`)                                          | Not all symbols are in nerd fonts symbols, so this supplements that                                                                                |

### Optional

These come from `skwd-daemon`'s `optdepends` and are only needed if you want the corresponding features in Skwd-wall.

| Dependency                                                                              | Why                                                                                                                                                                                                                                    |
|----------------------------------------------------------------------------------------------------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| [ollama](https://ollama.com) (`ollama`)                                                                  | Used for computer vision to automatically tag wallpapers. Disabled by default - enable in Skwd-wall's settings                                                                                                                                     |
| [steamcmd](https://developer.valvesoftware.com/wiki/SteamCMD) (`steamcmd`)                               | Steam Workshop integration for the in-app browsing of Wallpaper Engine wallpapers. Requires API keys and an actual purchased copy of Wallpaper Engine. Disabled by default but the functionality is in there if you want to try it out |
| [linux-wallpaperengine](https://github.com/Almamu/linux-wallpaperengine) (`linux-wallpaperengine`)       | Wallpaper Engine scene rendering. **_Not required if you only want video wallpapers_**!                                                                                                                                                |

</Details>

## Install

### Compositor-specific examples on how to launch

Skwd is driven entirely by `skwd <subcommand>` calls to `skwd-daemon`, so binding things in your compositor is just binding shell commands. Run `skwd help` for the full list of commands.

<Details>
<Summary>Niri</Summary>

#### Niri (`~/.config/niri/config.kdl`)

```kdl
spawn-at-startup "skwd-daemon"
spawn-at-startup "sh" "-c" "skwd bar toggle"

binds {
    Mod+Space        { spawn "skwd" "launcher" "toggle"; }
    Mod+B            { spawn "skwd" "bar" "toggle"; }
    Mod+Comma        { spawn "skwd" "settings" "toggle"; }
    Mod+Escape       { spawn "skwd" "power" "toggle"; }

    Alt+Tab          { spawn "skwd" "switch" "open"; }
    Alt+Shift+Tab    { spawn "skwd" "switch" "prev"; }
    Alt+Return       { spawn "skwd" "switch" "confirm"; }
    Alt+Escape       { spawn "skwd" "switch" "cancel"; } // closes the switcher without selecting
    Alt+C            { spawn "skwd" "switch" "close"; } // quits the currently selected program
}
```

</Details>

<Details>
<Summary>Hyprland</Summary>

#### Hyprland (`~/.config/hypr/hyprland.conf`)

```conf
exec-once = skwd-daemon
exec-once = skwd bar show

bind = SUPER, SPACE,  exec, skwd launcher toggle
bind = SUPER, B, exec, skwd bar toggle
bind = SUPER, COMMA, exec, skwd settings toggle
bind = SUPER, ESCAPE, exec, skwd power toggle

bind = ALT, TAB, exec, skwd switch open
bind = ALT+SHIFT, TAB, exec, skwd switch prev
bind = ALT, RETURN, exec, skwd switch confirm
bind = ALT, ESCAPE, exec, skwd switch cancel // closes the switcher without selecting
bind = ALT, C, exec, skwd switch close // quits the currently selected program
```

</Details>

These are just starting points - swap the keys for whatever fits your layout. `skwd help` (or just `skwd`) prints every available subcommand.

### Arch Linux

<Details>
<Summary>Arch Linux, CachyOS, EndevourOS, Manjaro, Garuda Linux etc.</Summary>

```sh
# Install Skwd and its dependencies
yay -S skwd

# Enable Skwd-daemon
systemctl --user enable --now skwd-daemon.service

# Note that on some setups you will need to execute skwd-daemon on startup
# Here are some examples:

#   # Niri (~/.config/niri/config.kdl)
#   spawn-at-startup "skwd-daemon"
#
#   # Hyprland (~/.config/hypr/hyprland.conf)
#   exec-once = skwd-daemon

# Launch a Skwd widget, like Skwd-bar. Bind this command to a key in your compositor for quick access:
skwd bar toggle
```

If you're updating Skwd-wall, note that Skwd-wall is two applications - Skwd-wall and Skwd-daemon.
Skwd-daemon is automatically installed as part of installing Skwd-wall, but if you're updating and not updating all packages you need to
either use `yay -S skwd-wall --devel` or `yay -S skwd-wall skwd-daemon` 

> **Note:** `yay` is an AUR helper. If you don't have it, install it or use another helper like `paru`.

</Details>

### NixOS

<Details>
<Summary>NixOS</Summary>

```nix
Currently in testing!
```

</Details>

### Fedora

<Details>
<Summary>Fedora, Bazzite, Nobara etc.</Summary>

```sh
Currently in testing!
```

</Details>

## Compositor-specific tweaks (KDE Plasma, Hyprland etc)

### Hyprland
<Details>
<Summary>Hyprland fixes and tweaks</Summary>
In testing I experienced issues with NixOS + systemctl service autostart on Hyprland.

This was resolved by adding a basic exec once to `hyprland.conf`, e.g.
  
`exec-once = systemctl --user start skwd-daemon`

</Details>

## Running Skwd

All commands go through `skwd-daemon` over its unix socket. Here's the complete list.

<Details>
<Summary>All Skwd commands</Summary>

```

skwd - command-line interface for skwd-daemon

usage: skwd <command> [json-params]
       skwd help

  skwd bar toggle
  skwd bar show
  skwd bar hide
  skwd bar mouseover
  skwd bar visualizer clean

  skwd launcher toggle

  skwd settings toggle

  skwd power toggle

  skwd switch open
  skwd switch next
  skwd switch prev
  skwd switch confirm
  skwd switch cancel
  skwd switch close

  skwd status
  skwd theme colors
  skwd subscribe '{"events":["skwd.*"]}'
  skwd state get '{"key":"..."}'
  skwd state set '{"key":"k","value":"v"}'

  skwd dev toggle
  skwd dev enable
  skwd dev disable
  skwd dev status

  skwd wall toggle
  skwd wall list
  skwd wall import '{"path":"/abs/path/to/file.jpg"}'
  skwd wall apply '{"name":"file.jpg"}'
  skwd wall restore
  skwd wall retheme
  skwd wall theme_preview '{"name":"file.jpg"}'
  skwd wall preheat
  skwd wall cache_rebuild
  skwd wall cache_status
  skwd wall clear_data
  skwd wall recompute_colors
  skwd wall set_favourite '{"name":"file.jpg","favourite":true}'
  skwd wall update_analysis '{"name":"file.jpg","tags":["..."]}'
  skwd wall update_metadata '{"name":"file.jpg","...":"..."}'
  skwd wall delete '{"name":"file.jpg"}'
  skwd wall outputs
  skwd wall set_audio '{"output":"DP-1","enabled":true}'
  skwd wall suppress
  skwd wall unsuppress
  skwd wall weather
  skwd wall random_start
  skwd wall random_stop
  skwd wall random_status

  skwd music status
  skwd music devices
  skwd music device set '{"id":"..."}'
  skwd music player start
  skwd music player stop
  skwd music player play
  skwd music player pause
  skwd music player next
  skwd music player previous
  skwd music player volume '{"volume_percent":50}'
  skwd music transfer '{"device_id":"..."}'
  skwd music play uris '{"uris":["spotify:track:..."]}'
  skwd music play context '{"context_uri":"spotify:playlist:..."}'
  skwd music queue
  skwd music queue add '{"uri":"spotify:track:..."}'
  skwd music search '{"q":"...","type":"track"}'
  skwd music playlists
  skwd music playlist tracks '{"id":"..."}'
  skwd music liked
  skwd music like check '{"ids":["..."]}'
  skwd music like set '{"id":"...","liked":true}'
  skwd music artist top_tracks '{"id":"..."}'
  skwd music auth start
  skwd music auth status
  skwd music auth logout

  skwd lyrics peek
  skwd lyrics get '{"track":"...","artist":"..."}'
  skwd lyrics fetch '{"track":"...","artist":"..."}'

  skwd steam download '{"id":"123456789"}'
  skwd steam retry '{"id":"123456789"}'
  skwd steam status

  skwd optimize start '{"preset":"...","paths":["..."]}'
  skwd optimize cancel
  skwd optimize status
  skwd optimize presets

  skwd video_convert start '{"preset":"...","paths":["..."]}'
  skwd video_convert cancel
  skwd video_convert status
  skwd video_convert presets

  skwd analysis start
  skwd analysis stop
  skwd analysis status
  skwd analysis regenerate
  skwd analysis retag_one '{"name":"file.jpg"}'

  skwd optimize-videos [DIR_OR_FILE...]
  skwd gen-icons [--font PATH] [--output PATH]

```

</Details>

## License

[MIT](LICENSE)
