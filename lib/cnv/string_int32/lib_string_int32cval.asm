; ==============================================================================
; LIBRERÍA: lib_string_int32cval.asm
; DESCRIPCIÓN: Capa 1 (Escudo). Identifica prefijos y valida caracteres.
; CORRECCIÓN: Añadido soporte para números negativos (signo '-' inicial).
; ==============================================================================

default rel

extern lib_string_int32fast

section .text
    global lib_string_int32cval

lib_string_int32cval:
    push rbp
    mov rbp, rsp
    push rbx            
    
    mov rbx, rdi        ; Guardamos el inicio de la cadena

    mov cl, byte [rdi]
    test cl, cl
    jz .error           

    ; --- CORRECCIÓN: Manejar signo negativo ---
    ; Si el primer carácter es '-', lo saltamos para validar los dígitos,
    ; pero mantenemos RBX apuntando al '-' para pasar la cadena completa
    ; (con signo) a lib_string_int32fast al final.
    cmp cl, '-'
    jne .detectar_prefijo
    inc rdi             ; Saltamos el '-'
    mov cl, byte [rdi]  ; Leemos el siguiente carácter
    test cl, cl
    jz .error           ; Si la cadena es solo "-", es inválida

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

; --- FIX: Saltos en líneas separadas ---
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
    mov cl, byte [rdi]
    test cl, cl
    jz .exito
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
    jmp .val_hex

    ; --- VALIDACIÓN BINARIA ---
.val_bin:
    mov cl, byte [rdi]
    test cl, cl
    jz .exito
    cmp cl, '0'
    jl .error
    cmp cl, '1'
    jg .error
    inc rdi
    jmp .val_bin

    ; --- VALIDACIÓN OCTAL ---
.val_oct:
    mov cl, byte [rdi]
    test cl, cl
    jz .exito
    cmp cl, '0'
    jl .error
    cmp cl, '7'
    jg .error
    inc rdi
    jmp .val_oct

    ; --- VALIDACIÓN DECIMAL ---
.val_dec:
    mov cl, byte [rdi]
    test cl, cl
    jz .exito
    cmp cl, '0'
    jl .error
    cmp cl, '9'
    jg .error
    inc rdi
    jmp .val_dec

    ; --- DELEGACIÓN ---
.exito:
    ; Pasamos RBX (el puntero ORIGINAL, incluyendo el '-' si lo había)
    ; a lib_string_int32fast para que gestione la conversión completa.
    mov rdi, rbx        
    pop rbx             
    leave               
    jmp lib_string_int32fast 

.error:
    xor eax, eax        
    pop rbx
    leave
    ret
