# EZOKeybinds

Enables native keybinding chording in *The Elder Scrolls Online*, so you can assign modifier combinations (Ctrl, Alt, Shift, Command) to any existing bindable action directly from the Controls menu.

¿Prefieres español? Lee el [README en español](README.es.md).
📢 For support, feedback, bug reports or suggestions, join our Discord: https://discord.gg/ekw8zUAcRm

## ✨ What it does

ESO can bind modifier combinations to actions, but the Controls menu only allows it once chording is enabled. EZOKeybinds turns that native capability on.

For EZO-family actions shown under **Controls > General > EZO AddOns**, it also adds a small checkbox to mark a binding as shared across characters on the same Windows user profile. Shared bindings are restored only through ESO's protected-call path when the client exposes it.

The **EZO keybinding defaults** section shows every assigned slot for enabled EZO actions and can restore the family defaults after confirmation. Gamepad bindings use ESO's native adaptive button glyphs, matching the detected controller type instead of exposing numeric key codes. When EZOCore is enabled, the section is hosted inside the centralized **Settings > EZO** environment; without EZOCore, EZOKeybinds registers its standalone LibAddonMenu panel. Bindings are edited in ESO's native Controls menu because LibAddonMenu has no native key-capture control.

## 🎮 How to use it

1. Load a character, or run `/reloadui`.
2. Open the native **Controls** menu.
3. Assign a modifier combination (for example `Shift+NumPad key`) to any bindable action, as you would any other keybind.
4. For EZO actions, tick the checkbox on the row if that binding should be shared across characters.
5. Run `/ezokeybinds status` in chat to confirm chording is active.
6. With EZOCore enabled, open **Settings > EZO > EZOKeybinds** to review all assigned EZO slots. Without EZOCore, use the standalone **Settings > Addons > EZOKeybinds** panel. To clear the slots and restore the family defaults, use **Restore EZO keybinding defaults**.

## What it doesn't do

EZOKeybinds doesn't manage non-EZO addon keybinds or apply defaults to non-EZO actions. The explicit reset button clears all four slots of enabled EZO actions, restores keyboard defaults to slot 1 and EZO gamepad defaults to slot 2, and leaves slots 3 and 4 empty. Keyboard defaults are skipped when already owned by non-EZO actions. Gamepad defaults follow ESO's manual per-layer binding behavior, so use in another action layer does not block the EZO binding.

Shared EZO bindings are local to the Windows user profile, not stored as an ESO server-side account setting.

## EZO-family default keybind audit

The current declared defaults are:

- EZOArmory: `Shift+NumPad 0` for its window.
- EZOTools: `Shift+NumPad 1` / `HOLD X` for the command panel; `Shift+NumPad 2` / `HOLD Y` for the utility panel; `NumPad -` for Reload UI; and `NumPad +` for travel to the primary house.
- EZOCombat: `Shift+NumPad 3` for its window.
- EZOPVP: `Shift+NumPad 4` / `HOLD A` for its PvP menu.
- EZOcamsens declares an action but currently has no default key.
- EZOAlerts, EZOAuto, EZOChat, EZOCore, EZOCursor, EZOCustomSupportIcons, EZOGroupFrames, EZOhud, EZOKeybinds, EZOMetter, EZORaidPlanner, EZOta, and EZOTest do not declare their own persistent keybinding action. Any native keybind they display is owned by ESO or is only a temporary menu control.

Nine actions are deliberately left without a default: EZOcamsens `Apply presets`, plus EZOTools `Group Activities`, `Reset Instance`, `Disband Group`, `Travel to Crafting Hall`, `Travel to Secondary Hall`, `Leave Group`, `Leave Instance`, and `Leave Group and Instance`. Each owning addon declares only its keyboard defaults through ESO's native default API; EZOKeybinds does not perform a second protected assignment during startup. Only the confirmed reset applies the declared EZO gamepad defaults, using keyboard slot 1 and gamepad slot 2 and leaving slots 3 and 4 empty. Keyboard conflicts are checked across action layers; gamepad conflicts are checked within the EZO layer, matching ESO's manual binding behavior.

The numeric keypad requires the keyboard to emit NumPad key codes. ESO's public Lua API exposes `IsCapsLockOn()` but no equivalent Num Lock state function, so EZOKeybinds cannot reliably issue a conditional "Num Lock is off" alert. If these bindings do not respond, enable Num Lock; the LAM panel documents this limitation instead of guessing the state or printing a warning on every login.

## 🎮 Gamepad

EZOKeybinds activates keyboard chording (Ctrl, Shift, Alt combinations) and displays gamepad bindings with ESO's native controller glyphs. Automatic startup registration of `HOLD A/X/Y` is disabled. The explicit, confirmed reset assigns those EZO gamepad defaults to slot 2 using ESO's manual per-layer behavior. If another action layer uses the same button, both actions may respond while both layers are active. The gamepad input system in ESO is separate and addons cannot register new two-button gamepad combinations.

If you use a controller and want chord-style combinations (e.g. LB+A), the recommended approach is to use **Steam Input** (free, built into Steam) or **reWASD** to map that combination to a regular keyboard key, then assign that key in the native Controls menu as you would any other keybind.

## Requirements

- The Elder Scrolls Online (PC)
- LibAddonMenu-2.0
- EZOCore is optional; when enabled, it hosts EZOKeybinds inside the centralized EZO settings environment.

## Installation

1. Download the latest version from [Releases](../../releases) (or clone this repository).
2. Copy the `EZOKeybinds` folder into your ESO AddOns folder:
   `Documents/Elder Scrolls Online/live/AddOns/`
3. Enable the addon from the in-game Add-Ons screen.

## Reporting issues

Please include when possible: addon version, ESO client language, and reproduction steps.

## Status

Current version: **1.0.27** — closed beta testing.

## License

MIT — see [LICENSE](LICENSE).

Developed and maintained by Zuriplayer.
