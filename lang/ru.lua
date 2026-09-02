-- Textos en ruso para EZOKeybinds.
-- Este archivo lo carga el juego automáticamente cuando el idioma del cliente es ruso.

EZOKeybinds_Strings = EZOKeybinds_Strings or {}
EZOKeybinds_Strings["UNKNOWN_COMMAND"] = "EZOKeybinds: используй /ezokeybinds status"
EZOKeybinds_Strings["LAM_HEADER"] = "Стандартные клавиши EZO"
EZOKeybinds_Strings["LAM_HEADER_TOOLTIP"] = "Показывает текущие клавиши EZO и восстанавливает объявленные значения. Изменение выполняется в настройках управления ESO; LibAddonMenu не имеет встроенного захвата клавиш. Публичный Lua API ESO не сообщает состояние Num Lock."
EZOKeybinds_Strings["LAM_CURRENT_BINDINGS"] = "Текущие клавиши EZO"
EZOKeybinds_Strings["LAM_CURRENT_BINDINGS_TOOLTIP"] = "Показывает все назначенные слоты действий включённых аддонов EZO. Изменяйте их в настройках управления ESO."
EZOKeybinds_Strings["LAM_NO_BINDINGS"] = "Ни одному действию включённых аддонов EZO сейчас не назначена клавиша."
EZOKeybinds_Strings["LAM_SLOT"] = "Слот %d: %s"
EZOKeybinds_Strings["LAM_RESET_DEFAULTS"] = "Восстановить стандартные клавиши EZO"
EZOKeybinds_Strings["LAM_RESET_DEFAULTS_TOOLTIP"] = "После подтверждения очищает действия включённых аддонов EZO, помещает клавиатурные значения в слот 1, значения геймпада в слот 2 и очищает слоты 3 и 4. Значения геймпада следуют ручному поведению ESO по слоям и никогда не применяются автоматически при запуске."
EZOKeybinds_Strings["RESET_DIALOG_TITLE"] = "Восстановить стандартные клавиши EZO"
EZOKeybinds_Strings["RESET_DIALOG_TEXT"] = "Все четыре слота действий включённых аддонов EZO будут очищены. Клавиатурные значения вернутся в слот 1, значения геймпада — в слот 2; слоты 3 и 4 останутся пустыми. Кнопка геймпада, используемая в другом слое действий ESO, не блокирует привязку EZO, поэтому обе команды могут сработать при одновременной активности слоёв. Продолжить?"
EZOKeybinds_Strings["RESET_DONE"] = "EZOKeybinds: восстановлено действий EZO: %d; пропущено занятых или недоступных стандартов: %d."
EZOKeybinds_Strings["RESET_UNAVAILABLE"] = "EZOKeybinds: защищённые функции клавиш недоступны; ничего не изменено."
EZOKeybinds_Strings["RESET_FAILED"] = "EZOKeybinds: восстановление не удалось; проверьте технический журнал."
