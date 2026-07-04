# TODO — Tareas pendientes

Este archivo recoge mejoras y limitaciones conocidas del proyecto que se han
decidido **posponer conscientemente**, no olvidar. Cada entrada explica qué
falta, por qué se aplazó y qué haría falta para abordarla.

---

## Pendientes técnicos

### Soporte de profundidad de color variable (bpp ≠ 32)

**Estado:** código implementado y verificado a nivel de memoria (2026-07-04),
**pendiente de verificación visual** en un framebuffer real a 16/24 bpp.

El test unitario `draw_bpp` (23 casos) verifica sobre un framebuffer falso en
memoria: offsets, tamaño de escritura (2/3/4 bytes), no-solapamiento, salto de
fila con padding de pitch en los tres modos, y el contrato CF de los cuatro
`cval` gráficos. Lo único que NO puede verificar es el aspecto en pantalla.

**Descripción:**
Las funciones de dibujado del motor asumían bpp=32 en la escritura final
(`mov dword`). Ya no: `lib_draw_pixelfast` y `lib_draw_rectfast` leen
`ScreenInfo.bpp` y escriben 2, 3 o 4 bytes por píxel según el modo (16/24/32).
A 24 bpp se escriben los 3 bytes bajos sin solapar; a 16 bpp los 2 bytes bajos
(el llamante pasa el patrón ya empaquetado, p. ej. RGB565). `line` y `circle`
heredan el soporte porque delegan en `pixel`.

**Cambio lateral (norma 7):** al introducir `cmp` en `pixelfast`, este pasó a
alterar CF, y los cuatro `cval` gráficos (pixel, rect, line, circle) migraron
de la opción A (`clc + jmp fast`) a la opción B (`call fast + clc + ret`).
En line y circle la opción A ya era incorrecta según la norma (sus `fast`
usan `cmp`) y funcionaba solo porque sus bucles salen con una comparación de
igualdad que deja CF=0.

**Qué falta para cerrarlo:**

1. Probar en el Tecra si el framebuffer admite otra profundidad:
   `fbset -depth 16` (suele fallar con drivers DRM como i915), o arrancar
   con un framebuffer genérico que sí la admita (`nomodeset` + VESA, o
   parámetro de kernel `video=`). Verificar el modo real con `fb_core`.
2. Si el Tecra no lo permite, buscar otra máquina o probar en QEMU con
   framebuffer VESA configurable.
3. Probar visualmente en cada modo: `draw_pixel`, `draw_rect`, `draw_line`,
   `draw_circle` y `screenshot`. Los colores `0xRRGGBB` deben verse
   correctos en todos los modos: `lib_color_pack` ya trunca los canales a
   su longitud real (RGB565 incluido) y todos los comandos pasan por él.
   `fb_core` (y `fb_core -p`) muestra offsets y longitudes de canal para
   confirmar el modo real.

**Ubicación afectada:**

- `lib/graph/draw/pixel/lib_draw_pixelfast.asm` (+ cval)
- `lib/graph/draw/rect/lib_draw_rectfast.asm` (+ cval)
- `lib/graph/draw/line/lib_draw_linecval.asm`
- `lib/graph/draw/circle/lib_draw_circlecval.asm`

---

## Funcionalidad futura

- `draw_text` — requiere librería de fuentes bitmap, más trabajo que el resto.
- `lib/math/int32` — ampliar con potencia entera (`pow`) y otras operaciones
  siguiendo el patrón fast+cval cuando haya un caso de uso concreto.
- `lib/math/int64` o `lib/math/uint32` — cuando se necesiten coordenadas
  grandes, contadores de ticks de 64 bits, o operaciones de máscara sin signo.
- `lib/chrono` — ampliar con más benchmarks: `bench_pixel`, `bench_line`,
  `bench_circle`. Permitirá comparar el coste relativo de cada primitiva.
