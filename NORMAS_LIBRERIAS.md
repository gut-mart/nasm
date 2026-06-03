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
comando → lib_XYZcval → (si válido) → lib_XYZfast
librería → lib_XYZfast   (directamente, sin validar)
```

### Capa `cval` — Escudo

- **Quién la llama:** el comando directamente.
- **Responsabilidad:** validar la entrada y comunicar errores.
- **Mecanismo de error:** Carry Flag CF=1.
- **Si la entrada es válida:** ejecutar el motor y dejar CF=0 (ver sección 7
  para el modo correcto de delegar según si `fast` altera CF).
- **Si la entrada es inválida:** establecer EAX apropiado + `stc` + `ret`.
- **No repite lógica** del motor: delega siempre en `fast`.

### Capa `fast` — Motor

- **Quién la llama:** otras librerías, o `cval`.
- **Responsabilidad:** ejecutar la operación asumiendo entrada válida.
- **Sin validaciones.** Sin comprobaciones de rango ni formato.
- **CF:** ver sección 7. Puede o no alterar CF según las instrucciones que use;
  esto determina cómo debe delegar la capa `cval`.

### Cuándo NO aplicar el patrón

Si la operación no tiene entrada inválida posible (por ejemplo `min` y `max`
sobre cualquier par de int32), la capa `cval` existe igualmente para mantener
uniformidad, pero solo ejecuta el motor y fuerza CF=0 sin ninguna comprobación.

---

## 3. Contrato de Carry Flag (CF)

Regla universal en todo el proyecto:

| CF | Significado |
|---|---|
| `CF = 0` | Éxito. El resultado en EAX/RAX es fiable. |
| `CF = 1` | Error o caso especial. Ver documentación de la función. |

### Reglas de implementación

- La capa `fast` calcula y devuelve el resultado. Puede alterar CF como efecto
  secundario de sus instrucciones (ver sección 7).
- La capa `cval` **siempre garantiza un CF correcto** antes de retornar:
  - CF=0 en caso válido.
  - CF=1 (`stc`) en caso inválido.

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

## 5. Extensión de signo al pasar int32 a funciones de 64 bits

`print_int` y otras funciones de I/O reciben el argumento en `RDI` (64 bits)
y lo tratan como entero con signo de 64 bits. Cuando un comando tiene un
resultado int32 en `EAX` que puede ser negativo, **debe extender el signo a
64 bits antes de llamar**:

```nasm
; CORRECTO — extiende el signo de 32 a 64 bits
movsxd rdi, eax
call print_int

; INCORRECTO — deja basura/ceros en la parte alta de RDI
mov edi, eax        ; -3 (0xFFFFFFFD) se ve como 4294967293 en RDI
call print_int
```

**Síntoma del error:** un número negativo se imprime como su equivalente
unsigned grande (ej. `-3` aparece como `4294967293`).

**Regla:** al pasar un int32 con signo a una función que lo lee como 64 bits,
usar siempre `movsxd rdi, eax`. Solo usar `mov edi, eax` si el valor es
inequívocamente no negativo (un contador, un tamaño, etc.).

---

## 6. Estructura interna de un archivo de librería

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

%include "lib/math/int32/lib_math_int32.inc"   ; solo si se necesita

extern lib_XYZfast      ; solo si se llama a otra función

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

## 7. Delegación de cval a fast y preservación de CF (CRÍTICO)

Esta es la regla más sutil del proyecto y la fuente de un bug real corregido
en 2026-06. Determina **cómo** la capa `cval` debe llamar a `fast`.

### El problema

La capa `cval` quiere devolver CF=0 en caso válido. Tiene dos formas de delegar
en `fast`:

```nasm
; OPCIÓN A — tail-call con clc previo
clc
jmp lib_XYZfast

; OPCIÓN B — call + clc + ret
call lib_XYZfast
clc
ret
```

La opción A **solo funciona si `fast` NO altera CF**. Si `fast` contiene
cualquier `cmp`, `test`, `add`, `sub`, `idiv` u otra instrucción que modifique
CF, el `clc` previo se pierde: cuando `fast` hace su `ret`, el CF que ve el
llamante es el que dejó la última instrucción aritmética de `fast`, no el `clc`.

### La regla

| Caso | Cómo debe delegar `cval` |
|---|---|
| `fast` NO altera CF (solo `mov`, `imul`, `shl`, `lea`...) | Opción A: `clc` + `jmp fast` |
| `fast` SÍ altera CF (`cmp`, `test`, `idiv`, `add`, `sub`...) | Opción B: `call fast` + `clc` + `ret` |

### En caso de duda, usar siempre la opción B

`call fast` + `clc` + `ret` es **siempre correcta**, independientemente de lo
que haga `fast`. El coste es un frame de pila adicional (insignificante). La
opción A es una micro-optimización que solo debe usarse cuando se ha verificado
que `fast` no toca CF.

### Ejemplos reales del proyecto

```nasm
; lib_draw_pixelcval — fast usa mov/imul/add/shr, NO toca CF → opción A válida
clc
jmp lib_draw_pixelfast

