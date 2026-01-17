# Hyprclipboard
A clipboard visual interface for hyprland made with [Quickshell](https://quickshell.org/) based on the Windows clipboard. Feel free to open a PR and contribute.

## Demo
https://github.com/user-attachments/assets/ff941239-54d7-44c4-a0cf-1060d88fcec4

## Dependencies
- [hyprland](https://hypr.land/)
- [quickshell](https://quickshell.org/)
- [cliphist](https://github.com/sentriz/cliphist)
- [wl-clipboard](https://github.com/bugaevc/wl-clipboard)

## Installation
Make sure all the dependencies are installed and working correctly.

Clone this repo into Quickshell's config folder
```bash
git clone https://github.com/RezenDeveloper/hyprclipboard ~/.config/quickshell/hyprclipboard
```

Add these commands to your hyprland config file

```jsonc
exec-once = wl-paste --type text --watch cliphist store
exec-once = wl-paste --type image --watch cliphist store
```
The next line is used to clear the clipboard each hyprland session

```jsonc
exec-once = rm "$HOME/.cache/cliphist/db"
```

## Usage

You can run the app using the following command in your terminal

```bash
qs -c hyprclipboard -n
```

Or just add a bind to your hyprland config

```jsonc
bind = $mainMod, V, exec, qs -c hyprclipboard -n
```

This will bind hyprclipboard to Meta + V

### Search & Filters
- Type normally to search text
- Use `>img` or `>image` to show only image entries

### Controls
- Keyboard Arrows – navigate entries
- Tab - change focus between buttons
- Enter – execute the focused action
- Esc – close popup

## TODO
- [ ] Add file support
- [ ] Improve UI/UX
- [ ] Add a pin button
- [ ] Reposition popup with Meta + Left Click