- `lib_bmp_write` a 16/24 bpp — el bucle de lectura asume 4 bytes por píxel
  (`add rbx, 4`) y copia B,G,R directos, así que `screenshot` produce una
  captura corrupta en modos que no sean 32 bpp. Durante las pruebas de bpp
  variable en el Tecra esto es **esperado**, no un fallo del dibujado.
  Abordarlo cuando el modo 16 bpp esté verificado visualmente: leer 2/3/4
  bytes según `ScreenInfo.bpp` y, a 16 bpp, expandir RGB565 → RGB888 con
  los offsets/longitudes de canal.
- Operaciones de color: brillo, fade, mezcla — primer usuario real de
  `lib_math_clamp_int32fast` para limitar canales RGB a [0, 255].
- `run_tests.sh` — añadir compilación y `-h` de los comandos `tools/math`
  (abs, min, max, clamp, div, mod) cuando la suite de tests se amplíe.

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

Tras cada `syscall` de `ioctl` se comprueba `cmp rax, 0 / jl .error_ioctl`.
El handler cierra el file descriptor antes de retornar `rax = -1`.

**Ubicación:** `lib/graph/core/lib_fb_core.asm`

---

### Validación de overflow en `lib_string_int32cval`

**Resuelto:** 2026-05-12

Añadido conteo de dígitos tras la validación de caracteres. Límites: decimal=10,
hexadecimal=8, octal=11, binario=32. CF=1 si se supera el límite.

**Ubicación:** `lib/cnv/string_int32/lib_string_int32cval.asm`

---

### Doble salto de línea al final de mensajes de éxito

**Resuelto:** 2026-05-12

Eliminada la llamada a `print_nl` redundante en `draw_pixel` y `draw_rect`.

**Ubicación:**
- `comandos/monitor/draw_pixel/draw_pixel.asm`
- `comandos/monitor/draw_rect/draw_rect.asm`

---

### Comando `draw_line` con Bresenham y clipping Cohen-Sutherland

**Resuelto:** 2026-05-12

`lib_draw_linecval` implementa Cohen-Sutherland (CF=1 si totalmente fuera).
`lib_draw_linefast` implementa Bresenham para los 8 octantes.

**Ubicación:**
- `lib/graph/draw/line/lib_draw_linecval.asm`
- `lib/graph/draw/line/lib_draw_linefast.asm`
- `comandos/monitor/draw_line/draw_line.asm`

---

### Comando `screenshot` y librería `lib_bmp_write`

**Resuelto:** 2026-05-12

`lib_bmp_write` construye cabecera BMP de 54 bytes y convierte BGRA→BGR.

**Ubicación:**
- `lib/graph/bmp/lib_bmp_write.asm`
- `comandos/monitor/screenshot/screenshot.asm`

---

### Control de cursor y espera de tecla (`lib_console` + `fb_run.sh`)

**Resuelto:** 2026-05-12

`lib_console.asm` aporta `lib_cursor_hide`, `lib_cursor_show` y `lib_wait_key`.
`fb_run.sh` gestiona el cursor del TTY físico de forma transparente.

**Ubicación:**
- `lib/io/lib_console.asm`
- `scripts/fb_run/fb_run.sh`

---

### Segfault en `lib_bmp_write` por lectura qword de slot dword

**Resuelto:** 2026-05-22

`bytes_por_fila` guardado como dword pero leído como qword producía un valor
basura (~4M) que hacía escribir fuera del buffer. Corregido con `movzx rax, eax`
y slot ampliado a qword.

**Ubicación:** `lib/graph/bmp/lib_bmp_write.asm`

---

### `lib/math/int32` — abs, min, max, clamp (versión monolítica inicial)

**Resuelto:** 2026-05-24

Primera versión en archivo único `lib_math_int32.asm`. Eliminado en refactor
posterior (ver siguiente entrada).

---

### `lib/chrono` — medición de ciclos con RDTSC/RDTSCP y `bench_rect`

**Resuelto:** 2026-05-24

