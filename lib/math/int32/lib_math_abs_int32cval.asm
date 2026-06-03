; ==============================================================================
; RUTA: ./lib/math/int32/lib_math_abs_int32cval.asm
; DESCRIPCIÓN: Capa 1 (Escudo). Valor absoluto con notificación de caso especial.
;              La llama el comando. Delega en lib_math_abs_int32fast.
;
; CONTRATO:
;   Entrada: EDI = valor (int32)
;   Salida:  EAX = |valor| (int32)
;            CF  = 0  resultado fiable
;            CF  = 1  INT32_MIN detectado — resultado es INT32_MIN (overflow conocido)
;
; NOTA: lib_math_abs_int32fast usa instrucciones que NO alteran CF de forma
;       relevante, pero por seguridad de contrato hacemos clc explícito tras
;       volver del motor en lugar de confiar en un tail-call. Función leaf.
; ==============================================================================

%include "lib/math/int32/lib_math_int32.inc"

default rel

extern lib_math_abs_int32fast

section .text
    global lib_math_abs_int32cval

lib_math_abs_int32cval:
    ; --- Detectar INT32_MIN antes de calcular ---
    cmp   edi, INT32_MIN
    je    .caso_min

    ; --- Caso normal: calcular y forzar CF=0 ---
    call  lib_math_abs_int32fast    ; EAX = |valor|
    clc                             ; CF=0: resultado fiable
    ret

.caso_min:
    mov   eax, INT32_MIN            ; abs(INT32_MIN) = INT32_MIN por overflow
    stc                             ; CF=1: avisar al llamante del caso especial
    ret
