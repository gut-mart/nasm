# Entorno NASM para Linux

![CI](https://github.com/gut-mart/nasm/actions/workflows/ci.yml/badge.svg)

Proyecto personal de aprendizaje y experimentación con ensamblador x86_64 en
Linux. La idea es crear pequeñas librerías reutilizables escritas íntegramente
en NASM, sin depender de libc ni de ninguna otra librería externa, y dibujar
directamente sobre el framebuffer del kernel (`/dev/fb0`).

El proyecto está pensado para ejecutarse en máquinas Linux **sin entorno
gráfico** (TTY pura o equipo headless). Soporta dos modos de desarrollo:
trabajar todo en el mismo equipo, o editar en un equipo principal y depurar
remotamente vía SSH/GDB en un equipo de pruebas dentro de la misma red.

## Requisitos

- Linux x86_64.
- NASM, `ld`, GDB, `make`.
- Acceso a `/dev/fb0` (necesita `sudo` o pertenecer al grupo `video`).
- **Importante:** el framebuffer no es accesible mientras hay un compositor
  gráfico activo (Wayland, Xorg). Para ver los píxeles dibujados, ejecuta
  desde una TTY (Ctrl+Alt+F2/F3) o desde un equipo sin entorno gráfico.

Limitación conocida: las funciones de dibujado actuales asumen un framebuffer
de 32 bits por píxel. En 16 o 24 bpp no funcionarán correctamente.
Ver [TODO.md](TODO.md).

## Estructura del proyecto

```
lib/             Librerías NASM reutilizables (se empaquetan en libcore.a)
  cnv/           Conversiones (string ↔ entero)
  graph/         Gráficos: framebuffer, color, dibujado
  io/            Entrada/salida básica
  math/          Matemáticas enteras
    int32/       abs, min, max, clamp, div, mod — capas fast + cval por operación
  chrono/        Medición de ciclos de CPU (RDTSC/RDTSCP)
comandos/        Programas ejecutables que usan las librerías
  monitor/       Comandos relacionados con el framebuffer
  chrono/        Comandos de medición y benchmarking
  tools/         Herramientas de desarrollo y utilidades
    math/        Calculadora de operaciones enteras desde CLI
  tests/         Tests unitarios ejecutables de las librerías
tests/           Suite de tests smoke
```

## Normas del proyecto

Dos documentos definen las reglas que se siguen siempre:

- [NORMAS_LIBRERIAS.md](NORMAS_LIBRERIAS.md) — nomenclatura, patrón de capas
  fast/cval, convención ABI, contrato de Carry Flag, y la regla crítica de
  preservación de CF al delegar de cval a fast.
- [NORMAS_PRUEBAS.md](NORMAS_PRUEBAS.md) — flujo de trabajo, criterios de test
  y checklist antes de cada commit.

## Patrón de capas de las librerías

Todas las librerías con validación siguen el mismo patrón de dos capas:

- **`fast`** — motor puro, asume entrada válida, la llaman otras librerías.
- **`cval`** — escudo con validación, usa CF=1 para señalizar errores,
  la llaman los comandos directamente.

```
comando → lib_XYZcval → (si válido) → lib_XYZfast
```

## Modos de uso

### Modo local: una sola máquina sin entorno gráfico

```bash
git clone https://github.com/gut-mart/nasm.git
cd nasm
./setup.sh
make SRC=comandos/monitor/draw_pixel/draw_pixel.asm
sudo ./bin/draw_pixel 100 100 0xFF0000
```

### Modo remoto: equipo gráfico + equipo headless por SSH

Configuración inicial (una sola vez):

```bash
git clone https://github.com/gut-mart/nasm.git
cd nasm
./setup.sh
cp config.example.mk config.local.mk
nano config.local.mk
```

Para depuración remota con VS Code, define la IP del equipo remoto:

```bash
export NASM_REMOTE_HOST=192.168.1.X
```

Uso diario:

```bash
make deploy SRC=comandos/monitor/draw_pixel/draw_pixel.asm
```

`config.local.mk` está en `.gitignore`, no se sube al repositorio.

## Comandos disponibles

### Framebuffer (`comandos/monitor/`)

Cada comando acepta `-h` para ver su ayuda. Todos soportan argumentos
numéricos en decimal, hexadecimal (`0x...`), binario (`0b...`) y octal (`0o...`).

| Comando | Descripción |
|---|---|
| `fb_core` | Diagnóstico del framebuffer (resolución, bpp, offsets de color). |
| `draw_pixel` | Dibuja un píxel en (X, Y) del color indicado. |
| `draw_rect` | Dibuja un rectángulo sólido con clipping inteligente. |
| `draw_line` | Dibuja una línea entre dos puntos con clipping Cohen-Sutherland. |
| `draw_circle` | Dibuja un círculo con algoritmo de punto medio. |
| `screenshot` | Captura el framebuffer y lo guarda como archivo BMP. |

### Benchmarking (`comandos/chrono/`)

| Comando | Descripción |
|---|---|
| `bench_rect` | Mide en ticks de CPU el coste de pintar un rectángulo de pantalla completa. |

### Herramientas matemáticas (`comandos/tools/math/`)

Calculadora de operaciones enteras desde CLI. Útil durante el desarrollo
para verificar cálculos sin salir del terminal. Todos aceptan `-h` y soportan
múltiples bases numéricas.

| Comando | Uso | Descripción |
|---|---|---|
| `abs` | `abs VALOR` | Valor absoluto de un int32. |
| `min` | `min A B` | Mínimo de dos int32. |
| `max` | `max A B` | Máximo de dos int32. |
| `clamp` | `clamp VAL LO HI` | Limita VAL al rango [LO, HI]. |
| `div` | `div DIVIDENDO DIVISOR` | División entera (trunca hacia cero). |
| `mod` | `mod DIVIDENDO DIVISOR` | Resto de división (signo del dividendo). |

```bash
./bin/abs -42          # → 42
./bin/min 3 7          # → 3
./bin/max -5 2         # → 2
./bin/clamp 15 0 10    # → 10
./bin/div -7 2         # → -3
./bin/mod -7 2         # → -1
./bin/div 5 0          # → Error: division por cero
./bin/clamp 5 10 0     # → Error: rango invalido (LO > HI)
```

## Targets del Makefile

```bash
make SRC=<ruta.asm>      # Compila un archivo específico
make clean               # Limpia el binario y objeto del comando actual
make clean-all           # Limpia todo (incluida libcore.a)
make test                # Ejecuta la suite de tests
make run                 # Ejecuta el binario compilado localmente
make deploy SRC=<...>    # Compila y despliega en equipo remoto (modo SSH)
make info                # Muestra la configuración actual
make help                # Muestra esta ayuda
```

## Tests

La suite de tests (`make test`) no requiere framebuffer ni sudo. Compila todos
los comandos, verifica que responden a `-h` y rechazan argumentos inválidos, y
ejecuta los tests unitarios de las librerías.

Los tests unitarios viven en `comandos/tests/` y son binarios autónomos que
imprimen `OK/FAIL` por caso e informan su resultado vía exit code.

```bash
make test              # Suite completa
./bin/math_int32       # Solo tests de lib/math/int32 (41 casos: fast + cval)
```

## Depuración

El proyecto compila siempre con símbolos DWARF (`-g -F dwarf` en NASM).

- **Local:** `gdb ./bin/draw_pixel` o configuración "Depurar Local (GDB)" en VS Code.
- **Remoto:** `make deploy` arranca `gdbserver` en el equipo remoto. Selecciona
  "Depurar Remoto (SSH + gdbserver)" en VS Code y pulsa F5.

## Filosofía del proyecto

- **Sin librerías externas.** Solo syscalls Linux directas. Nada de libc.
- **x86_64 Linux exclusivamente.** Sin objetivo de portabilidad.
- **Una librería, una responsabilidad.** Capas `fast` y `cval` separadas.
- **Pruebas reales en hardware sin entorno gráfico.** El framebuffer es
  hardware real, no se simula.

## Licencia

[MIT](LICENSE) © 2026 gut-mart