`lib_rdtsc.asm` detecta RDTSCP vs RDTSC via CPUID. `bench_rect` mide el coste
de un rectángulo de pantalla completa. Medición en Tecra M10 (1280×800, RDTSC):
**3.494.920 ticks** (~2.2ms a 1.6GHz).

**Ubicación:**
- `lib/chrono/lib_rdtsc.asm`
- `comandos/chrono/bench_rect/bench_rect.asm`

---

### Refactor `lib/math/int32` — separar en fast+cval por operación

**Resuelto:** 2026-05-26

Eliminado el monolítico. Cada operación (abs, min, max, clamp) tiene ahora dos
archivos independientes siguiendo el patrón del proyecto: `fast` (motor) y
`cval` (escudo con CF). Comandos CLI en `comandos/tools/math/`.

---

### Normas del proyecto documentadas

**Resuelto:** 2026-05-26

Añadidos `NORMAS_LIBRERIAS.md` (nomenclatura, capas, ABI, contrato CF) y
`NORMAS_PRUEBAS.md` (flujo de trabajo, checklist) como referencia canónica.

---

### `lib/math/int32` — div y mod con detección de overflow

**Resuelto:** 2026-06-03

**Descripción:**
División entera (`div`) y resto (`mod`) con signo de 32 bits, usando `idiv`.

**Solución aplicada:**
`fast` ejecuta `cdq` + `idiv`; `div` devuelve el cociente (EAX), `mod` devuelve
el resto (EDX movido a EAX). `cval` valida dos casos que provocarían excepción
#DE: división por cero y el overflow `INT32_MIN / -1`. Ambos se reportan con
CF=1. Test ampliado a 41 casos. Comandos CLI `div` y `mod` en
`comandos/tools/math/`. Probado en Tecra M10.

**Ubicación:**
- `lib/math/int32/lib_math_div_int32fast.asm`
- `lib/math/int32/lib_math_div_int32cval.asm`
- `lib/math/int32/lib_math_mod_int32fast.asm`
- `lib/math/int32/lib_math_mod_int32cval.asm`
- `comandos/tools/math/div/div.asm`
- `comandos/tools/math/mod/mod.asm`

---

### Bug de Carry Flag perdido en delegación cval → fast

**Resuelto:** 2026-06-03

**Descripción:**
Tras añadir div/mod, el test reveló que los `cval` de abs, min, max y clamp
devolvían el resultado correcto pero con CF=1 en casos válidos (debía ser CF=0).
Por ejemplo `min(3,7)` daba EAX=3 correcto pero CF=1, y el comando lo
interpretaba como error.

**Causa raíz:**
Los `cval` delegaban con `clc` + `jmp fast` (tail-call). Pero los `fast` de math
usan `cmp` (y div/mod usan `idiv`), que modifican CF. El `clc` se perdía: el CF
que veía el llamante era el de la última comparación de `fast`, no el `clc`
previo. `lib_draw_pixelcval` no tenía este bug porque su `fast` solo usa
mov/imul/add/shr, que no tocan CF.

**Solución aplicada:**
Cambiados los seis `cval` de math de `clc + jmp fast` a `call fast + clc + ret`,
de modo que el `cval` controla el CF final tras volver del motor. Documentada
la regla en `NORMAS_LIBRERIAS.md` sección 7: usar tail-call solo si `fast` no
altera CF; en caso de duda, `call + clc + ret`.

**Bug secundario corregido a la vez:**
`div -7 2` imprimía `4294967293` en vez de `-3`. Causa: los comandos pasaban el
resultado int32 a `print_int` con `mov edi, eax`, sin extender el signo a 64
bits. Corregido con `movsxd rdi, eax` en los seis comandos. Documentado en
`NORMAS_LIBRERIAS.md` sección 5.

