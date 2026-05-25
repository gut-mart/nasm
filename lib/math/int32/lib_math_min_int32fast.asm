; ==============================================================================
; RUTA: ./lib/math/int32/lib_math_min_int32fast.asm
; DESCRIPCIÓN: Capa 2 (Motor). Devuelve el menor de dos enteros con signo de 32 bits.
;              Asume entrada válida. La llaman otras librerías directamente.
;
; CONTRATO:
;   Entrada: EDI = a (int32)
;            ESI = b (int32)
;   Salida:  EAX = min(a, b)
;            CF  = no modificado
;
; NOTA: Función leaf. Sin acceso a memoria ni llamadas externas.
;       No modifica registros callee-saved.
; ==============================================================================

default rel

section .text
    global lib_math_min_int32fast

lib_math_min_int32fast:
    mov   eax, esi      ; EAX = b (candidato inicial)
    cmp   edi, esi      ; a vs b
    cmovl eax, edi      ; si a < b → EAX = a
    ret
