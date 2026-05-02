EZOKeybinds = EZOKeybinds or {}
local EZOKeybinds = EZOKeybinds

EZOKeybinds.name = "EZOKeybinds"
EZOKeybinds.version = "1.0.3"
EZOKeybinds.addOnVersion = 10003
EZOKeybinds._enabled = false
EZOKeybinds._retrying = false
EZOKeybinds._logger = nil

local EVENT_MANAGER = EVENT_MANAGER
local zo_callLater = zo_callLater
local GetString = GetString
local CHAT_SYSTEM = CHAT_SYSTEM
local table_concat = table.concat
local table_insert = table.insert
local table_sort = table.sort
local tostring = tostring
local type = type
local pairs = pairs

local RETRY_DELAYS_MS = { 500, 1500, 3000 }

local function TryEnableOn(manager)
    if type(manager) ~= "table" then
        return false
    end

    if type(manager.SetChordingAlwaysEnabled) == "function" then
        manager:SetChordingAlwaysEnabled(true)
        return true
    end

    return false
end

local function GetLogger()
    if EZOKeybinds._logger ~= nil then
        return EZOKeybinds._logger
    end

    if LibDebugLogger and type(LibDebugLogger.Create) == "function" then
        EZOKeybinds._logger = LibDebugLogger:Create(EZOKeybinds.name)

        if type(EZOKeybinds._logger.SetMinLevelOverride) == "function" then
            EZOKeybinds._logger:SetMinLevelOverride(LibDebugLogger.LOG_LEVEL_DEBUG)
        end

        return EZOKeybinds._logger
    end

    return nil
end

local function PrintChat(stringId)
    local message = GetString(stringId)

    if CHAT_SYSTEM and type(CHAT_SYSTEM.AddMessage) == "function" then
        CHAT_SYSTEM:AddMessage(message)
    else
        d(message)
    end
end

local function BuildGamepadKeyNames()
    local namesByCode = {}
    local sortedCodes = {}

    for name, value in pairs(_G) do
        if type(name) == "string" and type(value) == "number" and name:match("^KEY_GAMEPAD_") then
            namesByCode[value] = name
            table_insert(sortedCodes, value)
        end
    end

    table_sort(sortedCodes)
    return namesByCode, sortedCodes
end

local function IsValidKey(key)
    return key and key ~= KEY_INVALID
end

local function GetKeyName(key, gamepadKeyNames)
    if not IsValidKey(key) then
        return "KEY_INVALID"
    end

    return gamepadKeyNames[key] or tostring(key)
end

local function IsGamepadBinding(key, mod1, mod2, mod3, mod4, gamepadKeyNames)
    return gamepadKeyNames[key] ~= nil
        or gamepadKeyNames[mod1] ~= nil
        or gamepadKeyNames[mod2] ~= nil
        or gamepadKeyNames[mod3] ~= nil
        or gamepadKeyNames[mod4] ~= nil
end

local function FormatBinding(key, mod1, mod2, mod3, mod4, gamepadKeyNames)
    local parts = {}

    if IsValidKey(mod1) then table_insert(parts, GetKeyName(mod1, gamepadKeyNames)) end
    if IsValidKey(mod2) then table_insert(parts, GetKeyName(mod2, gamepadKeyNames)) end
    if IsValidKey(mod3) then table_insert(parts, GetKeyName(mod3, gamepadKeyNames)) end
    if IsValidKey(mod4) then table_insert(parts, GetKeyName(mod4, gamepadKeyNames)) end
    if IsValidKey(key) then table_insert(parts, GetKeyName(key, gamepadKeyNames)) end

    if #parts == 0 then
        return "unbound"
    end

    return table_concat(parts, " + ")
end

local function GetActionLabel(actionName)
    local stringId = _G["SI_BINDING_NAME_" .. actionName]

    if stringId then
        local label = GetString(stringId)
        if label and label ~= "" then
            return label
        end
    end

    return actionName
end

local function SameBinding(aKey, aMod1, aMod2, aMod3, aMod4, bKey, bMod1, bMod2, bMod3, bMod4)
    return aKey == bKey and aMod1 == bMod1 and aMod2 == bMod2 and aMod3 == bMod3 and aMod4 == bMod4
end

