# Skwd - A skewed (Quick)shell

> [!IMPORTANT]
> I just moved Skwd to a whole new architecture with a Rust backend. As such I need to rewrite the readme to reflect reality - patience please :)
> The tl;dr is that Skwd supports Arch, Fedora & NixOS, with Arch currently being alpha tested out of those three. Will update the readme but my focus is to get the software tested - not the github presentation.
>
> This is my personal shell and is alpha software still under heavy development and testing. Please report issues and do not expect polished software everywhere (yet!).
> Testing underway. Currently testing Arch Linux.
>
> Fedora: Not tested
>
> NixOS: Not tested

Skwd is modular - while it pulls in a lot of dependencies for various functionality at the end of the day only what you have enabled is actually running.
Skwd-setttings has a modules section where all logic for non-used components is gated to be completely shut off if not in use.

# Install

### Arch

`yay -S skwd`

> [!IMPORTANT]
> Note that skwd is a collection of Quickshell widgets held together by the Rust daemon skwd-daemon. So if you're updating only skwd, you want to update both skwd and skwd-daemon, e.g.
> `yay -S skwd skwd-daemon`

# Commands

All commands go through `skwd-daemon` over its unix socket. Every panel-style namespace (`bar`, `launcher`, `settings`, `power`) supports `toggle`, `show` and `hide`; only the most common form is shown below.

```
// Skwd-wall, github.com/liixini/skwd-wall
skwd wall toggle
skwd wall apply '{"name":"sunset.jpg"}'    // set wallpaper by name

// Skwd-bar, the top bar. Exec on session start for "always visible".
skwd bar toggle                            // also: show, hide

// Launcher
skwd launcher toggle                       // also: show, hide

// Settings panel. Same UI whether triggered via daemon or via the standalone wrapper.
skwd settings toggle                       // also: show, hide
skwd-settings                              // standalone wrapper (own quickshell process)

// Power menu (lock, logout, reboot, poweroff, ...).
skwd power toggle                          // also: show, hide

// Alt-tab style window switcher. Hold the bind, tap next/prev, release to confirm.
skwd switch open                           // open without selecting
skwd switch next
skwd switch prev
skwd switch confirm                        // pick highlighted window
skwd switch cancel                         // dismiss without selecting
skwd switch close                          // kill highlighted window

// Misc
skwd status                                // daemon version + current wallpaper
skwd gen-icons                             // regenerate the MDI icon cache (run if the icon picker is empty)
skwd optimize-videos [DIR_OR_FILE...]      // batch re-encode video wallpapers
```
