; ==============================================================================
; LIBRERÍA: lib_string_int32cval.asm
; DESCRIPCIÓN: Capa 1 (Escudo). Identifica prefijos, valida caracteres
;              y detecta overflow POR VALOR antes de delegar en la capa rápida.
; CONTRATO:
;   Entrada: RDI = puntero a cadena terminada en NUL.
;   Salida:  EAX = valor convertido (válido solo si CF=0).
;            CF = 0 si la conversión es válida.
;            CF = 1 si la cadena no representa un número válido,
;                   o si el valor no cabe en 32 bits (overflow).
;
; RANGOS ACEPTADOS (regla de tres topes):
;   Decimal sin signo       : 0 .. 2147483647 (INT32_MAX). Un decimal es una
;                             cantidad con signo; por encima de INT32_MAX el
;                             int32 resultante sería un valor "inventado".
;   Hex/bin/oct sin signo   : 0 .. 0xFFFFFFFF. Son patrones de bits de 32 bits
;                             (colores, máscaras); 0xFFFFFFFF equivale a -1.
;   Con signo '-' (cualquier base): magnitud 0 .. 2147483648 (|INT32_MIN|).
;
; ESTRATEGIA DE VALIDACIÓN DE OVERFLOW:
;   Durante el mismo bucle que valida los caracteres, acumula el valor en un
;   registro de 64 bits y comprueba tras cada dígito que no supera el tope.
;   Como el acumulador entra en cada paso valiendo <= 0xFFFFFFFF, ningún paso
;   puede envolver los 64 bits: la comprobación es siempre fiable, admite
;   ceros a la izquierda y cualquier longitud de cadena. Mismo enfoque que
;   la validación en 64 bits de lib_math_pow_int32cval.
;   (Sustituye a la detección por conteo de dígitos, que dejaba pasar valores
;   como 5000000000 —10 dígitos— o 0o77777777777 —11 dígitos octales—.)
; ==============================================================================

default rel

extern lib_string_int32fast

section .text
    global lib_string_int32cval

lib_string_int32cval:
    push rbp
    mov rbp, rsp
    push rbx
    push r12                ; R12 = puntero al inicio de los dígitos (tras prefijo)
    push r13                ; R13 = tope de valor según base y signo

    mov rbx, rdi            ; RBX = inicio de la cadena original

    mov cl, byte [rdi]
    test cl, cl
    jz .error

    ; --- Manejar signo negativo ---
    cmp cl, '-'
    jne .detectar_prefijo
    inc rdi
    mov cl, byte [rdi]
    test cl, cl
    jz .error               ; Cadena solo "-" es inválida

.detectar_prefijo:
    cmp cl, '0'
    jne .val_dec

    ; --- DETECCIÓN DE PREFIJO ---
    mov ch, byte [rdi+1]
    cmp ch, 'x'
    je .prep_hex
    cmp ch, 'X'
    je .prep_hex
    cmp ch, 'b'
    je .prep_bin
    cmp ch, 'B'
    je .prep_bin
    cmp ch, 'o'
    je .prep_oct
    cmp ch, 'O'
    je .prep_oct
    cmp ch, 'd'
    je .prep_dec
    cmp ch, 'D'
    je .prep_dec
    jmp .val_dec

.prep_hex:
    add rdi, 2
    jmp .val_hex
.prep_bin:
    add rdi, 2
    jmp .val_bin
.prep_oct:
    add rdi, 2
    jmp .val_oct
.prep_dec:
    add rdi, 2
    jmp .val_dec

    ; --- VALIDACIÓN HEXADECIMAL ---
.val_hex:
    mov r12, rdi            ; Guardar inicio de dígitos
    mov r13d, 0xFFFFFFFF    ; Tope: patrón de bits de 32 bits
    call .ajustar_tope_signo
    xor eax, eax            ; RAX = valor acumulado (64 bits)
.val_hex_bucle:
    movzx ecx, byte [rdi]
    test cl, cl
    jz .fin_digitos
    cmp cl, '0'
    jl .error
    cmp cl, '9'
    jle .hex_digito
    cmp cl, 'A'
    jl .error
    cmp cl, 'F'
    jle .hex_letra
    cmp cl, 'a'
    jl .error
    cmp cl, 'f'
    jg .error
