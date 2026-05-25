; ==============================================================================
; RUTA: ./lib/math/int32/lib_math_clamp_int32cval.asm
; DESCRIPCIÓN: Capa 1 (Escudo). Limita un valor al rango [lo, hi] con validación.
;              Valida que lo <= hi antes de operar. La llama el comando.
;              Delega en lib_math_clamp_int32fast si el rango es válido.
;
; CONTRATO:
;   Entrada: EDI = val (int32) — valor a limitar
;            ESI = lo  (int32) — límite inferior (inclusive)
;            EDX = hi  (int32) — límite superior (inclusive)
;   Salida:  EAX = valor clampeado (int32)
;            CF  = 0  rango válido (lo <= hi), resultado fiable
;            CF  = 1  rango inválido (lo > hi), EAX = val original sin modificar
;
; NOTA: Función leaf. Sin acceso a memoria ni llamadas externas.
;       No modifica registros callee-saved.
; ==============================================================================

default rel

extern lib_math_clamp_int32fast

section .text
    global lib_math_clamp_int32cval

lib_math_clamp_int32cval:
    cmp   esi, edx              ; lo vs hi
    jg    .rango_invalido

    clc                         ; CF=0: rango válido
    jmp   lib_math_clamp_int32fast  ; tail-call al motor

.rango_invalido:
    mov   eax, edi              ; EAX = val sin modificar
    stc                         ; CF=1: rango inválido
    ret
