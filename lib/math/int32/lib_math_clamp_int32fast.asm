; ==============================================================================
; RUTA: ./lib/math/int32/lib_math_clamp_int32fast.asm
; DESCRIPCIÓN: Capa 2 (Motor). Limita un valor al rango cerrado [lo, hi].
;              Asume lo <= hi (entrada ya validada). La llaman otras librerías.
;
; CONTRATO:
;   Entrada: EDI = val (int32) — valor a limitar
;            ESI = lo  (int32) — límite inferior (inclusive), se asume lo <= hi
;            EDX = hi  (int32) — límite superior (inclusive)
;   Salida:  EAX = valor clampeado (int32)
;            CF  = no modificado
;
; NOTA: Función leaf. Sin acceso a memoria ni llamadas externas.
;       No modifica registros callee-saved.
; ==============================================================================

default rel

section .text
    global lib_math_clamp_int32fast

lib_math_clamp_int32fast:
    mov   eax, edi          ; EAX = val
    cmp   eax, esi          ; val vs lo
    cmovl eax, esi          ; si val < lo → EAX = lo
    cmp   eax, edx          ; val (ajustado) vs hi
    cmovg eax, edx          ; si val > hi  → EAX = hi
    ret
