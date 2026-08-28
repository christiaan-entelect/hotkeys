# Window Manager

This is a small [AutoHotkey](https://www.autohotkey.com/) v2 window manager for assigning windows to keyboard slots and switching between them quickly. Slot assignments are saved in [`Config/window-slots.ini`](Config/window-slots.ini), so they are available the next time the script runs.

## Install and start automatically

Run this once from PowerShell after downloading or cloning the repository:

```powershell
Set-ExecutionPolicy -Scope Process Bypass
.\install.ps1
```

The installer uses `winget` to install **AutoHotkey v2**, creates a shortcut to [`main.ahk`](main.ahk) in your Windows Startup folder, and starts the manager immediately. It will also start automatically the next time you sign in.

## Run the manager

After installation, AutoHotkey adds the manager icon to the system tray. Use the shortcuts below to assign and switch windows. To start it again after closing it, double-click [`main.ahk`](main.ahk).

## Window slots

Slots use letters and numbers. The letters `u` and `o` are reserved for cycling and cannot be used as slots.

| Shortcut | Action |
| --- | --- |
| `Win+Shift+key` | Assign the active window to `key`. A window can belong to only one slot. |
| `Win+key` | Switch to the last visited window in `key`. |
| `Win+u` | Move forward through the windows in the active slot. |
| `Win+o` | Move backward through the windows in the active slot. |
| `Win+/` | Open a list of assigned slots and their windows. Press `Esc` to close it. |

### Example

1. Focus your browser and press `Win+Shift+b` to assign it to slot `b`.
2. Focus your editor and press `Win+Shift+e` to assign it to slot `e`.
3. Press `Win+b` to return to the browser or `Win+e` to return to the editor.
4. Assign multiple windows to the same slot as needed, then use `Win+u` and `Win+o` to cycle through them.

Closed windows are removed automatically the next time the slot is used. To edit assignments manually, close the script first and update [`Config/window-slots.ini`](Config/window-slots.ini).

>### Note: The `master` branch includes my personal hotkeys as well, for only the window manager, use the `window-manager-only` branch
