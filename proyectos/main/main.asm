; ==============================================================================
; RUTA: ./proyectos/main/main.asm
; DESCRIPCIÓN: Prueba de conversión multibase (Base 10, Base 2, Base 16).
; ==============================================================================

%include "lib/constants.inc"
%include "lib/cnv/lib_cnv_uint32_to_str.inc"

default rel

section .data
    ; Mensajes para identificar cada prueba
    msg_titulo  db "--- Prueba Multi-Base (Numero: 305419896) ---", 10, 0
    
    lbl_dec     db "Base 10 (Decimal): ", 0
    lbl_bin     db "Base  2 (Binario): ", 0
    lbl_hex     db "Base 16 (Hex):     ", 0
    
    newline     db 10

section .bss
    ; IMPORTANTE: Para binario necesitamos hasta 32 caracteres + 1 nulo.
    ; Reservamos 64 bytes para estar sobrados y alineados.
    buffer_num  resb 64

section .text
    global _start

_start:
    ; 1. Imprimir Título
    lea rsi, [msg_titulo]
    call _print_fixed_str

    ; Número de prueba: 305419896 (Equivale a 0x12345678)
    ; Usaremos R12 para guardar el número y no perderlo entre llamadas
    mov r12d, 305419896

    ; --------------------------------------------------------------------------
    ; PRUEBA 1: DECIMAL (Base 10)
    ; --------------------------------------------------------------------------
    lea rsi, [lbl_dec]      ; Imprimir etiqueta "Decimal: "
    call _print_fixed_str
    
    lea rdi, [buffer_num]   ; Buffer
    mov esi, r12d           ; Número
    mov edx, 10             ; BASE 10 <---
    call lib_cnv_uint32_to_str
    
    call _print_buffer_result ; Imprimir resultado

    ; --------------------------------------------------------------------------
    ; PRUEBA 2: BINARIO (Base 2)
    ; --------------------------------------------------------------------------
    lea rsi, [lbl_bin]      ; Imprimir etiqueta "Binario: "
    call _print_fixed_str

    lea rdi, [buffer_num]   ; Buffer (reutilizamos)
    mov esi, r12d           ; Número
    mov edx, 2              ; BASE 2 <---
    call lib_cnv_uint32_to_str

    call _print_buffer_result

    ; --------------------------------------------------------------------------
    ; PRUEBA 3: HEXADECIMAL (Base 16)
    ; --------------------------------------------------------------------------
    lea rsi, [lbl_hex]      ; Imprimir etiqueta "Hex: "
    call _print_fixed_str

    lea rdi, [buffer_num]
    mov esi, r12d
    mov edx, 16             ; BASE 16 <---
    call lib_cnv_uint32_to_str

    call _print_buffer_result

    ; Salir
    mov rax, SYS_EXIT
    xor rdi, rdi
    syscall

; ==============================================================================
; SUBRUTINAS AUXILIARES (Para no repetir código en el main)
; ==============================================================================

; --------------------------------------------------------------------------
; _print_buffer_result:
; Calcula la longitud de la cadena en 'buffer_num', la imprime y añade un \n
; --------------------------------------------------------------------------
_print_buffer_result:
    lea rsi, [buffer_num]   ; Apuntamos al buffer
    call _strlen            ; Calculamos longitud en RDX
    
    mov rax, SYS_WRITE
    mov rdi, STDOUT
    syscall                 ; RSI ya tiene el buffer, RDX la longitud

    ; Imprimir nueva línea
    mov rax, SYS_WRITE
    mov rdi, STDOUT
    lea rsi, [newline]
    mov rdx, 1
    syscall
    ret

; --------------------------------------------------------------------------
; _print_fixed_str:
; Imprime una cadena fija terminada en 0 apuntada por RSI
; --------------------------------------------------------------------------
_print_fixed_str:
    push rsi                ; Guardamos RSI original
    call _strlen            ; RDX = Longitud
    pop rsi                 ; Recuperamos inicio de cadena
    mov rax, SYS_WRITE
    mov rdi, STDOUT
    syscall
    ret

; --------------------------------------------------------------------------
; _strlen:
; Entrada: RSI apunta a cadena terminada en 0
; Salida:  RDX contiene la longitud
; --------------------------------------------------------------------------
_strlen:
    xor rdx, rdx            ; Contador a 0
.loop:
    cmp byte [rsi + rdx], 0 ; ¿Es fin de cadena?
    je .done
    inc rdx
    jmp .loop
.done:
    ret