.hex_letra:
    and cl, 0xDF            ; Forzar mayúscula ('a'..'f' → 'A'..'F')
    sub cl, 'A' - 10        ; ECX = 10..15
    jmp .hex_acum
.hex_digito:
    sub cl, '0'             ; ECX = 0..9
.hex_acum:
    shl rax, 4              ; valor = valor*16 + dígito (en 64 bits)
    add rax, rcx
    cmp rax, r13
    ja .error               ; Supera el tope → overflow
    inc rdi
    jmp .val_hex_bucle

    ; --- VALIDACIÓN BINARIA ---
.val_bin:
    mov r12, rdi
    mov r13d, 0xFFFFFFFF    ; Tope: patrón de bits de 32 bits
    call .ajustar_tope_signo
    xor eax, eax
.val_bin_bucle:
    movzx ecx, byte [rdi]
    test cl, cl
    jz .fin_digitos
    cmp cl, '0'
    jl .error
    cmp cl, '1'
    jg .error
    sub cl, '0'
    shl rax, 1              ; valor = valor*2 + dígito
    add rax, rcx
    cmp rax, r13
    ja .error
    inc rdi
    jmp .val_bin_bucle

    ; --- VALIDACIÓN OCTAL ---
.val_oct:
    mov r12, rdi
    mov r13d, 0xFFFFFFFF    ; Tope: patrón de bits de 32 bits
    call .ajustar_tope_signo
    xor eax, eax
.val_oct_bucle:
    movzx ecx, byte [rdi]
    test cl, cl
    jz .fin_digitos
    cmp cl, '0'
    jl .error
    cmp cl, '7'
    jg .error
    sub cl, '0'
    shl rax, 3              ; valor = valor*8 + dígito
    add rax, rcx
    cmp rax, r13
    ja .error
    inc rdi
    jmp .val_oct_bucle

    ; --- VALIDACIÓN DECIMAL ---
    ; Para decimal no hay prefijo obligatorio, así que r12/tope se fijan aquí.
.val_dec:
    mov r12, rdi            ; Inicio de dígitos decimales
    mov r13d, 0x7FFFFFFF    ; Tope: INT32_MAX (un decimal es cantidad con signo)
    call .ajustar_tope_signo
    xor eax, eax
.val_dec_bucle:
    movzx ecx, byte [rdi]
    test cl, cl
    jz .fin_digitos
    cmp cl, '0'
    jl .error
    cmp cl, '9'
    jg .error
    sub cl, '0'
    lea rax, [rax + rax*4]  ; valor *= 5
    add rax, rax            ; valor *= 2 (total ×10)
    add rax, rcx
    cmp rax, r13
    ja .error
    inc rdi
    jmp .val_dec_bucle

    ; --- Subrutina interna: si la cadena empieza por '-', el tope pasa a
    ;     |INT32_MIN| = 2147483648, sea cual sea la base. No altera RDI/RCX. ---
.ajustar_tope_signo:
    cmp byte [rbx], '-'
    jne .ats_ret
    mov r13d, 0x80000000    ; Magnitud máxima de un negativo: |INT32_MIN|
.ats_ret:
    ret

    ; --- FIN DE DÍGITOS ---
    ; RDI apunta al NUL, R12 al primer carácter tras prefijo/signo.
    ; Cubre "0x", "0d", "-0b"...: prefijo sin ningún dígito es error.
.fin_digitos:
    cmp rdi, r12
    je .error               ; RDI == R12: no hubo ningún dígito

    ; --- DELEGACIÓN ---
.exito:
    mov rdi, rbx
    pop r13
    pop r12
    pop rbx
    leave
    ; Tail-call a fast: CF=0 garantizado por clc en lib_string_int32fast.
    jmp lib_string_int32fast

.error:
    xor eax, eax
    pop r13
    pop r12
    pop rbx
    leave
    stc                     ; CF=1: error al llamante
    ret
