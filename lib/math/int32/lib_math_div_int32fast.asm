; ==============================================================================
; RUTA: ./lib/math/int32/lib_math_div_int32fast.asm
; DESCRIPCIÓN: Capa 2 (Motor). División entera con signo de 32 bits.
;              Asume divisor != 0 y que NO se da el caso INT32_MIN / -1
;              (entrada ya validada por la capa cval). La llaman otras librerías.
;
; CONTRATO:
;   Entrada: EDI = dividendo (int32)
;            ESI = divisor   (int32, se asume != 0)
;   Salida:  EAX = cociente (trunca hacia cero, igual que C)
;            CF  = no modificado
;
; NOTA: Función leaf en cuanto a llamadas, pero usa EDX internamente
;       (idiv lo destruye). No modifica registros callee-saved.
;       Trunca hacia cero: -7 / 2 = -3.
; ==============================================================================

default rel

section .text
    global lib_math_div_int32fast

lib_math_div_int32fast:
    mov   eax, edi      ; EAX = dividendo
    cdq                 ; extiende signo de EAX a EDX:EAX (necesario para idiv)
    idiv  esi           ; EDX:EAX / ESI → cociente en EAX, resto en EDX
    ret                 ; devolvemos el cociente (EAX)
