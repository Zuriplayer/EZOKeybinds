EZOKeybinds = EZOKeybinds or {}
local EZOKeybinds = EZOKeybinds

EZOKeybinds.name = "EZOKeybinds"
EZOKeybinds.version = "1.0.7"
EZOKeybinds.addOnVersion = 10007
EZOKeybinds._enabled = false
EZOKeybinds._retrying = false

local EVENT_MANAGER = EVENT_MANAGER
local zo_callLater = zo_callLater
local type = type

local RETRY_DELAYS_MS = { 500, 1500, 3000 }

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

local function EnableChording()
    if EZOKeybinds._enabled then
        return true
    end

    local enabled = false

    -- Ricardo: algunos clientes exponen el control del dialogo y el manager general
    -- por rutas distintas. Tocamos todas las que existan y no paramos en el primer OK.
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
    RetryEnableChording()
end

local function OnPlayerActivated()
    RetryEnableChording()
    EVENT_MANAGER:UnregisterForEvent(EZOKeybinds.name, EVENT_PLAYER_ACTIVATED)
end

EVENT_MANAGER:RegisterForEvent(EZOKeybinds.name, EVENT_ADD_ON_LOADED, OnAddonLoaded)
EVENT_MANAGER:RegisterForEvent(EZOKeybinds.name, EVENT_PLAYER_ACTIVATED, OnPlayerActivated)
