; ==============================================================================
; LIBRERÍA: lib_string_int32cval.asm
; DESCRIPCIÓN: Capa 1 (Escudo). Identifica prefijos y valida caracteres.
; CONTRATO:
;   Entrada: RDI = puntero a cadena terminada en NUL.
;   Salida:  EAX = valor convertido (válido solo si CF=0).
;            CF = 0 si la conversión es válida.
;            CF = 1 si la cadena no representa un número válido.
; CORRECCIÓN: Antes devolvía EAX=0 silenciosamente al detectar error, lo que
;             era ambiguo con el valor "0" legítimo. Ahora se usa Carry Flag
;             como bandera de error fuera de banda. Esto permite al llamante
;             distinguir "0 válido" de "error → 0".
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

    ; --- Manejar signo negativo ---
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
    jmp .val_hex

    ; --- VALIDACIÓN BINARIA ---
.val_bin:
    mov cl, byte [rdi]
    test cl, cl
    jz .verificar_no_vacio_tras_prefijo
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
    jz .verificar_no_vacio_tras_prefijo
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

    ; Verifica que tras el prefijo (0x, 0b, 0o, 0d) hubo al menos un dígito.
    ; Si la cadena era solo "0x", "0b", etc., la consideramos inválida.
.verificar_no_vacio_tras_prefijo:
    ; RBX apunta al inicio de la cadena, RDI al carácter tras el último dígito.
    ; Mínimo válido: 3 sin '-' (ej: "0xF"), 4 con '-' (ej: "-0xF").
    mov rax, rdi
    sub rax, rbx
    cmp byte [rbx], '-'
    jne .comprobar_sin_signo
    cmp rax, 4
    jl .error
    jmp .exito
.comprobar_sin_signo:
    cmp rax, 3
    jl .error
    jmp .exito

    ; --- DELEGACIÓN ---
.exito:
    mov rdi, rbx        
    pop rbx             
    leave               
    ; Tail-call a fast: fast siempre tiene éxito (no valida) y dejará
    ; CF=0 al retornar (clc se hace allí).
    jmp lib_string_int32fast 

.error:
    xor eax, eax        
    pop rbx
    leave
    stc                 ; CF=1: indicar error al llamante
    ret
