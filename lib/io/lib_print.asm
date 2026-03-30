; ==============================================================================
; LIBRERÍA: lib_print.asm
; DESCRIPCIÓN: Funciones básicas para imprimir texto en la terminal.
; ==============================================================================

default rel

section .text
    global print_string
    global print_error
    global string_length
    global print_int          ; NUEVO: Imprimir enteros con signo
    global print_nl           ; NUEVO: Imprimir salto de línea

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
    
    mov rbx, rdi
    call string_length

    mov rdx, rax            ; Longitud
    mov rsi, rbx            ; Puntero a la cadena
    mov rdi, 1              ; STDOUT
    mov rax, 1              ; sys_write
    syscall

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
    
    mov rbx, rdi
    call string_length

    mov rdx, rax            ; Longitud
    mov rsi, rbx            ; Puntero a la cadena
    mov rdi, 2              ; STDERR
    mov rax, 1              ; sys_write
    syscall

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
    mov r12, 1              ; Marcar como negativo
    neg rax                 ; Convertir a positivo (valor absoluto)

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
    sub rsp, 8              ; Reservar espacio en la pila para mantener alineación
    mov byte [rsp], 10      ; Código ASCII del salto de línea (\n)
    
    mov rax, 1              ; sys_write
    mov rdi, 1              ; STDOUT
    mov rsi, rsp            ; Puntero al carácter '\n'
    mov rdx, 1              ; Longitud 1
    syscall
    
    leave
    ret