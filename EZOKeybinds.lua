EZOKeybinds = EZOKeybinds or {}
local EZOKeybinds = EZOKeybinds

EZOKeybinds.name = "EZOKeybinds"
EZOKeybinds.version = "1.0.5"
EZOKeybinds.addOnVersion = 10005
EZOKeybinds._enabled = false
EZOKeybinds._retrying = false
EZOKeybinds._logger = nil

local EVENT_MANAGER = EVENT_MANAGER
local zo_callLater = zo_callLater
local GetString = GetString
local CHAT_SYSTEM = CHAT_SYSTEM
local string_format = string.format
local table_concat = table.concat
local table_insert = table.insert
local tostring = tostring
local type = type

local RETRY_DELAYS_MS = { 500, 1500, 3000 }
local GAMEPAD_KEYS = {
    "KEY_GAMEPAD_DPAD_UP",
    "KEY_GAMEPAD_DPAD_DOWN",
    "KEY_GAMEPAD_DPAD_LEFT",
    "KEY_GAMEPAD_DPAD_RIGHT",
    "KEY_GAMEPAD_START",
    "KEY_GAMEPAD_BACK",
    "KEY_GAMEPAD_LEFT_STICK",
    "KEY_GAMEPAD_RIGHT_STICK",
    "KEY_GAMEPAD_LEFT_SHOULDER",
    "KEY_GAMEPAD_RIGHT_SHOULDER",
    "KEY_GAMEPAD_BUTTON_1",
    "KEY_GAMEPAD_BUTTON_2",
    "KEY_GAMEPAD_BUTTON_3",
    "KEY_GAMEPAD_BUTTON_4",
    "KEY_GAMEPAD_LEFT_TRIGGER",
    "KEY_GAMEPAD_RIGHT_TRIGGER",
    "KEY_GAMEPAD_LSTICK_UP",
    "KEY_GAMEPAD_LSTICK_DOWN",
    "KEY_GAMEPAD_LSTICK_LEFT",
    "KEY_GAMEPAD_LSTICK_RIGHT",
    "KEY_GAMEPAD_RSTICK_UP",
    "KEY_GAMEPAD_RSTICK_DOWN",
    "KEY_GAMEPAD_RSTICK_LEFT",
    "KEY_GAMEPAD_RSTICK_RIGHT",
    "KEY_GAMEPAD_BOTH_SHOULDERS",
    "KEY_GAMEPAD_LEFT_TRIGGER_THEN_RIGHT_TRIGGER",
    "KEY_GAMEPAD_BOTH_STICKS",
    "KEY_GAMEPAD_BOTH_RIGHT_SHOULDER_BUTTON_1",
    "KEY_GAMEPAD_BOTH_RIGHT_SHOULDER_BUTTON_2",
    "KEY_GAMEPAD_BOTH_RIGHT_SHOULDER_BUTTON_3",
    "KEY_GAMEPAD_BOTH_RIGHT_SHOULDER_BUTTON_4",
    "KEY_GAMEPAD_BOTH_LEFT_SHOULDER_BUTTON_1",
    "KEY_GAMEPAD_BOTH_LEFT_SHOULDER_BUTTON_2",
    "KEY_GAMEPAD_BOTH_LEFT_SHOULDER_BUTTON_3",
    "KEY_GAMEPAD_BOTH_LEFT_SHOULDER_BUTTON_4",
    "KEY_GAMEPAD_BOTH_LEFT_SHOULDER_LEFT_STICK",
    "KEY_GAMEPAD_BOTH_LEFT_SHOULDER_RIGHT_STICK",
    "KEY_GAMEPAD_BOTH_LEFT_SHOULDER_DPAD_LEFT",
    "KEY_GAMEPAD_BOTH_LEFT_TRIGGER_BUTTON_1",
    "KEY_GAMEPAD_BOTH_BUTTON_2_BUTTON_4",
    "KEY_GAMEPAD_BOTH_BUTTON_2_BUTTON_3",
    "KEY_GAMEPAD_BOTH_BUTTON_1_BUTTON_4",
    "KEY_GAMEPAD_BOTH_BACK_START",
    "KEY_GAMEPAD_BOTH_TOUCHPAD_START",
    "KEY_GAMEPAD_BOTH_DPAD_RIGHT_BUTTON_2",
    "KEY_GAMEPAD_LEFT_SHOULDER_HOLD",
    "KEY_GAMEPAD_RIGHT_SHOULDER_HOLD",
    "KEY_GAMEPAD_BUTTON_1_HOLD",
    "KEY_GAMEPAD_BUTTON_2_HOLD",
    "KEY_GAMEPAD_BUTTON_3_HOLD",
    "KEY_GAMEPAD_BUTTON_4_HOLD",
    "KEY_GAMEPAD_LEFT_TRIGGER_HOLD",
    "KEY_GAMEPAD_RIGHT_TRIGGER_HOLD",
    "KEY_GAMEPAD_DPAD_UP_HOLD",
    "KEY_GAMEPAD_DPAD_DOWN_HOLD",
    "KEY_GAMEPAD_DPAD_LEFT_HOLD",
    "KEY_GAMEPAD_DPAD_RIGHT_HOLD",
    "KEY_GAMEPAD_START_HOLD",
    "KEY_GAMEPAD_BACK_HOLD",
    "KEY_GAMEPAD_LEFT_STICK_HOLD",
    "KEY_GAMEPAD_RIGHT_STICK_HOLD",
    "KEY_GAMEPAD_TOUCHPAD_HOLD",
    "KEY_GAMEPAD_TOUCHPAD_TOUCHED",
    "KEY_GAMEPAD_TOUCHPAD_PRESSED",
    "KEY_GAMEPAD_TOUCHPAD_SWIPE_UP",
    "KEY_GAMEPAD_TOUCHPAD_SWIPE_DOWN",
    "KEY_GAMEPAD_TOUCHPAD_SWIPE_LEFT",
    "KEY_GAMEPAD_TOUCHPAD_SWIPE_RIGHT",
}

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

    for index = 1, #GAMEPAD_KEYS do
        local name = GAMEPAD_KEYS[index]
        local value = _G[name]

        if type(value) == "number" then
            namesByCode[value] = name
        end
    end

    return namesByCode
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

