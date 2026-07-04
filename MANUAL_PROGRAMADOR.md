# Manual del programador

Referencia de la API de las librerías para usarlas desde código NASM. Cada
librería expone funciones globales que se llaman con `extern` y siguen el ABI
y el contrato de Carry Flag del proyecto.

> **Mantenimiento:** este manual debe actualizarse cada vez que se crea una
> librería nueva. Añade su entrada en la tabla y su sección de contrato.
> Las reglas de implementación están en `NORMAS_LIBRERIAS.md`.

---

## Convenciones generales

### ABI (System V x86-64)

| Registro | Uso |
|---|---|
| `EDI` / `RDI` | Argumento 1 |
| `ESI` / `RSI` | Argumento 2 |
| `EDX` / `RDX` | Argumento 3 |
| `ECX` / `RCX` | Argumento 4 |
| `R8D` / `R8` | Argumento 5 |
| `R9D` / `R9` | Argumento 6 |
| `EAX` / `RAX` | Valor de retorno |

Callee-saved (la función los preserva): `RBX`, `RBP`, `R12`–`R15`.
Caller-saved (pueden destruirse): `RCX`, `RDX`, `RSI`, `RDI`, `R8`–`R11`.

### Contrato de Carry Flag

| CF | Significado |
|---|---|
| 0 | Éxito. El resultado en EAX es fiable. |
| 1 | Error o caso especial. Ver la función concreta. |

### Patrón de dos capas

Cada operación con validación tiene dos versiones:

- **`fast`** — motor puro. Asume entrada válida, no comprueba nada. Llámala
  desde otras librerías cuando ya sabes que los datos son correctos.
- **`cval`** — escudo. Valida la entrada y usa CF para señalar errores.
  Llámala desde comandos o cuando los datos vienen del exterior.

**Regla clave:** desde otra librería, llama a `fast`. Desde un comando o con
datos sin validar, llama a `cval`. No valides dos veces.

### Dos trampas con el Carry Flag

Documentadas en detalle en `NORMAS_LIBRERIAS.md` secciones 7 y 7-bis:

1. **El CF no sobrevive a una `call`.** Si necesitas el CF que devolvió una
   función después de llamar a otra (ej. `print_int`), guárdalo antes en un
   registro callee-saved.
2. **El `clc` se pierde en un tail-call si `fast` usa `cmp`/`idiv`.** Por eso
   los `cval` de math usan `call fast + clc + ret` en lugar de `clc + jmp fast`.

---

## lib/math/int32 — Aritmética entera con signo

Constantes en `lib/math/int32/lib_math_int32.inc`:

```nasm
%define INT32_MIN   0x80000000      ; -2147483648
%define INT32_MAX   0x7FFFFFFF      ;  2147483647
```

### Tabla resumen

| Operación | fast | cval | Entrada | Salida (EAX) | CF=1 cuando |
|---|---|---|---|---|---|
| abs | `lib_math_abs_int32fast` | `lib_math_abs_int32cval` | EDI=val | \|val\| | val == INT32_MIN |
| min | `lib_math_min_int32fast` | `lib_math_min_int32cval` | EDI=a, ESI=b | min(a,b) | nunca |
| max | `lib_math_max_int32fast` | `lib_math_max_int32cval` | EDI=a, ESI=b | max(a,b) | nunca |
| clamp | `lib_math_clamp_int32fast` | `lib_math_clamp_int32cval` | EDI=val, ESI=lo, EDX=hi | clamp | lo > hi |
| div | `lib_math_div_int32fast` | `lib_math_div_int32cval` | EDI=dividendo, ESI=divisor | cociente | divisor=0 u overflow |
| mod | `lib_math_mod_int32fast` | `lib_math_mod_int32cval` | EDI=dividendo, ESI=divisor | resto | divisor=0 u overflow |
| pow | `lib_math_pow_int32fast` | `lib_math_pow_int32cval` | EDI=base, ESI=exp | base^exp | exp<0 u overflow |

### Contratos detallados

**abs** — valor absoluto.
```
fast: EDI=val → EAX=|val|. No toca CF. abs(INT32_MIN)=INT32_MIN (overflow).
cval: igual, pero CF=1 si val==INT32_MIN (avisa del overflow conocido).
```

