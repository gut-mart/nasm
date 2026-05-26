# Normas de las librerías NASM

Este documento define las normas que debe cumplir toda librería del proyecto.
Es la referencia canónica. Si existe contradicción con cualquier otro documento,
prevalece este.

---

## 1. Nomenclatura de archivos

### Patrón general

```
lib_<dominio>_<operación>_<tipo><capa>.asm
```

| Campo | Descripción | Ejemplos |
|---|---|---|
| `lib_` | Prefijo obligatorio en toda librería | |
| `<dominio>` | Área funcional | `math`, `draw`, `string`, `color` |
| `<operación>` | Qué hace | `abs`, `pixel`, `rect`, `clamp` |
| `<tipo>` | Tipo de dato si es relevante | `int32`, `uint32`, `int64` |
| `<capa>` | `cval` o `fast` (ver sección 2) | `cval`, `fast` |

### Ejemplos correctos

```
lib_math_abs_int32cval.asm
lib_math_abs_int32fast.asm
lib_draw_pixelcval.asm
lib_draw_pixelfast.asm
lib_string_int32cval.asm
lib_string_int32fast.asm
```

### Librerías sin capa

Las librerías que no tienen validación de entrada ni separación de capas
no llevan sufijo `cval`/`fast`:

```
lib_color_pack.asm        ← utilidad pura, sin validación posible
lib_bmp_write.asm         ← operación compleja única
lib_rdtsc.asm             ← conjunto de funciones de medición
lib_fb_core.asm           ← acceso a hardware, responsabilidad única
lib_uint32_string.asm     ← conversión sin caso de error (base se valida internamente)
```

### Archivos `.inc`

Uno por dominio, no por operación:

```
lib_math_int32.inc        ← constantes de todo lib/math/int32/
lib_fb_core.inc           ← estructura ScreenInfo y tamaño
lib_uint32_string.inc     ← reservado para constantes futuras
```

---

## 2. Patrón de capas: `fast` y `cval`

Toda operación que pueda recibir entrada inválida se implementa en dos capas:

```
comando → lib_XYZcval → (si válido, tail-call) → lib_XYZfast
librería → lib_XYZfast   (directamente, sin validar)
```

### Capa `cval` — Escudo

- **Quién la llama:** el comando directamente.
- **Responsabilidad:** validar la entrada y comunicar errores.
- **Mecanismo de error:** Carry Flag CF=1.
- **Si la entrada es válida:** `clc` + `jmp lib_XYZfast` (tail-call).
- **Si la entrada es inválida:** establecer EAX apropiado + `stc` + `ret`.
- **No repite lógica** del motor: delega siempre en `fast`.

### Capa `fast` — Motor

- **Quién la llama:** otras librerías, o `cval` via tail-call.
- **Responsabilidad:** ejecutar la operación asumiendo entrada válida.
- **Sin validaciones.** Sin comprobaciones de rango ni formato.
- **CF:** no modificado intencionadamente (así el `clc` previo de `cval` persiste).

### Cuándo NO aplicar el patrón

Si la operación no tiene entrada inválida posible (por ejemplo `min` y `max`
sobre cualquier par de int32), la capa `cval` existe igualmente para mantener
uniformidad, pero solo hace `clc` + tail-call sin ninguna comprobación.

---

## 3. Contrato de Carry Flag (CF)

Regla universal en todo el proyecto:

| CF | Significado |
|---|---|
| `CF = 0` | Éxito. El resultado en EAX/RAX es fiable. |
| `CF = 1` | Error o caso especial. Ver documentación de la función. |

### Reglas de implementación

- La capa `fast` **nunca toca CF** intencionadamente. Devuelve lo que calcula.
- La capa `cval` **siempre establece CF** antes de retornar o de hacer tail-call:
  - `clc` antes del `jmp lib_XYZfast` (caso válido).
  - `stc` antes del `ret` (caso inválido).
- Excepción: `lib_string_int32fast` hace `clc` explícito al final como
  documentación de contrato, aunque el llamante normal sea `cval`.