**Ubicación:**
- `lib/math/int32/lib_math_abs_int32cval.asm`
- `lib/math/int32/lib_math_min_int32cval.asm`
- `lib/math/int32/lib_math_max_int32cval.asm`
- `lib/math/int32/lib_math_clamp_int32cval.asm`
- `lib/math/int32/lib_math_div_int32cval.asm`
- `lib/math/int32/lib_math_mod_int32cval.asm`
- `comandos/tools/math/{abs,min,max,clamp,div,mod}/*.asm`

---

### `lib/math/int32` — pow con square-and-multiply

**Resuelto:** 2026-06-07

**Descripción:**
Potencia entera con signo: base^exp.

**Solución aplicada:**
`fast` usa exponenciación binaria (square-and-multiply), O(log exp). `cval`
valida en 64 bits tras cada multiplicación que el valor sigue cabiendo en int32,
y devuelve CF=1 si desborda. El exponente negativo se trata como error (CF=1):
x^(-n) sería una fracción no representable como entero, decisión coherente con
abs(INT32_MIN) y div(x,0) — cuando el resultado correcto no cabe en int32, se
señaliza, no se inventa un valor. Casos válidos: pow(x,0)=1, pow(0,n>0)=0.
Test ampliado a 54 casos. Comando `pow` en `comandos/tools/math/`. Probado en
Tecra M10.

**Ubicación:**
- `lib/math/int32/lib_math_pow_int32fast.asm`
- `lib/math/int32/lib_math_pow_int32cval.asm`
- `comandos/tools/math/pow/pow.asm`

---

### Manuales centralizados de usuario y programador

**Resuelto:** 2026-06-07

**Descripción:**
Faltaba documentación de uso orientada a las dos audiencias del proyecto: quien
ejecuta los comandos desde la terminal, y quien usa las librerías desde NASM.

**Solución aplicada:**
Dos manuales centralizados (uno por audiencia, no un archivo por comando, para
evitar la desincronización de decenas de ficheros):

- `MANUAL_USUARIO.md` — todos los comandos, con ejemplos, dominio y rango. Incluye
  una sección sobre la amplitud de los enteros de 32 bits y por qué ciertos
  casos límite dan error.
- `MANUAL_PROGRAMADOR.md` — la API de cada librería: ABI, contrato CF, qué capa
  fast/cval llamar, y ejemplos de integración.

El flujo de trabajo y el checklist de `NORMAS_PRUEBAS.md` se actualizaron para
exigir mantener ambos manuales al crear comandos o librerías nuevas.

**Ubicación:**
- `MANUAL_USUARIO.md`
- `MANUAL_PROGRAMADOR.md`
- `NORMAS_PRUEBAS.md` (flujo y checklist actualizados)




---

### Eliminar `--tics` de comandos gráficos e igualar comportamiento de coordenadas

**Resuelto:** 2026-06-07

**Descripción:**
Los cuatro comandos gráficos (`draw_pixel`, `draw_rect`, `draw_line`,
`draw_circle`) tenían el flag `--tics` para medir ciclos de CPU, mezclando
la responsabilidad de dibujar con la de medir. Además, `draw_pixel` era el
único que devolvía error (exit 1) cuando las coordenadas quedaban fuera de
pantalla, siendo inconsistente con los otros tres que hacen clipping.

**Solución aplicada:**
Eliminado `--tics` de los cuatro comandos. Para medir ciclos usar `bench_rect`
o futuros comandos de `comandos/chrono/`. Unificado el comportamiento de
coordenadas fuera de pantalla: todos devuelven exit 0 (ignorado silenciosamente)
cuando la figura queda fuera, igual que hace el clipping parcial. El error exit 1
solo se da para argumentos malformados o fallo de framebuffer.

Configurado `/etc/sudoers.d/nasm_path` en el Tecra para que `sudo` encuentre
los binarios en `~/bin` sin necesidad de especificar la ruta completa.

