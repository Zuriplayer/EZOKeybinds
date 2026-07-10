# EZOKeybinds

Enables native keybinding chording in *The Elder Scrolls Online*, so you can assign modifier combinations (Ctrl, Alt, Shift, Command) to any existing bindable action directly from the Controls menu.

¿Prefieres español? Lee el [README en español](README.es.md).
📢 For support, feedback, bug reports or suggestions, join our Discord: https://discord.gg/gn4MutdhcB

## ✨ What it does

ESO can bind modifier combinations to actions, but the Controls menu only allows it once chording is enabled. EZOKeybinds turns that native capability on — no extra UI, no settings panel, no SavedVariables, nothing else running in the background.

## 🎮 How to use it

1. Load a character, or run `/reloadui`.
2. Open the native **Controls** menu.
3. Assign a modifier combination (e.g. `Ctrl+Alt+key`) to any bindable action, as you would any other keybind.
4. Run `/ezokeybinds status` in chat to confirm chording is active.

## What it doesn't do

EZOKeybinds doesn't manage other addons' default keybinds, doesn't reset your bindings, and doesn't apply any recommended shortcuts on its own. Assigning and keeping your own combinations is always done by you, from the native Controls menu.

## 🎮 Gamepad

EZOKeybinds activates keyboard chording (Ctrl, Shift, Alt combinations). The gamepad input system in ESO is entirely separate and is not extensible by addons — there is no public API to register new two-button gamepad combinations.

If you use a controller and want chord-style combinations (e.g. LB+A), the recommended approach is to use **Steam Input** (free, built into Steam) or **reWASD** to map that combination to a regular keyboard key, then assign that key in the native Controls menu as you would any other keybind.

## Requirements

- The Elder Scrolls Online (PC)
- No other addons required

## Installation

1. Download the latest version from [Releases](../../releases) (or clone this repository).
2. Copy the `EZOKeybinds` folder into your ESO AddOns folder:
   `Documents/Elder Scrolls Online/live/AddOns/`
3. Enable the addon from the in-game Add-Ons screen.

## Reporting issues

Please include when possible: addon version, ESO client language, and reproduction steps.

## Status

Current version: **1.0.22** — closed beta testing.

## License

MIT — see [LICENSE](LICENSE).

Developed and maintained by Zuriplayer.
