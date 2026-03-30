Entorno de Desarrollo y Experimentación en Ensamblador (NASM) para Linux
📌 Propósito del Proyecto
El objetivo principal de este proyecto es proporcionar un entorno estructurado para la experimentación y el aprendizaje del lenguaje Ensamblador x86_64 (NASM) en sistemas Linux.

El diseño del proyecto se centra en la creación modular de código de bajo nivel capaz de interactuar directamente con el kernel del sistema operativo (mediante syscalls). Para lograr esto, el entorno divide claramente la lógica reutilizable (librerías) de los programas finales (comandos). Como caso de uso actual, el entorno incluye herramientas para leer datos gráficos y mapear la memoria RAM de video a través del dispositivo /dev/fb0.

📂 Arquitectura de Directorios
El proyecto impone una estructura de carpetas estricta para mantener el código organizado y facilitar el proceso de construcción automatizado:


lib/: Aloja todas las librerías desarrolladas en Ensamblador. Estas librerías contienen las funciones base que interactúan con el kernel de Linux (como operaciones de entrada/salida de archivos, conversiones numéricas y macros del sistema). Todo el código aquí se empaqueta en una librería estática unificada (libcore.a).
+3


comandos/: Contiene los programas individuales o "comandos" diseñados por el desarrollador. Cada programa alojado aquí utiliza las funciones proporcionadas por la carpeta lib/ para ejecutar tareas específicas.
+3

build/: Es un directorio temporal gestionado automáticamente por el sistema. Durante la compilación, aquí se almacenan todos los archivos objeto (.o) y archivos de dependencias generados.
+1


bin/: Es el directorio de destino final. Una vez que el enlazador (ld) une el código del comando con la librería estática, el ejecutable binario resultante se guarda en esta carpeta listo para ser utilizado.
+2

🚀 Flujo de Trabajo y Compilación Automatizada
El entorno implementa un flujo de trabajo altamente automatizado que permite al desarrollador centrarse en escribir código sin preocuparse por los detalles del enlazador:


Monitorización: Un script en segundo plano (monitor_comandos.sh) vigila la carpeta comandos/.
+1


Generación Dinámica: Al detectar la creación o modificación de un archivo .asm, el sistema genera o actualiza automáticamente un archivo Makefile específico para ese comando.
+1


Construcción (Make): Al solicitar la compilación, make procesa el código, enviando los archivos intermedios a build/ y generando el binario final en bin/.


Ejecución y Depuración: Gracias a la integración con VS Code, el ejecutable resultante en la carpeta bin/ puede ser lanzado o depurado paso a paso utilizando GDB.

🛠️ Requisitos Previos e Instalación
Este entorno está diseñado inicialmente para Manjaro Linux (o distribuciones basadas en Arch Linux) y utiliza Visual Studio Code como editor principal.
+3

1. Preparar el Entorno
El proyecto incluye un script automatizado para configurar el sistema operativo. Abre tu terminal en la raíz del proyecto y ejecuta:

Bash
./setup_manjaro.sh
Este script se encarga de:

Instalar las dependencias del sistema (inotify-tools, nasm, make, gdb, gcc).
+2

Crear y activar un servicio en segundo plano (monitor_asm.service) para vigilar tus archivos.
+2

Configurar los atajos de teclado en VS Code.

2. Extensiones de VS Code
Para que las macros de teclado y la depuración funcionen correctamente, es obligatorio instalar las extensiones definidas en .vscode/extensions.json:


ryuta46.multi-command (Requerida para las macros automatizadas).


ms-vscode.cpptools (Para el soporte del depurador GDB).


13xforever.language-x86-64-assembly (Para el resaltado de sintaxis).

3. Uso Diario
Simplemente crea un archivo .asm en comandos/. El sistema creará su Makefile. Presiona F12 en VS Code para disparar la limpieza de terminales, crear las carpetas necesarias y compilar el proyecto.
+4