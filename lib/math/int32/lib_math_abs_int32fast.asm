; ==============================================================================
; RUTA: ./lib/math/int32/lib_math_abs_int32fast.asm
; DESCRIPCIÓN: Capa 2 (Motor). Valor absoluto de un entero con signo de 32 bits.
;              Asume entrada válida. La llaman otras librerías directamente.
;
; CONTRATO:
;   Entrada: EDI = valor (int32)
;   Salida:  EAX = |valor| (int32)
;            CF  = no modificado
;
; CASO ESPECIAL:
;   abs(INT32_MIN) = INT32_MIN — overflow inherente al complemento a dos.
;   Mismo comportamiento que abs() en C. No se señaliza como error.
;
; NOTA: Función leaf. Sin acceso a memoria ni llamadas externas.
;       No modifica registros callee-saved.
; ==============================================================================

default rel

section .text
    global lib_math_abs_int32fast

lib_math_abs_int32fast:
    mov   eax, edi      ; EAX = valor original
    neg   eax           ; EAX = -valor
    cmovl eax, edi      ; si -valor < 0 (valor era >= 0), restaurar original
    ret
