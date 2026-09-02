# EZOKeybinds

Habilita el chording nativo de keybindings de *The Elder Scrolls Online*, para poder asignar combinaciones con modificadores (Ctrl, Alt, Shift, Command) a cualquier accion bindable existente directamente desde el menu de Controles.

Prefer English? Read the [README in English](README.md).
📢 Para soporte, feedback, reportes de errores o sugerencias, únete a nuestro Discord: https://discord.gg/ekw8zUAcRm

## ✨ Que hace

ESO permite asignar combinaciones con modificadores a acciones, pero el menu de Controles solo lo permite una vez que el chording esta activado. EZOKeybinds activa esa capacidad nativa.

Para acciones de la familia EZO mostradas en **Controles > General > EZO AddOns**, tambien anade una pequena casilla para marcar un binding como compartido entre personajes del mismo perfil de usuario de Windows. Los bindings compartidos solo se restauran mediante la ruta protegida de ESO cuando el cliente la expone.

La seccion **Valores predeterminados de teclas EZO** muestra todos los slots asignados de las acciones EZO activadas y puede restaurar, tras confirmacion, los valores predeterminados de la familia. Las asignaciones de gamepad usan los glifos adaptativos nativos de ESO, de acuerdo con el tipo de mando detectado, en lugar de mostrar codigos numericos. Cuando EZOCore esta activado, la seccion se aloja dentro del entorno centralizado **Ajustes > EZO**; sin EZOCore, EZOKeybinds registra su panel independiente de LibAddonMenu. Las teclas se editan en el menu nativo de Controles de ESO porque LibAddonMenu no tiene un control nativo para capturarlas.

## 🎮 Como usarlo

1. Carga un personaje, o ejecuta `/reloadui`.
2. Abre el menu nativo de **Controles**.
3. Asigna una combinacion con modificador (por ejemplo `Mayusculas+NumPad`) a cualquier accion bindable, igual que cualquier otro keybind.
4. En acciones EZO, marca la casilla de la fila si ese binding debe compartirse entre personajes.
5. Ejecuta `/ezokeybinds status` en el chat para confirmar que el chording esta activo.
6. Con EZOCore activado, abre **Ajustes > EZO > EZOKeybinds** para revisar todos los slots EZO asignados. Sin EZOCore, usa el panel independiente **Ajustes > Complementos > EZOKeybinds**. Para limpiar los slots y restaurar los valores predeterminados de la familia, usa **Restaurar teclas EZO predeterminadas**.

## Lo que no hace

EZOKeybinds no gestiona keybinds de addons no EZO ni aplica valores predeterminados a acciones que no son EZO. El boton de restauracion limpia los cuatro slots de las acciones EZO activadas, devuelve los valores de teclado al slot 1 y los valores EZO de gamepad al slot 2, y deja vacios los slots 3 y 4. Los defaults de teclado se omiten si ya pertenecen a acciones que no son EZO. Los defaults de gamepad siguen el comportamiento manual por capas de ESO, por lo que su uso en otra capa no bloquea el binding EZO.

Los bindings EZO compartidos son locales al perfil de usuario de Windows, no una preferencia de cuenta ESO guardada en servidor.

## Auditoria de valores predeterminados de la familia EZO

Los valores predeterminados declarados actualmente son:

- EZOArmory: `Mayusculas+NumPad 0` para su ventana.
- EZOTools: `Mayusculas+NumPad 1` / `MANTENER X` para el panel de comandos; `Mayusculas+NumPad 2` / `MANTENER Y` para el panel de utilidades; `NumPad -` para recargar la interfaz; y `NumPad +` para viajar a la casa principal.
- EZOCombat: `Mayusculas+NumPad 3` para su ventana.
- EZOPVP: `Mayusculas+NumPad 4` / `MANTENER A` para su menu PvP.
- EZOcamsens declara una accion, pero actualmente no tiene tecla predeterminada.
- EZOAlerts, EZOAuto, EZOChat, EZOCore, EZOCursor, EZOCustomSupportIcons, EZOGroupFrames, EZOhud, EZOKeybinds, EZOMetter, EZORaidPlanner, EZOta y EZOTest no declaran su propia accion persistente de keybind. Cualquier tecla nativa que muestran pertenece a ESO o es solo un control temporal de menu.

Nueve acciones quedan deliberadamente sin valor predeterminado: `Aplicar presets` de EZOcamsens y las acciones `Actividades de grupo`, `Resetear instancia`, `Disbandear grupo`, `Viajar a la sala de artesania`, `Viajar a la sala secundaria`, `Abandonar grupo`, `Salir de instancia` y `Abandonar grupo y salir de instancia` de EZOTools. Cada addon propietario declara solo sus defaults de teclado mediante la API nativa de ESO; EZOKeybinds no realiza una segunda asignacion protegida durante el inicio. Solo el reset confirmado aplica los defaults EZO de gamepad declarados: usa el slot 1 para teclado y el slot 2 para gamepad y deja vacios los slots 3 y 4. Los conflictos de teclado se comprueban entre todas las capas; los de gamepad solo dentro de la capa EZO, igual que en la asignacion manual de ESO.

El teclado numerico necesita que el teclado emita codigos NumPad. La API Lua publica de ESO expone `IsCapsLockOn()`, pero no una funcion equivalente para leer el estado de Bloq Num, por lo que EZOKeybinds no puede emitir de forma fiable una alerta condicional de "Bloq Num desactivado". Si estas teclas no responden, activa Bloq Num; el panel LAM documenta esta limitacion en vez de adivinar el estado o mostrar un aviso en cada inicio.

## 🎮 Mando / Gamepad

EZOKeybinds activa el chording de teclado (combinaciones con Ctrl, Shift, Alt) y muestra los bindings de gamepad con los glifos nativos de ESO. El registro automatico al iniciar de `MANTENER A/X/Y` esta desactivado. El reset explicito y confirmado asigna esos defaults EZO de gamepad al slot 2 siguiendo el comportamiento manual por capas de ESO. Si otra capa usa el mismo boton, ambas acciones pueden responder mientras las dos capas esten activas. El sistema de entrada del mando es independiente y los addons no pueden registrar combinaciones nuevas de dos botones.

Si usas mando y quieres combinaciones tipo LB+A, la solucion recomendada es usar **Steam Input** (gratuito, integrado en Steam) o **reWASD** para mapear esa combinacion a una tecla normal del teclado, y despues asignar esa tecla en el menu nativo de Controles como cualquier otro keybind.

## Requisitos

- The Elder Scrolls Online (PC)
- LibAddonMenu-2.0
- EZOCore es opcional; cuando esta activado, aloja EZOKeybinds dentro del entorno centralizado de ajustes EZO.

## Instalacion

1. Descarga la ultima version desde [Releases](../../releases) (o clona este repositorio).
2. Copia la carpeta `EZOKeybinds` dentro de tu carpeta de addons de ESO:
   `Documents/Elder Scrolls Online/live/AddOns/`
3. Activa el addon desde la pantalla de complementos del juego.

## Reportar problemas

Incluye si puedes: version del addon, idioma del cliente de ESO y pasos para reproducirlo.

## Estado

Version actual: **1.0.27** — beta cerrada.

## Licencia

MIT — ver [LICENSE](LICENSE).

Desarrollado y mantenido por Zuriplayer.
