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
overflow y devolver error.

**Ubicación afectada:**

- `lib/cnv/string_int32/lib_string_int32fast.asm`

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