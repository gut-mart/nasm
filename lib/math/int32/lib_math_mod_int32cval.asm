; ==============================================================================
; RUTA: ./lib/math/int32/lib_math_mod_int32cval.asm
; DESCRIPCIÓN: Capa 1 (Escudo). Resto de división entera con validación.
;              Valida divisor != 0 y el caso de overflow INT32_MIN / -1.
;              La llama el comando. Delega en lib_math_mod_int32fast.
;
; CONTRATO:
;   Entrada: EDI = dividendo (int32)
;            ESI = divisor   (int32)
;   Salida:  EAX = resto (válido solo si CF=0)
;            CF  = 0  módulo válido, resultado fiable
;            CF  = 1  entrada inválida:
;                     - divisor == 0            → EAX = 0
;                     - INT32_MIN % -1 overflow → EAX = 0
;
; NOTA: Matemáticamente INT32_MIN % -1 = 0, pero idiv lanza #DE igualmente
;       porque calcula el cociente (que sí desborda) antes del resto. Por eso
;       se intercepta y se reporta con CF=1 (EAX=0, que es el resto correcto).
;       Se usa call + clc + ret (no tail-call) para controlar el CF final de
;       forma robusta. Función leaf.
; ==============================================================================

%include "lib/math/int32/lib_math_int32.inc"

default rel

extern lib_math_mod_int32fast

section .text
    global lib_math_mod_int32cval

lib_math_mod_int32cval:
    ; --- 1. Validar división por cero ---
    test  esi, esi
    jz    .div_por_cero

    ; --- 2. Validar overflow INT32_MIN / -1 ---
    cmp   edi, INT32_MIN
    jne   .ok                   ; si dividendo != INT32_MIN, no hay overflow posible
    cmp   esi, -1
    je    .overflow             ; INT32_MIN % -1 → idiv lanza #DE igualmente

.ok:
    call  lib_math_mod_int32fast    ; EAX = resto
    clc                             ; CF=0: entrada válida
    ret

.div_por_cero:
    xor   eax, eax              ; EAX = 0
    stc                         ; CF=1: divisor cero
    ret

.overflow:
    xor   eax, eax              ; resto matemático de INT32_MIN % -1 es 0
    stc                         ; CF=1: caso interceptado (idiv habría lanzado #DE)
    ret
