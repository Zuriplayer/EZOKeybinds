-- Textos en inglés para EZOKeybinds.
-- Este archivo lo carga el juego automáticamente cuando el idioma del cliente es inglés.

EZOKeybinds_Strings = EZOKeybinds_Strings or {}
EZOKeybinds_Strings["UNKNOWN_COMMAND"] = "EZOKeybinds: use /ezokeybinds status or /ezokeybinds restore"
EZOKeybinds_Strings["ACCOUNT_WIDE_CATEGORY_NOTE"] = "* Checked box = account-wide EZO binding."
EZOKeybinds_Strings["ACCOUNT_WIDE_TOOLTIP"] = "Share this EZO keybinding with every character on this Windows user profile."
EZOKeybinds_Strings["SHARING_UNAVAILABLE"] = "EZOKeybinds: keybind sharing is not available in this client session."
EZOKeybinds_Strings["LAM_HEADER"] = "EZO keybinding defaults"
EZOKeybinds_Strings["LAM_HEADER_TOOLTIP"] = "Review current EZO-family bindings and restore their declared defaults. Edit bindings in ESO Controls; LibAddonMenu has no native key-capture control. ESO's public Lua API does not expose the Num Lock state."
EZOKeybinds_Strings["LAM_CURRENT_BINDINGS"] = "Current EZO bindings"
EZOKeybinds_Strings["LAM_CURRENT_BINDINGS_TOOLTIP"] = "Shows every currently assigned slot for enabled EZO addon actions. Change them from ESO Controls."
EZOKeybinds_Strings["LAM_NO_BINDINGS"] = "No enabled EZO action currently has an assigned key."
EZOKeybinds_Strings["LAM_SLOT"] = "Slot %d: %s"
EZOKeybinds_Strings["LAM_RESET_DEFAULTS"] = "Restore EZO keybinding defaults"
EZOKeybinds_Strings["LAM_RESET_DEFAULTS_TOOLTIP"] = "After confirmation, clears enabled EZO actions, puts keyboard defaults in slot 1 and gamepad defaults in slot 2, and clears slots 3 and 4. Gamepad defaults follow ESO's manual per-layer binding behavior and are never applied automatically at startup."
EZOKeybinds_Strings["RESET_DIALOG_TITLE"] = "Restore EZO keybinding defaults"
EZOKeybinds_Strings["RESET_DIALOG_TEXT"] = "This clears all four slots of enabled EZO actions. Keyboard defaults return to slot 1 and gamepad defaults to slot 2; slots 3 and 4 remain empty. A gamepad button already used in another ESO action layer will not block the EZO binding, so both actions may respond when both layers are active. Continue?"
EZOKeybinds_Strings["RESET_DONE"] = "EZOKeybinds: restored %d EZO actions; skipped %d occupied or unavailable defaults."
EZOKeybinds_Strings["RESET_UNAVAILABLE"] = "EZOKeybinds: secure keybinding functions are unavailable; nothing was changed."
EZOKeybinds_Strings["RESET_FAILED"] = "EZOKeybinds: the default restore failed; inspect the technical log."
