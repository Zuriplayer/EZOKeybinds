EZOKeybinds = EZOKeybinds or {}
local EZOKeybinds = EZOKeybinds

EZOKeybinds.name = "EZOKeybinds"
EZOKeybinds.version = "1.0.12"
EZOKeybinds.addOnVersion = 10012
EZOKeybinds._enabled = false
EZOKeybinds._retrying = false

local EVENT_MANAGER = EVENT_MANAGER
local GetActionInfo = GetActionInfo
local GetActionLabel = GetActionLabel
local GetActionLayerCategoryInfo = GetActionLayerCategoryInfo
local GetActionLayerInfo = GetActionLayerInfo
local GetBindingIndicesFromKeys = GetBindingIndicesFromKeys
local GetNumActionLayers = GetNumActionLayers
local KEY_INVALID = KEY_INVALID
local SLASH_COMMANDS = SLASH_COMMANDS
local _G = _G
local pairs = pairs
local string_format = string.format
local table_concat = table.concat
local table_insert = table.insert
local zo_callLater = zo_callLater
local tostring = tostring
local type = type

local RETRY_DELAYS_MS = { 500, 1500, 3000 }
local MODIFIER_ALIASES = {
    ALT = "KEY_ALT",
    COMMAND = "KEY_COMMAND",
    CTRL = "KEY_CTRL",
    SHIFT = "KEY_SHIFT",
}

EZOKeybinds.defaultRegistry = EZOKeybinds.defaultRegistry or {}
EZOKeybinds._lastDefaultValidation = EZOKeybinds._lastDefaultValidation or nil

local function Print(message)
    if CHAT_SYSTEM and type(CHAT_SYSTEM.AddMessage) == "function" then
        CHAT_SYSTEM:AddMessage(tostring(message))
    else
        d(tostring(message))
    end
end

local function GetLogger()
    if EZOKeybinds._logger ~= nil then
        return EZOKeybinds._logger
    end

    local lib = _G.LibDebugLogger
    if type(lib) ~= "function" and type(lib) ~= "table" then
        return nil
    end

    local ok, logger = false, nil

    if type(lib) == "function" then
        ok, logger = pcall(lib, EZOKeybinds.name)
    end

    if (not ok or logger == nil) and type(lib) == "table" and type(lib.Create) == "function" then
        ok, logger = pcall(function()
            return lib:Create(EZOKeybinds.name)
        end)

        if not ok or logger == nil then
            ok, logger = pcall(lib.Create, EZOKeybinds.name)
        end
    end

    if not ok or logger == nil then
        return nil
    end

    if type(logger.SetMinLevelOverride) == "function" and type(lib) == "table" and lib.LOG_LEVEL_DEBUG ~= nil then
        pcall(function()
            logger:SetMinLevelOverride(lib.LOG_LEVEL_DEBUG)
        end)
    end

    EZOKeybinds._logger = logger
    return logger
end

local function DebugLog(message)
    local logger = GetLogger()

    if not logger then
        return false
    end

    if type(logger.Debug) == "function" then
        return pcall(function()
            logger:Debug(tostring(message))
        end)
    end

    local lib = _G.LibDebugLogger
    if type(logger.Log) == "function" and type(lib) == "table" and lib.LOG_LEVEL_DEBUG ~= nil then
        return pcall(function()
            logger:Log(lib.LOG_LEVEL_DEBUG, tostring(message))
        end)
    end

    return false
end

local function CanOpenDebugLogViewer()
    local viewer = _G.DebugLogViewer

    if not viewer then
        return false
    end

    return type(viewer.ShowWindow) == "function" or type(viewer.ToggleWindow) == "function"
end

local function GetKeyConstant(part)
    local value = _G[part]

    if type(value) == "number" then
        return value
    end

    local alias = MODIFIER_ALIASES[part]
    if alias then
        value = _G[alias]

        if type(value) == "number" then
            return value
        end
    end

    return nil
