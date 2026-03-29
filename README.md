


## 🚀 Título y Propósito del Proyecto

El encabezado principal debe dejar claro de un vistazo qué es esto: un **Entorno de Desarrollo Automatizado para Ensamblador (NASM)**. 

Debes especificar que es un entorno profesional, 100% portable y optimizado para distribuciones basadas en Arch Linux (como Manjaro), diseñado para eliminar la fricción de compilar y enlazar archivos a bajo nivel integrándose con Visual Studio Code.

## ✨ Características Principales a Destacar

Es vital que los visitantes entiendan qué hace especial a tu entorno. Te sugiero incluir esta lista exacta:

* **Monitor de Sistema (inotify):** Un servicio en segundo plano que vigila las carpetas. Al crear un nuevo archivo `main.asm`, genera instantáneamente un `Makefile` automático con rutas relativas para garantizar la portabilidad.
* **Centro de Mando Dual (VS Code):** Automatización mediante macros de teclado (`F10`, `F11`, `F12`) que transforma la interfaz del editor gestionando terminales divididas y ocultando paneles sin tocar el ratón.
* **Compilación Inteligente y Segura:** Las tareas de VS Code ejecutan `make clean` automáticamente antes de cada construcción, evitando errores de dependencias fantasma y conservando las rutas ancladas de las terminales.
* **Librería Estática Integrada:** Todo el código fuente almacenado en la carpeta `lib/` se compila y enlaza automáticamente como `libcore.a` en todos los comandos.

## 🛠️ Instrucciones de Instalación

El paso a paso para un usuario nuevo debe ser muy directo:

1. Clonar o descargar el repositorio en su equipo.
2. Abrir una terminal en la raíz del proyecto.
3. Ejecutar el script de preparación con el comando: `./setup_manjaro.sh`
   > **Nota para el usuario:** Este script instalará dependencias (`nasm`, `make`, `gdb`, `inotify-tools`) y levantará el servicio `systemd` que monitoriza los archivos.

## ⚙️ Configuración Obligatoria de VS Code

Aquí debes avisarles de la única limitación técnica que no podemos automatizar por seguridad: los atajos de teclado locales. 

Indica que, tras aceptar las extensiones recomendadas por el área de trabajo, deben abrir sus preferencias de atajos de teclado (`Ctrl + K`, luego `Ctrl + S`), abrir el formato JSON y pegar el siguiente bloque para activar el Centro de Mando:

```json
[
    {
        "key": "f12",
        "command": "multiCommand.entornoNasm",
        "when": "editorTextFocus"
    },
    {
        "key": "f12",
        "command": "workbench.action.togglePanel",
        "when": "terminalFocus"
    },
    {
        "key": "f10",
        "command": "workbench.action.terminal.focusNextPane",
        "when": "terminalFocus"
    },
    {
        "key": "f11",
        "command": "workbench.action.toggleSidebarVisibility"
    }
]
```

## 💻 Flujo de Trabajo Diario

Explica brevemente cómo usar el entorno una vez configurado:

1. **Crear:** Añadir una carpeta nueva en `comandos/` con un archivo `main.asm`.
2. **Magia:** El sistema crea el `Makefile` en segundo plano.
3. **Desplegar:** Al pulsar **`F12`** en el código, la pantalla se divide en el modo de desarrollo (terminal `bin/` a la izquierda, terminal normal a la derecha).
4. **Navegar:** Usar **`F10`** para cambiar entre terminales y **`F11`** para ocultar/mostrar el explorador de archivos.
5. **Compilar y Ejecutar:** Lanzar la compilación con VS Code y ejecutar con `./main` en la terminal izquierda.

---