**min / max** — menor / mayor de dos int32.
```
fast: EDI=a, ESI=b → EAX=min/max. No toca CF.
cval: igual, CF=0 siempre (cualquier par de int32 es válido).
```

**clamp** — limitar al rango [lo, hi].
```
fast: EDI=val, ESI=lo, EDX=hi → EAX=clamp. Asume lo<=hi.
cval: igual, pero CF=1 si lo>hi (rango inválido, EAX=val sin tocar).
```

**div** — división entera, trunca hacia cero.
```
fast: EDI=dividendo, ESI=divisor → EAX=cociente. Asume divisor!=0 y no overflow.
cval: CF=1 si divisor==0 (EAX=0) o si INT32_MIN/-1 (overflow, EAX=INT32_MIN).
```

**mod** — resto, signo del dividendo.
```
fast: EDI=dividendo, ESI=divisor → EAX=resto. Asume divisor!=0 y no overflow.
cval: CF=1 si divisor==0 (EAX=0) o si INT32_MIN/-1 (EAX=0).
```

**pow** — potencia entera (square-and-multiply, O(log exp)).
```
fast: EDI=base, ESI=exp → EAX=base^exp. Asume exp>=0 y resultado en rango.
cval: CF=1 si exp<0 (no representable) o si el resultado desborda int32 (EAX=0).
      Casos válidos: pow(x,0)=1, pow(0,n>0)=0.
```

### Ejemplo de integración

Calcular `clamp(a + b, 0, 255)` desde otra librería (usando las capas `fast`
porque los datos ya son válidos en este contexto):

```nasm
extern lib_math_clamp_int32fast

    ; supongamos EAX = a + b ya calculado
    mov  edi, eax       ; val = a+b
    xor  esi, esi       ; lo = 0
    mov  edx, 255       ; hi = 255
    call lib_math_clamp_int32fast
    ; EAX = valor limitado a [0, 255]
```

Desde un comando, con datos que vienen del usuario, usarías `lib_math_clamp_int32cval`
y comprobarías el CF con `jc .error`.

---

## lib/cnv — Conversiones

### lib_string_int32 — string → int32

| Función | Entrada | Salida | CF=1 cuando |
|---|---|---|---|
| `lib_string_int32cval` | RDI=puntero a cadena NUL | EAX=valor | cadena no es número válido o desborda |
| `lib_string_int32fast` | RDI=cadena ya validada | EAX=valor | nunca (asume válida) |

Acepta prefijos `0x`, `0b`, `0o`, `0d` y signo negativo. El `cval` valida los
caracteres y detecta overflow **por valor**: acumula en 64 bits durante la
validación y comprueba tras cada dígito que no se supera el tope. Los ceros a
la izquierda no cuentan para el rango. Topes según base y signo:

| Entrada | Tope | Racional |
|---|---|---|
| Decimal sin signo | `2147483647` (INT32_MAX) | Un decimal es una cantidad con signo |
| Hex/bin/oct sin signo | `0xFFFFFFFF` | Patrón de bits de 32 bits (colores, máscaras); `0xFFFFFFFF` = -1 |
| Con signo `-` (cualquier base) | magnitud `2147483648` (\|INT32_MIN\|) | El resultado debe ser representable en int32 |

### lib_uint32_string — uint32 → string

```
RDI=buffer destino, ESI=número uint32, EDX=base (2-36) → escribe cadena, RAX=buffer.
```

---

## lib/graph — Gráficos

### lib_fb_core — acceso al framebuffer

```
fb_core: RDI=puntero a ScreenInfo → rellena la estructura. RAX<0 si error.
fb_map:  RDI=ScreenInfo (ya rellena) → mapea /dev/fb0 en memoria. RAX<0 si error.
```

La estructura `ScreenInfo` y su tamaño están en `lib/graph/core/lib_fb_core.inc`.

### lib_color_pack — RGB → formato nativo

```
RDI=ScreenInfo, ESI=color 0xRRGGBB → EAX=color empaquetado para el hardware.
```

Usa los offsets **y las longitudes** de canal de `ScreenInfo`: cada canal de
8 bits se trunca a su longitud real antes de colocarse en su offset. Con
canales de 8 bits (24/32 bpp) el resultado es la identidad; a 16 bpp produce
RGB565 correcto (`0xFFFFFF` → `0xFFFF`, `0xFF0000` → `0xF800`). Asume
longitudes ≤ 8 bits.

