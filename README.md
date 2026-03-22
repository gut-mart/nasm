# ⚙️ Entorno de Desarrollo Profesional para NASM (x86_64)

Un ecosistema automatizado y modular para el desarrollo en ensamblador x86_64 bajo Linux. Este proyecto no es solo una colección de scripts, sino un entorno completo que incluye monitorización en segundo plano, enlazado estático inteligente y una profunda integración con VS Code.

## ✨ Características Principales

*   **Monitorización Activa (Systemd + inotify):** Un servicio en segundo plano vigila la carpeta `proyectos/`. Al crear una nueva carpeta, genera automáticamente la plantilla base (`main.asm`) y un `Makefile` local con rutas absolutas configuradas.
*   **Enlazado Estático Inteligente:** El sistema de compilación empaqueta todas las librerías en un archivo estático (`libcore.a`). El enlazador (`ld`) extrae e inyecta *únicamente* las funciones que tu programa utiliza, manteniendo los binarios finales ultraligeros.
*   **Librería Estándar Propia:** Incluye módulos reutilizables para operaciones comunes:
    *   `sys_macros.inc`: Macros limpias para abstraer las llamadas al sistema (Syscalls) y evitar lidiar con la fontanería de los registros.
    *   `lib_print`: E/S de consola (strings, enteros, manejo de errores por STDERR).
    *   `lib_file`: Manipulación y extracción de archivos segura.
    *   `lib_graph`: Interacción con el Framebuffer (`/dev/fb0`) para gráficos a bajo nivel.
*   **Integración Total con VS Code:** Incluye tareas de construcción sensibles al contexto (compila el archivo que estés viendo) y depuración nativa con GDB paso a paso.

## 🚀 Requisitos Previos

Este entorno está optimizado para **Manjaro / Arch Linux**. El script de configuración instalará automáticamente las dependencias necesarias:
*   `nasm` (Ensamblador)
*   `make` y `gcc` (Herramientas de construcción)
*   `gdb` (Depurador)
*   `inotify-tools` (Monitorización del sistema de archivos)

## 🛠️ Instalación y Configuración

1. Clona este repositorio en tu máquina local:
   ```bash
   git clone <URL_DE_TU_REPOSITORIO>
   cd <NOMBRE_DE_LA_CARPETA>