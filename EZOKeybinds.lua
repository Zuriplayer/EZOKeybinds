-- EZOKeybinds — activa la opción nativa de combinaciones con modificadores en ESO
-- y permite compartir bindings EZO entre personajes cuando el cliente expone la vía segura.

EZOKeybinds = EZOKeybinds or {}
local EZOKeybinds = EZOKeybinds

EZOKeybinds.name         = "EZOKeybinds"
EZOKeybinds.version      = "1.0.27"
EZOKeybinds.addOnVersion = 10027
EZOKeybinds._enabled     = false  -- si el chording ya está activo
EZOKeybinds._retrying    = false  -- si estamos esperando para volver a intentarlo
EZOKeybinds._uiHooked    = false
EZOKeybinds._restoring   = false
EZOKeybinds._lamRegistered = false

-- Guardamos referencias directas a las cosas que vamos a usar,
-- así el juego no tiene que buscarlas en la tabla global cada vez que las necesitamos.
local EVENT_MANAGER  = EVENT_MANAGER
local SLASH_COMMANDS = SLASH_COMMANDS
local _G             = _G
local math_max       = math.max
local string_find    = string.find
local string_format  = string.format
local string_sub     = string.sub
local table_concat   = table.concat
local table_sort     = table.sort
local tostring       = tostring
local type           = type
local zo_callLater   = zo_callLater
local LOGGER_TAG     = "EZOKeybinds"
local SAVED_VARIABLES_NAME = "EZOKeybinds_Saved"
local SAVED_VARIABLES_VERSION = 1
local LAYER_DATA_TYPE = 1
local LAYER_HEADER_HEIGHT = 96
local KEYBIND_DATA_TYPE = 3
local EZO_ACTION_PREFIX = "EZO"
local EZO_CATEGORY_MARKER = "EZO AddOns"
local EZO_ACTION_LAYER_NAME = "E|cB040FFZ|rO AddOns"
local INVALID_KEY = KEY_INVALID or 0
local INFO_HEADER_TEXTURE = "EsoUI/Art/Miscellaneous/help_icon.dds"
local LAM_PANEL_ID = "EZOKeybinds_Options"
local RESET_DIALOG_NAME = "EZOKEYBINDS_RESET_DEFAULTS"
local bindKeyToAction
local unbindAllKeysFromAction
local resetDialogRegistered = false

-- Registro central usado por la auditoria y por el reset explicito. El reset
-- confirmado coloca teclado en slot 1 y gamepad en slot 2. Los addons
-- propietarios no registran estos defaults de gamepad durante el inicio.
local DEFAULT_BINDINGS = {
    {
        addon = "EZOArmory",
        action = "EZOARMORY_TOGGLE_WINDOW",
        keyboard = { key = "KEY_NUMPAD0", modifiers = { "KEY_SHIFT" } },
    },
    {
        addon = "EZOTools",
        action = "EZO_TOGGLE_COMMAND_PANEL",
        keyboard = { key = "KEY_NUMPAD1", modifiers = { "KEY_SHIFT" } },
        gamepad = { key = "KEY_GAMEPAD_BUTTON_3_HOLD", sameLayerOnly = true },
    },
    {
        addon = "EZOTools",
        action = "EZO_TOGGLE_UTILITY_PANEL",
        keyboard = { key = "KEY_NUMPAD2", modifiers = { "KEY_SHIFT" } },
        gamepad = { key = "KEY_GAMEPAD_BUTTON_4_HOLD", sameLayerOnly = true },
    },
    {
        addon = "EZOCombat",
        action = "EZO_COMBAT_TOGGLE_WINDOW",
        keyboard = { key = "KEY_NUMPAD3", modifiers = { "KEY_SHIFT" } },
    },
    {
        addon = "EZOpvp",
        action = "EZOPVP_TOGGLE_PVP_MENU",
        keyboard = { key = "KEY_NUMPAD4", modifiers = { "KEY_SHIFT" } },
        gamepad = { key = "KEY_GAMEPAD_BUTTON_1_HOLD", sameLayerOnly = true },
    },
    {
        addon = "EZOTools",
        action = "EZO_RELOAD_UI",
        keyboard = { key = "KEY_NUMPAD_MINUS" },
    },
    {
        addon = "EZOTools",
        action = "EZO_TRAVEL_PRIMARY_HOUSE",
        keyboard = { key = "KEY_NUMPAD_ADD" },
    },
}

-- Cuánto tiempo esperamos entre cada intento (en milisegundos):
-- medio segundo, segundo y medio, tres segundos.
local RETRY_DELAYS_MS = { 500, 1500, 3000 }

