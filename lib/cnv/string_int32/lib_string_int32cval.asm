; ==============================================================================
; LIBRERÍA: lib_string_int32cval.asm
; DESCRIPCIÓN: Capa 1 (Escudo). Identifica prefijos, valida caracteres
;              y detecta overflow antes de delegar en la capa rápida.
; CONTRATO:
;   Entrada: RDI = puntero a cadena terminada en NUL.
;   Salida:  EAX = valor convertido (válido solo si CF=0).
;            CF = 0 si la conversión es válida.
;            CF = 1 si la cadena no representa un número válido,
;                   o si el valor no cabe en un int32 (overflow).
; CORRECCIONES:
;   - Antes devolvía EAX=0 silenciosamente al detectar error, lo que
;     era ambiguo con el valor "0" legítimo. Ahora se usa Carry Flag
;     como bandera de error fuera de banda.
;   - Añadida detección de overflow por conteo de dígitos antes de
;     delegar en lib_string_int32fast. Límites por base:
;       Decimal     : máx 10 dígitos (4294967295)
;       Hexadecimal : máx  8 dígitos (FFFFFFFF)
;       Octal       : máx 11 dígitos (37777777777)
;       Binario     : máx 32 dígitos (32 unos)
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
    push r13                ; R13 = límite de dígitos según base

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
    mov r13, 8              ; Hex: máximo 8 dígitos
    jmp .val_hex
.prep_bin:
    add rdi, 2
    mov r13, 32             ; Bin: máximo 32 dígitos
    jmp .val_bin
.prep_oct:
    add rdi, 2
    mov r13, 11             ; Oct: máximo 11 dígitos
    jmp .val_oct
.prep_dec:
    add rdi, 2
    mov r13, 10             ; Dec: máximo 10 dígitos
    jmp .val_dec

    ; --- VALIDACIÓN HEXADECIMAL ---
.val_hex:
    mov r12, rdi            ; Guardar inicio de dígitos
.val_hex_bucle:
    mov cl, byte [rdi]
    test cl, cl
    jz .verificar_no_vacio_tras_prefijo
    cmp cl, '0'
    jl .error
    cmp cl, '9'
    jle .next_hex
    cmp cl, 'A'
    jl .error
    cmp cl, 'F'
    jle .next_hex
    cmp cl, 'a'
    jl .error
    cmp cl, 'f'
    jg .error
.next_hex:
    inc rdi
    jmp .val_hex_bucle

    ; --- VALIDACIÓN BINARIA ---
.val_bin:
    mov r12, rdi
.val_bin_bucle:
    mov cl, byte [rdi]
    test cl, cl
    jz .verificar_no_vacio_tras_prefijo
    cmp cl, '0'
    jl .error
    cmp cl, '1'
    jg .error
    inc rdi
    jmp .val_bin_bucle

    ; --- VALIDACIÓN OCTAL ---
.val_oct:
    mov r12, rdi
.val_oct_bucle:
    mov cl, byte [rdi]
    test cl, cl
    jz .verificar_no_vacio_tras_prefijo
    cmp cl, '0'
    jl .error
    cmp cl, '7'
    jg .error
    inc rdi
    jmp .val_oct_bucle

    ; --- VALIDACIÓN DECIMAL ---
    ; Para decimal no hay prefijo explícito, así que guardamos r12 aquí.
    ; También asignamos el límite si no viene de .prep_dec.
.val_dec:
    mov r12, rdi            ; Inicio de dígitos decimales
    mov r13, 10             ; Dec: máximo 10 dígitos
.val_dec_bucle:
    mov cl, byte [rdi]
    test cl, cl
    jz .comprobar_overflow
    cmp cl, '0'
    jl .error
    cmp cl, '9'
    jg .error
    inc rdi
    jmp .val_dec_bucle

    ; --- VERIFICAR QUE TRAS PREFIJO HAY AL MENOS UN DÍGITO ---
    ; Llegamos aquí desde hex/bin/oct cuando encontramos el NUL.
    ; RDI apunta al NUL, R12 al primer carácter tras el prefijo.
.verificar_no_vacio_tras_prefijo:
    cmp rdi, r12
    je .error               ; RDI == R12: no hubo ningún dígito tras el prefijo
    ; Caemos en comprobar_overflow

    ; --- DETECCIÓN DE OVERFLOW POR CONTEO DE DÍGITOS ---
    ; RDI apunta al NUL final, R12 al primer dígito (tras prefijo).
    ; R13 = límite máximo de dígitos para esta base.
    ; Cuenta = RDI - R12. Si cuenta > R13, overflow.
.comprobar_overflow:
    mov rax, rdi
    sub rax, r12            ; RAX = número de dígitos
    cmp rax, r13
    ja .error               ; Si dígitos > límite, overflow → error

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