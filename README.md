He estructurado el documento para que sirva tanto de documentación para ti mismo en el futuro, como de guía para cualquiera que vea tu repositorio. Explica claramente tu flujo de trabajo "híbrido" (ejecutable local + librerías en build).

Puedes copiar y pegar el siguiente bloque directamente en un archivo llamado README.md en la raíz de tu proyecto.

Markdown
# NASM x86_64 Development Framework

Este repositorio contiene un entorno de desarrollo para **Ensamblador x86_64** en Linux, preconfigurado para **Visual Studio Code**. 

Está diseñado con un flujo de trabajo **híbrido**: mantiene las librerías ordenadas en una carpeta de construcción (`build/`), pero genera los ejecutables y objetos de tu código principal en la **misma carpeta** donde trabajas, facilitando la ejecución y el depurado rápido.

## 📂 Estructura del Proyecto

```text
.
├── lib/                  # 📚 Librerías reutilizables (Código Fuente)
│   ├── constants.inc     # Constantes globales (Syscalls, colores, etc.)
│   └── text/             # Módulos de texto (ej. print_dec32)
├── proyectos/            # 🚀 Tu espacio de trabajo (Aquí creas tus .asm)
│   └── demo/
│       ├── demo.asm      # Código fuente principal
│       ├── demo.o        # Objeto (Generado aquí al compilar)
│       └── demo          # Ejecutable (Generado aquí al compilar)
├── build/                # ⚙️ Archivos intermedios de librerías (Auto-generado)
├── .vscode/              # 🛠 Configuración de Tareas y Debugger (GDB)
└── Makefile              # 🧠 Script de automatización inteligente
🚀 Requisitos Previos
Asegúrate de tener instaladas las herramientas básicas de ensamblado y depuración:

Bash
sudo apt update
sudo apt install nasm build-essential gdb
🛠 Cómo Compilar y Ejecutar
El sistema es dinámico: compila el archivo que tengas abierto en ese momento.

Opción A: Desde Visual Studio Code (Recomendado)
Abrir archivo: Abre tu archivo .asm principal (ej. proyectos/demo/demo.asm).

Compilar: Presiona Ctrl + Shift + B.

Resultado: Se crearán demo.o y el ejecutable demo en la misma carpeta.

Depurar (Debug): Presiona F5.

Se abrirá GDB integrado en VS Code.

Puedes ver registros, memoria y paso a paso.

Opción B: Desde la Terminal (Manual)
Si prefieres usar la consola, puedes invocar al Makefile pasando la ruta de tu archivo:

Bash
# Compilar un proyecto específico
make SRC=proyectos/demo/demo.asm

# Ejecutar
./proyectos/demo/demo
🧹 Limpieza del Proyecto
Como los ejecutables se generan junto al código fuente, es importante limpiar el proyecto antes de hacer commits o compartir el código.

Desde VS Code: Ejecuta la tarea Limpiar Proyecto Actual (Menú Terminal > Run Task...).

Desde Terminal:

Bash
make clean
Nota: El comando clean es agresivo: borrará la carpeta build/, todos los archivos .o dispersos y los ejecutables detectados.

🧩 Sistema de Librerías
Las librerías se encuentran en la carpeta lib/. El Makefile detecta automáticamente cualquier archivo .asm dentro de lib/, lo compila y lo enlaza a tu proyecto.

Cómo usar una librería en tu código:
Incluye el archivo de cabecera (.inc) en tu código:

Fragmento de código
%include "lib/text/print_dec32/lib_text_print_dec32.inc"
Llama a la función (pasando los argumentos según la documentación de la librería):

Fragmento de código
mov edi, 12345
call lib_text_print_dec32
¡Listo! No necesitas modificar el Makefile.

📝 Convenciones de Código
Punto de entrada: Usa global _start.

Modo: Todo el código debe ser default rel (Position Independent Code).

Registros: Las funciones deben preservar los registros callee-saved (rbx, rbp, r12-r15) según la ABI de System V.

🛡 Git Ignore (Importante)
Dado que generamos binarios dentro de las carpetas de código, asegúrate de que tu .gitignore contenga:

Fragmento de código
build/
*.o
.vscode/
# Ejecutables sin extensión (se limpian con make clean)
Configuración creada para aprendizaje eficiente de Arquitectura de Computadores.


### ¿Qué valor añadido tiene este README?

1.  [cite_start]**Explica la lógica "Híbrida":** [cite: 30, 31] Deja claro al lector por qué aparecen archivos `.o` en su carpeta pero no en la carpeta `lib`.
2.  [cite_start]**Documenta la Automatización:** [cite: 57, 58] Explica que la compilación depende del archivo abierto (`${relativeFile}`), algo que no es obvio a primera vista.
3.  [cite_start]**Seguridad:** Hace énfasis en la limpieza (`make clean`) [cite: 32, 33] y el `.gitignore` para evitar subir binarios al repositorio, que es el riesgo principal de compilar en la misma carpeta.