### Primitivas de dibujado

Todas con patrón fast/cval. ABI común: `RDI=ScreenInfo`, luego coordenadas.

| Primitiva | cval | fast | Parámetros (tras RDI) |
|---|---|---|---|
| pixel | `lib_draw_pixelcval` | `lib_draw_pixelfast` | ESI=X, EDX=Y, ECX=color |
| rect | `lib_draw_rectcval` | `lib_draw_rectfast` | ESI=X, EDX=Y, ECX=W, R8D=H, R9D=color |
| line | `lib_draw_linecval` | `lib_draw_linefast` | ESI=X1, EDX=Y1, ECX=X2, R8D=Y2, R9D=color |
| circle | `lib_draw_circlecval` | `lib_draw_circlefast` | ESI=Xc, EDX=Yc, ECX=radio, R8D=color |

Los `cval` hacen clipping. CF=1 si la figura queda totalmente fuera (el llamante
puede ignorarlo — los comandos de usuario lo tratan como exit 0, no como error).
Los `fast` asumen coordenadas válidas.

**Profundidad de color (bpp):** las primitivas leen `ScreenInfo.bpp` y soportan
16, 24 y 32 bpp. El color que reciben es el **patrón de bits nativo del
framebuffer**, no un RGB abstracto:

- **32 bpp** — se escriben los 4 bytes del color (uso habitual: `lib_color_pack`).
- **24 bpp** — se escriben los 3 bytes bajos, sin solapar píxeles vecinos. Un
  color `0x00RRGGBB` produce los mismos bytes B,G,R que a 32 bpp: se ve igual.
- **16 bpp** — se escriben los 2 bytes bajos. El patrón (p. ej. RGB565) lo
  produce `lib_color_pack` a partir de un `0xRRGGBB` estándar, usando las
  longitudes de canal de `ScreenInfo`. Los comandos de dibujo ya pasan por
  `lib_color_pack`, así que funcionan sin cambios en cualquier modo.

Otras profundidades no están soportadas. Pendiente de verificación visual en
hardware real a 16/24 bpp (ver TODO.md).

### lib_bmp_write — framebuffer → BMP

```
RDI=ScreenInfo (mapeada), RSI=puntero a ruta de archivo → escribe BMP 24bpp.
```

---

## lib/chrono — Medición de ciclos

### lib_rdtsc

```
lib_rdtsc_init:   detecta RDTSCP vs RDTSC via CPUID. Llamar una vez al inicio.
lib_rdtsc_start:  marca el inicio de la medición.
lib_rdtsc_stop:   RAX = ciclos transcurridos desde start.
lib_rdtsc_method: RAX = puntero a cadena "RDTSCP" o "RDTSC".
```

---

## lib/io — Entrada/salida

### lib_print

```
print_string: RDI=cadena NUL → imprime en STDOUT.
print_error:  RDI=cadena NUL → imprime en STDERR.
print_int:    RDI=entero con signo de 64 bits → imprime en decimal.
print_nl:     imprime un salto de línea.
print_hex:    RDI=valor 64 bits → imprime en hexadecimal con prefijo 0x.
string_length: RDI=cadena → RAX=longitud.
```

**Importante:** `print_int` lee RDI como 64 bits con signo. Para imprimir un
int32 con signo, extiende el signo antes: `movsxd rdi, eax` (no `mov edi, eax`).
Ver `NORMAS_LIBRERIAS.md` sección 5.

### lib_file

```
file_open:  RDI=ruta, RSI=flags, RDX=modo → RAX=fd o error negativo.
file_read:  RDI=fd, RSI=buffer, RDX=bytes → RAX=leídos.
file_write: RDI=fd, RSI=buffer, RDX=bytes → RAX=escritos.
file_close: RDI=fd → RAX=0 o error.
```

### lib_console

```
lib_cursor_hide: oculta el cursor del terminal (ANSI ESC[?25l).
lib_cursor_show: lo restaura (ANSI ESC[?25h).
lib_wait_key:    espera una pulsación de tecla en modo raw (TCGETS/TCSETS).
```



