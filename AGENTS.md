# EZOKeybinds - AI Development Rules


<!-- EZO-SHARED-LAM-START -->
## Estándar LAM compartido

Antes de crear o modificar ajustes LibAddonMenu, leer y aplicar:
`E:\DEV\EZOFamilyDocs\docs\ezo-lam-settings-style.md`

Las reglas específicas de este addon tienen prioridad. Si el archivo compartido
no está accesible, no modificar LAM e indicarlo explícitamente.
<!-- EZO-SHARED-LAM-END -->
Este proyecto es un addon para The Elder Scrolls Online dentro de la familia EZO.

## Versionado y APIVersion

- Para cualquier cambio visible del addon, actualizar version con `.\tools\bump-version.ps1 -Patch` o `.\tools\bump-version.ps1 -Version x.y.z`.
- Si el cambio se prepara para release o hay parche de ESO, comprobar la API actual con `/script d(GetAPIVersion())` o fuente fiable ESOUI/UESP.
- `## APIVersion` controla si ESO muestra el addon como desactualizado en la pantalla de complementos/addons.
- No adivinar `## APIVersion`; solo cambiarlo si el valor actual esta verificado.
- Usar `.\tools\bump-version.ps1 -Patch -ApiVersion <api_actual>` para actualizar version y API.
- Mantener como maximo dos valores en `## APIVersion`; ESO ignora entradas adicionales.
- Antes de commit/release ejecutar `.\tools\bump-version.ps1 -Check -ApiVersion <api_actual>` y `git diff --check`.

## Publicacion en Discord

- La publicacion en Discord es un paso separado de commit/push.
- No lanzar workflows de Discord automaticamente tras cada cambio.
- Proponer publicacion solo para cambios funcionales reales, correcciones importantes o versiones suficientemente estables para jugadores.
- Antes de lanzar un workflow de Discord, pedir confirmacion explicita indicando la opcion: `status`, `beta`, `release + download` o `no publicar`.
- Los workflows de Discord tienen `confirm_publish` con valor por defecto `DRY_RUN`; solo publicar si el usuario ha autorizado explicitamente y se escribe exactamente `PUBLISH`.
- No activar `publish_download` ni `publish_announcement` salvo autorizacion expresa del usuario.
- El contenido publico (releases, announcements, status) es siempre en ingles, **excepto `#downloads`, que es bilingue (ingles + espanol)**. Es la unica excepcion a la regla de idioma.
- El workflow de release acepta `download_note` (texto bilingue EN+ES) para `#downloads`; si se deja vacio, reutiliza `note` tal cual (quedaria solo en ingles).
- Para detalles operativos, usar `docs/ezo-discord-automation.md`.

## Notas tecnicas (uso interno)

- Relacion con la familia: `EZOBindings OLD` queda pausado como historico local, no es dependencia de EZOKeybinds. Los addons EZO no deben depender de EZOKeybinds para registrar o restablecer controles.
- El addon no llama directamente a `BindKeyToAction` ni `UnbindAllKeysFromAction`; si el cliente las expone como protegidas, la restauracion de bindings compartidos debe pasar por `CallSecureProtected` tras comprobar `IsProtectedFunction`. No usar `UnbindKeyFromAction`.
- El chording se activa sobre los managers presentes en runtime (`KEYBINDINGS_MANAGER`, `KEYBOARD_KEYBINDING_MANAGER`, `KEYBINDING_MANAGER`) aceptando `SetChordingAlwaysEnabled` o `SetChordingEnabled`, con comprobacion de tipo en todas las llamadas.
- Referencia tecnica principal para APIs de ESO: https://esodata.uesp.net/current/index.html. Puede ir por detras del manifest (`101049 101050`); ante discrepancia, no inventar API y validar en cliente real.

## Checklist de pruebas cerradas

- El addon aparece habilitado en la lista de addons.
- No muestra mensajes en chat al cargar.
- `/ezokeybinds status` responde sin otros addons.
- En teclado, el menu de Controles permite asignar combinaciones con modificadores.
- En gamepad, no cambia navegacion, controles ni binds.
- Tras `/reloadui`, las combinaciones asignadas manualmente siguen disponibles.

<!-- EZO-ESO-UPDATE-START -->
## Baseline obligatorio de ESO

Antes de analizar, modificar, validar, versionar o publicar este proyecto, leer
`..\EZOFamilyDocs\docs\eso-updates\current.md` y aplicar la política enlazada.

Baseline vigente: `U51-PTS-v12.1.0`.

- La matriz por addon vive en `..\EZOFamilyDocs\data\eso-update-baseline.json`.
- U51 sigue siendo PTS provisional hasta que exista verificación explícita.
- No cambiar `## APIVersion` por inferencia; verificarla en el cliente o en una
  fuente fiable de API.
- Si estos archivos no están disponibles, detener el trabajo sensible a
  compatibilidad e indicar el bloqueo.

Fuente remota de respaldo:
https://github.com/Zuriplayer/EZOFamilyDocs/blob/main/docs/eso-updates/current.md
<!-- EZO-ESO-UPDATE-END -->
