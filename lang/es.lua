-- Textos en español para EZOKeybinds.
-- Este archivo lo carga el juego automáticamente cuando el idioma del cliente es español.

EZOKeybinds_Strings = EZOKeybinds_Strings or {}
EZOKeybinds_Strings["UNKNOWN_COMMAND"] = "EZOKeybinds: usa /ezokeybinds status o /ezokeybinds restore"
EZOKeybinds_Strings["ACCOUNT_WIDE_CATEGORY_NOTE"] = "* Casilla marcada = binding EZO para cuenta."
EZOKeybinds_Strings["ACCOUNT_WIDE_TOOLTIP"] = "Comparte este keybinding EZO con todos los personajes de este perfil de usuario de Windows."
EZOKeybinds_Strings["SHARING_UNAVAILABLE"] = "EZOKeybinds: compartir keybinds no esta disponible en esta sesion del cliente."
EZOKeybinds_Strings["LAM_HEADER"] = "Valores predeterminados de teclas EZO"
EZOKeybinds_Strings["LAM_HEADER_TOOLTIP"] = "Revisa las teclas actuales de la familia EZO y restaura sus valores declarados. Las teclas se editan en Controles de ESO: LibAddonMenu no tiene un control nativo para capturarlas. La API Lua pública de ESO no expone el estado de Bloq Num."
EZOKeybinds_Strings["LAM_CURRENT_BINDINGS"] = "Teclas EZO actuales"
EZOKeybinds_Strings["LAM_CURRENT_BINDINGS_TOOLTIP"] = "Muestra todos los slots asignados actualmente a acciones de addons EZO activados. Cámbialos desde Controles de ESO."
EZOKeybinds_Strings["LAM_NO_BINDINGS"] = "Ninguna acción EZO activada tiene una tecla asignada actualmente."
EZOKeybinds_Strings["LAM_SLOT"] = "Slot %d: %s"
EZOKeybinds_Strings["LAM_RESET_DEFAULTS"] = "Restaurar teclas EZO predeterminadas"
EZOKeybinds_Strings["LAM_RESET_DEFAULTS_TOOLTIP"] = "Tras confirmar, limpia las acciones EZO activadas, pone los valores de teclado en el slot 1 y los valores de gamepad en el slot 2, y vacía los slots 3 y 4. Los defaults de gamepad siguen el comportamiento manual por capas de ESO y nunca se aplican automáticamente al iniciar."
EZOKeybinds_Strings["RESET_DIALOG_TITLE"] = "Restaurar teclas EZO predeterminadas"
EZOKeybinds_Strings["RESET_DIALOG_TEXT"] = "Esto limpia los cuatro slots de las acciones EZO activadas. Los valores de teclado vuelven al slot 1 y los valores de gamepad al slot 2; los slots 3 y 4 quedan vacíos. Un botón de gamepad usado en otra capa de acciones de ESO no bloqueará el binding EZO, por lo que ambas acciones pueden responder cuando las dos capas estén activas. ¿Continuar?"
EZOKeybinds_Strings["RESET_DONE"] = "EZOKeybinds: restauradas %d acciones EZO; omitidos %d valores ocupados o no disponibles."
EZOKeybinds_Strings["RESET_UNAVAILABLE"] = "EZOKeybinds: las funciones seguras de teclas no están disponibles; no se ha cambiado nada."
EZOKeybinds_Strings["RESET_FAILED"] = "EZOKeybinds: ha fallado la restauración; revisa el registro técnico."
