# EZOKeybinds

EZOKeybinds habilita el chording nativo de keybindings de ESO para permitir combinaciones con modificadores como Ctrl, Alt, Shift y Command desde el menu de controles del juego.

El addon no anade interfaz propia, panel de configuracion, SavedVariables ni keybinds nuevos. Solo activa el comportamiento nativo del cliente cuando el manager de keybindings esta disponible.

## Pruebas cerradas

Validar en cliente real:

- El addon aparece habilitado en la lista de addons.
- No muestra mensajes en chat al cargar.
- En teclado, el menu de controles permite asignar combinaciones con modificadores a acciones normales.
- En gamepad, no cambia navegacion, controles ni binds.
- Tras `/reloadui`, las combinaciones siguen disponibles.
- En PTS, revisar si el cliente acepta `APIVersion` 101050 sin marcar el addon como obsoleto.
- Para diagnostico o coordinacion de bindings de la familia EZO, usar `EZOBindings`.

## Relacion con EZOBindings

`EZOKeybinds` solo habilita la capacidad nativa de chording del cliente.

`EZOBindings` se encarga del registro, snapshot y diagnostico de bindings para otros addons EZO.

Mantener estas responsabilidades separadas evita que este addon toque input, comandos, SavedVariables o politicas de asignacion.

## Compatibilidad

La referencia tecnica principal para APIs de ESO es UESP ESO Data:

https://esodata.uesp.net/current/index.html

En la revision actual, UESP `current` publica API 101047, por detras del manifest del addon (`101049 101050`). UESP confirma el manager nativo de keybindings y la funcion de chording, pero la prueba real en cliente ha mostrado diferencias de exposicion entre rutas del manager.

Por compatibilidad, el addon intenta activar chording sobre los managers que existan en tiempo de ejecucion (`KEYBINDINGS_MANAGER` y `KEYBINDING_MANAGER`) y acepta el metodo moderno `SetChordingAlwaysEnabled` o el metodo compatible `SetChordingEnabled` si esta presente. Todas las llamadas estan protegidas por comprobacion de tipo y no se crean bindings, comandos ni datos persistentes.
