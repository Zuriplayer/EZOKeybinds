-- Textos en chino simplificado para EZOKeybinds.
-- Este archivo lo carga el juego automáticamente cuando el idioma del cliente es chino.

EZOKeybinds_Strings = EZOKeybinds_Strings or {}
EZOKeybinds_Strings["UNKNOWN_COMMAND"] = "EZOKeybinds: 请使用 /ezokeybinds status"
EZOKeybinds_Strings["LAM_HEADER"] = "EZO 默认按键"
EZOKeybinds_Strings["LAM_HEADER_TOOLTIP"] = "查看当前 EZO 按键并恢复声明的默认值。请在 ESO 控制设置中修改；LibAddonMenu 没有原生按键捕获控件。ESO 公共 Lua API 不提供 Num Lock 状态。"
EZOKeybinds_Strings["LAM_CURRENT_BINDINGS"] = "当前 EZO 按键"
EZOKeybinds_Strings["LAM_CURRENT_BINDINGS_TOOLTIP"] = "显示已启用 EZO 插件操作当前分配的所有按键槽。请在 ESO 控制设置中修改。"
EZOKeybinds_Strings["LAM_NO_BINDINGS"] = "当前没有已启用的 EZO 操作分配按键。"
EZOKeybinds_Strings["LAM_SLOT"] = "按键槽 %d：%s"
EZOKeybinds_Strings["LAM_RESET_DEFAULTS"] = "恢复 EZO 默认按键"
EZOKeybinds_Strings["LAM_RESET_DEFAULTS_TOOLTIP"] = "确认后清除已启用的 EZO 操作，将键盘默认值放入按键槽 1、手柄默认值放入按键槽 2，并清空按键槽 3 和 4。手柄默认值遵循 ESO 按操作层手动绑定的行为，启动时绝不会自动应用。"
EZOKeybinds_Strings["RESET_DIALOG_TITLE"] = "恢复 EZO 默认按键"
EZOKeybinds_Strings["RESET_DIALOG_TEXT"] = "这会清除已启用 EZO 操作的四个按键槽。键盘默认值回到按键槽 1，手柄默认值回到按键槽 2；按键槽 3 和 4 保持空白。其他 ESO 操作层中已使用的手柄按钮不会阻止 EZO 绑定，因此两个操作层同时激活时，两项操作都可能响应。是否继续？"
EZOKeybinds_Strings["RESET_DONE"] = "EZOKeybinds：已恢复 %d 个 EZO 操作；跳过 %d 个已占用或不可用的默认值。"
EZOKeybinds_Strings["RESET_UNAVAILABLE"] = "EZOKeybinds：安全按键功能不可用；未进行任何更改。"
EZOKeybinds_Strings["RESET_FAILED"] = "EZOKeybinds：恢复失败；请查看技术日志。"
