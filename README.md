# Skwd - A skewed (Quick)shell

> [!IMPORTANT]
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
```
// Skwd-wall, github.com/liixini/skwd-wall
skwd wall toggle

//Skwd-bar, the top bar. exec on launch for "bar always visible". Run command to quit or start the bar.
skwd bar toggle

// Traditional alt-tab switcher with various modes, I like wheel. Release on selection to select, run close to kill currently selected app.
skwd switch next
skwd switch prev
skwd switch confirm
// Cancel without selecting
skwd switch cancel
// Kill selected app
skwd switch close

// Launcher
skwd launcher toggle

// Settings panel for like, everything. Very WIP and rough around the edges.
skwd-settings
```
