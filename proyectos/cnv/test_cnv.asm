; ==============================================================================
; RUTA: ./proyectos/cnv/test_cnv.asm
; DESCRIPCIÓN: Programa para probar la librería lib_cnv_uint32_to_str
; ==============================================================================

default rel             ; IMPORTANTE: Direccionamiento relativo para 64 bits

section .data
    ; Mensajes para identificar cada prueba
    msg_titulo  db "--- TEST LIBRERIA CONVERSION ---", 10, 0
    msg_dec     db "1. Decimal (12345):      ", 0
    msg_hex     db "2. Hexadecimal (ADBEEF): ", 0
    msg_bin     db "3. Binario (255):        ", 0
    newline     db 10, 0

section .bss
    ; Buffer grande para el resultado (Binario necesita hasta 33 bytes)
    buffer_out  resb 64 

section .text
    global _start
    extern lib_cnv_uint32_to_str ; Importamos tu librería

_start:
    ; --- Imprimir Título ---
    lea rsi, [msg_titulo]
    call _print_str

    ; ==========================================================================
    ; PRUEBA 1: DECIMAL (Base 10)
    ; Convertiremos el número 12345
    ; ==========================================================================
    
    ; 1. Imprimir etiqueta
    lea rsi, [msg_dec]
    call _print_str

    ; 2. Preparar llamada a librería
    lea rdi, [buffer_out]   ; RDI = Dónde guardar el texto
    mov esi, 12345          ; ESI = Número a convertir
    mov edx, 255             ; EDX = Base (10 para Decimal)
    call lib_cnv_uint32_to_str

    ; 3. Imprimir resultado
    lea rsi, [buffer_out]
    call _print_str
    
    ; 4. Salto de línea
    lea rsi, [newline]
    call _print_str

    ; ==========================================================================
    ; PRUEBA 2: HEXADECIMAL (Base 16)
    ; Convertiremos el número 0xADBEEF (11386607)
    ; ==========================================================================
    
    lea rsi, [msg_hex]
    call _print_str

    lea rdi, [buffer_out]
    mov esi, 0xADBEEF       ; Número en formato Hex
    mov edx, 16             ; Base (16 para Hexadecimal)
    call lib_cnv_uint32_to_str

    lea rsi, [buffer_out]
    call _print_str
    
    lea rsi, [newline]
    call _print_str

    ; ==========================================================================
    ; PRUEBA 3: BINARIO (Base 2)
    ; Convertiremos el número 255 (debería ser 11111111)
    ; ==========================================================================
    
    lea rsi, [msg_bin]
    call _print_str

    lea rdi, [buffer_out]
    mov esi, 255            ; Número
    mov edx, 2              ; Base (2 para Binario)
    call lib_cnv_uint32_to_str

    lea rsi, [buffer_out]
    call _print_str
    
    lea rsi, [newline]
    call _print_str

    ; ==========================================================================
    ; FINALIZAR
    ; ==========================================================================
    mov rax, 60             ; sys_exit
    xor rdi, rdi            ; código 0
    syscall

; ------------------------------------------------------------------------------
; RUTINA AUXILIAR: Imprimir String terminada en 0
; Entradas: RSI = Puntero a la cadena
; ------------------------------------------------------------------------------
_print_str:
    push rax
    push rdi
    push rdx
    push rcx
    
    ; Calcular longitud (strlen)
    xor rdx, rdx
.count:
    cmp byte [rsi+rdx], 0
    je .write
    inc rdx
    jmp .count
.write:
    mov rax, 1              ; sys_write
    mov rdi, 1              ; stdout
    syscall

    pop rcx
    pop rdx
    pop rdi
    pop rax
    ret