; lib_math_min_int32cval — fast usa cmp → DEBE usar opción B
call lib_math_min_int32fast
clc
ret
```

### Por qué importa

El bug se manifestó así: `min(3,7)` devolvía el resultado correcto (3) pero con
CF=1 en lugar de CF=0, porque el `cmp edi, esi` dentro de `lib_math_min_int32fast`
dejaba CF=1 (3 < 7 activa CF en la comparación unsigned interna). El comando
interpretaba CF=1 como error y reportaba fallo pese a tener el valor correcto.

---

## 8. Funciones leaf vs. no-leaf

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

Nota: una capa `cval` que usa la opción B (`call fast`) deja de ser leaf
técnicamente, pero como no usa registros callee-saved tampoco necesita
prólogo/epílogo. El `call` + `ret` es suficiente.

### Función no-leaf con estado

Hace `call` y usa registros callee-saved. Requiere prólogo/epílogo estándar:

```nasm
lib_algo:
    push rbp
    mov  rbp, rsp
    push rbx
    push r12
    ; ... cuerpo ...
    pop  r12
    pop  rbx
    leave
    ret
```

---

## 9. Coherencia de nombres entre archivo y símbolo global

El nombre del símbolo `global` debe coincidir exactamente con el nombre del
archivo sin la extensión:

| Archivo | Símbolo global |
|---|---|
| `lib_math_abs_int32fast.asm` | `lib_math_abs_int32fast` |
| `lib_math_clamp_int32cval.asm` | `lib_math_clamp_int32cval` |
| `lib_draw_pixelfast.asm` | `lib_draw_pixelfast` |

---

## 10. Archivos `.inc`

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

## 11. Inventario de librerías del proyecto

### `lib/cnv/string_int32/` — Conversión string → int32

| Archivo | Capa | Llamante |
|---|---|---|
| `lib_string_int32cval.asm` | cval | comandos |
| `lib_string_int32fast.asm` | fast | `cval` |

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

| Archivo | Capa | fast toca CF | Delegación |
|---|---|---|---|
| `lib_draw_pixelcval.asm` | cval | No | Opción A (jmp) |
| `lib_draw_pixelfast.asm` | fast | — | — |

### `lib/graph/draw/rect/`

| Archivo | Capa |
|---|---|
| `lib_draw_rectcval.asm` | cval |
| `lib_draw_rectfast.asm` | fast |

### `lib/graph/draw/line/`

| Archivo | Capa |
|---|---|
| `lib_draw_linecval.asm` | cval |
| `lib_draw_linefast.asm` | fast |

### `lib/graph/draw/circle/`

| Archivo | Capa |
|---|---|
| `lib_draw_circlecval.asm` | cval |
| `lib_draw_circlefast.asm` | fast |

### `lib/graph/bmp/`

| Archivo | Nota |
|---|---|
| `lib_bmp_write.asm` | Sin capa: operación compleja única |

### `lib/math/int32/`

Todos los `fast` usan `cmp` o `idiv`, así que todos los `cval` usan la
opción B (`call fast` + `clc` + `ret`).

| Archivo | Capa | fast toca CF | Delegación |
|---|---|---|---|
| `lib_math_abs_int32cval.asm` | cval | No (cmovl) | Opción B por uniformidad |
| `lib_math_abs_int32fast.asm` | fast | — | — |
| `lib_math_min_int32cval.asm` | cval | Sí (cmp) | Opción B |
| `lib_math_min_int32fast.asm` | fast | — | — |
| `lib_math_max_int32cval.asm` | cval | Sí (cmp) | Opción B |
| `lib_math_max_int32fast.asm` | fast | — | — |
| `lib_math_clamp_int32cval.asm` | cval | Sí (cmp) | Opción B |
| `lib_math_clamp_int32fast.asm` | fast | — | — |
| `lib_math_div_int32cval.asm` | cval | Sí (idiv) | Opción B |
| `lib_math_div_int32fast.asm` | fast | — | — |
| `lib_math_mod_int32cval.asm` | cval | Sí (idiv) | Opción B |
| `lib_math_mod_int32fast.asm` | fast | — | — |

### `lib/chrono/`

| Archivo | Nota |
|---|---|
| `lib_rdtsc.asm` | Sin capa: conjunto de funciones de medición |

### `lib/io/`

| Archivo | Nota |
|---|---|
| `lib_print.asm` | Sin capa: I/O básica |
| `lib_file.asm` | Sin capa: wrappers de syscall |
| `lib_console.asm` | Sin capa: control de terminal |
