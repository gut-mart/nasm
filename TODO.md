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
Implementarlo en NASM puro es razonable (sustituir `shl X, 2` por
`imul X, bytes_per_pixel` y elegir entre `mov word`/`mov [3 bytes]`/`mov dword`
según `bpp`), pero **no se puede verificar sin hardware donde probarlo**.
El equipo de pruebas actual (Tecra M10) trabaja a 32 bpp.

**Qué haría falta para abordarlo:**

1. Acceso a una máquina con framebuffer configurable a 16 o 24 bpp (vía
   parámetro de kernel `vga=` o `video=`).
2. Modificar `lib_draw_pixelfast` para leer `ScreenInfo.bpp` y calcular el
   factor de bytes en lugar de hardcodear `shr 3`/`shl 2`.
3. Modificar `lib_draw_rectfast` con la misma lógica.
4. Para 24 bpp, escribir 3 bytes por píxel sin solapar (un `mov word` + un
   `mov byte`, o tres `mov byte` consecutivos).
5. Probar visualmente en cada modo.

**Ubicación afectada:**

- `lib/graph/draw/pixel/lib_draw_pixelfast.asm`
- `lib/graph/draw/rect/lib_draw_rectfast.asm`

Las cabeceras de ambos archivos ya documentan esta limitación.

---

## Funcionalidad futura

Nuevos comandos y librerías a desarrollar, por orden de prioridad natural:

- `draw_text` — requiere librería de fuentes bitmap, más trabajo que el resto.
- `lib/math/int32` — ampliar con división entera (floor_div, ceil_div) y punto
  fijo cuando haya un caso de uso concreto (física, animación).
- `lib/chrono` — ampliar `bench_rect` con más benchmarks: `bench_pixel`,
  `bench_line`, `bench_circle`. Permitirá comparar el coste relativo de cada
  primitiva y detectar regresiones tras optimizaciones.
- Operaciones de color: brillo, fade, mezcla — primer usuario real de
  `lib_math_clamp_i32` para limitar canales RGB a [0, 255].

---

## Convenciones de este archivo

- Cuando un item se complete, **no borrarlo**: marcarlo como hecho y mover a
  una sección "Resuelto" al final, con la fecha. El historial de decisiones
  pospuestas tiene valor.
- Cada item nuevo debe explicar: qué es, por qué se pospone, y qué haría falta
  para abordarlo. Sin esos tres campos, el item no es accionable a futuro.

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
El handler `.error_ioctl` cierra el file descriptor con `sys_close rbx` antes
de saltar a `.error`, que devuelve `rax = -1`. Los llamantes ya comprobaban
ese valor negativo, por lo que no requirieron cambios.

**Ubicación:** `lib/graph/core/lib_fb_core.asm`

---

### Validación de overflow en `lib_string_int32cval`

**Resuelto:** 2026-05-12

**Descripción:**
La conversión de cadena a entero no detectaba desbordamiento. Una entrada como
`"99999999999999"` se convertía silenciosamente a un valor truncado de 32 bits
con CF=0, como si fuera válida.

**Solución aplicada:**
Añadido conteo de dígitos en `lib_string_int32cval` tras la validación de
caracteres. Si el número de dígitos supera el máximo posible para la base,
se devuelve CF=1 antes de llamar a `lib_string_int32fast`. Límites aplicados:
decimal=10, hexadecimal=8, octal=11, binario=32. Se añadieron los registros
callee-saved R12 (puntero al primer dígito) y R13 (límite de la base).

**Ubicación:** `lib/cnv/string_int32/lib_string_int32cval.asm`

---

### Doble salto de línea al final de mensajes de éxito

**Resuelto:** 2026-05-12

**Descripción:**
`draw_pixel` y `draw_rect` imprimían un salto de línea extra tras el mensaje
de éxito porque combinaban `print_string` (con `\n` en el literal) y
`print_nl`.

**Solución aplicada:**
Eliminada la llamada a `print_nl` tras el `print_string` del mensaje de éxito
en ambos comandos.

**Ubicación:**
- `comandos/monitor/draw_pixel/draw_pixel.asm`
- `comandos/monitor/draw_rect/draw_rect.asm`

---

### Comando `draw_line` con Bresenham y clipping Cohen-Sutherland

**Resuelto:** 2026-05-12

**Descripción:**
Necesidad de dibujar líneas rectas entre dos puntos arbitrarios, incluyendo
líneas que empiezan o terminan fuera de los límites de la pantalla.

**Solución aplicada:**
Dos capas siguiendo el patrón del proyecto. `lib_draw_linecval` implementa el
algoritmo de Cohen-Sutherland para recortar la línea contra los bordes de la
pantalla (CF=1 si totalmente fuera). `lib_draw_linefast` implementa Bresenham
para rasterizar los 8 octantes usando solo sumas y comparaciones enteras.
El comando `draw_line` sigue el ABI estándar del proyecto.

**Ubicación:**
- `lib/graph/draw/line/lib_draw_linecval.asm`
- `lib/graph/draw/line/lib_draw_linefast.asm`
- `comandos/monitor/draw_line/draw_line.asm`

---

### Comando `screenshot` y librería `lib_bmp_write`

**Resuelto:** 2026-05-12

**Descripción:**
Necesidad de capturar el framebuffer a un archivo de imagen visualizable en
cualquier ordenador, sin depender de herramientas externas como ffmpeg.

