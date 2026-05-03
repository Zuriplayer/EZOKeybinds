# EZOKeybinds

EZOKeybinds habilita el chording nativo de keybindings de ESO para permitir combinaciones con modificadores como Ctrl, Alt, Shift y Command desde el menu de controles del juego.

El addon funciona por si solo. No anade interfaz propia, panel de configuracion ni SavedVariables. Su funcion principal es activar el comportamiento nativo del cliente cuando el manager de keybindings esta disponible.

Ademas expone una API opcional para que otros addons puedan declarar defaults de bindings sin llamar directamente a la API nativa de ESO.

## Uso independiente

Con solo este addon activo, el flujo esperado es:

- Cargar personaje o ejecutar `/reloadui`.
- Abrir el menu nativo de controles de ESO.
- Asignar combinaciones de teclado con modificadores, por ejemplo `Ctrl+Alt+tecla`, sobre acciones bindables existentes.
- Usar `/ezokeybinds status` si se quiere comprobar que el chording quedo activo.

Si no hay otros addons registrados, los comandos de defaults no aplican nada y no son necesarios para la funcionalidad original.

## Defaults nativos

Otros addons pueden declarar sus defaults sin aplicarlos directamente:

```lua
if EZOKeybinds then
    EZOKeybinds:RegisterAddonDefaults("EZOTools", {
        {
            action = "EZO_TOGGLE_COMMAND_PANEL",
            gamepad = {
                preferred = "KEY_GAMEPAD_BUTTON_3_HOLD",
                fallbacks = {
                    "KEY_GAMEPAD_DPAD_RIGHT_HOLD",
                },
            },
            keyboard = {
                preferred = "CTRL+ALT+KEY_NUMPAD0",
                fallbacks = {
                    "CTRL+SHIFT+KEY_NUMPAD0",
                },
            },
        },
    })
end
```

La validacion usa la API nativa `GetBindingIndicesFromKeys` para comprobar si un
default propuesto desplazaria una accion existente en el mismo layer. La validacion
no asigna ni desasigna bindings.

Comando de diagnostico:

```text
/ezokeybinds defaults
```

Comando para intentar aplicar defaults seguros de un addon registrado:

```text
/ezokeybinds apply-defaults EZOTools
```

El nombre del addon es obligatorio para evitar aplicar defaults del addon equivocado
por descuido. Solo intenta aplicar candidatos que la validacion nativa marca como
libres. Si el binding ya pertenece a la misma accion, lo informa como ya aplicado.
Si un candidato desplazaria otra accion, no lo toca.

## Contrato para otros addons

Los addons que usen `EZOKeybinds` no deberian llamar directamente a
`CreateDefaultActionBind`. La ruta recomendada es registrar sus candidatos con
`RegisterAddonDefaults` y dejar que `EZOKeybinds` valide colisiones y aplique solo
bindings seguros.

Los fallbacks son parte del contrato: cada accion puede declarar un `preferred` y
una lista ordenada de `fallbacks` por dispositivo. `EZOKeybinds` probara primero el
preferido y despues los fallbacks hasta encontrar una opcion libre o ya asignada a
la misma accion.

## Pruebas cerradas

Validar en cliente real:

- El addon aparece habilitado en la lista de addons.
- No muestra mensajes en chat al cargar.
- Con solo `EZOKeybinds` activo, `/ezokeybinds status` responde sin depender de otros addons.
- En teclado, el menu de controles permite asignar combinaciones con modificadores a acciones normales.
- En gamepad, no cambia navegacion, controles ni binds.
- Tras `/reloadui`, las combinaciones siguen disponibles.
- Con `EZOTools` cargado, `/ezokeybinds defaults` lista los defaults declarados y sus conflictos nativos.
- En PTS, revisar si el cliente acepta `APIVersion` 101050 sin marcar el addon como obsoleto.

## Relacion con EZOBindings

`EZOBindings` queda fuera del flujo activo. La gestion util de defaults y colisiones vive en `EZOKeybinds` para mantenerla cerca del chording y de las APIs nativas de ESO.

Mantener esta responsabilidad centralizada evita que `EZOTools`, `EZOChat` y otros addons dupliquen logica de colisiones o llamen directamente a `CreateDefaultActionBind`.

## Compatibilidad

La referencia tecnica principal para APIs de ESO es UESP ESO Data:

https://esodata.uesp.net/current/index.html

En la revision actual, UESP `current` publica API 101047, por detras del manifest del addon (`101049 101050`). UESP confirma el manager nativo de keybindings y la funcion de chording, pero la prueba real en cliente ha mostrado diferencias de exposicion entre rutas del manager.

Por compatibilidad, el addon intenta activar chording sobre los managers que existan en tiempo de ejecucion (`KEYBINDINGS_MANAGER` y `KEYBINDING_MANAGER`) y acepta el metodo moderno `SetChordingAlwaysEnabled` o el metodo compatible `SetChordingEnabled` si esta presente. Todas las llamadas estan protegidas por comprobacion de tipo y no se crean bindings, comandos ni datos persistentes.