local function DebugScanGamepadBindings()
    local logger = GetLogger()

    if not logger then
        PrintChat(SI_EZOKEYBINDS_DEBUG_SCAN_MISSING_LOGGER)
        return
    end

    local gamepadKeyNames, sortedGamepadCodes = BuildGamepadKeyNames()
    local maxBindings = GetMaxBindingsPerAction()
    local currentCount = 0
    local defaultCount = 0
    local emittedCount = 0

    logger:Debug("=== EZOKeybinds debug scan: gamepad bindings ===")
    logger:Debug("Version=%s AddOnVersion=%s GamepadKeyCodes=%d", EZOKeybinds.version, tostring(EZOKeybinds.addOnVersion), #sortedGamepadCodes)

    -- Ricardo: esto no toca binds. Solo fotografia lo que ESO ya tiene en memoria.
    for layerIndex = 1, GetNumActionLayers() do
        local layerName, numCategories = GetActionLayerInfo(layerIndex)

        for categoryIndex = 1, numCategories do
            local categoryName, numActions = GetActionLayerCategoryInfo(layerIndex, categoryIndex)

            for actionIndex = 1, numActions do
                local actionName, isRebindable, isHidden = GetActionInfo(layerIndex, categoryIndex, actionIndex)

                if actionName and not isHidden then
                    local actionLabel = GetActionLabel(actionName)

                    for bindingIndex = 1, maxBindings do
                        local key, mod1, mod2, mod3, mod4 = GetActionBindingInfo(layerIndex, categoryIndex, actionIndex, bindingIndex)
                        local defaultKey, defaultMod1, defaultMod2, defaultMod3, defaultMod4 = GetActionDefaultBindingInfo(layerIndex, categoryIndex, actionIndex, bindingIndex)
                        local hasCurrentGamepad = IsGamepadBinding(key, mod1, mod2, mod3, mod4, gamepadKeyNames)
                        local hasDefaultGamepad = IsGamepadBinding(defaultKey, defaultMod1, defaultMod2, defaultMod3, defaultMod4, gamepadKeyNames)

                        if hasCurrentGamepad or hasDefaultGamepad then
                            local status = SameBinding(key, mod1, mod2, mod3, mod4, defaultKey, defaultMod1, defaultMod2, defaultMod3, defaultMod4) and "default" or "custom"

                            if hasCurrentGamepad then currentCount = currentCount + 1 end
                            if hasDefaultGamepad then defaultCount = defaultCount + 1 end
                            emittedCount = emittedCount + 1

                            logger:Debug(
                                "[%s] layer=%d:%s category=%d:%s action=%d:%s (%s) slot=%d rebindable=%s current=%s default=%s",
                                status,
                                layerIndex,
                                tostring(layerName),
                                categoryIndex,
                                tostring(categoryName),
                                actionIndex,
                                actionName,
                                actionLabel,
                                bindingIndex,
                                tostring(isRebindable),
                                FormatBinding(key, mod1, mod2, mod3, mod4, gamepadKeyNames),
                                FormatBinding(defaultKey, defaultMod1, defaultMod2, defaultMod3, defaultMod4, gamepadKeyNames)
                            )
                        end
                    end
                end
            end
        end
    end

    logger:Debug("Summary: emitted=%d currentGamepad=%d defaultGamepad=%d", emittedCount, currentCount, defaultCount)
    PrintChat(SI_EZOKEYBINDS_DEBUG_SCAN_STARTED)
end

local function RegisterSlashCommands()
    SLASH_COMMANDS["/ezokb"] = function(args)
        local command = (args or ""):lower():gsub("^%s+", ""):gsub("%s+$", "")

        if command == "debug scan" then
            DebugScanGamepadBindings()
        else
            PrintChat(SI_EZOKEYBINDS_DEBUG_SCAN_USAGE)
        end
    end
end

local function EnableChording()
    if EZOKeybinds._enabled then
        return true
    end

    if TryEnableOn(KEYBINDING_MANAGER) then
        EZOKeybinds._enabled = true
        EZOKeybinds._retrying = false
        return true
    end

    return false
end

local function ScheduleRetry(delayIndex)
    if EZOKeybinds._enabled then
        EZOKeybinds._retrying = false
        return
    end

    if delayIndex > #RETRY_DELAYS_MS then
        EZOKeybinds._retrying = false
        return
    end

    -- ESO carga algunos managers mas tarde segun cliente, idioma y modo de entrada.
    -- Reintentamos en silencio para no molestar al jugador durante pruebas reales.
    zo_callLater(function()
        if not EnableChording() then
            ScheduleRetry(delayIndex + 1)
        end
    end, RETRY_DELAYS_MS[delayIndex])
end

local function RetryEnableChording()
    if EnableChording() or EZOKeybinds._retrying then
        return
    end

    EZOKeybinds._retrying = true
    ScheduleRetry(1)
end

local function OnAddonLoaded(_, addonName)
    if addonName ~= EZOKeybinds.name then
        return
    end

    EVENT_MANAGER:UnregisterForEvent(EZOKeybinds.name, EVENT_ADD_ON_LOADED)
    RegisterSlashCommands()
    RetryEnableChording()
end

local function OnPlayerActivated()
    RetryEnableChording()
    EVENT_MANAGER:UnregisterForEvent(EZOKeybinds.name, EVENT_PLAYER_ACTIVATED)
end

EVENT_MANAGER:RegisterForEvent(EZOKeybinds.name, EVENT_ADD_ON_LOADED, OnAddonLoaded)
EVENT_MANAGER:RegisterForEvent(EZOKeybinds.name, EVENT_PLAYER_ACTIVATED, OnPlayerActivated)
