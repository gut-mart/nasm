# 🚀 NASM x86_64 Development Framework (Manjaro Edition)

Este repositorio es un entorno de desarrollo profesional y preconfigurado para programar en **Ensamblador (Assembly x86_64)** bajo Linux. 

Está diseñado específicamente para trabajar con **Visual Studio Code**, automatizando las tareas tediosas de compilación y enlazado.

## 🧐 ¿Para qué sirve esto? (Contexto para principiantes)

Programar en ensamblador "a mano" suele ser doloroso. Para probar un simple "Hola Mundo" normalmente tendrías que escribir esto en la terminal cada vez:

```bash
nasm -f elf64 -g -F dwarf programa.asm -o programa.o
ld -m elf_x86_64 -o programa programa.o
./programa
Este proyecto elimina ese dolor.

Automatización: Con solo pulsar una tecla, el sistema detecta qué archivo estás editando, lo compila, enlaza las librerías necesarias y te deja el ejecutable listo.

Depuración Visual: Viene configurado para usar GDB dentro de VS Code. Puedes ver cómo cambian los registros de la CPU y la memoria línea por línea, sin usar comandos crudos.

Gestión Híbrida: Mantiene tu carpeta de trabajo limpia organizando las librerías compiladas en una carpeta oculta build/, pero dejando tu ejecutable principal a la vista para un acceso rápido.

📂 Estructura del Proyecto (El Árbol)
Así es como se organiza tu entorno de trabajo:

Plaintext
.
├── 📁 lib/                   # 📚 LIBRERÍAS (Código reutilizable)
│   ├── constants.inc         # Constantes globales (Syscalls, colores...)
│   ├── 📁 text/              # Módulos de texto
│   │   ├── print_dec32/      # Librería para imprimir números decimales
│   │   └── print_bin32/      # Librería para imprimir binario
│   └── ...
│
├── 📁 proyectos/             # 🔨 TU TALLER (Aquí creas tus programas)
│   └── 📁 demo/
│       ├── demo.asm          # Tu código fuente
│       ├── demo.o            # Objeto (Generado automáticamente aquí)
│       └── demo              # Ejecutable (Generado automáticamente aquí)
│
├── 📁 build/                 # ⚙️ SALA DE MÁQUINAS (Auto-generado)
│   └── lib/                  # Aquí se guardan los .o de las librerías para no estorbar
│
├── 📁 .vscode/               # 🧠 CEREBRO DE VS CODE
│   ├── tasks.json            # Define los comandos de "Construir" y "Limpiar"
│   └── launch.json           # Configura el depurador (F5)
│
├── .gitignore                # Reglas para Git (ignora binarios)
└── Makefile                  # Script maestro de compilación inteligente
🐧 Instalación en Manjaro (Arch Linux)
Al usar Manjaro, utilizamos pacman en lugar de apt. Abre tu terminal y ejecuta:

Bash
# 1. Actualizar el sistema
sudo pacman -Syu

# 2. Instalar herramientas base (NASM, Make, GDB y GCC)
sudo pacman -S nasm base-devel gdb
Nota: base-devel incluye make y el enlazador ld.

⚡ Guía de Inicio Rápido
El sistema es dinámico: Compila el archivo que tienes abierto en pantalla.

1. Compilar y Ejecutar
Abre VS Code en la carpeta del proyecto.

Abre tu archivo fuente (ej: proyectos/demo/demo.asm).

Presiona Ctrl + Shift + B.

Verás que aparecen demo.o y el archivo demo (ejecutable) al lado de tu código.

Abre la terminal integrada (Ctrl + ñ) y ejecuta:

Bash
./proyectos/demo/demo
2. Depurar (Debug)
Pon un punto de ruptura (clic rojo a la izquierda del número de línea).

Presiona F5.

El programa se pausará y podrás inspeccionar registros y memoria.

3. Limpiar (Clean)
Para borrar todos los ejecutables y archivos temporales antes de guardar o compartir:

Menú superior: Terminal -> Run Task...

Selecciona: Limpiar Proyecto Actual.

Esto borrará la carpeta build/ y buscará/eliminará cualquier .o disperso.

📝 Cómo crear un nuevo programa
No necesitas configurar nada nuevo. Solo:

Crea una carpeta nueva en proyectos/ (ej: proyectos/calculadora).

Crea un archivo .asm dentro (ej: main.asm).

Escribe tu código.

Pulsa Ctrl + Shift + B. El Makefile detectará la ubicación automáticamente.

🛠 Comandos Manuales (Terminal)
Si prefieres no usar VS Code, puedes usar el Makefile directamente desde la terminal:

Bash
# Compilar un archivo específico
make SRC=proyectos/demo/demo.asm

# Limpiar todo el proyecto (modo agresivo)
make clean
Configuración optimizada para arquitectura x86_64 en Linux.


### Principales adaptaciones que he hecho:

1.  **Instalación para Manjaro:** He cambiado los comandos a `sudo pacman -S nasm base-devel gdb`. El paquete `base-devel` es vital en Arch/Manjaro porque contiene `make` y `ld`.
2.  **Explicación del valor:** La sección "¿Para qué sirve esto?" ayuda a entender por qué este entorno es valioso frente a hacerlo manual.
3.  **Diagrama de árbol:** He incluido el árbol visual ASCII mostrando claramente la distinción entre `lib/` (fuente) y `build/` ( compilación de lib/').