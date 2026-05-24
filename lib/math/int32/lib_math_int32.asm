; ==============================================================================
; RUTA: ./lib/math/int32/lib_math_int32.asm
; DESCRIPCIÓN: Operaciones matemáticas básicas sobre enteros con signo de 32 bits.
;              abs, min, max, clamp.
;
; CONTRATO GENERAL:
;   - Entradas y salida en registros de 32 bits (EDI, ESI, EDX, EAX).
;   - Ninguna función modifica registros callee-saved (RBX, R12-R15, RBP).
;   - CF solo se usa en lib_math_clamp_i32 (ver contrato individual).
;   - Sin acceso a memoria, sin llamadas externas: todas son funciones leaf.
; ==============================================================================

default rel

section .text
    global lib_math_abs_i32
    global lib_math_min_i32
    global lib_math_max_i32
    global lib_math_clamp_i32

; ------------------------------------------------------------------------------
; FUNCIÓN: lib_math_abs_i32
; DESCRIPCIÓN: Valor absoluto de un entero con signo de 32 bits.
;              Caso especial documentado: abs(INT32_MIN) = INT32_MIN.
;              Es overflow inherente al complemento a dos; mismo comportamiento
;              que abs() en C. No se señaliza como error.
; ENTRADA:
;   EDI = valor (int32)
; SALIDA:
;   EAX = |valor| (int32)
;   CF  = no modificado
; ------------------------------------------------------------------------------
lib_math_abs_i32:
    mov   eax, edi      ; EAX = valor original
    neg   eax           ; EAX = -valor
    cmovl eax, edi      ; Si -valor < 0 (valor era positivo o cero), restaurar
    ret

; ------------------------------------------------------------------------------
; FUNCIÓN: lib_math_min_i32
; DESCRIPCIÓN: Devuelve el menor de dos enteros con signo de 32 bits.
; ENTRADA:
;   EDI = a (int32)
;   ESI = b (int32)
; SALIDA:
;   EAX = min(a, b)
;   CF  = no modificado
; ------------------------------------------------------------------------------
lib_math_min_i32:
    mov   eax, esi      ; EAX = b (candidato inicial)
    cmp   edi, esi      ; a vs b
    cmovl eax, edi      ; si a < b → EAX = a
    ret

; ------------------------------------------------------------------------------
; FUNCIÓN: lib_math_max_i32
; DESCRIPCIÓN: Devuelve el mayor de dos enteros con signo de 32 bits.
; ENTRADA:
;   EDI = a (int32)
;   ESI = b (int32)
; SALIDA:
;   EAX = max(a, b)
;   CF  = no modificado
; ------------------------------------------------------------------------------
lib_math_max_i32:
    mov   eax, esi      ; EAX = b (candidato inicial)
    cmp   edi, esi      ; a vs b
    cmovg eax, edi      ; si a > b → EAX = a
    ret

; ------------------------------------------------------------------------------
; FUNCIÓN: lib_math_clamp_i32
; DESCRIPCIÓN: Limita un valor al rango cerrado [lo, hi].
;              val < lo  → devuelve lo
;              val > hi  → devuelve hi
;              lo <= val <= hi → devuelve val sin cambios
;              lo == hi  → válido, devuelve lo  (CF=0)
;              lo > hi   → rango inválido        (CF=1, EAX = val sin tocar)
; ENTRADA:
;   EDI = val (int32)  — valor a limitar
;   ESI = lo  (int32)  — límite inferior (inclusive)
;   EDX = hi  (int32)  — límite superior (inclusive)
; SALIDA:
;   EAX = valor clampeado (int32)
;   CF  = 0  rango válido, resultado fiable
;   CF  = 1  rango inválido (lo > hi), EAX = val original sin modificar
; ------------------------------------------------------------------------------
lib_math_clamp_i32:
    cmp   esi, edx          ; lo vs hi
    jg    .rango_invalido

    mov   eax, edi          ; EAX = val
    cmp   eax, esi          ; val vs lo
    cmovl eax, esi          ; si val < lo → EAX = lo
    cmp   eax, edx          ; val (ajustado) vs hi
    cmovg eax, edx          ; si val > hi  → EAX = hi
    clc                     ; CF=0: éxito
    ret

.rango_invalido:
    mov   eax, edi          ; EAX = val sin modificar
    stc                     ; CF=1: rango inválido
    ret
