-- EZOKeybinds — activa la opción nativa de combinaciones con modificadores en ESO
-- y permite compartir bindings EZO entre personajes cuando el cliente expone la vía segura.

EZOKeybinds = EZOKeybinds or {}
local EZOKeybinds = EZOKeybinds

EZOKeybinds.name         = "EZOKeybinds"
EZOKeybinds.version      = "1.0.24"
EZOKeybinds.addOnVersion = 10024
EZOKeybinds._enabled     = false  -- si el chording ya está activo
EZOKeybinds._retrying    = false  -- si estamos esperando para volver a intentarlo
EZOKeybinds._uiHooked    = false
EZOKeybinds._restoring   = false

-- Guardamos referencias directas a las cosas que vamos a usar,
-- así el juego no tiene que buscarlas en la tabla global cada vez que las necesitamos.
local EVENT_MANAGER  = EVENT_MANAGER
local SLASH_COMMANDS = SLASH_COMMANDS
local _G             = _G
local math_max       = math.max
local string_find    = string.find
local string_format  = string.format
local string_sub     = string.sub
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
local bindKeyToAction
local unbindAllKeysFromAction

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
    end
)
EVENT_MANAGER:RegisterForEvent(
    EZOKeybinds.name,
    EVENT_KEYBINDING_CLEARED,
    function(_, layerIndex, categoryIndex, actionIndex)
        EZOKeybinds:SaveChangedBinding(layerIndex, categoryIndex, actionIndex)
    end
)
if EVENT_KEYBINDINGS_LOADED then
    EVENT_MANAGER:RegisterForEvent(EZOKeybinds.name, EVENT_KEYBINDINGS_LOADED, function()
        EZOKeybinds:RetryHookControlsPanel(1)
        EZOKeybinds:RestoreSharedBindings()
    end)
end