**Ubicación:**
- `comandos/monitor/draw_pixel/draw_pixel.asm`
- `comandos/monitor/draw_rect/draw_rect.asm`
- `comandos/monitor/draw_line/draw_line.asm`
- `comandos/monitor/draw_circle/draw_circle.asm`

---

### `lib_color_pack` universal por bpp: longitudes de canal en `ScreenInfo`

**Resuelto:** 2026-07-04

**Descripción:**
`lib_color_pack` colocaba cada canal de 8 bits en su offset sin truncarlo a la
longitud real del canal, así que a 16 bpp (RGB565, canales de 5/6/5 bits) el
resultado era basura y había que pasar el patrón empaquetado a mano.

**Solución aplicada:**
`ScreenInfo` amplía con `red_len`/`green_len`/`blue_len`/`transp_len` (el
kernel las devuelve en el mismo `ioctl` `FBIOGET_VSCREENINFO`, campo `length`
de cada `fb_bitfield`; tamaño de la estructura: 56 → 72 bytes). `fb_core` las
rellena y `lib_color_pack` trunca cada canal (`shr` de `8 - len`) antes del
desplazamiento al offset. Con canales de 8 bits el truncado es nulo (idéntico
comportamiento a 24/32 bpp); a 16 bpp produce RGB565 correcto. Como los cuatro
comandos de dibujo pasan por `lib_color_pack`, el flujo `0xRRGGBB` → pantalla
funciona sin cambios en cualquier modo. El comando `fb_core` muestra ahora
offsets y longitudes de canal en ambos formatos de salida.

Test `draw_bpp` ampliado a 29 casos (identidad a 24/32 bpp, RGB565 y la
integración pack→pixel). Pendiente solo la verificación visual en hardware
real, junto con la del resto del soporte de bpp variable (ver Pendientes).

**Ubicación:**
- `lib/graph/core/lib_fb_core.inc` (+ `lib_fb_core.asm`)
- `lib/graph/color/lib_color_pack.asm`
- `comandos/monitor/core/fb_core.asm`
- `comandos/tests/draw_bpp/draw_bpp.asm`

---

### Hueco en la detección de overflow de `lib_string_int32cval`

**Resuelto:** 2026-07-04

**Descripción:**
La validación de overflow del parser contaba dígitos (decimal ≤ 10,
octal ≤ 11...) en lugar de comprobar el valor. El conteo rechazaba cadenas
demasiado largas, pero aceptaba valores que cabían en el conteo y no en
32 bits: `abs 5000000000` devolvía 705032704 (truncado), `abs 4294967295`
devolvía 1 (envolvía a -1) y `abs 0o77777777777` devolvía 1, todos con
exit 0. Violaba la regla del proyecto de nunca inventar un valor.

**Solución aplicada:**
Validación por valor: el `cval` acumula el número en 64 bits dentro de los
mismos bucles que validan caracteres, y tras cada dígito comprueba que no se
supera el tope (mismo enfoque que la validación de `lib_math_pow_int32cval`).
Regla de tres topes: decimal sin signo ≤ INT32_MAX (una cantidad con signo);
hex/bin/oct sin signo ≤ 0xFFFFFFFF (patrones de bits para colores y máscaras,
`0xFFFFFFFF` = -1); con signo `-` magnitud ≤ |INT32_MIN| en cualquier base.
Mejoras laterales: los ceros a la izquierda ya no cuentan para el rango
(`0x00000000FF` = 255 antes se rechazaba), y `0d` sin dígitos ahora es error
(antes se aceptaba como 0, inconsistente con `0x`).

Test unitario nuevo `string_int32` (26 casos: fast + cval) y 5 casos de error
lógico de rango añadidos a `run_tests.sh`. Suite total: 78 tests.

**Ubicación:**
- `lib/cnv/string_int32/lib_string_int32cval.asm`
- `comandos/tests/string_int32/string_int32.asm`
- `tests/run_tests.sh`
- `MANUAL_USUARIO.md`, `MANUAL_PROGRAMADOR.md` (rangos documentados)