**Solución aplicada:**
`lib_bmp_write` construye una cabecera BMP de 54 bytes en tiempo de ejecución
y convierte los píxeles de BGRA (formato nativo del framebuffer) a BGR (24 bpp)
descartando el canal alfa. El resultado es un BMP estándar sin compresión que
abre correctamente en cualquier visor. El comando `screenshot` acepta dos
argumentos: nombre del archivo y ruta de destino, construyendo la ruta completa
`RUTA/NOMBRE.bmp` internamente.

**Ubicación:**
- `lib/graph/bmp/lib_bmp_write.asm`
- `comandos/monitor/screenshot/screenshot.asm`

---

### Control de cursor y espera de tecla (`lib_console` + `fb_run.sh`)

**Resuelto:** 2026-05-12

**Descripción:**
Al ejecutar comandos gráficos desde la TTY del Tecra, el cursor del terminal
parpadeaba encima del framebuffer, apareciendo en las capturas de pantalla.
Además, comandos rápidos como `draw_line` terminaban antes de que el usuario
pudiera ver el resultado.

**Solución aplicada:**
Dos piezas complementarias. `lib_console.asm` aporta tres funciones NASM:
`lib_cursor_hide` y `lib_cursor_show` (secuencias ANSI ESC[?25l/h) y
`lib_wait_key` (modo raw mínimo vía TCGETS/TCSETS, lee 1 byte sin eco ni Enter,
restaura el terminal al salir). El wrapper de shell `scripts/fb_run/fb_run.sh`
detecta el TTY activo vía `/sys/class/tty/tty0/active`, oculta el cursor en ese
TTY, ejecuta el comando con `--espera` si se solicita, y restaura el cursor al
terminar o si se interrumpe con Ctrl+C. `make deploy` copia `fb_run.sh` al
Tecra automáticamente junto con el binario.

**Ubicación:**
- `lib/io/lib_console.asm`
- `scripts/fb_run/fb_run.sh`
- `Makefile` (target `deploy`)

---

### Segfault en `lib_bmp_write` por lectura qword de slot dword

**Resuelto:** 2026-05-22

**Descripción:**
`screenshot` terminaba con segfault y generaba un BMP de solo 54 bytes (solo
la cabecera, sin píxeles). El bucle de conversión BGRA→BGR no ejecutaba
ninguna iteración antes de petar.

**Causa raíz:**
`bytes_por_fila` se calculaba correctamente (3840 para 1280 píxeles) y se
guardaba en el slot de pila como `dword`. Pero al leerlo posteriormente se
usaba `mov r11, qword [rbp - 52]` — leyendo 8 bytes cuando solo se habían
escrito 4. Los 4 bytes superiores contenían basura del stack, resultando en
`r11 ≈ 4.192.428` en lugar de 0. El bucle de padding intentaba escribir
4 millones de ceros fuera del buffer `row_buffer`, causando el segfault.
Detectado con GDB: crash en `.pad_bucle`, `r11 = 0x3ff8ac`.

**Solución aplicada:**
Añadido `movzx rax, eax` antes de guardar en el slot de pila para
zero-extend a 64 bits, garantizando que la lectura posterior como qword
devuelve un valor limpio. El slot se amplió a 8 bytes (`qword`) de forma
consistente.

**Ubicación:** `lib/graph/bmp/lib_bmp_write.asm`

---

### `lib/math/int32` — abs, min, max, clamp

**Resuelto:** 2026-05-24

**Descripción:**
Necesidad de operaciones matemáticas básicas sobre enteros de 32 bits con
signo como bloque de construcción para lógica de nivel alto (UI, animación,
operaciones de color).

**Solución aplicada:**
`lib_math_int32.asm` implementa cuatro funciones leaf sin ramas condicionales,
usando `cmovl`/`cmovg` para evitar mispredictions. `lib_math_clamp_i32` usa
Carry Flag (CF=1) para señalizar rango inválido (lo > hi), siguiendo la
convención del proyecto. Test unitario autónomo en
`comandos/tests/math_int32/math_int32.asm`: 17/17 casos OK. Integrado en
`tests/run_tests.sh` como nueva sección de tests unitarios de librerías.

**Ubicación:**
- `lib/math/int32/lib_math_int32.asm`
- `lib/math/int32/lib_math_int32.inc`
- `comandos/tests/math_int32/math_int32.asm`

---

### `lib/chrono` — medición de ciclos con RDTSC/RDTSCP y `bench_rect`

**Resuelto:** 2026-05-24

**Descripción:**
Necesidad de medir el coste real en ciclos de CPU de las primitivas gráficas
para tener una línea base antes de optimizar.

**Solución aplicada:**
`lib_rdtsc.asm` detecta en tiempo de inicialización via CPUID si el procesador
soporta RDTSCP (más preciso, serializa el pipeline) o solo RDTSC, y usa el
método disponible de forma transparente. Exporta `lib_rdtsc_init`,
`lib_rdtsc_start`, `lib_rdtsc_stop` y `lib_rdtsc_method`. El comando
`bench_rect` mide el coste de pintar un rectángulo de pantalla completa y
reporta método, resolución y ticks. Medición real en Tecra M10
(1280×800, RDTSC): **3.494.920 ticks** (~2.2ms a 1.6GHz).

**Ubicación:**
- `lib/chrono/lib_rdtsc.asm`
- `comandos/chrono/bench_rect/bench_rect.asm`
