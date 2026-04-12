; ==============================================================================
; LIBRERÍA: lib_string_int32fast.asm
; DESCRIPCIÓN: Capa 2 (Motor Rápido). Convierte String a Int32 según su prefijo.
; CORRECCIÓN: Añadido soporte para números negativos (signo '-' inicial).
; ==============================================================================

default rel

section .text
    global lib_string_int32fast

lib_string_int32fast:
    xor eax, eax        
    xor rcx, rcx        

    ; --- CORRECCIÓN: Manejar signo negativo ---
    ; Comprobamos si hay un '-' al inicio. Si lo hay, lo anotamos en R11
    ; y avanzamos el puntero para procesar los dígitos normalmente.
    xor r11d, r11d      ; R11D = 0 (bandera: sin signo negativo)
    mov cl, byte [rdi]
    cmp cl, '-'
    jne .detectar_prefijo
    mov r11d, 1         ; R11D = 1 (bandera: número negativo)
    inc rdi             ; Saltamos el '-'
    mov cl, byte [rdi]  ; Leemos el primer dígito real

.detectar_prefijo:
    cmp cl, '0'
    jne .bucle_dec      

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
    
    jmp .bucle_dec

; --- FIX: Saltos en líneas separadas ---
.prep_hex: 
    add rdi, 2
    jmp .bucle_hex
.prep_bin: 
    add rdi, 2
    jmp .bucle_bin
.prep_oct: 
    add rdi, 2
    jmp .bucle_oct
.prep_dec: 
    add rdi, 2
    jmp .bucle_dec

    ; --- BUCLE HEXADECIMAL ---
.bucle_hex:
    movzx ecx, byte [rdi]
    test cl, cl
    jz .fin
    shl eax, 4          
    cmp cl, '9'
    jle .hex_num
    and cl, 0xDF        
    sub cl, 'A' - 10    
    jmp .hex_add
.hex_num:
    sub cl, '0'
.hex_add:
    add eax, ecx
    inc rdi
    jmp .bucle_hex

    ; --- BUCLE BINARIO ---
.bucle_bin:
    movzx ecx, byte [rdi]
    test cl, cl
    jz .fin
    shl eax, 1          
    sub cl, '0'
    add eax, ecx
    inc rdi
    jmp .bucle_bin

    ; --- BUCLE OCTAL ---
.bucle_oct:
    movzx ecx, byte [rdi]
    test cl, cl
    jz .fin
    shl eax, 3          
    sub cl, '0'
    add eax, ecx
    inc rdi
    jmp .bucle_oct

    ; --- BUCLE DECIMAL ---
.bucle_dec:
    movzx ecx, byte [rdi]
    test cl, cl
    jz .fin
    lea eax, [eax + eax*4] 
    add eax, eax           
    sub cl, '0'
    add eax, ecx
    inc rdi
    jmp .bucle_dec

.fin:
    ; --- CORRECCIÓN: Aplicar negación si se detectó el signo '-' ---
    test r11d, r11d
    jz .retornar
    neg eax             ; Negamos el resultado para obtener el valor negativo

.retornar:
    ret
