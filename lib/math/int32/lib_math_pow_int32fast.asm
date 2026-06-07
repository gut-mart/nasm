; ==============================================================================
; RUTA: ./lib/math/int32/lib_math_pow_int32fast.asm
; DESCRIPCIÓN: Capa 2 (Motor). Potencia entera con signo: base^exp.
;              Algoritmo de exponenciación binaria (square-and-multiply): O(log exp).
;              Asume exp >= 0 y que el resultado NO desborda int32 (entrada ya
;              validada por la capa cval). La llaman otras librerías.
;
; CONTRATO:
;   Entrada: EDI = base (int32)
;            ESI = exp  (int32, se asume >= 0)
;   Salida:  EAX = base^exp (int32)
;            CF  = no modificado de forma fiable (usa imul/cmp internamente)
;
; ALGORITMO (square-and-multiply):
;   resultado = 1
;   mientras exp > 0:
;       si exp es impar:  resultado *= base
;       base *= base
;       exp >>= 1
;   Recorre los bits del exponente de menor a mayor. En cada bit a 1 acumula
;   la potencia de base correspondiente. O(log exp) multiplicaciones en lugar
;   de O(exp).
;
; NOTA: pow(x, 0) = 1 para cualquier x (incluido 0^0 = 1 por convención).
;       Usa EBX (callee-saved) para 'base', así que hace push/pop de RBX.
; ==============================================================================

default rel

section .text
    global lib_math_pow_int32fast

lib_math_pow_int32fast:
    push rbx                ; RBX es callee-saved, lo usamos para 'base'

    mov   eax, 1            ; EAX = resultado acumulado = 1
    mov   ebx, edi          ; EBX = base actual (se irá elevando al cuadrado)
    mov   ecx, esi          ; ECX = exp (contador de bits restantes)

.bucle:
    test  ecx, ecx          ; ¿quedan bits de exponente?
    jz    .fin              ; exp == 0 → terminado

    test  ecx, 1            ; ¿el bit menos significativo de exp es 1?
    jz    .saltar_mul       ; si es par, no multiplicamos este paso
    imul  eax, ebx          ; resultado *= base actual

.saltar_mul:
    imul  ebx, ebx          ; base = base^2 (preparar siguiente potencia)
    shr   ecx, 1            ; exp >>= 1 (pasar al siguiente bit)
    jmp   .bucle

.fin:
    pop  rbx
    ret