local function IsNativeGamepadCombo(key, gamepadKeyNames)
    local keyName = gamepadKeyNames[key]

    return keyName
        and (keyName:match("_BOTH_") or keyName:match("_THEN_") or keyName:match("_HOLD") or keyName:match("_SWIPE_"))
end

local function DebugScanGamepadBindings()
    local logger = GetLogger()

    if not logger then
        PrintChat(SI_EZOKEYBINDS_DEBUG_SCAN_MISSING_LOGGER)
        return
    end

    local gamepadKeyNames = BuildGamepadKeyNames()
    local maxBindings = GetMaxBindingsPerAction()
    local currentCount = 0
    local defaultCount = 0
    local interestingCount = 0
    local entries = {}

    -- Ricardo: esto no toca binds. Solo fotografia lo que ESO ya tiene en memoria.
    for layerIndex = 1, GetNumActionLayers() do
        local _, numCategories = GetActionLayerInfo(layerIndex)

        for categoryIndex = 1, numCategories do
            local _, numActions = GetActionLayerCategoryInfo(layerIndex, categoryIndex)

            for actionIndex = 1, numActions do
                local actionName, _, isHidden = GetActionInfo(layerIndex, categoryIndex, actionIndex)

                if actionName and not isHidden then
                    local actionLabel = GetActionLabel(actionName)

                    for bindingIndex = 1, maxBindings do
                        local key, mod1, mod2, mod3, mod4 = GetActionBindingInfo(layerIndex, categoryIndex, actionIndex, bindingIndex)
                        local defaultKey, defaultMod1, defaultMod2, defaultMod3, defaultMod4 = GetActionDefaultBindingInfo(layerIndex, categoryIndex, actionIndex, bindingIndex)
                        local hasCurrentGamepad = IsGamepadBinding(key, mod1, mod2, mod3, mod4, gamepadKeyNames)
                        local hasDefaultGamepad = IsGamepadBinding(defaultKey, defaultMod1, defaultMod2, defaultMod3, defaultMod4, gamepadKeyNames)

                        if hasCurrentGamepad or hasDefaultGamepad then
                            local status = SameBinding(key, mod1, mod2, mod3, mod4, defaultKey, defaultMod1, defaultMod2, defaultMod3, defaultMod4) and "default" or "custom"
                            local isInteresting = status == "custom"
                                or IsNativeGamepadCombo(key, gamepadKeyNames)
                                or IsNativeGamepadCombo(defaultKey, gamepadKeyNames)

                            if hasCurrentGamepad then currentCount = currentCount + 1 end
                            if hasDefaultGamepad then defaultCount = defaultCount + 1 end

                            if isInteresting then
                                interestingCount = interestingCount + 1
                                table_insert(entries, string_format(
                                    "%s | %s | slot %d | current=%s | default=%s",
                                    status,
                                    actionLabel,
                                    bindingIndex,
                                    FormatBinding(key, mod1, mod2, mod3, mod4, gamepadKeyNames),
                                    FormatBinding(defaultKey, defaultMod1, defaultMod2, defaultMod3, defaultMod4, gamepadKeyNames)
                                ))
                            end
                        end
                    end
                end
            end
        end
    end

    logger:Debug(
        "EZOKeybinds gamepad scan | version=%s addonVersion=%s | nativeKeys=%d | currentGamepad=%d | defaultGamepad=%d | listed=%d\n%s",
        EZOKeybinds.version,
        tostring(EZOKeybinds.addOnVersion),
        #GAMEPAD_KEYS,
        currentCount,
        defaultCount,
        interestingCount,
        table_concat(entries, "\n")
    )
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
