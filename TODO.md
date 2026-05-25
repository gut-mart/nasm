# TODO — Tareas pendientes

Este archivo recoge mejoras y limitaciones conocidas del proyecto que se han
decidido **posponer conscientemente**, no olvidar. Cada entrada explica qué
falta, por qué se aplazó y qué haría falta para abordarla.

---

## Pendientes técnicos

### Soporte de profundidad de color variable (bpp ≠ 32)

**Estado:** pendiente.

**Descripción:**
Las funciones de dibujado del motor (`lib_draw_pixelfast`, `lib_draw_rectfast`)
asumen que el framebuffer trabaja a 32 bits por píxel (4 bytes por píxel).
En el cálculo del offset X y en la escritura final usan `shl X, 2` y
`mov dword [...]` directamente, en lugar de leer `ScreenInfo.bpp` y calcular
el factor de bytes en tiempo de ejecución.

**Impacto actual:**
Si el framebuffer del sistema está configurado a 16 bpp o 24 bpp:

- Las coordenadas X se calculan como si fueran 32 bpp, por lo que los píxeles
  caen en posiciones incorrectas.
- La escritura de 4 bytes solapa píxeles adyacentes (16 bpp) o desalinea la
  estructura de la fila (24 bpp).

En la práctica, la mayoría de framebuffers Linux modernos exponen 32 bpp por
defecto, así que el problema solo aparece en hardware muy antiguo o configurado
manualmente.

**Por qué se pospone:**
Implementarlo en NASM puro es razonable, pero **no se puede verificar sin
hardware donde probarlo**. El equipo de pruebas actual (Tecra M10) trabaja
a 32 bpp.

**Qué haría falta para abordarlo:**

1. Acceso a una máquina con framebuffer configurable a 16 o 24 bpp.
2. Modificar `lib_draw_pixelfast` y `lib_draw_rectfast` para leer
   `ScreenInfo.bpp` y calcular el factor de bytes en lugar de hardcodearlo.
3. Para 24 bpp, escribir 3 bytes por píxel sin solapar.
4. Probar visualmente en cada modo.

**Ubicación afectada:**

- `lib/graph/draw/pixel/lib_draw_pixelfast.asm`
- `lib/graph/draw/rect/lib_draw_rectfast.asm`

---

## Funcionalidad futura

- `draw_text` — requiere librería de fuentes bitmap, más trabajo que el resto.
- `lib/math/int32` — ampliar con división entera (floor_div, ceil_div) siguiendo
  el patrón fast+cval cuando haya un caso de uso concreto.
- `lib/chrono` — ampliar con más benchmarks: `bench_pixel`, `bench_line`,
  `bench_circle`. Permitirá comparar el coste relativo de cada primitiva.
- Operaciones de color: brillo, fade, mezcla — primer usuario real de
  `lib_math_clamp_int32fast` para limitar canales RGB a [0, 255].
- `run_tests.sh` — añadir compilación y `-h` de los comandos `tools/math`
  cuando la suite de tests se amplíe.

---

## Convenciones de este archivo

- Cuando un item se complete, **no borrarlo**: marcarlo como hecho y mover a
  una sección "Resuelto" al final, con la fecha.
- Cada item nuevo debe explicar: qué es, por qué se pospone, y qué haría falta
  para abordarlo.

---

## Resuelto

### `fb_core` no comprueba el código de retorno de los `ioctl`

**Resuelto:** 2026-05-12

**Descripción:**
`fb_core` llamaba dos veces a `ioctl` sin comprobar el valor de retorno.
Si alguno fallaba, la función continuaba rellenando `ScreenInfo` con datos
basura sin avisar al llamante.

**Solución aplicada:**
Tras cada `syscall` de `ioctl` se comprueba `cmp rax, 0 / jl .error_ioctl`.
El handler cierra el file descriptor antes de retornar `rax = -1`.

**Ubicación:** `lib/graph/core/lib_fb_core.asm`

---

### Validación de overflow en `lib_string_int32cval`

**Resuelto:** 2026-05-12

**Descripción:**
La conversión de cadena a entero no detectaba desbordamiento.

**Solución aplicada:**
Añadido conteo de dígitos tras la validación de caracteres. Límites: decimal=10,
hexadecimal=8, octal=11, binario=32. CF=1 si se supera el límite.

**Ubicación:** `lib/cnv/string_int32/lib_string_int32cval.asm`

---

### Doble salto de línea al final de mensajes de éxito

**Resuelto:** 2026-05-12

**Solución aplicada:**
Eliminada la llamada a `print_nl` redundante en `draw_pixel` y `draw_rect`.

**Ubicación:**
- `comandos/monitor/draw_pixel/draw_pixel.asm`
- `comandos/monitor/draw_rect/draw_rect.asm`

---

### Comando `draw_line` con Bresenham y clipping Cohen-Sutherland

**Resuelto:** 2026-05-12

