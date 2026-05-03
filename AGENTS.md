# EZOKeybinds - AI Development Rules

Este proyecto es un addon para The Elder Scrolls Online dentro de la familia EZO.

## Versionado y APIVersion

- Para cualquier cambio visible del addon, actualizar version con `.\tools\bump-version.ps1 -Patch` o `.\tools\bump-version.ps1 -Version x.y.z`.
- Si el cambio se prepara para release o hay parche de ESO, comprobar la API actual con `/script d(GetAPIVersion())` o fuente fiable ESOUI/UESP.
- `## APIVersion` controla si ESO muestra el addon como desactualizado en la pantalla de complementos/addons.
- No adivinar `## APIVersion`; solo cambiarlo si el valor actual esta verificado.
- Usar `.\tools\bump-version.ps1 -Patch -ApiVersion <api_actual>` para actualizar version y API.
- Mantener como maximo dos valores en `## APIVersion`; ESO ignora entradas adicionales.
- Antes de commit/release ejecutar `.\tools\bump-version.ps1 -Check -ApiVersion <api_actual>` y `git diff --check`.
