EZOKeybinds = EZOKeybinds or {}
local EZOKeybinds = EZOKeybinds

EZOKeybinds.name = "EZOKeybinds"
EZOKeybinds.version = "1.0.21"
EZOKeybinds.addOnVersion = 10021
EZOKeybinds._enabled = false
EZOKeybinds._retrying = false

local EVENT_MANAGER = EVENT_MANAGER
local SLASH_COMMANDS = SLASH_COMMANDS
local _G = _G
local string_format = string.format
local tostring = tostring
local type = type
local zo_callLater = zo_callLater

local RETRY_DELAYS_MS = { 500, 1500, 3000 }

local function Print(message)
    local text = tostring(message)
    local chatSystem = _G.CHAT_SYSTEM

    if type(chatSystem) == "table" and type(chatSystem.AddMessage) == "function" then
        chatSystem:AddMessage(text)
    elseif type(_G.d) == "function" then
        _G.d(text)
    end
end

function EZOKeybinds:IsChordingEnabled()
    return self._enabled == true
end

function EZOKeybinds:GetStatusText()
    local status = "pending"

    if self._enabled then
        status = "enabled"
    elseif self._retrying then
        status = "retrying"
    end

    return string_format(
        "EZOKeybinds: chording=%s version=%s addonVersion=%s",
        status,
        tostring(self.version),
        tostring(self.addOnVersion)
    )
end

function EZOKeybinds:RegisterSlashCommands()
    if type(SLASH_COMMANDS) ~= "table" then
        return false
    end

    SLASH_COMMANDS["/ezokeybinds"] = function(args)
        local command = tostring(args or ""):gsub("^%s+", ""):gsub("%s+$", ""):lower()

        if command == "" or command == "status" then
            Print(self:GetStatusText())
        else
            Print("EZOKeybinds: use /ezokeybinds status")
        end
    end

    return true
end

local function TryEnableOn(manager)
    if type(manager) ~= "table" then
        return false
    end

    -- ESO ha expuesto esta capacidad por rutas distintas segun version/cliente.
    -- Probamos las conocidas sin asumir que todas existan.
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

    enabled = TryEnableOn(_G.KEYBINDINGS_MANAGER) or enabled
    enabled = TryEnableOn(_G.KEYBINDING_MANAGER) or enabled

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

    -- Algunos managers aparecen tarde durante la carga del personaje.
    -- Reintentamos en silencio para no generar ruido en chat.
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
