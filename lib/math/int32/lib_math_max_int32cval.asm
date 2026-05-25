; ==============================================================================
; RUTA: ./lib/math/int32/lib_math_max_int32cval.asm
; DESCRIPCIÓN: Capa 1 (Escudo). Máximo de dos int32 con contrato CF explícito.
;              La llama el comando. Delega en lib_math_max_int32fast.
;
; CONTRATO:
;   Entrada: EDI = a (int32)
;            ESI = b (int32)
;   Salida:  EAX = max(a, b)
;            CF  = 0 siempre (cualquier par de int32 es entrada válida)
;
; NOTA: Función leaf. Sin acceso a memoria ni llamadas externas.
;       No modifica registros callee-saved.
; ==============================================================================

default rel

extern lib_math_max_int32fast

section .text
    global lib_math_max_int32cval

lib_math_max_int32cval:
    clc                             ; CF=0: entrada siempre válida
    jmp lib_math_max_int32fast      ; tail-call al motor
