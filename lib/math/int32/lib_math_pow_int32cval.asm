; ==============================================================================
; RUTA: ./lib/math/int32/lib_math_pow_int32cval.asm
; DESCRIPCIÓN: Capa 1 (Escudo). Potencia entera con validación de overflow.
;              La llama el comando. Detecta exponente negativo (no representable)
;              y desbordamiento de int32. Delega en lib_math_pow_int32fast solo
;              cuando ha confirmado que el resultado cabe.
;
; CONTRATO:
;   Entrada: EDI = base (int32)
;            ESI = exp  (int32)
;   Salida:  EAX = base^exp (int32, válido solo si CF=0)
;            CF  = 0  resultado válido
;            CF  = 1  no representable en int32; EAX = 0. Dos causas:
;                     - exp < 0   → el resultado sería una fracción (no entera)
;                     - overflow  → el resultado entero no cabe en int32
;
; CASOS ESPECIALES (con CF=0):
;   exp == 0          → EAX = 1   (incluido 0^0 = 1 por convención)
;   base == 0, exp>0  → EAX = 0
;   base == 1         → EAX = 1
;
; DECISIÓN DE DISEÑO (exp negativo):
;   x^(-n) = 1/(x^n) es una fracción que no es representable como entero
;   (salvo |x|=1, que aquí no se trata como caso especial para mantener una
;   regla única y simple). Coherente con abs(INT32_MIN) y div(x,0): cuando el
;   resultado correcto no cabe en int32, se señaliza con CF=1 en vez de
;   inventar un valor.
;
; ESTRATEGIA DE VALIDACIÓN DE OVERFLOW:
;   Repite square-and-multiply en 64 bits. Tras CADA multiplicación (de
;   'resultado' y de 'base'), comprueba que el valor sigue en el rango int32
;   con signo. Como cada producto de dos int32 cabe holgadamente en 64 bits,
;   la comprobación es siempre fiable. Si en algún punto se sale → CF=1.
;
; NOTA: Usa RBX, R12 (callee-saved): prólogo/epílogo con push/pop.
; ==============================================================================

%include "lib/math/int32/lib_math_int32.inc"

default rel

section .text
    global lib_math_pow_int32cval

lib_math_pow_int32cval:
    push rbx
    push r12

    ; --- Exponente negativo: no representable como entero → error ---
    test  esi, esi
    js    .no_representable     ; exp < 0 → CF=1

    ; --- exp == 0 → 1 (caso válido) ---
    jz    .resultado_uno

    ; --- Bucle de validación en 64 bits ---
    mov   eax, 1               ; RAX = resultado acumulado = 1
    movsxd rbx, edi            ; RBX = base (sign-extend a 64 bits)
    mov   r12d, esi            ; R12D = exp restante

.bucle:
    test  r12d, 1              ; ¿bit bajo del exponente a 1?
    jz    .cuadrado

    imul  rax, rbx             ; resultado *= base  (64 bits)
    call  .cabe_en_int32       ; CF=1 si RAX se salió del rango
    jc    .overflow

.cuadrado:
    shr   r12d, 1              ; exp >>= 1
    jz    .terminado           ; no quedan más bits → fin

    imul  rbx, rbx             ; base = base^2  (64 bits)
    push  rax                  ; validar la base: guardamos resultado,
    mov   rax, rbx             ;   ponemos base en RAX y comprobamos rango
    call  .cabe_en_int32
    pop   rax                  ; restaurar resultado (pop no toca CF)
    jc    .overflow
    jmp   .bucle

.terminado:
    clc                        ; CF=0: resultado válido
    jmp   .salir               ; EAX = parte baja de RAX (cabe con seguridad)

.resultado_uno:
    mov   eax, 1
    clc
    jmp   .salir

.no_representable:
.overflow:
    xor   eax, eax             ; EAX = 0
    stc                        ; CF=1: no representable / overflow
    jmp   .salir

; --- Subrutina interna: CF=1 si RAX no cabe en int32 con signo, CF=0 si cabe.
;     No altera RAX. ---
.cabe_en_int32:
    push  rcx
    movsxd rcx, eax            ; RCX = sign-extend de los 32 bits bajos de RAX
    cmp   rcx, rax             ; ¿coincide con el RAX completo de 64 bits?
    pop   rcx                  ; (pop no altera flags; cmp ya fijó ZF)
    je    .cr_cabe
    stc
    ret
.cr_cabe:
    clc
    ret

.salir:
    pop  r12                   ; pop no altera CF
    pop  rbx
    ret