**Solución aplicada:**
`lib_draw_linecval` implementa Cohen-Sutherland (CF=1 si totalmente fuera).
`lib_draw_linefast` implementa Bresenham para los 8 octantes.

**Ubicación:**
- `lib/graph/draw/line/lib_draw_linecval.asm`
- `lib/graph/draw/line/lib_draw_linefast.asm`
- `comandos/monitor/draw_line/draw_line.asm`

---

### Comando `screenshot` y librería `lib_bmp_write`

**Resuelto:** 2026-05-12

**Solución aplicada:**
`lib_bmp_write` construye cabecera BMP de 54 bytes y convierte BGRA→BGR.
El comando acepta nombre de archivo y ruta de destino.

**Ubicación:**
- `lib/graph/bmp/lib_bmp_write.asm`
- `comandos/monitor/screenshot/screenshot.asm`

---

### Control de cursor y espera de tecla (`lib_console` + `fb_run.sh`)

**Resuelto:** 2026-05-12

**Solución aplicada:**
`lib_console.asm` aporta `lib_cursor_hide`, `lib_cursor_show` y `lib_wait_key`.
`fb_run.sh` gestiona el cursor del TTY físico de forma transparente.

**Ubicación:**
- `lib/io/lib_console.asm`
- `scripts/fb_run/fb_run.sh`

---

### Segfault en `lib_bmp_write` por lectura qword de slot dword

**Resuelto:** 2026-05-22

**Causa raíz:**
`bytes_por_fila` guardado como dword pero leído como qword, produciendo
un valor basura (~4M) que hacía escribir fuera del buffer.

**Solución aplicada:**
`movzx rax, eax` antes de guardar, slot ampliado a qword consistentemente.

**Ubicación:** `lib/graph/bmp/lib_bmp_write.asm`

---

### `lib/math/int32` — abs, min, max, clamp (primera versión monolítica)

**Resuelto:** 2026-05-24

**Descripción:**
Primera versión de las operaciones matemáticas básicas sobre int32, en un
único archivo monolítico con nombres `lib_math_abs_i32`, etc.

**Solución aplicada:**
`lib_math_int32.asm` con cuatro funciones leaf usando `cmovl`/`cmovg`.
Test unitario: 17/17 casos OK.

**Ubicación:**
- `lib/math/int32/lib_math_int32.asm` (eliminado en refactor posterior)
- `lib/math/int32/lib_math_int32.inc`

---

### `lib/chrono` — medición de ciclos con RDTSC/RDTSCP y `bench_rect`

**Resuelto:** 2026-05-24

**Solución aplicada:**
`lib_rdtsc.asm` detecta RDTSCP vs RDTSC via CPUID. `bench_rect` mide el
coste de un rectángulo de pantalla completa. Medición en Tecra M10
(1280×800, RDTSC): **3.494.920 ticks** (~2.2ms a 1.6GHz).

**Ubicación:**
- `lib/chrono/lib_rdtsc.asm`
- `comandos/chrono/bench_rect/bench_rect.asm`

---

### Refactor `lib/math/int32` — separar en fast+cval por operación

**Resuelto:** 2026-05-26

**Descripción:**
El archivo monolítico `lib_math_int32.asm` agrupaba cuatro operaciones con
nombres inconsistentes (`lib_math_abs_i32`) y sin separación de capas
fast/cval, rompiendo el patrón del resto del proyecto.

**Solución aplicada:**
Eliminado el monolítico. Cada operación tiene ahora dos archivos independientes
siguiendo el patrón del proyecto:

- `fast` — motor puro, sin validación, la llaman otras librerías.
- `cval` — escudo con validación, CF=1 para errores, la llaman los comandos.

`lib_math_abs_int32cval` detecta `INT32_MIN` y avisa con CF=1 (overflow
conocido). `lib_math_clamp_int32cval` valida `lo <= hi`. `min` y `max` no
tienen entrada inválida posible — su `cval` establece CF=0 y delega.

Test actualizado: 29 casos cubriendo fast y cval de cada operación.

Nuevos comandos CLI en `comandos/tools/math/`: `abs`, `min`, `max`, `clamp`.
Probados en Tecra M10. Aceptan múltiples bases numéricas.

**Ubicación:**
- `lib/math/int32/lib_math_abs_int32fast.asm`
- `lib/math/int32/lib_math_abs_int32cval.asm`
- `lib/math/int32/lib_math_min_int32fast.asm`
- `lib/math/int32/lib_math_min_int32cval.asm`
- `lib/math/int32/lib_math_max_int32fast.asm`
- `lib/math/int32/lib_math_max_int32cval.asm`
- `lib/math/int32/lib_math_clamp_int32fast.asm`
- `lib/math/int32/lib_math_clamp_int32cval.asm`
- `comandos/tools/math/abs/abs.asm`
- `comandos/tools/math/min/min.asm`
- `comandos/tools/math/max/max.asm`
- `comandos/tools/math/clamp/clamp.asm`
- `comandos/tests/math_int32/math_int32.asm`
