# EZOKeybinds

EZOKeybinds habilita el chording nativo de keybindings de ESO para permitir combinaciones con modificadores como Ctrl, Alt, Shift y Command desde el menu de controles del juego.

El addon funciona por si solo. No anade interfaz propia, panel de configuracion, SavedVariables ni keybinds propios. Su unico objetivo runtime es activar la capacidad nativa de chording cuando el manager de keybindings esta disponible.

## Uso

Con solo este addon activo:

- Cargar personaje o ejecutar `/reloadui`.
- Abrir el menu nativo de Controles de ESO.
- Asignar combinaciones de teclado con modificadores, por ejemplo `Ctrl+Alt+tecla`, sobre acciones bindables existentes.
- Usar `/ezokeybinds status` para comprobar si el chording quedo activo.

## Comandos

```text
/ezokeybinds status
```

El comando muestra un resumen corto en chat. No usa LibDebugLogger ni DebugLogViewer.

## Lo que no hace

EZOKeybinds no gestiona defaults de otros addons, no restablece bindings y no aplica atajos recomendados desde LAM.

Segun la guia familiar actual, cada addon funcional debe:

- Declarar sus acciones bindables en su propio `Bindings.xml`.
- Registrar sus defaults nativos localmente con `CreateDefaultActionBind` si los necesita.
- Hacerlo despues de `EVENT_KEYBINDINGS_LOADED`.
- Mantener esa logica en su propio modulo, por ejemplo `modules/keybinds.lua`.

EZOKeybinds tampoco llama a `BindKeyToAction`. Esa API puede ser privada/protegida en cliente real y no debe usarse desde addons funcionales normales.

## Relacion con la familia EZO

`EZOBindings OLD` queda pausado como historico local. No es dependencia de EZOKeybinds.

Los addons EZO no deben depender de EZOKeybinds para registrar o restablecer controles. Pueden instalarlo de forma independiente si quieren permitir al jugador asignar combinaciones con modificadores desde el menu nativo de ESO.

## Pruebas cerradas

- El addon aparece habilitado en la lista de addons.
- No muestra mensajes en chat al cargar.
- `/ezokeybinds status` responde sin otros addons.
- En teclado, el menu de Controles permite asignar combinaciones con modificadores.
- En gamepad, no cambia navegacion, controles ni binds.
- Tras `/reloadui`, las combinaciones asignadas manualmente siguen disponibles.

## Compatibilidad

La referencia tecnica principal para APIs de ESO es UESP ESO Data:

https://esodata.uesp.net/current/index.html

UESP `current` puede ir por detras del manifest del addon (`101049 101050`). Si hay discrepancia, se prioriza no inventar APIs y validar en cliente real antes de ampliar funcionalidad.

Por compatibilidad, el addon intenta activar chording sobre los managers que existan en tiempo de ejecucion (`KEYBINDINGS_MANAGER` y `KEYBINDING_MANAGER`) y acepta `SetChordingAlwaysEnabled` o `SetChordingEnabled` si estan presentes. Todas las llamadas estan protegidas por comprobacion de tipo.
