# Entorno NASM para Linux

## Propósito del Proyecto

Este proyecto ofrece un entorno estructurado para la experimentación y el aprendizaje de ensamblador x86_64 con NASM en Linux.

El diseño separa claramente la lógica reutilizable de las librerías (`lib/`) de los programas ejecutables (`comandos/`). El objetivo principal es facilitar la creación de código de bajo nivel que interactúe directamente con el kernel mediante syscalls, con un enfoque práctico en gráficos y framebuffer.

## Documentación y mejoras

- **[Documentación principal](docs/index.md)**
- **[Guía de contribuciones](CONTRIBUTING.md)**
- **[Mejores prácticas](docs/BEST_PRACTICES.md)**
- **[Resumen de mejoras](IMPROVEMENTS.md)**
- **[Licencia MIT](LICENSE)**

## Arquitectura de directorios

- `lib/`: Librerías NASM reutilizables, empaquetadas en `build/libcore.a`.
- `comandos/`: Programas individuales que usan las librerías.
- `build/`: Archivos objeto y dependencias generados.
- `bin/`: Ejecutables finales.
- `docs/`: Documentación técnica.

## Flujo de trabajo

1. Crea un archivo `.asm` en `comandos/`.
2. Compila con `make SRC=comandos/tu_comando/tu_comando.asm`.
3. Ejecuta el binario resultante en `bin/`.
4. Usa `make test` para validar la suite de pruebas.

## Requisitos

- NASM
- GCC
- Make
- GDB
- inotify-tools (opcional, para monitoreo automático)

## Comandos útiles

- `make help`
- `make test`
- `make run`
- `make install`
- `make clean`
- `make clean-all`

## Setup multiplataforma

Ejecuta `./setup.sh` para instalar dependencias y configurar el entorno en:
- Ubuntu/Debian
- Fedora
- RHEL/CentOS
- Arch/Manjaro

## Ejemplos incluidos

- `comandos/hello_world/`
- `comandos/count_numbers/`
- `comandos/fibonacci/`
- `comandos/monitor/`

## Extensiones recomendadas para VS Code

- `ryuta46.multi-command`
- `ms-vscode.cpptools`
- `13xforever.language-x86-64-assembly`

## CI/CD

El proyecto incluye un workflow de GitHub Actions en `.github/workflows/build.yml` que valida compilación y tests.