---

## 4. ABI — Convención de registros

El proyecto sigue el ABI System V x86-64. Resumen de lo relevante:

### Registros de argumentos (caller pone los datos aquí)

| Registro | Uso | Nota |
|---|---|---|
| `RDI` / `EDI` | Argumento 1 | Puntero o int32/int64 |
| `RSI` / `ESI` | Argumento 2 | |
| `RDX` / `EDX` | Argumento 3 | |
| `RCX` / `ECX` | Argumento 4 | |
| `R8` / `R8D` | Argumento 5 | |
| `R9` / `R9D` | Argumento 6 | |

### Registro de retorno

| Registro | Uso |
|---|---|
| `RAX` / `EAX` | Valor de retorno principal |

### Registros callee-saved (la función debe preservarlos)

`RBX`, `RBP`, `R12`, `R13`, `R14`, `R15`

Si una función los usa, debe hacer `push` al inicio y `pop` antes del `ret`.

### Registros caller-saved (pueden ser destruidos por la función)

`RCX`, `RDX`, `RSI`, `RDI`, `R8`, `R9`, `R10`, `R11`

El llamante no puede asumir que siguen válidos tras una `call`.

### Alineación de pila

La pila debe estar alineada a 16 bytes antes de cualquier `call`.
En `_start`, el patrón estándar del proyecto es:

```nasm
mov rbp, rsp        ; guardar RSP original (con argc/argv)
and rsp, -16        ; alinear antes de cualquier call
```

Los argumentos de CLI se leen siempre a través de `RBP`, nunca de `RSP`
tras la alineación.

---

## 5. Estructura interna de un archivo de librería

### Cabecera obligatoria

```nasm
; ==============================================================================
; RUTA: ./lib/<dominio>/<operación>/lib_<nombre>.asm
; DESCRIPCIÓN: Una línea explicando qué hace.
; CONTRATO:
;   Entrada: <registro> = <descripción> (<tipo>)
;   Salida:  <registro> = <descripción>
;            CF  = 0  <significado>
;            CF  = 1  <significado>
; NOTA: Función leaf / No modifica registros callee-saved / etc.
; ==============================================================================
```

### Secciones

```nasm
default rel             ; siempre presente

; %include solo si se necesita
%include "lib/math/int32/lib_math_int32.inc"

; extern solo si se llama a otra función
extern lib_XYZfast

section .text
    global lib_nombre_función
```

### Comentarios en el cuerpo

Cada instrucción con efecto no obvio lleva comentario en la misma línea:

```nasm
lib_math_abs_int32fast:
    mov   eax, edi      ; EAX = valor original
    neg   eax           ; EAX = -valor
    cmovl eax, edi      ; si -valor < 0 (valor era >= 0), restaurar original
    ret
```

---

## 6. Funciones leaf vs. no-leaf

### Función leaf

No hace ninguna `call` a otra función. No necesita prólogo/epílogo si no usa
registros callee-saved:

```nasm
lib_math_min_int32fast:
    mov   eax, esi
    cmp   edi, esi
    cmovl eax, edi
    ret
```

### Función no-leaf

Hace `call` a otras funciones. Requiere prólogo/epílogo estándar:

```nasm
lib_algo:
    push rbp
    mov  rbp, rsp
    push rbx            ; si usa RBX
    push r12            ; si usa R12
    ; ... cuerpo ...
    pop  r12
    pop  rbx
    leave
    ret
```

---

## 7. Tail-call en cval

La delegación de `cval` a `fast` se hace siempre con `jmp`, nunca con `call`:

```nasm
lib_math_min_int32cval:
    clc
    jmp lib_math_min_int32fast      ; tail-call — NO usar call+ret
```

Esto evita un frame de pila innecesario y preserva CF entre la instrucción
`clc` y el `ret` de `fast`.

---

## 8. Coherencia de nombres entre archivo y símbolo global

