# 🛠️ Entorno de Desarrollo Modular Assembly x86_64 (Linux)

Este repositorio contiene un framework de desarrollo **educativo, modular y automatizado** para programación en Ensamblador (NASM) sobre Linux.

El objetivo principal es aprender el funcionamiento de bajo nivel de la arquitectura x86_64 sin depender de librerías externas de C (`libc`).

### ✨ Características Principales
* **Puro Bajo Nivel:** Todo se realiza mediante llamadas directas al sistema (*syscalls*), sin `printf` ni `scanf`.
* **Librería Propia:** Incluye una "Libc artesanal" modular (`lib/`) para tareas comunes como imprimir números en binario o decimal.
* **Automatización Total:** Integración profunda con **VS Code** para compilar, enlazar y depurar pulsando una sola tecla (`F5`).

---

## 📋 1. Requisitos Previos

Este entorno está configurado nativamente para Linux (específicamente probado en **Manjaro/Arch**), pero funciona en cualquier distribución moderna.

Necesitas las herramientas base de compilación:
* **NASM:** El ensamblador.
* **LD:** El enlazador (parte de binutils).
* **GDB:** El depurador.
* **Make:** Para la automatización de la construcción.

### Instalación

```bash
# Arch Linux / Manjaro
sudo pacman -S base-devel nasm gdb

# Debian / Ubuntu / Mint
sudo apt update && sudo apt install build-essential nasm gdb
🧩 2. Extensiones Recomendadas (VS Code)
Para aprovechar la configuración automática incluida en la carpeta .vscode, es muy recomendable instalar las siguientes extensiones. El editor debería sugerírtelas al abrir la carpeta:

C/C++ (Microsoft): Indispensable. Proporciona la interfaz gráfica para el depurador GDB.

x86_64 Assembly (13xforever): Proporciona el resaltado de sintaxis y coloreado para archivos .asm y .inc.

📂 3. Estructura del Proyecto
El sistema de construcción (Makefile) depende de esta estructura de directorios. Es importante mantenerla ordenada.

Plaintext
.
├── .vscode/               # ⚙️ Scripts de automatización (Launch/Tasks)
├── build/                 # 🧱 Aquí se generan los ejecutables (Ignorado por Git)
├── lib/                   # 📚 Librerías propias (Tu "libc" personalizada)
│   ├── constants.inc      # Constantes globales (Syscalls, Exit codes)
│   └── text/              # Rutinas de texto (print, conversión, etc.)
│       ├── print_bin32/   # Módulo: Imprimir binario
│       └── print_dec32/   # Módulo: Imprimir decimal
├── proyectos/             # ✍️ TU ESPACIO DE TRABAJO
│   ├── demo/              # (Ejemplo) Cada programa en su propia carpeta
│   │   └── demo.asm
│   └── ...
└── Makefile               # 🛠️ Script maestro de compilación (NO MOVER)
🚀 4. Compilación y Ejecución
El proyecto utiliza un sistema de construcción dinámico. No necesitas escribir comandos largos en la terminal; el Makefile detecta qué archivo estás editando.

Método Automático (Recomendado)
Abre tu archivo .asm en Visual Studio Code.

Asegúrate de que sea la pestaña activa.

Presiona F5.

¿Qué ocurre internamente?

VS Code envía la ruta del archivo actual al Makefile.

Se compila tu código y se enlaza con todas las librerías de lib/.

Se abre la consola de depuración (GDB) automáticamente, pausada al inicio del programa.

Método Manual (Terminal)
Si prefieres usar la terminal, puedes compilar explícitamente:

Bash
# Compilar un archivo específico
make SRC=proyectos/demo/demo.asm

# Ejecutar el resultado
./build/demo
📝 5. Ejemplo: demo.asm
A continuación se muestra un programa de ejemplo que utiliza la estructura del proyecto y las librerías personalizadas para imprimir texto y números.

Ubicación sugerida: proyectos/demo/demo.asm

Fragmento de código
; ==============================================================================
; EJEMPLO DE USO DEL FRAMEWORK
; ==============================================================================

; 1. Inclusión de constantes y librerías
; (Las rutas siempre son relativas a la raíz del proyecto)
%include "lib/constants.inc"
%include "lib/text/print_dec32/lib_text_print_dec32.inc"

default rel  ; OBLIGATORIO: Direccionamiento relativo (RIP-relative) en 64-bits

section .data
    msg_hola    db "Hola, mundo desde Assembly x64!", 10, 0
    len_hola    equ $ - msg_hola

section .text
    global _start

_start:
    ; --- 1. Imprimir un mensaje simple (Syscall directa) ---
    mov rax, SYS_WRITE
    mov rdi, STDOUT
    lea rsi, [msg_hola]
    mov rdx, len_hola
    syscall

    ; --- 2. Usar la librería propia para imprimir un número ---
    mov edi, -12345         ; Cargamos el argumento en EDI
    call lib_text_print_dec32 ; Llamamos a nuestra función modular

    ; --- 3. Salida limpia del programa ---
    mov rax, SYS_EXIT       ; Syscall 60
    mov rdi, EXIT_SUCCESS   ; Código 0
    syscall