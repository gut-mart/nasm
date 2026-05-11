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
comandos/        Programas ejecutables que usan las librerías
  monitor/       Comandos relacionados con el framebuffer
tests/           Suite de tests
```

## Modos de uso

### Modo local: una sola máquina sin entorno gráfico

Si trabajas directamente en una máquina Linux sin compositor gráfico (TTY
pura, o servidor headless), todo el flujo cabe en una sola sesión:

```bash
git clone https://github.com/gut-mart/nasm.git
cd nasm
./setup.sh
make SRC=comandos/monitor/draw_pixel/draw_pixel.asm
sudo ./bin/draw_pixel 100 100 0xFF0000
```

### Modo remoto: equipo gráfico + equipo headless por SSH

Es el flujo principal del autor. Se edita y compila en un equipo con entorno
gráfico, y se ejecuta el binario por SSH en un equipo headless dentro de la
misma red WiFi.

Configuración inicial (una sola vez):

```bash
git clone https://github.com/gut-mart/nasm.git
cd nasm
./setup.sh

# Tu config personal: alias SSH, ruta remota, puerto de gdbserver
cp config.example.mk config.local.mk
nano config.local.mk
```

Para que VS Code pueda conectarse al equipo remoto al pulsar F5, define la
variable de entorno con la IP del equipo (en `~/.bashrc` o equivalente):

```bash
export NASM_REMOTE_HOST=192.168.1.X   # sustituye por la IP real de tu equipo remoto
```

Tras añadir la variable, reinicia VS Code para que la lea.

Uso diario:

```bash
make deploy SRC=comandos/monitor/draw_pixel/draw_pixel.asm
# Compila localmente, copia el binario al equipo remoto via scp
# y arranca gdbserver para depuración con VS Code.
```

Para ejecutar sin depurar (sin gdbserver), conéctate por SSH y ejecuta
manualmente:

```bash
ssh tu_equipo_remoto
sudo ./draw_pixel 100 100 0xFF0000
```

`config.local.mk` está en `.gitignore`, no se sube al repositorio.

## Comandos disponibles

Los comandos viven en `comandos/monitor/`. Cada uno acepta `-h` para ver su
ayuda.

| Comando | Descripción |
|---|---|
| `fb_core` | Diagnóstico del framebuffer (resolución, bpp, offsets de color). |
| `draw_pixel` | Dibuja un píxel en (X, Y) del color indicado. |
| `draw_rect` | Dibuja un rectángulo sólido con clipping inteligente. |

Cada comando soporta argumentos numéricos en decimal, hexadecimal (`0x...`),
binario (`0b...`) y octal (`0o...`).

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

## Depuración

El proyecto compila siempre con símbolos DWARF (`-g -F dwarf` en NASM) para
permitir depuración por línea de código fuente con GDB.

- **Local:** abre el binario con `gdb ./bin/draw_pixel` o usa la
  configuración "Depurar Local (GDB)" en VS Code (F5).
- **Remoto:** `make deploy` arranca un `gdbserver` en el equipo remoto. En VS
  Code, selecciona la configuración "Depurar Remoto (SSH + gdbserver)" y
  pulsa F5. Requiere haber definido la variable de entorno
  `NASM_REMOTE_HOST` con la IP del equipo remoto.

## Filosofía del proyecto

- **Sin librerías externas.** Solo syscalls Linux directas. Nada de libc.
- **x86_64 Linux exclusivamente.** Sin objetivo de portabilidad.
- **Pequeñas librerías reutilizables.** Cada librería tiene una sola
  responsabilidad y se compone con las demás.
- **Pruebas reales en hardware sin entorno gráfico.** El framebuffer es
  hardware real, no se simula.

## Licencia

[MIT](LICENSE) © 2026 gut-mart