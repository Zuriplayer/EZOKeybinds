# EZOKeybinds

EZOKeybinds habilita el chording nativo de keybindings de ESO para permitir combinaciones con modificadores como Ctrl, Alt, Shift y Command desde el menu de controles del juego.

El addon no anade interfaz propia, panel de configuracion ni SavedVariables. Activa el comportamiento nativo del cliente cuando el manager de keybindings esta disponible y expone una validacion experimental de defaults para la familia EZO.

## Defaults EZO

Otros addons EZO pueden declarar sus defaults sin aplicarlos directamente:

```lua
if EZOKeybinds then
    EZOKeybinds:RegisterAddonDefaults("EZOTools", {
        {
            action = "EZO_TOGGLE_COMMAND_PANEL",
            gamepad = {
                preferred = "KEY_GAMEPAD_BUTTON_3_HOLD",
            },
            keyboard = {
                preferred = "CTRL+ALT+KEY_NUMPAD0",
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

## Pruebas cerradas

Validar en cliente real:

- El addon aparece habilitado en la lista de addons.
- No muestra mensajes en chat al cargar.
- En teclado, el menu de controles permite asignar combinaciones con modificadores a acciones normales.
- En gamepad, no cambia navegacion, controles ni binds.
- Tras `/reloadui`, las combinaciones siguen disponibles.
- Con `EZOTools` cargado, `/ezokeybinds defaults` lista los defaults declarados y sus conflictos nativos.
- En PTS, revisar si el cliente acepta `APIVersion` 101050 sin marcar el addon como obsoleto.

## Relacion con EZOBindings

`EZOKeybinds` solo habilita la capacidad nativa de chording del cliente.

La validacion de defaults propuesta vive aqui porque esta cerca de la capacidad tecnica de keybindings. `EZOBindings` queda como diagnostico experimental mientras se decide si aporta valor separado.

Mantener esta responsabilidad centralizada evita que `EZOTools`, `EZOChat` y otros addons EZO dupliquen logica de colisiones.

## Compatibilidad

La referencia tecnica principal para APIs de ESO es UESP ESO Data:

https://esodata.uesp.net/current/index.html

En la revision actual, UESP `current` publica API 101047, por detras del manifest del addon (`101049 101050`). UESP confirma el manager nativo de keybindings y la funcion de chording, pero la prueba real en cliente ha mostrado diferencias de exposicion entre rutas del manager.

Por compatibilidad, el addon intenta activar chording sobre los managers que existan en tiempo de ejecucion (`KEYBINDINGS_MANAGER` y `KEYBINDING_MANAGER`) y acepta el metodo moderno `SetChordingAlwaysEnabled` o el metodo compatible `SetChordingEnabled` si esta presente. Todas las llamadas estan protegidas por comprobacion de tipo y no se crean bindings, comandos ni datos persistentes.
