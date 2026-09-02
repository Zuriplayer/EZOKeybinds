-- Textos en francés para EZOKeybinds.
-- Este archivo lo carga el juego automáticamente cuando el idioma del cliente es francés.

EZOKeybinds_Strings = EZOKeybinds_Strings or {}
EZOKeybinds_Strings["UNKNOWN_COMMAND"] = "EZOKeybinds: utilise /ezokeybinds status"
EZOKeybinds_Strings["LAM_HEADER"] = "Raccourcis EZO par défaut"
EZOKeybinds_Strings["LAM_HEADER_TOOLTIP"] = "Vérifie les raccourcis EZO actuels et restaure leurs valeurs déclarées. La modification se fait dans les contrôles ESO ; LibAddonMenu ne possède pas de capture native. L'API Lua publique d'ESO n'expose pas l'état de Verr Num."
EZOKeybinds_Strings["LAM_CURRENT_BINDINGS"] = "Raccourcis EZO actuels"
EZOKeybinds_Strings["LAM_CURRENT_BINDINGS_TOOLTIP"] = "Affiche tous les emplacements actuellement assignés aux actions des addons EZO activés. Modifiez-les dans les contrôles ESO."
EZOKeybinds_Strings["LAM_NO_BINDINGS"] = "Aucune action EZO activée n'a actuellement de touche assignée."
EZOKeybinds_Strings["LAM_SLOT"] = "Emplacement %d : %s"
EZOKeybinds_Strings["LAM_RESET_DEFAULTS"] = "Restaurer les raccourcis EZO par défaut"
EZOKeybinds_Strings["LAM_RESET_DEFAULTS_TOOLTIP"] = "Après confirmation, efface les actions EZO activées, place les valeurs clavier dans l'emplacement 1 et les valeurs manette dans l'emplacement 2, puis vide les emplacements 3 et 4. Les valeurs manette suivent le comportement manuel par couche d'ESO et ne sont jamais appliquées automatiquement au démarrage."
EZOKeybinds_Strings["RESET_DIALOG_TITLE"] = "Restaurer les raccourcis EZO par défaut"
EZOKeybinds_Strings["RESET_DIALOG_TEXT"] = "Cette action efface les quatre emplacements des actions EZO activées. Les valeurs clavier reviennent dans l'emplacement 1 et les valeurs manette dans l'emplacement 2 ; les emplacements 3 et 4 restent vides. Un bouton de manette utilisé dans une autre couche d'actions ESO ne bloque pas le raccourci EZO ; les deux actions peuvent donc répondre si les deux couches sont actives. Continuer ?"
EZOKeybinds_Strings["RESET_DONE"] = "EZOKeybinds : %d actions EZO restaurées ; %d valeurs occupées ou indisponibles ignorées."
EZOKeybinds_Strings["RESET_UNAVAILABLE"] = "EZOKeybinds : les fonctions sécurisées de raccourcis sont indisponibles ; rien n'a été modifié."
EZOKeybinds_Strings["RESET_FAILED"] = "EZOKeybinds : échec de la restauration ; consultez le journal technique."
