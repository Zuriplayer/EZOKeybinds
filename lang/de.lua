-- Textos en alemán para EZOKeybinds.
-- Este archivo lo carga el juego automáticamente cuando el idioma del cliente es alemán.

EZOKeybinds_Strings = EZOKeybinds_Strings or {}
EZOKeybinds_Strings["UNKNOWN_COMMAND"] = "EZOKeybinds: benutze /ezokeybinds status"
EZOKeybinds_Strings["LAM_HEADER"] = "EZO-Tastenbelegungen"
EZOKeybinds_Strings["LAM_HEADER_TOOLTIP"] = "Aktuelle EZO-Belegungen prüfen und Standards wiederherstellen. Änderungen erfolgen in den ESO-Steuerungseinstellungen; LibAddonMenu hat keine native Tastenerfassung. Die öffentliche ESO-Lua-API stellt den Num-Lock-Status nicht bereit."
EZOKeybinds_Strings["LAM_CURRENT_BINDINGS"] = "Aktuelle EZO-Tasten"
EZOKeybinds_Strings["LAM_CURRENT_BINDINGS_TOOLTIP"] = "Zeigt alle derzeit belegten Slots aktivierter EZO-Addon-Aktionen. Änderungen erfolgen in den ESO-Steuerungseinstellungen."
EZOKeybinds_Strings["LAM_NO_BINDINGS"] = "Derzeit ist keiner aktivierten EZO-Aktion eine Taste zugewiesen."
EZOKeybinds_Strings["LAM_SLOT"] = "Slot %d: %s"
EZOKeybinds_Strings["LAM_RESET_DEFAULTS"] = "EZO-Tastenbelegungen wiederherstellen"
EZOKeybinds_Strings["LAM_RESET_DEFAULTS_TOOLTIP"] = "Löscht nach Bestätigung aktivierte EZO-Aktionen, setzt Tastaturstandards in Slot 1 und Gamepadstandards in Slot 2 und leert Slots 3 und 4. Gamepadstandards folgen ESOs manuellem Verhalten pro Aktionsschicht und werden beim Start nie automatisch angewendet."
EZOKeybinds_Strings["RESET_DIALOG_TITLE"] = "EZO-Tastenbelegungen wiederherstellen"
EZOKeybinds_Strings["RESET_DIALOG_TEXT"] = "Alle vier Slots aktivierter EZO-Aktionen werden gelöscht. Tastaturstandards kommen in Slot 1 und Gamepadstandards in Slot 2; Slots 3 und 4 bleiben frei. Eine in einer anderen ESO-Aktionsschicht verwendete Gamepad-Taste blockiert die EZO-Belegung nicht, sodass beide Aktionen reagieren können, wenn beide Schichten aktiv sind. Fortfahren?"
EZOKeybinds_Strings["RESET_DONE"] = "EZOKeybinds: %d EZO-Aktionen wiederhergestellt; %d belegte oder nicht verfügbare Standards übersprungen."
EZOKeybinds_Strings["RESET_UNAVAILABLE"] = "EZOKeybinds: Sichere Tastenfunktionen sind nicht verfügbar; nichts wurde geändert."
EZOKeybinds_Strings["RESET_FAILED"] = "EZOKeybinds: Wiederherstellung fehlgeschlagen; technische Protokolle prüfen."