-- Devuelve el texto localizado para una clave dada.
-- El archivo de idioma correcto ya debe estar cargado antes de que esto se llame.
-- Si por algún motivo no está disponible, devuelve el texto en inglés como plan B.
local function GetString(key)
    local strings = _G.EZOKeybinds_Strings
    if type(strings) == "table" and type(strings[key]) == "string" then
        return strings[key]
    end
    -- Plan B: si el archivo de idioma no cargó por cualquier razón, usamos inglés.
    local fallback = {
        UNKNOWN_COMMAND = "EZOKeybinds: use /ezokeybinds status or /ezokeybinds restore",
        ACCOUNT_WIDE_CATEGORY_NOTE = "* Checked box = account-wide EZO binding.",
        ACCOUNT_WIDE_TOOLTIP = "Share this EZO keybinding with every character on this Windows user profile.",
        SHARING_UNAVAILABLE = "EZOKeybinds: keybind sharing is not available in this client session.",
        LAM_HEADER = "EZO keybinding defaults",
        LAM_HEADER_TOOLTIP = "Review current EZO-family bindings and restore their declared defaults. Edit bindings in ESO Controls; LibAddonMenu has no native key-capture control. ESO's public Lua API does not expose the Num Lock state.",
        LAM_CURRENT_BINDINGS = "Current EZO bindings",
        LAM_CURRENT_BINDINGS_TOOLTIP = "Shows every currently assigned slot for enabled EZO addon actions. Change them from ESO Controls.",
        LAM_NO_BINDINGS = "No enabled EZO action currently has an assigned key.",
        LAM_SLOT = "Slot %d: %s",
        LAM_RESET_DEFAULTS = "Restore EZO keybinding defaults",
        LAM_RESET_DEFAULTS_TOOLTIP = "After confirmation, clears enabled EZO actions, puts keyboard defaults in slot 1 and gamepad defaults in slot 2, and clears slots 3 and 4. Gamepad defaults follow ESO's manual per-layer binding behavior and are never applied automatically at startup.",
        RESET_DIALOG_TITLE = "Restore EZO keybinding defaults",
        RESET_DIALOG_TEXT = "This clears all four slots of enabled EZO actions. Keyboard defaults return to slot 1 and gamepad defaults to slot 2; slots 3 and 4 remain empty. A gamepad button already used in another ESO action layer will not block the EZO binding, so both actions may respond when both layers are active. Continue?",
        RESET_DONE = "EZOKeybinds: restored %d EZO actions; skipped %d occupied or unavailable defaults.",
        RESET_UNAVAILABLE = "EZOKeybinds: secure keybinding functions are unavailable; nothing was changed.",
        RESET_FAILED = "EZOKeybinds: the default restore failed; inspect the technical log.",
    }
    return fallback[key] or key
end

local function LogInfo(message)
    if EZOKeybinds._debugLoggerUnavailable == true then
        return false
    end

    local lib = _G.LibDebugLogger
    if type(lib) ~= "function" and type(lib) ~= "table" then
        EZOKeybinds._debugLoggerUnavailable = true
        return false
    end

    if not EZOKeybinds._debugLogger and type(lib) == "function" then
        local ok, logger = pcall(lib, LOGGER_TAG)
        if ok then
            EZOKeybinds._debugLogger = logger
        end
    end
    if not EZOKeybinds._debugLogger and type(lib) == "table" and type(lib.Create) == "function" then
        local ok, logger = pcall(function()
            return lib:Create(LOGGER_TAG)
        end)
        if ok then
            EZOKeybinds._debugLogger = logger
        end
    end

    local logger = EZOKeybinds._debugLogger
    if logger and type(logger.Info) == "function" then
        EZOKeybinds._debugLoggerUnavailable = false
        return pcall(function()
            logger:Info(tostring(message or ""))
        end)
    end

    EZOKeybinds._debugLoggerUnavailable = true
    return false
end

local function Print(message)
    local text = tostring(message)
    local chatSystem = _G.CHAT_SYSTEM

    if type(chatSystem) == "table" and type(chatSystem.AddMessage) == "function" then
        chatSystem:AddMessage(text)
    elseif type(_G.d) == "function" then
        _G.d(text)
    end
end

