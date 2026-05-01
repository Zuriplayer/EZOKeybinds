EZOKeybinds = EZOKeybinds or {}
local EZOKeybinds = EZOKeybinds

EZOKeybinds.name = "EZOKeybinds"
EZOKeybinds.version = "1.0.1"
EZOKeybinds.addOnVersion = 10001
EZOKeybinds._enabled = false

local EVENT_MANAGER = EVENT_MANAGER
local zo_callLater = zo_callLater

local function PrintToChat(message)
    local prefix = "|c80C8FF[EZOKeybinds]|r "

    if CHAT_SYSTEM and type(CHAT_SYSTEM.AddMessage) == "function" then
        CHAT_SYSTEM:AddMessage(prefix .. tostring(message))
    else
        d("[EZOKeybinds] " .. tostring(message))
    end
end

local function TryEnableOn(manager, managerName)
    if type(manager) ~= "table" then
        return false
    end

    if type(manager.SetChordingAlwaysEnabled) == "function" then
        manager:SetChordingAlwaysEnabled(true)
        PrintToChat("Chording enabled via " .. managerName .. ":SetChordingAlwaysEnabled")
        return true
    end

    if type(manager.SetChordingEnabled) == "function" then
        manager:SetChordingEnabled(true)
        PrintToChat("Chording enabled via " .. managerName .. ":SetChordingEnabled")
        return true
    end

    return false
end

local function EnableChording()
    if EZOKeybinds._enabled then
        return true
    end

    if TryEnableOn(KEYBINDINGS_MANAGER, "KEYBINDINGS_MANAGER") then
        EZOKeybinds._enabled = true
        return true
    end

    if TryEnableOn(KEYBOARD_KEYBINDING_MANAGER, "KEYBOARD_KEYBINDING_MANAGER") then
        EZOKeybinds._enabled = true
        return true
    end

    if TryEnableOn(KEYBINDING_MANAGER, "KEYBINDING_MANAGER") then
        EZOKeybinds._enabled = true
        return true
    end

    return false
end

local function RetryEnableChording()
    if EnableChording() then
        return
    end

    zo_callLater(function()
        if EnableChording() then
            return
        end

        zo_callLater(function()
            if not EnableChording() then
                PrintToChat("WARNING: Could not enable keybinding chording on this client path.")
            end
        end, 1500)
    end, 500)
end

local function OnAddonLoaded(eventCode, addonName)
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
