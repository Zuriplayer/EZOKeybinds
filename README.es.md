# EZOKeybinds

Habilita el chording nativo de keybindings de *The Elder Scrolls Online*, para poder asignar combinaciones con modificadores (Ctrl, Alt, Shift, Command) a cualquier accion bindable existente directamente desde el menu de Controles.

🇬🇧 Prefer English? Read the [README in English](README.md).

📢 Para soporte, feedback, reportes de errores o sugerencias, unete a nuestro Discord: https://discord.gg/ekw8zUAcRm

## ✨ Que hace

ESO permite asignar combinaciones con modificadores a acciones, pero el menu de Controles solo lo permite una vez que el chording esta activado. EZOKeybinds activa esa capacidad nativa — sin interfaz propia, sin panel de ajustes, sin SavedVariables, sin nada mas ejecutandose de fondo.

## 🎮 Como usarlo

1. Carga un personaje, o ejecuta `/reloadui`.
2. Abre el menu nativo de **Controles**.
3. Asigna una combinacion con modificador (por ejemplo `Ctrl+Alt+tecla`) a cualquier accion bindable, igual que cualquier otro keybind.
4. Ejecuta `/ezokeybinds status` en el chat para confirmar que el chording esta activo.

## Lo que no hace

EZOKeybinds no gestiona los defaults de otros addons, no restablece tus bindings y no aplica ningun atajo recomendado por su cuenta. Asignar y mantener tus propias combinaciones siempre lo haces tu, desde el menu nativo de Controles.

## 🎮 Mando / Gamepad

EZOKeybinds activa el chording de teclado (combinaciones con Ctrl, Shift, Alt). El sistema de entrada del mando en ESO es completamente independiente y los addons no pueden ampliarlo: no existe ninguna API publica para registrar nuevas combinaciones de dos botones de gamepad.

Si usas mando y quieres combinaciones tipo LB+A, la solucion recomendada es usar **Steam Input** (gratuito, integrado en Steam) o **reWASD** para mapear esa combinacion a una tecla normal del teclado, y despues asignar esa tecla en el menu nativo de Controles como cualquier otro keybind.

## Requisitos

- The Elder Scrolls Online (PC)
- No requiere otros addons

## Instalacion

1. Descarga la ultima version desde [Releases](../../releases) (o clona este repositorio).
2. Copia la carpeta `EZOKeybinds` dentro de tu carpeta de addons de ESO:
   `Documents/Elder Scrolls Online/live/AddOns/`
3. Activa el addon desde la pantalla de complementos del juego.

## Reportar problemas

Incluye si puedes: version del addon, idioma del cliente de ESO y pasos para reproducirlo.

## Estado

Version actual: **1.0.22** — beta cerrada.

## Licencia

MIT — ver [LICENSE](LICENSE).

Desarrollado y mantenido por Zuriplayer.