local function IsEzoAction(actionName)
    return type(actionName) == "string" and string_sub(actionName, 1, #EZO_ACTION_PREFIX) == EZO_ACTION_PREFIX
end

local function IsAddonInstalledAndEnabled(addonName)
    if type(addonName) ~= "string" or addonName == "" then
        return false
    end

    local manager
    if type(_G.GetAddOnManager) == "function" then
        local ok, resolved = pcall(_G.GetAddOnManager)
        if ok then
            manager = resolved
        end
    end
    manager = manager or _G.AddOnManager or _G.ADD_ON_MANAGER
    if not manager or type(manager.GetNumAddOns) ~= "function" or type(manager.GetAddOnInfo) ~= "function" then
        return false
    end

    local ok, enabled = pcall(function()
        for index = 1, manager:GetNumAddOns() do
            local name, _, _, _, isEnabled = manager:GetAddOnInfo(index)
            if name == addonName then
                return isEnabled == true
            end
        end
        return false
    end)

    return ok and enabled == true
end

local function IsEzoLayer(layerName)
    if type(layerName) ~= "string" then
        return false
    end
    return string_find(layerName, EZO_CATEGORY_MARKER, 1, true) ~= nil
        or string_find(layerName, "O AddOns", 1, true) ~= nil
end

local function GetActionData(data)
    if type(data) == "table" and type(data.GetDataSource) == "function" then
        return data:GetDataSource()
    end
    return data
end

local function EnsureSavedVariables()
    if EZOKeybinds.sv then
        return true
    end

    if not ZO_SavedVars or type(ZO_SavedVars.NewAccountWide) ~= "function" then
        return false
    end

    local world = type(GetWorldName) == "function" and GetWorldName() or nil
    EZOKeybinds.sv = ZO_SavedVars:NewAccountWide(SAVED_VARIABLES_NAME, SAVED_VARIABLES_VERSION, world, {
        sharedActions = {},
        bindings = {},
    })
    EZOKeybinds.sv.sharedActions = EZOKeybinds.sv.sharedActions or {}
    EZOKeybinds.sv.bindings = EZOKeybinds.sv.bindings or {}
    return true
end

local function ResolveSecureBindingFunctions()
    if type(bindKeyToAction) == "function" and type(unbindAllKeysFromAction) == "function" then
        return true
    end

    if type(IsProtectedFunction) == "function" and IsProtectedFunction("BindKeyToAction") then
        if type(CallSecureProtected) == "function" then
            bindKeyToAction = function(...)
                return CallSecureProtected("BindKeyToAction", ...)
            end
        end
    elseif not (type(IsPrivateFunction) == "function" and IsPrivateFunction("BindKeyToAction"))
        and type(BindKeyToAction) == "function"
    then
        bindKeyToAction = BindKeyToAction
    end

    if type(IsProtectedFunction) == "function" and IsProtectedFunction("UnbindAllKeysFromAction") then
        if type(CallSecureProtected) == "function" then
            unbindAllKeysFromAction = function(...)
                return CallSecureProtected("UnbindAllKeysFromAction", ...)
            end
        end
    elseif not (type(IsPrivateFunction) == "function" and IsPrivateFunction("UnbindAllKeysFromAction"))
        and type(UnbindAllKeysFromAction) == "function"
    then
        unbindAllKeysFromAction = UnbindAllKeysFromAction
    end

    return type(bindKeyToAction) == "function" and type(unbindAllKeysFromAction) == "function"
end

local function GetDefaultBindingParts(binding)
    if type(binding) ~= "table" or type(binding.key) ~= "string" then
        return nil
    end

    local key = _G[binding.key]
    if type(key) ~= "number" then
        return nil
    end

    local modifiers = binding.modifiers or {}
    return key,
        (type(modifiers[1]) == "string" and _G[modifiers[1]]) or INVALID_KEY,
        (type(modifiers[2]) == "string" and _G[modifiers[2]]) or INVALID_KEY,
        (type(modifiers[3]) == "string" and _G[modifiers[3]]) or INVALID_KEY,
        (type(modifiers[4]) == "string" and _G[modifiers[4]]) or INVALID_KEY
end

local function GetActionDisplayName(actionName)
    local stringId = _G["SI_BINDING_NAME_" .. tostring(actionName or "")]
    if stringId and type(_G.GetString) == "function" then
        local ok, value = pcall(_G.GetString, stringId)
        if ok and type(value) == "string" and value ~= "" then
            return value
        end
    end
    return tostring(actionName or "")
end

local function GetBindingDisplayText(key, mod1, mod2, mod3, mod4)
    if type(_G.ZO_Keybindings_GetBindingStringFromKeys) == "function" then
        local textureOptions = _G.KEYBIND_TEXTURE_OPTIONS_EMBED_MARKUP
            or _G.KEYBIND_TEXTURE_OPTIONS_NONE
        local ok, value = pcall(
            _G.ZO_Keybindings_GetBindingStringFromKeys,
            key,
            mod1,
            mod2,
            mod3,
            mod4,
            _G.KEYBIND_TEXT_OPTIONS_FULL_NAME,
            textureOptions,
            150,
            150
        )
        if ok and type(value) == "string" and value ~= "" then
            return value
        end
    end

    if type(_G.GetKeyName) == "function" then
        local parts = {}
        for _, keyCode in ipairs({ mod1, mod2, mod3, mod4, key }) do
            if type(keyCode) == "number" and keyCode ~= INVALID_KEY then
                local ok, value = pcall(_G.GetKeyName, keyCode)
                if ok and type(value) == "string" and value ~= "" then
                    parts[#parts + 1] = value
                end
            end
        end
        if #parts > 0 then
            return table_concat(parts, "-")
        end
    end

    return tostring(key)
end

local function CollectActionIndices()
    if type(GetNumActionLayers) ~= "function"
        or type(GetActionLayerInfo) ~= "function"
        or type(GetActionLayerCategoryInfo) ~= "function"
        or type(GetActionInfo) ~= "function"
    then
        return nil
    end

    local actions = {}
    local ok = pcall(function()
        for layerIndex = 1, GetNumActionLayers() do
            local _, categoryCount = GetActionLayerInfo(layerIndex)
            for categoryIndex = 1, categoryCount do
                local _, actionCount = GetActionLayerCategoryInfo(layerIndex, categoryIndex)
                for actionIndex = 1, actionCount do
                    local actionName, isRebindable, isHidden = GetActionInfo(layerIndex, categoryIndex, actionIndex)
                    if type(actionName) == "string" then
                        actions[#actions + 1] = {
                            name = actionName,
                            layerIndex = layerIndex,
                            categoryIndex = categoryIndex,
                            actionIndex = actionIndex,
                            isRebindable = isRebindable,
                            isHidden = isHidden,
                        }
                    end
                end
            end
        end
    end)

    return ok and actions or nil
end

local function BindingMatches(key, mod1, mod2, mod3, mod4, targetKey, targetMod1, targetMod2, targetMod3, targetMod4)
    return key == targetKey
        and mod1 == targetMod1
        and mod2 == targetMod2
        and mod3 == targetMod3
        and mod4 == targetMod4
end

local function FindBindingOwner(actions, targetKey, targetMod1, targetMod2, targetMod3, targetMod4, excludedAction, ignoreEzoActions, requiredLayerIndex)
    if type(GetActionBindingInfo) ~= "function" or type(GetMaxBindingsPerAction) ~= "function" then
        return nil, true
    end

    for _, action in ipairs(actions) do
        if action.name ~= excludedAction
            and (ignoreEzoActions ~= true or not IsEzoAction(action.name))
            and (requiredLayerIndex == nil or action.layerIndex == requiredLayerIndex)
        then
            for bindingIndex = 1, GetMaxBindingsPerAction() do
                local ok, key, mod1, mod2, mod3, mod4 = pcall(
                    GetActionBindingInfo,
                    action.layerIndex,
                    action.categoryIndex,
                    action.actionIndex,
                    bindingIndex
                )
                if not ok then
                    return nil, true
                end
                if BindingMatches(key, mod1, mod2, mod3, mod4, targetKey, targetMod1, targetMod2, targetMod3, targetMod4) then
                    return action.name, false
                end
            end
        end
    end

    return nil, false
end

function EZOKeybinds:GetBindingsSummaryText()
    local actions = CollectActionIndices()
    if not actions or type(GetActionBindingInfo) ~= "function" then
        return GetString("LAM_NO_BINDINGS")
    end

    local maxBindings = type(GetMaxBindingsPerAction) == "function" and GetMaxBindingsPerAction() or 4
    local summaries = {}

    for _, action in ipairs(actions) do
        if IsEzoAction(action.name) and not action.isHidden and action.isRebindable ~= false then
            local slots = {}
            for bindingIndex = 1, maxBindings do
                local ok, key, mod1, mod2, mod3, mod4 = pcall(
                    GetActionBindingInfo,
                    action.layerIndex,
                    action.categoryIndex,
                    action.actionIndex,
                    bindingIndex
                )
                if ok and key ~= nil and key ~= INVALID_KEY then
                    slots[#slots + 1] = string_format(
                        GetString("LAM_SLOT"),
                        bindingIndex,
                        GetBindingDisplayText(key, mod1, mod2, mod3, mod4)
                    )
                end
            end

            if #slots > 0 then
                summaries[#summaries + 1] = {
                    sortKey = GetActionDisplayName(action.name),
                    text = string_format("|cB040FF%s|r\n%s", GetActionDisplayName(action.name), table_concat(slots, "\n")),
                }
            end
        end
    end

    if #summaries == 0 then
        return GetString("LAM_NO_BINDINGS")
    end

    table_sort(summaries, function(left, right)
        return tostring(left.sortKey) < tostring(right.sortKey)
    end)

    local lines = {}
    for index, summary in ipairs(summaries) do
        lines[index] = summary.text
    end
    return table_concat(lines, "\n\n")
end

function EZOKeybinds:RestoreDefaultBindings()
    if not EnsureSavedVariables() or not ResolveSecureBindingFunctions() then
        return false, 0, 0, "unavailable"
    end

    local actions = CollectActionIndices()
    if not actions then
        return false, 0, 0, "unavailable"
    end

    local ezoActions = {}
    for _, action in ipairs(actions) do
        if IsEzoAction(action.name) and not action.isHidden and action.isRebindable ~= false then
            ezoActions[action.name] = action
        end
    end

    local blocked = {}
    local skipped = 0
    local addonEnabled = {}
    for index, definition in ipairs(DEFAULT_BINDINGS) do
        local action = ezoActions[definition.action]
        if addonEnabled[definition.addon] == nil then
            addonEnabled[definition.addon] = IsAddonInstalledAndEnabled(definition.addon)
        end
        blocked[index] = {}
        if not addonEnabled[definition.addon] or not action then
            blocked[index][1] = true
            blocked[index][2] = true
            if not addonEnabled[definition.addon] then
                LogInfo(string_format(
                    "Default bindings skipped for %s; addon %s is not installed and enabled.",
                    tostring(definition.action),
                    tostring(definition.addon)
                ))
            end
        else
            for bindingIndex, binding in ipairs({ definition.keyboard, definition.gamepad }) do
                if binding then
                    local key, mod1, mod2, mod3, mod4 = GetDefaultBindingParts(binding)
                    local owner, scanFailed
                    if key then
                        owner, scanFailed = FindBindingOwner(
                            actions,
                            key,
                            mod1,
                            mod2,
                            mod3,
                            mod4,
                            definition.action,
                            true,
                            binding.sameLayerOnly == true and action.layerIndex or nil
                        )
                    else
                        scanFailed = true
                    end
                    if scanFailed or owner then
                        blocked[index][bindingIndex] = true
                        skipped = skipped + 1
                        LogInfo(string_format(
                            "Default binding skipped for %s slot %d; owner=%s scanFailed=%s.",
                            tostring(definition.action),
                            bindingIndex,
                            tostring(owner or "none"),
                            tostring(scanFailed == true)
                        ))
                    end
                end
            end
        end
    end

    local resetCount = 0
    self._restoring = true
    local ok = pcall(function()
        for _, action in pairs(ezoActions) do
            local unbound = pcall(unbindAllKeysFromAction, action.layerIndex, action.categoryIndex, action.actionIndex)
            if not unbound then
                error("UnbindAllKeysFromAction failed")
            end
            resetCount = resetCount + 1
        end

        for index, definition in ipairs(DEFAULT_BINDINGS) do
            local action = ezoActions[definition.action]
            if action then
                for bindingIndex, binding in ipairs({ definition.keyboard, definition.gamepad }) do
                    if binding and not blocked[index][bindingIndex] then
                        local key, mod1, mod2, mod3, mod4 = GetDefaultBindingParts(binding)
                        local bound = pcall(
                            bindKeyToAction,
                            action.layerIndex,
                            action.categoryIndex,
                            action.actionIndex,
                            bindingIndex,
                            key,
                            mod1,
                            mod2,
                            mod3,
                            mod4
                        )
                        if not bound then
                            error("BindKeyToAction failed")
                        end
                    end
                end
            end
        end
    end)
    self._restoring = false

    if not ok then
        LogInfo("EZO default binding restore failed during secure application.")
        return false, 0, skipped, "failed"
    end

    for actionName, action in pairs(ezoActions) do
        if self.sv.sharedActions[actionName] == true then
            self:SaveActionBindings(actionName, action.layerIndex, action.categoryIndex, action.actionIndex)
        else
            self.sv.bindings[actionName] = nil
        end
    end

    LogInfo(string_format("EZO default bindings restored. actions=%d skipped=%d", resetCount, skipped))
    self:RequestSettingsRefresh()
    return true, resetCount, skipped
end

local function NormalizeModifier(keyCode, mod1, mod2, mod3, mod4)
    if type(ZO_Keybindings_DoesKeyMatchAnyModifiers) == "function" then
        return ZO_Keybindings_DoesKeyMatchAnyModifiers(keyCode, mod1, mod2, mod3, mod4) and keyCode or INVALID_KEY
    end
    if mod1 == keyCode or mod2 == keyCode or mod3 == keyCode or mod4 == keyCode then
        return keyCode
    end
    return INVALID_KEY
end

local function ReadBinding(layerIndex, categoryIndex, actionIndex, bindingIndex)
    local keyCode, mod1, mod2, mod3, mod4 = GetActionBindingInfo(layerIndex, categoryIndex, actionIndex, bindingIndex)
    return {
        keyCode = keyCode or INVALID_KEY,
        mod1 = NormalizeModifier(KEY_CTRL, mod1, mod2, mod3, mod4),
        mod2 = NormalizeModifier(KEY_ALT, mod1, mod2, mod3, mod4),
        mod3 = NormalizeModifier(KEY_SHIFT, mod1, mod2, mod3, mod4),
        mod4 = NormalizeModifier(KEY_COMMAND, mod1, mod2, mod3, mod4),
    }
end

local function IsSameBinding(a, b)
    return type(a) == "table"
        and type(b) == "table"
        and (a.keyCode or INVALID_KEY) == (b.keyCode or INVALID_KEY)
        and (a.mod1 or INVALID_KEY) == (b.mod1 or INVALID_KEY)
        and (a.mod2 or INVALID_KEY) == (b.mod2 or INVALID_KEY)
        and (a.mod3 or INVALID_KEY) == (b.mod3 or INVALID_KEY)
        and (a.mod4 or INVALID_KEY) == (b.mod4 or INVALID_KEY)
end

function EZOKeybinds:SaveActionBindings(actionName, layerIndex, categoryIndex, actionIndex)
    if not IsEzoAction(actionName) or not EnsureSavedVariables() then
        return false
    end

    local maxBindings = type(GetMaxBindingsPerAction) == "function" and GetMaxBindingsPerAction() or 4
    local actionBindings = {}

    for bindingIndex = 1, maxBindings do
        actionBindings[bindingIndex] = ReadBinding(layerIndex, categoryIndex, actionIndex, bindingIndex)
    end

    self.sv.bindings[actionName] = actionBindings
    return true
end

function EZOKeybinds:IsSharedAction(actionName)
    return EnsureSavedVariables() and self.sv.sharedActions[actionName] == true
end

function EZOKeybinds:SetSharedAction(actionName, shared, layerIndex, categoryIndex, actionIndex)
    if not IsEzoAction(actionName) or not EnsureSavedVariables() then
        return false
    end

    self.sv.sharedActions[actionName] = shared == true or nil

    if shared then
        self:SaveActionBindings(actionName, layerIndex, categoryIndex, actionIndex)
    end

    return true
end

function EZOKeybinds:SaveChangedBinding(layerIndex, categoryIndex, actionIndex)
    if self._restoring then
        return
    end

    local actionName = GetActionInfo(layerIndex, categoryIndex, actionIndex)
    if self:IsSharedAction(actionName) then
        self:SaveActionBindings(actionName, layerIndex, categoryIndex, actionIndex)
    end
end

function EZOKeybinds:IsStoredActionCurrent(layerIndex, categoryIndex, actionIndex, storedBindings)
    if type(storedBindings) ~= "table" then
        return true
    end

    local maxBindings = type(GetMaxBindingsPerAction) == "function" and GetMaxBindingsPerAction() or 4
    for bindingIndex = 1, maxBindings do
        if not IsSameBinding(ReadBinding(layerIndex, categoryIndex, actionIndex, bindingIndex), storedBindings[bindingIndex]) then
            return false
        end
    end
    return true
end

function EZOKeybinds:ApplyStoredActionBindings(layerIndex, categoryIndex, actionIndex, storedBindings)
    if type(storedBindings) ~= "table" or self:IsStoredActionCurrent(layerIndex, categoryIndex, actionIndex, storedBindings) then
        return false
    end

    if not ResolveSecureBindingFunctions() then
        LogInfo("Secure keybinding functions unavailable; shared bindings not restored.")
        return false
    end

    local ok = pcall(unbindAllKeysFromAction, layerIndex, categoryIndex, actionIndex)
    if not ok then
        LogInfo("UnbindAllKeysFromAction failed; shared bindings not restored for action.")
        return false
    end

    local maxBindings = type(GetMaxBindingsPerAction) == "function" and GetMaxBindingsPerAction() or 4
    for bindingIndex = 1, maxBindings do
        local stored = storedBindings[bindingIndex]
        local keyCode = type(stored) == "table" and (stored.keyCode or INVALID_KEY) or INVALID_KEY
        if keyCode ~= INVALID_KEY then
            ok = pcall(
                bindKeyToAction,
                layerIndex,
                categoryIndex,
                actionIndex,
                bindingIndex,
                keyCode,
                stored.mod1 or INVALID_KEY,
                stored.mod2 or INVALID_KEY,
                stored.mod3 or INVALID_KEY,
                stored.mod4 or INVALID_KEY
            )
            if not ok then
                LogInfo("BindKeyToAction failed; shared binding restore stopped for action.")
                return false
            end
        end
    end

    return true
end

function EZOKeybinds:RestoreSharedBindings()
    if not EnsureSavedVariables() then
        return false
    end

    local bindings = self.sv.bindings or {}
    local sharedActions = self.sv.sharedActions or {}
    local changed = 0

    self._restoring = true

    for layerIndex = 1, GetNumActionLayers() do
        local _, numCategories = GetActionLayerInfo(layerIndex)
        for categoryIndex = 1, numCategories do
            local _, numActions = GetActionLayerCategoryInfo(layerIndex, categoryIndex)
            for actionIndex = 1, numActions do
                local actionName, _, isHidden = GetActionInfo(layerIndex, categoryIndex, actionIndex)
                local actionBindings = actionName and not isHidden and sharedActions[actionName] and bindings[actionName]
                if type(actionBindings) == "table"
                    and self:ApplyStoredActionBindings(layerIndex, categoryIndex, actionIndex, actionBindings)
                then
                    changed = changed + 1
                end
            end
        end
    end

    self._restoring = false
    LogInfo(string_format("Shared EZO keybindings restored. changed=%d", changed))
    return true
end

function EZOKeybinds:CountSharedActions()
    if not EnsureSavedVariables() then
        return 0
    end

    local count = 0
    for _, shared in pairs(self.sv.sharedActions or {}) do
        if shared == true then
            count = count + 1
        end
    end
    return count
end

-- Nos dice si el chording está activo en este momento.
function EZOKeybinds:IsChordingEnabled()
    return self._enabled == true
end

-- Prepara el texto de estado que se muestra al usar /ezokeybinds status.
-- Siempre en inglés: es información técnica, útil para reportar problemas.
function EZOKeybinds:GetStatusText()
    local status = "pending"

    if self._enabled then
        status = "enabled"
    elseif self._retrying then
        status = "retrying"
    end

    return string_format(
        "EZOKeybinds: chording=%s sharedActions=%s sharing=%s version=%s addonVersion=%s",
        status,
        tostring(self:CountSharedActions()),
        tostring(ResolveSecureBindingFunctions() and "available" or "unavailable"),
        tostring(self.version),
        tostring(self.addOnVersion)
    )
end

-- Registra el comando /ezokeybinds en el chat del juego.
-- Si la tabla de comandos no está disponible todavía, lo indicamos y no hacemos nada.
function EZOKeybinds:RegisterSlashCommands()
    if type(SLASH_COMMANDS) ~= "table" then
        return false
    end

    SLASH_COMMANDS["/ezokeybinds"] = function(args)
        -- Limpiamos espacios al inicio y al final, y pasamos a minúsculas
        -- para que "Status", "STATUS" y "status" funcionen igual.
        local command = tostring(args or ""):gsub("^%s+", ""):gsub("%s+$", ""):lower()

        if command == "" or command == "status" then
            Print(self:GetStatusText())
        elseif command == "restore" then
            if ResolveSecureBindingFunctions() then
                self:RestoreSharedBindings()
            else
                Print(GetString("SHARING_UNAVAILABLE"))
            end
            Print(self:GetStatusText())
        else
            Print(GetString("UNKNOWN_COMMAND"))
        end
    end

    return true
end

function EZOKeybinds:SetupAccountWideCheckbox(control, data)
    local actionData = GetActionData(data)
    local actionName = actionData and actionData.actionName

    if not IsEzoAction(actionName) then
        if control.ezoAccountWideCheckbox then
            control.ezoAccountWideCheckbox:SetHidden(true)
        end
        if control.actionLabel then
            control.actionLabel:SetWidth(260)
        end
        if control.bindingButtons and control.bindingButtons[1] and control.actionLabel then
            local primaryButton = control.bindingButtons[1]
            primaryButton:ClearAnchors()
            primaryButton:SetAnchor(TOPLEFT, control.actionLabel, TOPRIGHT)
        end
        return
    end

    local checkbox = control.ezoAccountWideCheckbox
    if not checkbox then
        checkbox = CreateControlFromVirtual(control:GetName() .. "EZOAccountWide", control, "ZO_CheckButton")
        checkbox:SetDimensions(24, 24)
        checkbox:SetMouseEnabled(true)
        checkbox:SetHandler("OnClicked", function(buttonControl, button)
            ZO_CheckButton_OnClicked(buttonControl, button)
        end)
        ZO_CheckButton_SetTooltipEnabledState(checkbox, true)
        ZO_CheckButton_SetTooltipAnchor(checkbox, RIGHT, checkbox)
        ZO_CheckButton_SetTooltipText(checkbox, GetString("ACCOUNT_WIDE_TOOLTIP"))
        control.ezoAccountWideCheckbox = checkbox
    end

    control.actionLabel:SetWidth(226)
    checkbox:ClearAnchors()
    checkbox:SetAnchor(LEFT, control.actionLabel, RIGHT, 4, 0)
    checkbox:SetHidden(false)

    if control.bindingButtons and control.bindingButtons[1] then
        local primaryButton = control.bindingButtons[1]
        primaryButton:ClearAnchors()
        primaryButton:SetAnchor(TOPLEFT, checkbox, TOPRIGHT, 5, -5)
    end

    ZO_CheckButton_SetCheckState(checkbox, self:IsSharedAction(actionName))
    ZO_CheckButton_SetToggleFunction(checkbox, function(_, checked)
        self:SetSharedAction(
            actionName,
            checked == true,
            actionData.layerIndex,
            actionData.categoryIndex,
            actionData.actionIndex
        )
    end)
end

function EZOKeybinds:SetupLayerNote(control, data)
    local layerData = GetActionData(data)
    local layerName = layerData and layerData.layerName

    if IsEzoLayer(layerName) then
        control:SetText(layerName)
        control:SetHeight(LAYER_HEADER_HEIGHT)
        if type(control.SetVerticalAlignment) == "function" and TEXT_ALIGN_TOP then
            control:SetVerticalAlignment(TEXT_ALIGN_TOP)
        end

        local note = control.ezoAccountWideNote
        if not note then
            note = CreateControl(control:GetName() .. "EZOAccountWideNote", control, CT_LABEL)
            note:SetFont("ZoFontGameSmall")
            note:SetColor(0.8, 0.74, 0.55, 1)
            note:SetDimensions(720, 20)
            note:SetAnchor(TOPLEFT, control, TOPLEFT, 0, 54)
            control.ezoAccountWideNote = note
        end

        note:SetText(GetString("ACCOUNT_WIDE_CATEGORY_NOTE"))
        note:SetHidden(false)
    elseif control.ezoAccountWideNote then
        control.ezoAccountWideNote:SetHidden(true)
    end
end

function EZOKeybinds:PushEzoActionLayer()
    if self._ezoActionLayerPushed then
        return true
    end

    if type(PushActionLayerByName) ~= "function" then
        return false
    end

    local ok = pcall(PushActionLayerByName, EZO_ACTION_LAYER_NAME)
    if ok then
        self._ezoActionLayerPushed = true
        LogInfo("EZO AddOns action layer pushed.")
    end
    return ok
end

function EZOKeybinds:HookControlsPanel()
    if self._uiHooked then
        return true
    end

    local keybindingManager = _G.KEYBOARD_KEYBINDING_MANAGER or _G.KEYBINDING_MANAGER
    local keybindList = keybindingManager and keybindingManager.list
    local listControl = (keybindList and keybindList.list) or _G.ZO_KeybindingsList
    if not listControl or type(ZO_ScrollList_GetDataTypeTable) ~= "function" then
        return false
    end

    local layerDataType = ZO_ScrollList_GetDataTypeTable(listControl, LAYER_DATA_TYPE)
    local keybindDataType = ZO_ScrollList_GetDataTypeTable(listControl, KEYBIND_DATA_TYPE)
    if type(layerDataType) ~= "table"
        or type(layerDataType.setupCallback) ~= "function"
        or type(keybindDataType) ~= "table"
        or type(keybindDataType.setupCallback) ~= "function"
    then
        return false
    end

    local layerSetupCallback = layerDataType.setupCallback
    layerDataType.height = math_max(layerDataType.height or 0, LAYER_HEADER_HEIGHT)
    layerDataType.setupCallback = function(control, data, list)
        layerSetupCallback(control, data, list)
        EZOKeybinds:SetupLayerNote(control, data)
    end

    local keybindSetupCallback = keybindDataType.setupCallback
    keybindDataType.setupCallback = function(control, data, list)
        keybindSetupCallback(control, data, list)
        EZOKeybinds:SetupAccountWideCheckbox(control, data)
    end

    self._uiHooked = true
    LogInfo("Controls panel account-wide checkbox hook installed.")
    return true
end

function EZOKeybinds:RetryHookControlsPanel(delayIndex)
    if self:HookControlsPanel() then
        return
    end

    local delays = RETRY_DELAYS_MS
    if delayIndex > #delays then
        LogInfo("Controls panel account-wide checkbox hook not available after retries.")
        return
    end

    zo_callLater(function()
        EZOKeybinds:RetryHookControlsPanel(delayIndex + 1)
    end, delays[delayIndex])
end

local function CreateInfoHeader(name, tooltip)
    return {
        type = "header",
        name = zo_strformat(
            "<<1>> |cB040FF|t26:26:<<2>>:inheritcolor|t|r",
            tostring(name or ""),
            INFO_HEADER_TEXTURE
        ),
        tooltip = tooltip,
    }
end

function EZOKeybinds:RequestSettingsRefresh()
    local function RefreshHostedPanel()
        local core = _G.EZOCore
        if self.ezoSettingsRegistered
            and type(core) == "table"
            and type(core.RefreshSettingsPanel) == "function"
        then
            pcall(function()
                core:RefreshSettingsPanel(true)
            end)
        end
    end

    if self.ezoSettingsRegistered and type(zo_callLater) == "function" then
        zo_callLater(RefreshHostedPanel, 1)
    else
        RefreshHostedPanel()
    end

    local lam = _G.LibAddonMenu2
    local util = lam and lam.util
    if util and type(util.RequestRefreshIfNeeded) == "function" and self._lamPanel then
        pcall(util.RequestRefreshIfNeeded, self._lamPanel)
    end
end

local function EnsureResetDialog()
    if resetDialogRegistered then
        return true
    end
    if type(ZO_Dialogs_RegisterCustomDialog) ~= "function" then
        return false
    end

    local dialogInfo = {
        canQueue = true,
        title = { text = GetString("RESET_DIALOG_TITLE") },
        mainText = { text = GetString("RESET_DIALOG_TEXT") },
        buttons = {
            [1] = {
                keybind = "DIALOG_PRIMARY",
                text = SI_DIALOG_CONFIRM,
                callback = function()
                    local ok, resetCount, skipped, reason = EZOKeybinds:RestoreDefaultBindings()
                    if ok then
                        Print(string_format(GetString("RESET_DONE"), resetCount, skipped))
                    elseif reason == "failed" then
                        Print(GetString("RESET_FAILED"))
                    else
                        Print(GetString("RESET_UNAVAILABLE"))
                    end
                end,
            },
            [2] = {
                keybind = "DIALOG_NEGATIVE",
                text = SI_DIALOG_CANCEL,
            },
        },
    }

    if type(GAMEPAD_DIALOGS) == "table" and GAMEPAD_DIALOGS.BASIC ~= nil then
        dialogInfo.gamepadInfo = { dialogType = GAMEPAD_DIALOGS.BASIC }
    end

    local ok = pcall(ZO_Dialogs_RegisterCustomDialog, RESET_DIALOG_NAME, dialogInfo)
    resetDialogRegistered = ok
    return ok
end

function EZOKeybinds:ShowDefaultResetDialog()
    if not EnsureResetDialog() or type(ZO_Dialogs_ShowDialog) ~= "function" then
        Print(GetString("RESET_FAILED"))
        return false
    end

    ZO_Dialogs_ShowDialog(RESET_DIALOG_NAME)
    return true
end

local function BuildSettingsOptions()
    return {
        CreateInfoHeader(GetString("LAM_HEADER"), GetString("LAM_HEADER_TOOLTIP")),
        {
            type = "description",
            title = GetString("LAM_CURRENT_BINDINGS"),
            text = function()
                return EZOKeybinds:GetBindingsSummaryText()
            end,
            tooltip = GetString("LAM_CURRENT_BINDINGS_TOOLTIP"),
            width = "full",
        },
        {
            type = "button",
            name = GetString("LAM_RESET_DEFAULTS"),
            tooltip = GetString("LAM_RESET_DEFAULTS_TOOLTIP"),
            func = function()
                EZOKeybinds:ShowDefaultResetDialog()
            end,
            width = "full",
        },
    }
end

function EZOKeybinds:RegisterSettingsPanel()
    if self._lamRegistered then
        return true
    end

    local panelData = {
        type = "panel",
        name = LAM_PANEL_ID,
        displayName = "EZOKeybinds",
        author = "@Zuriplayer",
        version = self.version,
        registerForRefresh = true,
    }

    local core = _G.EZOCore
    if type(core) == "table" and type(core.RegisterSettingsPanel) == "function" then
        local ok, registered = pcall(function()
            return core:RegisterSettingsPanel(self.name, LAM_PANEL_ID, panelData, BuildSettingsOptions)
        end)
        if ok and registered == true then
            self.ezoSettingsRegistered = true
            self._lamRegistered = true
            return true
        end
    end

    local lam = _G.LibAddonMenu2
    if type(lam) ~= "table"
        or type(lam.RegisterAddonPanel) ~= "function"
        or type(lam.RegisterOptionControls) ~= "function"
    then
        return false
    end

    local ok, panel = pcall(function()
        local registeredPanel = lam:RegisterAddonPanel(LAM_PANEL_ID, panelData)
        lam:RegisterOptionControls(LAM_PANEL_ID, BuildSettingsOptions())
        return registeredPanel
    end)
    if not ok then
        LogInfo("EZOKeybinds LAM panel registration failed.")
        return false
    end

    self._lamPanel = panel
    self.ezoSettingsRegistered = false
    self._lamRegistered = true
    return true
end

-- Intenta activar el chording en el gestor de teclas que le pasemos.
-- Dependiendo de la versión del juego, la función puede tener uno de dos nombres,
-- así que probamos los dos por si acaso.
local function TryEnableOn(manager)
    if type(manager) ~= "table" then
        return false
    end

    if type(manager.SetChordingAlwaysEnabled) == "function" then
        manager:SetChordingAlwaysEnabled(true)
        return true
    end

    if type(manager.SetChordingEnabled) == "function" then
        manager:SetChordingEnabled(true)
        return true
    end

    return false
end

-- Intenta activar el chording en los gestores de teclas disponibles del juego.
-- El juego puede tener uno o los dos según la versión del cliente.
local function EnableChording()
    if EZOKeybinds._enabled then
        return true
    end

    local enabled = false

    enabled = TryEnableOn(_G.KEYBINDINGS_MANAGER)          or enabled
    enabled = TryEnableOn(_G.KEYBOARD_KEYBINDING_MANAGER) or enabled
    enabled = TryEnableOn(_G.KEYBINDING_MANAGER)          or enabled

    if enabled then
        EZOKeybinds._enabled  = true
        EZOKeybinds._retrying = false
        LogInfo("Native keybinding chording enabled.")
        return true
    end

    return false
end

-- Si el gestor de teclas no estaba listo todavía, esperamos un poco y lo intentamos de nuevo.
-- Hacemos esto en silencio, sin mensajes en el chat, para no molestar al jugador.
local function ScheduleRetry(delayIndex)
    if EZOKeybinds._enabled then
        EZOKeybinds._retrying = false
        return
    end

    -- Si ya agotamos todos los intentos, paramos sin hacer ruido.
    if delayIndex > #RETRY_DELAYS_MS then
        EZOKeybinds._retrying = false
        LogInfo("Native keybinding chording manager not available after retries.")
        return
    end

    zo_callLater(function()
        if not EnableChording() then
            ScheduleRetry(delayIndex + 1)
        end
    end, RETRY_DELAYS_MS[delayIndex])
end

-- Punto de entrada para los reintentos.
-- Si el primer intento falla y no estamos ya esperando, ponemos en marcha la secuencia.
local function RetryEnableChording()
    if EnableChording() or EZOKeybinds._retrying then
        return
    end

    EZOKeybinds._retrying = true
    LogInfo("Native keybinding chording not ready; scheduling retries.")
    ScheduleRetry(1)
end

-- Esto se ejecuta cuando el addon termina de cargarse.
-- Registramos los comandos de chat e intentamos activar el chording por primera vez.
local function OnAddonLoaded(_, addonName)
    if addonName ~= EZOKeybinds.name then
        return
    end

    -- Nos damos de baja del evento para no recibir más llamadas innecesarias.
    EVENT_MANAGER:UnregisterForEvent(EZOKeybinds.name, EVENT_ADD_ON_LOADED)
    EZOKeybinds:RegisterSlashCommands()
    EZOKeybinds:RegisterSettingsPanel()
    EnsureSavedVariables()
    EZOKeybinds:PushEzoActionLayer()
    RetryEnableChording()
end

-- Esto se ejecuta cuando el personaje ya está en el mundo y la interfaz está lista.
-- Es un segundo intento por si los gestores de teclas no estaban disponibles antes.
local function OnPlayerActivated()
    EnsureSavedVariables()
    EZOKeybinds:PushEzoActionLayer()
    RetryEnableChording()
    EZOKeybinds:RetryHookControlsPanel(1)
    EZOKeybinds:RestoreSharedBindings()
    EVENT_MANAGER:UnregisterForEvent(EZOKeybinds.name, EVENT_PLAYER_ACTIVATED)
end

-- Le decimos al juego que nos avise cuando el addon cargue y cuando el personaje esté listo.
EVENT_MANAGER:RegisterForEvent(EZOKeybinds.name, EVENT_ADD_ON_LOADED,    OnAddonLoaded)
EVENT_MANAGER:RegisterForEvent(EZOKeybinds.name, EVENT_PLAYER_ACTIVATED, OnPlayerActivated)
EVENT_MANAGER:RegisterForEvent(
    EZOKeybinds.name,
    EVENT_KEYBINDING_SET,
    function(_, layerIndex, categoryIndex, actionIndex)
        EZOKeybinds:SaveChangedBinding(layerIndex, categoryIndex, actionIndex)
        EZOKeybinds:RequestSettingsRefresh()
    end
)
EVENT_MANAGER:RegisterForEvent(
    EZOKeybinds.name,
    EVENT_KEYBINDING_CLEARED,
    function(_, layerIndex, categoryIndex, actionIndex)
        EZOKeybinds:SaveChangedBinding(layerIndex, categoryIndex, actionIndex)
        EZOKeybinds:RequestSettingsRefresh()
    end
)
if EVENT_KEYBINDINGS_LOADED then
    EVENT_MANAGER:RegisterForEvent(EZOKeybinds.name, EVENT_KEYBINDINGS_LOADED, function()
        EZOKeybinds:RetryHookControlsPanel(1)
        EZOKeybinds:RestoreSharedBindings()
    end)
end
