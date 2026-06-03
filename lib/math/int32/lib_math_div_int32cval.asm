; ==============================================================================
; RUTA: ./lib/math/int32/lib_math_div_int32cval.asm
; DESCRIPCIÓN: Capa 1 (Escudo). División entera con validación de entrada.
;              Valida divisor != 0 y el caso de overflow INT32_MIN / -1.
;              La llama el comando. Delega en lib_math_div_int32fast.
;
; CONTRATO:
;   Entrada: EDI = dividendo (int32)
;            ESI = divisor   (int32)
;   Salida:  EAX = cociente (válido solo si CF=0)
;            CF  = 0  división válida, resultado fiable
;            CF  = 1  entrada inválida:
;                     - divisor == 0           → EAX = 0
;                     - INT32_MIN / -1 overflow → EAX = INT32_MIN
;
; NOTA: El caso INT32_MIN / -1 daría +2147483648, que no cabe en int32 y
;       provoca excepción #DE en idiv. Se intercepta y se reporta con CF=1.
;       Se usa call + clc + ret (no tail-call) para controlar el CF final de
;       forma robusta, independientemente de cómo idiv deje las flags.
;       Función leaf.
; ==============================================================================

%include "lib/math/int32/lib_math_int32.inc"

default rel

extern lib_math_div_int32fast

section .text
    global lib_math_div_int32cval

lib_math_div_int32cval:
    ; --- 1. Validar división por cero ---
    test  esi, esi
    jz    .div_por_cero

    ; --- 2. Validar overflow INT32_MIN / -1 ---
    cmp   edi, INT32_MIN
    jne   .ok                   ; si dividendo != INT32_MIN, no hay overflow posible
    cmp   esi, -1
    je    .overflow             ; INT32_MIN / -1 → overflow

.ok:
    call  lib_math_div_int32fast    ; EAX = cociente
    clc                             ; CF=0: entrada válida
    ret

.div_por_cero:
    xor   eax, eax              ; EAX = 0
    stc                         ; CF=1: divisor cero
    ret

.overflow:
    mov   eax, INT32_MIN        ; resultado documentado para el caso de overflow
    stc                         ; CF=1: overflow INT32_MIN / -1
    ret
