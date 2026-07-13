-- EZOKeybinds — activa la opción nativa de combinaciones con modificadores en ESO.
-- Sin interfaces propias, sin guardar datos, sin dependencias obligatorias.

EZOKeybinds = EZOKeybinds or {}
local EZOKeybinds = EZOKeybinds

EZOKeybinds.name         = "EZOKeybinds"
EZOKeybinds.version      = "1.0.22"
EZOKeybinds.addOnVersion = 10022
EZOKeybinds._enabled     = false  -- si el chording ya está activo
EZOKeybinds._retrying    = false  -- si estamos esperando para volver a intentarlo

-- Guardamos referencias directas a las cosas que vamos a usar,
-- así el juego no tiene que buscarlas en la tabla global cada vez que las necesitamos.
local EVENT_MANAGER  = EVENT_MANAGER
local SLASH_COMMANDS = SLASH_COMMANDS
local _G             = _G
local string_format  = string.format
local tostring       = tostring
local type           = type
local zo_callLater   = zo_callLater
local LOGGER_TAG     = "EZOKeybinds"

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
        UNKNOWN_COMMAND = "EZOKeybinds: use /ezokeybinds status",
    }
    return fallback[key] or key
end

-- Manda un mensaje al chat del juego.
-- Si el chat todavía no está listo cuando esto se llama,
-- usamos la función de depuración del juego como alternativa.
local function Print(message)
    local text      = tostring(message)
    local chatSystem = _G.CHAT_SYSTEM

    if type(chatSystem) == "table" and type(chatSystem.AddMessage) == "function" then
        chatSystem:AddMessage(text)
    elseif type(_G.d) == "function" then
        _G.d(text)
    end
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
        "EZOKeybinds: chording=%s version=%s addonVersion=%s",
        status,
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
        else
            Print(GetString("UNKNOWN_COMMAND"))
        end
    end

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

    enabled = TryEnableOn(_G.KEYBINDINGS_MANAGER) or enabled
    enabled = TryEnableOn(_G.KEYBINDING_MANAGER)  or enabled

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
    RetryEnableChording()
end

-- Esto se ejecuta cuando el personaje ya está en el mundo y la interfaz está lista.
-- Es un segundo intento por si los gestores de teclas no estaban disponibles antes.
local function OnPlayerActivated()
    RetryEnableChording()
    EVENT_MANAGER:UnregisterForEvent(EZOKeybinds.name, EVENT_PLAYER_ACTIVATED)
end

-- Le decimos al juego que nos avise cuando el addon cargue y cuando el personaje esté listo.
EVENT_MANAGER:RegisterForEvent(EZOKeybinds.name, EVENT_ADD_ON_LOADED,    OnAddonLoaded)
EVENT_MANAGER:RegisterForEvent(EZOKeybinds.name, EVENT_PLAYER_ACTIVATED, OnPlayerActivated)
