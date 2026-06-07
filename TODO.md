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
Si el framebuffer del sistema está configurado a 16 bpp o 24 bpp, los píxeles
caen en posiciones incorrectas y la escritura de 4 bytes solapa píxeles
adyacentes. En la práctica, la mayoría de framebuffers Linux modernos exponen
32 bpp por defecto.

**Por qué se pospone:**
No se puede verificar sin hardware donde probarlo. El equipo de pruebas actual
(Tecra M10) trabaja a 32 bpp.

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
- `lib/math/int32` — ampliar con potencia entera (`pow`) y otras operaciones
  siguiendo el patrón fast+cval cuando haya un caso de uso concreto.
- `lib/math/int64` o `lib/math/uint32` — cuando se necesiten coordenadas
  grandes, contadores de ticks de 64 bits, o operaciones de máscara sin signo.
- `lib/chrono` — ampliar con más benchmarks: `bench_pixel`, `bench_line`,
  `bench_circle`. Permitirá comparar el coste relativo de cada primitiva.
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
