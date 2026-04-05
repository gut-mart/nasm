; ==============================================================================
; LIBRERÍA: lib_print.asm
; DESCRIPCIÓN: Funciones básicas para imprimir texto en la terminal.
; ==============================================================================

default rel

section .data
    hex_prefix db "0x", 0
    hex_chars  db "0123456789ABCDEF"

section .bss
    hex_buffer resb 17  ; 16 caracteres + null terminator para hexadecimal

section .text
    global print_string
    global print_error
    global string_length
    global print_int          ; Imprimir enteros con signo
    global print_nl           ; Imprimir salto de línea
    global print_hex          ; Imprimir hexadecimal

; ------------------------------------------------------------------------------
; FUNCIÓN: string_length
; Calcula la longitud de una cadena terminada en nulo (0).
; ENTRADA: RDI = Puntero a la cadena
; SALIDA:  RAX = Longitud de la cadena
; ------------------------------------------------------------------------------
string_length:
    xor rax, rax
.bucle:
    cmp byte [rdi + rax], 0
    je .fin
    inc rax
    jmp .bucle
.fin:
    ret

; ------------------------------------------------------------------------------
; FUNCIÓN: print_string
; Imprime una cadena terminada en nulo en STDOUT (Consola normal).
; ENTRADA: RDI = Puntero a la cadena
; ------------------------------------------------------------------------------
print_string:
    push rbp
    mov rbp, rsp
    push rbx
    sub rsp, 8              
    mov rbx, rdi
    call string_length
    add rsp, 8              
    mov rdx, rax            ; Longitud
    mov rsi, rbx            ; Puntero a la cadena
    mov rdi, 1              ; STDOUT
    mov rax, 1              ; sys_write
    syscall
    cmp rax, 0
    jl .error_print_string
    jmp .fin_print_string
.error_print_string:
    mov rax, -1
.fin_print_string:
    pop rbx
    leave
    ret

; ------------------------------------------------------------------------------
; FUNCIÓN: print_error
; Imprime una cadena terminada en nulo en STDERR (Consola de errores).
; ENTRADA: RDI = Puntero a la cadena
; ------------------------------------------------------------------------------
print_error:
    push rbp
    mov rbp, rsp
    push rbx
    
    sub rsp, 8              ; Alineación a 16 bytes (ABI)
    
    mov rbx, rdi
    call string_length
    
    add rsp, 8              ; Restaurar estado de la pila

    mov rdx, rax            ; Longitud
    mov rsi, rbx            ; Puntero a la cadena
    mov rdi, 2              ; STDERR
    mov rax, 1              ; sys_write
    syscall
    cmp rax, 0
    jl .error_print_error
    jmp .fin_print_error
.error_print_error:
    mov rax, -1
.fin_print_error:
    pop rbx
    leave
    ret

; ------------------------------------------------------------------------------
; FUNCIÓN: print_int
; Imprime un número entero con signo en STDOUT.
; ENTRADA: RDI = Número entero (64 bits)
; ------------------------------------------------------------------------------
print_int:
    push rbp
    mov rbp, rsp
    sub rsp, 32             ; Reservar 32 bytes en la pila para el buffer numérico
    push rbx
    push r12

    mov rax, rdi            ; RAX = Número a dividir
    mov r12, 0              ; Flag de signo (0 = positivo, 1 = negativo)

    cmp rax, 0
    jge .preparar
   
    mov r12, 1              ; Marcar como negativo (Duplicado eliminado aquí)
    neg rax                 ; Convertir a positivo (INT64_MIN se niega a sí mismo)

.preparar:
    lea rbx, [rbp - 1]      ; RBX = Puntero al final de nuestro buffer temporal
    mov byte [rbx], 0       ; Colocar terminador nulo al final
    mov rcx, 10             ; Divisor base 10

.bucle_div:
    xor rdx, rdx            ; Limpiar RDX antes de dividir
    div rcx                 ; RAX / 10 -> Cociente en RAX, Resto en RDX
    add dl, '0'             ; Convertir el resto (0-9) a carácter ASCII ('0'-'9')
    dec rbx                 ; Retroceder el puntero en el buffer
    mov [rbx], dl           ; Guardar el carácter
    test rax, rax           ; ¿Queda algo en el cociente?
    jnz .bucle_div          ; Si no es 0, seguir dividiendo

    cmp r12, 1              ; ¿El número original era negativo?
    jne .imprimir
    dec rbx
    mov byte [rbx], '-'     ; Añadir el signo menos al principio

.imprimir:
    mov rdi, rbx            ; Pasar el inicio de la cadena generada a print_string
    call print_string       ; Imprimir el número en pantalla

    pop r12
    pop rbx
    leave
    ret

; ------------------------------------------------------------------------------
; FUNCIÓN: print_nl
; Imprime un salto de línea en STDOUT.
; ------------------------------------------------------------------------------
print_nl:
    push rbp
    mov rbp, rsp
    sub rsp, 16             ; Reservar 16 bytes para alineación x86-64
    mov byte [rsp], 10      ; Código ASCII del salto de línea (\n)
    
    mov rax, 1              ; sys_write
    mov rdi, 1              ; STDOUT
    mov rsi, rsp            ; Puntero al carácter '\n'
    mov rdx, 1              ; Longitud 1
    syscall
    cmp rax, 0
    jl .error_print_nl
    jmp .fin_print_nl
.error_print_nl:
    mov rax, -1
.fin_print_nl:
    leave
    ret

; ------------------------------------------------------------------------------
; FUNCIÓN: print_hex
; Imprime un valor de 64 bits (en RDI) en formato hexadecimal
; ------------------------------------------------------------------------------
print_hex:
    push rbx
    push rcx
    push rdx
    push rdi
    
    mov rcx, 16                 ; Vamos a procesar 16 nibbles (64 bits)
    mov rbx, hex_buffer + 15    ; Apuntamos al final del buffer
    mov byte [hex_buffer + 16], 0 ; Añadimos el terminador nulo al final

.bucle_hex:
    mov rdx, rdi
    and rdx, 0xF                ; Extraemos los 4 bits mas bajos (un nibble)
    mov dl, byte [hex_chars + rdx] ; Buscamos su caracter ASCII correspondiente
    mov byte [rbx], dl          ; Lo guardamos en el buffer
    dec rbx                     ; Movemos el puntero del buffer hacia la izquierda
    shr rdi, 4                  ; Desplazamos los bits originales para leer los siguientes 4
    dec rcx
    jnz .bucle_hex

    sub rsp, 8                  ; <--- CORRECCIÓN: Alineación ABI a 16 bytes

    ; Imprimir el prefijo y el numero
    mov rdi, hex_prefix
    call print_string
    mov rdi, hex_buffer
    call print_string

    add rsp, 8                  ; <--- CORRECCIÓN: Restauración de pila

    pop rdi
    pop rdx
    pop rcx
    pop rbx
    ret