El nombre del símbolo `global` debe coincidir exactamente con el nombre del
archivo sin la extensión:

| Archivo | Símbolo global |
|---|---|
| `lib_math_abs_int32fast.asm` | `lib_math_abs_int32fast` |
| `lib_math_clamp_int32cval.asm` | `lib_math_clamp_int32cval` |
| `lib_draw_pixelfast.asm` | `lib_draw_pixelfast` |

---

## 9. Archivos `.inc`

- Un `.inc` por dominio tipado, no por función.
- Siempre con guard de inclusión múltiple:

```nasm
%ifndef LIB_MATH_INT32_INC
%define LIB_MATH_INT32_INC

%define INT32_MIN   0x80000000
%define INT32_MAX   0x7FFFFFFF

%endif
```

- Solo contienen constantes (`%define`) y estructuras (`struc`). Nunca código.

---

## 10. Inventario de librerías del proyecto

### `lib/cnv/string_int32/` — Conversión string → int32

| Archivo | Capa | Llamante |
|---|---|---|
| `lib_string_int32cval.asm` | cval | comandos |
| `lib_string_int32fast.asm` | fast | `cval` via tail-call |

### `lib/cnv/uint32_string/` — Conversión uint32 → string

| Archivo | Nota |
|---|---|
| `lib_uint32_string.asm` | Sin capa: base se valida internamente |

### `lib/graph/color/` — Empaquetado de color

| Archivo | Nota |
|---|---|
| `lib_color_pack.asm` | Sin capa: no hay entrada inválida posible |

### `lib/graph/core/` — Acceso al framebuffer

| Archivo | Nota |
|---|---|
| `lib_fb_core.asm` | Sin capa: operación compleja de hardware |

### `lib/graph/draw/pixel/`

| Archivo | Capa | Llamante |
|---|---|---|
| `lib_draw_pixelcval.asm` | cval | comandos |
| `lib_draw_pixelfast.asm` | fast | `cval`, `lib_draw_linefast`, `lib_draw_circlefast` |

### `lib/graph/draw/rect/`

| Archivo | Capa | Llamante |
|---|---|---|
| `lib_draw_rectcval.asm` | cval | comandos |
| `lib_draw_rectfast.asm` | fast | `cval`, `bench_rect` |

### `lib/graph/draw/line/`

| Archivo | Capa | Llamante |
|---|---|---|
| `lib_draw_linecval.asm` | cval | comandos |
| `lib_draw_linefast.asm` | fast | `cval` |

### `lib/graph/draw/circle/`

| Archivo | Capa | Llamante |
|---|---|---|
| `lib_draw_circlecval.asm` | cval | comandos |
| `lib_draw_circlefast.asm` | fast | `cval` |

### `lib/graph/bmp/`

| Archivo | Nota |
|---|---|
| `lib_bmp_write.asm` | Sin capa: operación compleja única |

### `lib/math/int32/`

| Archivo | Capa | Llamante |
|---|---|---|
| `lib_math_abs_int32cval.asm` | cval | comando `abs` |
| `lib_math_abs_int32fast.asm` | fast | otras librerías |
| `lib_math_min_int32cval.asm` | cval | comando `min` |
| `lib_math_min_int32fast.asm` | fast | otras librerías |
| `lib_math_max_int32cval.asm` | cval | comando `max` |
| `lib_math_max_int32fast.asm` | fast | otras librerías |
| `lib_math_clamp_int32cval.asm` | cval | comando `clamp` |
| `lib_math_clamp_int32fast.asm` | fast | otras librerías |

### `lib/chrono/`

| Archivo | Nota |
|---|---|
| `lib_rdtsc.asm` | Sin capa: conjunto de funciones de medición |

### `lib/io/`

| Archivo | Nota |
|---|---|
| `lib_print.asm` | Sin capa: I/O básica, sin validación de entrada |
| `lib_file.asm` | Sin capa: wrappers de syscall |
| `lib_console.asm` | Sin capa: control de terminal |
