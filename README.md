⚙️ x86_64 Linux Assembly Toolkit
Este repositorio contiene una colección de librerías y programas de prueba escritos completamente en Ensamblador x86_64 para Linux (sintaxis NASM). El proyecto está diseñado desde cero sin utilizar librerías estándar de C (libc), interactuando directamente con el Kernel de Linux mediante llamadas al sistema (syscalls).
+2

📦 Módulos Principales
Actualmente, el proyecto se divide en dos librerías principales:

1. Conversión Numérica (lib_cnv)
Convierte números enteros sin signo de 32 bits (uint32) a cadenas de texto ASCII (strings).


Multibase: Soporta conversiones a cualquier base numérica pasándola como argumento, como Binario (2), Decimal (10) o Hexadecimal (16).


Segura: Implementa validaciones internas para forzar Base 10 si se solicita una base inválida (< 2).

2. Información del Framebuffer (lib_graph)
Interactúa con el driver de video del sistema (/dev/fb0) utilizando la syscall ioctl para extraer la configuración del hardware de video.
+2

Extrae la Resolución Lógica (ancho y alto en píxeles).

Extrae el Tamaño Físico real del monitor en milímetros.

Obtiene la profundidad de color (BPP) y calcula automáticamente el Pitch o LineLength (Bytes por línea) necesario para dibujar.

📂 Estructura del Proyecto
El código está organizado de forma modular para separar las librerías reutilizables de los programas ejecutables:

lib/: Contiene el código fuente de las librerías.


constants.inc: Constantes globales como descriptores de archivo y números de syscalls.


cnv/: Archivos de la librería de conversión de texto.


graph/: Archivos de la librería gráfica y definiciones de estructuras (struc).
+1

proyectos/: Contiene los programas principales que consumen las librerías.


test_cnv.asm: Programa de prueba para la conversión a bases 10, 16 y 2.
+3


main.asm (Test DPI): Imprime en consola un reporte completo del hardware de video.
+1


build/ (Generada automáticamente): Carpeta donde se almacenan los objetos compilados (.o) de las librerías.

🛠️ Requisitos previos
Para compilar y ejecutar este proyecto, necesitas un entorno Linux con las siguientes herramientas:

NASM (Netwide Assembler)

LD (GNU Linker)

GDB (Para depuración)


Nota: Para ejecutar el módulo gráfico, tu usuario debe tener permisos de lectura sobre /dev/fb0.
+1

🚀 Cómo compilar y ejecutar
El proyecto incluye un Makefile inteligente capaz de compilar las librerías como dependencias y enlazarlas con el archivo principal especificado.

1. Para compilar un proyecto específico:
Pasamos la ruta del archivo a compilar a través de la variable SRC:

Bash
# Compilar el test de conversión
make SRC=proyectos/cnv/test_cnv.asm

# Compilar el reporte de hardware de video
make SRC=proyectos/graph/main.asm
2. Para ejecutar el binario resultante:
El ejecutable se genera en la misma carpeta que el archivo fuente:

Bash
./proyectos/graph/main
3. Para limpiar el proyecto:
El sistema elimina la carpeta build/, los archivos .o dispersos y los ejecutables:
+1

Bash
make clean
💻 Integración con Visual Studio Code
El repositorio está listo para funcionar en VS Code con soporte completo de construcción y depuración:

Extensiones recomendadas configuradas (C/C++ Tools, x86-64 Assembly).

Archivo tasks.json que enlaza el atajo de compilación (Ctrl+Shift+B) con el Makefile, pasando el archivo actualmente abierto como SRC.

Archivo launch.json configurado para lanzar GDB en arquitectura x86_64, deteniéndose automáticamente en el punto de entrada (_start).