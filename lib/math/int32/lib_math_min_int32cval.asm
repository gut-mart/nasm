; ==============================================================================
; RUTA: ./lib/math/int32/lib_math_min_int32cval.asm
; DESCRIPCIÓN: Capa 1 (Escudo). Mínimo de dos int32 con contrato CF explícito.
;              La llama el comando. Delega en lib_math_min_int32fast.
;
; CONTRATO:
;   Entrada: EDI = a (int32)
;            ESI = b (int32)
;   Salida:  EAX = min(a, b)
;            CF  = 0 siempre (cualquier par de int32 es entrada válida)
;
; NOTA: lib_math_min_int32fast usa `cmp`, que altera CF. Por eso NO se puede
;       hacer tail-call con clc previo (el cmp del motor machacaría el clc).
;       Se usa call + clc + ret para controlar el CF final. Función leaf.
; ==============================================================================

default rel

extern lib_math_min_int32fast

section .text
    global lib_math_min_int32cval

lib_math_min_int32cval:
    call  lib_math_min_int32fast    ; EAX = min(a, b)
    clc                             ; CF=0: entrada siempre válida
    ret
