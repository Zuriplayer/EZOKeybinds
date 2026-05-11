# EZO Discord automation

Este repositorio usa una configuracion local por addon en `ezo-addon.json`. No depende del catalogo global de la familia EZO para publicar builds.

## Objetivo

- Generar un ZIP limpio en `dist/`.
- Mantener fuera del ZIP los archivos internos de desarrollo.
- Publicar estado, beta builds, releases, downloads, announcements y codex-log en Discord mediante GitHub Actions.
- No guardar URLs reales de webhooks en el repositorio.

## Configuracion local

`ezo-addon.json` define:

- nombre real del addon;
- version visible;
- manifest runtime;
- carpeta raiz dentro del ZIP;
- reglas de inclusion y exclusion;
- nombres de secretos esperados en GitHub Actions.

Para EZOKeybinds, el ZIP se genera como:

```text
dist/EZOKeybinds_v1.0.21.zip
```

Dentro del ZIP siempre debe existir una carpeta raiz:

```text
EZOKeybinds/
```

## Archivos incluidos en el ZIP

Por defecto se permiten archivos runtime de ESO:

- `*.txt`
- `*.lua`
- `*.xml`
- `modules/**`
- `lang/**`
- `libs/**`
- `media/**`
- `textures/**`
- `fonts/**`
- `bindings/**`

En este addon concreto el paquete contiene solo:

- `EZOKeybinds/EZOKeybinds.txt`
- `EZOKeybinds/EZOKeybinds.lua`

## Archivos excluidos

El empaquetado excluye estructura interna como `.git`, `.github`, `docs`, `scripts`, `dist`, `tests`, markdown, scripts sueltos, logs y temporales.

El script no borra ni mueve archivos del repositorio. Copia los archivos permitidos a una carpeta temporal y comprime desde ahi.

## Secretos de GitHub Actions

Crear estos secretos en el repositorio:

- `EZO_CODEX_DOWNLOADS`: webhook de `#downloads`
- `EZO_CODEX_RELEASES`: webhook de `#releases`
- `EZO_CODEX_STATUS`: webhook de `#addon-status`
- `EZO_CODEX_BETA_BUILDS`: webhook de `#beta-builds`
- `EZO_CODEX_ANNOUNCER`: webhook de `#announcements`
- `CODEX_LOG`: webhook de `#codex-log`

## Uso recomendado de canales

- `#addon-status`: estado tecnico corto del addon. No adjunta ZIP.
- `#beta-builds`: builds para testers. Adjunta ZIP limpio.
- `#releases`: nota tecnica de release. No adjunta ZIP por defecto.
- `#downloads`: canal limpio de descarga. Adjunta ZIP limpio.
- `#announcements`: aviso humano para jugadores/testers. No adjunta ZIP por defecto.
- `#codex-log`: log interno de automatizacion. No adjunta ZIP.

El criterio profesional es no duplicar binarios en varios canales. El ZIP va en `#beta-builds` para pruebas y en `#downloads` para descargas finales.

## Procedimiento de publicacion

La publicacion en Discord no forma parte de cada commit o push. Se trata como un paso separado de release.

Flujo normal de trabajo:

```text
editar -> probar -> commit -> push
```

Flujo de publicacion cuando el cambio ya es util para jugadores:

```text
validar ZIP limpio -> pedir confirmacion -> lanzar workflow Discord
```

Codex debe proponer una publicacion en Discord solo cuando se cumplan estas condiciones:

- El cambio aporta una mejora funcional real, una correccion importante o una version estable para jugadores.
- El addon esta probado localmente o en juego con un resultado razonable.
- El ZIP limpio se genera correctamente y contiene solo archivos runtime.
- No quedan cambios sin commit relacionados con la publicacion.
- La rama que se va a publicar esta en `main` o ya ha sido fusionada.

Codex no debe proponer publicacion en Discord para cambios menores de documentacion, limpieza interna, pruebas parciales, ajustes de automatizacion o commits sin impacto practico para jugadores.

Antes de lanzar cualquier workflow que publique en Discord, Codex debe pedir confirmacion explicita con una opcion clara:

```text
Este cambio parece publicable. Que quieres hacer?
- status
- beta
- release + download
- no publicar
```

Los workflows tienen una barrera tecnica:

```text
confirm_publish = DRY_RUN
```

Con el valor por defecto no se envia nada a Discord. Para publicar de verdad, el campo debe escribirse exactamente como:

```text
PUBLISH
```

En el workflow de release, `publish_download` y `publish_announcement` estan desactivados por defecto. Activarlos requiere autorizacion expresa.

## Que workflow usar

- Usar `EZO addon status` cuando solo cambie el estado, fase o visibilidad del addon.
- Usar `EZO beta build` cuando se quiera que testers prueben un cambio nuevo, todavia no definitivo.
- Usar `EZO release` con `publish_download=true` cuando la version se considere funcional, segura y lista para descarga.
- Mantener `publish_announcement=true` solo cuando el mensaje sea util para jugadores/testers, no para ruido tecnico.

## Workflows

### `ezo-status.yml`

Manual. Publica el estado local de `ezo-addon.json` en `#addon-status`.

Tambien publica una entrada corta en `#codex-log`.

### `ezo-beta.yml`

Manual. Genera ZIP limpio, lo sube como artifact de GitHub Actions y lo publica en `#beta-builds`.

Tambien publica una entrada corta en `#codex-log`.

### `ezo-release.yml`

Manual. Genera ZIP limpio, publica nota tecnica en `#releases` y, si `publish_download` esta activo, publica el ZIP en `#downloads`.

Si `publish_announcement` esta activo, publica un aviso en `#announcements`. Tambien publica una entrada corta en `#codex-log`.

## Pruebas locales seguras

Estos comandos no publican nada a Discord:

```powershell
Get-Content .\ezo-addon.json -Raw | ConvertFrom-Json
.\scripts\ezo\publish-status.ps1 -DryRun
.\scripts\ezo\build-addon-package.ps1 -Force
```

Para revisar el contenido del ZIP:

```powershell
Expand-Archive .\dist\EZOKeybinds_v1.0.21.zip -DestinationPath .\dist\check -Force
Get-ChildItem .\dist\check -Recurse -File
```

No usar `-DryRun` en GitHub Actions salvo que se quiera probar el workflow sin publicar.