end

local function GetBindingParts(bindingName)
    if type(bindingName) ~= "string" or bindingName == "" or bindingName == "unbound" then
        return nil
    end

    local key = GetKeyConstant(bindingName)
    if key then
        return key, KEY_INVALID, KEY_INVALID, KEY_INVALID, KEY_INVALID
    end

    local parts = {}
    for part in bindingName:gmatch("[^+]+") do
        table_insert(parts, part)
    end

    key = GetKeyConstant(parts[#parts] or "")
    if not key then
        return nil
    end

    local mods = { KEY_INVALID, KEY_INVALID, KEY_INVALID, KEY_INVALID }

    for index = 1, #parts - 1 do
        local mod = GetKeyConstant(parts[index])

        if not mod then
            return nil
        end

        mods[index] = mod
    end

    return key, mods[1], mods[2], mods[3], mods[4]
end

local function FindActionIndices(actionName)
    if type(actionName) ~= "string" or actionName == "" then
        return nil
    end

    for layerIndex = 1, GetNumActionLayers() do
        local _, numCategories = GetActionLayerInfo(layerIndex)

        for categoryIndex = 1, numCategories do
            local _, numActions = GetActionLayerCategoryInfo(layerIndex, categoryIndex)

            for actionIndex = 1, numActions do
                local currentActionName = GetActionInfo(layerIndex, categoryIndex, actionIndex)

                if currentActionName == actionName then
                    return layerIndex, categoryIndex, actionIndex
                end
            end
        end
    end

    return nil
end

local function GetActionContext(layerIndex, categoryIndex, actionIndex, bindingIndex)
    local layerName = GetActionLayerInfo(layerIndex)
    local categoryName = GetActionLayerCategoryInfo(layerIndex, categoryIndex)
    local actionName = GetActionInfo(layerIndex, categoryIndex, actionIndex)
    local actionLabel = actionName or "-"

    if actionName and type(GetActionLabel) == "function" then
        actionLabel = GetActionLabel(actionName)
    elseif actionName and type(GetString) == "function" then
        local stringId = _G["SI_BINDING_NAME_" .. actionName]

        if stringId ~= nil then
            actionLabel = GetString(stringId)
        end
    end

    return {
        layerIndex = layerIndex,
        layerName = tostring(layerName or layerIndex),
        categoryIndex = categoryIndex,
        categoryName = tostring(categoryName or categoryIndex),
        actionIndex = actionIndex,
        actionName = actionName or "-",
        actionLabel = actionLabel or "-",
        bindingIndex = bindingIndex or 0,
    }
end

local function SameAction(categoryIndex, actionIndex, targetCategoryIndex, targetActionIndex)
    return categoryIndex == targetCategoryIndex and actionIndex == targetActionIndex
end

local function ValidateBindingCandidate(actionName, device, bindingName, candidateType)
    local result = {
        actionName = actionName,
        device = device,
        binding = bindingName or "-",
        candidateType = candidateType,
        status = "ok",
        conflict = nil,
    }

    local layerIndex, categoryIndex, actionIndex = FindActionIndices(actionName)
    if not layerIndex then
        result.status = "missing-action"
        return result
    end

    result.target = GetActionContext(layerIndex, categoryIndex, actionIndex, 0)

    if type(GetBindingIndicesFromKeys) ~= "function" then
        result.status = "native-api-missing"
        return result
    end

    local key, mod1, mod2, mod3, mod4 = GetBindingParts(bindingName)
    if not key then
        result.status = "unsupported-binding"
        return result
    end

    local conflictCategoryIndex, conflictActionIndex, conflictBindingIndex = GetBindingIndicesFromKeys(layerIndex, key, mod1, mod2, mod3, mod4)

    if conflictCategoryIndex and conflictActionIndex and conflictBindingIndex then
        if SameAction(conflictCategoryIndex, conflictActionIndex, categoryIndex, actionIndex) then
            result.status = "own-action"
        else
            result.status = "blocked"
            result.conflict = GetActionContext(layerIndex, conflictCategoryIndex, conflictActionIndex, conflictBindingIndex)
        end
    end

    return result
end

local function AddDeviceCandidates(results, action, device)
    local config = type(action[device]) == "table" and action[device] or nil

    if not config then
        return
    end

    if config.preferred then
        table_insert(results, ValidateBindingCandidate(action.action or action.name, device, config.preferred, "preferred"))
    end

    if type(config.fallbacks) == "table" then
        for index = 1, #config.fallbacks do
            table_insert(results, ValidateBindingCandidate(action.action or action.name, device, config.fallbacks[index], "fallback"))
        end
    end
end

local function FindFirstUsableCandidate(results)
    for index = 1, #results do
        local result = results[index]

        if result.status == "ok" or result.status == "own-action" then
            return result
        end
    end

    return nil
end

function EZOKeybinds:RegisterAddonDefaults(addonName, defaults)
    if type(addonName) ~= "string" or addonName == "" or type(defaults) ~= "table" then
        return false
    end

    self.defaultRegistry[addonName] = defaults
    return true
end

function EZOKeybinds:GetAddonDefaults(addonName)
    return self.defaultRegistry[addonName]
end

function EZOKeybinds:ValidateAddonDefaults(addonName)
    local defaults = self.defaultRegistry[addonName]
    local validation = {
        addonName = addonName,
        actions = {},
        total = 0,
        totalCandidates = 0,
        ok = 0,
        blocked = 0,
        missing = 0,
        unsupported = 0,
    }

    if type(defaults) ~= "table" then
        return validation
    end

    for index = 1, #defaults do
        local action = defaults[index]
        local actionName = type(action) == "table" and (action.action or action.name) or nil
        local actionResults = {}

        if actionName then
            AddDeviceCandidates(actionResults, action, "gamepad")
            AddDeviceCandidates(actionResults, action, "keyboard")
        end

        local usable = FindFirstUsableCandidate(actionResults)
        local actionValidation = {
            actionName = actionName or "-",
            candidates = actionResults,
            selected = usable,
            status = usable and "ok" or "blocked",
        }

        table_insert(validation.actions, actionValidation)
        validation.total = validation.total + 1

        for resultIndex = 1, #actionResults do
            local status = actionResults[resultIndex].status

            validation.totalCandidates = validation.totalCandidates + 1
            if status == "ok" or status == "own-action" then validation.ok = validation.ok + 1 end
            if status == "blocked" then validation.blocked = validation.blocked + 1 end
            if status == "missing-action" then validation.missing = validation.missing + 1 end
            if status == "unsupported-binding" then validation.unsupported = validation.unsupported + 1 end
        end
    end

    return validation
end

function EZOKeybinds:ValidateAllAddonDefaults()
    local all = {
        addons = {},
        total = 0,
        totalCandidates = 0,
        ok = 0,
        blocked = 0,
    }

    for addonName in pairs(self.defaultRegistry) do
        local validation = self:ValidateAddonDefaults(addonName)

        table_insert(all.addons, validation)
        all.total = all.total + validation.total
        all.totalCandidates = all.totalCandidates + validation.totalCandidates
        all.ok = all.ok + validation.ok
        all.blocked = all.blocked + validation.blocked
    end

    self._lastDefaultValidation = all
    return all
end

function EZOKeybinds:GetLastDefaultValidation()
    return self._lastDefaultValidation
end

function EZOKeybinds:DebugDefaultValidation()
    local validation = self:ValidateAllAddonDefaults()
    local lines = {}
    local header = string_format(
        "EZOKeybinds default validation || version=%s addonVersion=%s || addons=%d actions=%d candidates=%d ok=%d blocked=%d",
        self.version,
        tostring(self.addOnVersion),
        #validation.addons,
        validation.total,
        validation.totalCandidates,
        validation.ok,
        validation.blocked
    )

    for addonIndex = 1, #validation.addons do
        local addon = validation.addons[addonIndex]

        for actionIndex = 1, #addon.actions do
            local action = addon.actions[actionIndex]

            for candidateIndex = 1, #action.candidates do
                local candidate = action.candidates[candidateIndex]
                local conflict = candidate.conflict
                local conflictText = "-"

                if conflict then
                    conflictText = string_format(
                        "%s/%s/%s [%s] slot %d",
                        conflict.layerName,
                        conflict.categoryName,
                        conflict.actionLabel,
                        conflict.actionName,
                        conflict.bindingIndex
                    )
                end

                table_insert(lines, string_format(
                    "%s || %s || %s/%s || binding=%s || status=%s || conflict=%s",
                    addon.addonName,
                    action.actionName,
                    candidate.device,
                    candidate.candidateType,
                    candidate.binding,
                    candidate.status,
                    conflictText
                ))
            end
        end
    end

    local logged = DebugLog(header)

    if logged then
        for index = 1, #lines do
            DebugLog(lines[index])
        end
    else
        d(header)
        d(table_concat(lines, "\n"))
    end

    if logged and CanOpenDebugLogViewer() then
        Print(string_format("EZOKeybinds: default validation logged addons=%d actions=%d candidates=%d ok=%d blocked=%d", #validation.addons, validation.total, validation.totalCandidates, validation.ok, validation.blocked))
    elseif logged then
        Print(string_format("EZOKeybinds: default validation logged, but DebugLogViewer is not available. addons=%d actions=%d candidates=%d ok=%d blocked=%d", #validation.addons, validation.total, validation.totalCandidates, validation.ok, validation.blocked))
    else
        Print(string_format("EZOKeybinds: LibDebugLogger unavailable; printed validation to chat/debug. addons=%d actions=%d candidates=%d ok=%d blocked=%d", #validation.addons, validation.total, validation.totalCandidates, validation.ok, validation.blocked))
    end
end

function EZOKeybinds:RegisterSlashCommands()
    SLASH_COMMANDS["/ezokeybinds"] = function(args)
        local command = (args or ""):lower():gsub("^%s+", ""):gsub("%s+$", "")

        if command == "defaults" then
            self:DebugDefaultValidation()
        else
            Print("EZOKeybinds: use /ezokeybinds defaults")
        end
    end
end

local function TryEnableOn(manager)
    if type(manager) ~= "table" then
        return false
    end

    -- No conviene depender de una sola ruta. En cliente real esta parte ha
    -- cambiado entre versiones, asi que probamos la API nueva y la compatible.
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

local function EnableChording()
    if EZOKeybinds._enabled then
        return true
    end

    local enabled = false

    -- Algunos clientes exponen el dialogo y el manager general por rutas
    -- distintas. Probamos todas las disponibles y dejamos que ESO decida.
    enabled = TryEnableOn(KEYBINDINGS_MANAGER) or enabled
    enabled = TryEnableOn(KEYBINDING_MANAGER) or enabled

    if enabled then
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

    -- A veces ESO termina de preparar estos managers un poco mas tarde.
    -- Reintentamos en silencio para no llenar el chat ni molestar al jugador.
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
    EZOKeybinds:RegisterSlashCommands()
    RetryEnableChording()
end

local function OnPlayerActivated()
    RetryEnableChording()
    EVENT_MANAGER:UnregisterForEvent(EZOKeybinds.name, EVENT_PLAYER_ACTIVATED)
end

EVENT_MANAGER:RegisterForEvent(EZOKeybinds.name, EVENT_ADD_ON_LOADED, OnAddonLoaded)
EVENT_MANAGER:RegisterForEvent(EZOKeybinds.name, EVENT_PLAYER_ACTIVATED, OnPlayerActivated)
