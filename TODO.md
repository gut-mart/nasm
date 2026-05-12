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

- `draw_line` — algoritmo de Bresenham, siguiente paso lógico tras rect.
- `draw_circle` — siguiente en complejidad geométrica.
- `draw_text` — requiere librería de fuentes, más trabajo.
- Librerías matemáticas, gestión de memoria, estructuras de datos.

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