# TODO — Tareas pendientes

Este archivo recoge mejoras y limitaciones conocidas del proyecto que se han
decidido **posponer conscientemente**, no olvidar. Cada entrada explica qué
falta, por qué se aplazó y qué haría falta para abordarla.

---

## Pendientes técnicos

### Soporte de profundidad de color variable (bpp ≠ 32)

**Estado:** parcialmente resuelto. El offset X y el salto de fila leen
`ScreenInfo.bpp` dinámicamente. La escritura final (`mov dword`) sigue
asumiendo 32 bpp (misma limitación que `lib_draw_pixelfast`).

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

### `fb_core` no comprueba el código de retorno de los `ioctl`

**Estado:** pendiente.

**Descripción:**
La función `fb_core` (`lib/graph/core/lib_fb_core.asm`) llama dos veces a
`ioctl` para obtener la información del framebuffer (`FBIOGET_VSCREENINFO` y
`FBIOGET_FSCREENINFO`), pero no comprueba el valor de retorno tras los
`syscall`. Si alguno de los `ioctl` falla (permisos insuficientes, dispositivo
no disponible, kernel sin soporte de la operación), `fb_core` continúa como
si hubiera ido bien y rellena la estructura `ScreenInfo` con datos basura.

**Impacto actual:**
En la práctica casi nunca se manifiesta porque si `sys_open` sobre `/dev/fb0`
tiene éxito, los `ioctl` también suelen tenerlo. Pero en escenarios poco
comunes (kernel personalizado sin soporte de framebuffer, dispositivo
sustituido en caliente, etc.) el comando reportaría datos basura y los
comandos posteriores dibujarían en posiciones incorrectas o tocarían memoria
no mapeada.

**Por qué se pospone:**
No es bloqueante para el caso de uso principal (hardware de pruebas con
`/dev/fb0` estándar) y la solución requiere reordenar parte del flujo de
`fb_core` para tener un punto de salida común con cleanup del file descriptor.

**Qué haría falta para abordarlo:**

1. Tras cada `syscall` de `ioctl`, comprobar si `RAX < 0` y saltar a un
   handler de error si lo es.
2. El handler debe cerrar el file descriptor abierto antes de retornar
   (con `sys_close` sobre el FD guardado en `RBX`).
3. La función debe devolver un código de error claro en `EAX` (negativo)
   para que el llamante lo propague.
4. Los comandos `draw_pixel`, `draw_rect`, etc. ya comprueban `cmp rax, 0
   / jl .error_fb`, así que con que `fb_core` devuelva valor negativo
   bastará para que el flujo de error funcione.

**Ubicación afectada:**

- `lib/graph/core/lib_fb_core.asm`

---

## Mejoras de robustez

### Validación de overflow en `lib_string_int32fast`

**Estado:** pendiente.

**Descripción:**
La conversión de cadena a entero no detecta desbordamiento. Una entrada como
`"99999999999999"` se convierte silenciosamente a un valor truncado de 32 bits
sin avisar al llamante.

**Por qué se pospone:**
Para uso casual desde CLI, el problema es menor (las coordenadas y colores
típicos caben holgadamente en 32 bits). No bloquea ningún caso de uso real.

**Qué haría falta:**
Tras cada multiplicación/desplazamiento en los bucles de conversión, comprobar
si el resultado se ha reducido respecto al valor previo. Si lo ha hecho, marcar
overflow y devolver error vía Carry Flag (la API ya soporta CF=1 = error
desde el commit 198d6d0).

**Ubicación afectada:**

- `lib/cnv/string_int32/lib_string_int32fast.asm`

---

## Mejoras cosméticas

### Doble salto de línea al final de mensajes de éxito

**Estado:** pendiente.

**Descripción:**
Los comandos `draw_pixel` y `draw_rect` imprimen un salto de línea extra tras
el mensaje de éxito porque hacen `print_string` (con el `\n` ya incluido en el
literal) seguido de `print_nl`. Resultado: un renglón en blanco entre el
mensaje y el prompt.

**Por qué se pospone:**
Es puramente cosmético. No afecta a tests ni a comportamiento. Se arregla
cuando se haga el siguiente pase de pulido sobre los comandos.

**Qué haría falta:**
Quitar la llamada a `print_nl` después del `print_string` del mensaje de
éxito en ambos comandos.

**Ubicación afectada:**

- `comandos/monitor/draw_pixel/draw_pixel.asm`
- `comandos/monitor/draw_rect/draw_rect.asm`

---

## Funcionalidad futura

(Sin items todavía. Añadir aquí nuevos comandos a desarrollar:
`draw_line`, `draw_circle`, `draw_text`, etc.)

---

## Convenciones de este archivo

- Cuando un item se complete, **no borrarlo**: marcarlo como hecho y mover a
  una sección "Resuelto" al final, con la fecha. El historial de decisiones
  pospuestas tiene valor.
- Cada item nuevo debe explicar: qué es, por qué se pospone, y qué haría falta
  para abordarlo. Sin esos tres campos, el item no es accionable a futuro.
