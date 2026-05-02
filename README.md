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

## Compatibilidad

La referencia tecnica principal para APIs de ESO es UESP ESO Data:

https://esodata.uesp.net/current/index.html

En la revision actual, UESP `current` publica API 101047, por detras del manifest del addon (`101049 101050`). Por ese motivo, el addon usa solo la ruta confirmada por UESP para esta funcionalidad: `KEYBINDINGS_MANAGER:SetChordingAlwaysEnabled(true)`.
