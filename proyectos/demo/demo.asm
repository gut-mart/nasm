; ==============================================================================
; ARCHIVO: demo.asm
; DESCRIPCIÓN: Ejemplo básico de uso del framework.
;              Muestra cómo imprimir texto y usar la librería de números.
; ==============================================================================

; 1. Inclusión de constantes y librerías
;    (Las rutas siempre son relativas a la raíz del proyecto)
%include "lib/constants.inc"
%include "lib/text/print_dec32/lib_text_print_dec32.inc"

; 2. Configuración obligatoria para 64-bits
default rel

section .data
    ; Definimos un mensaje con salto de línea (10) y terminador nulo (0)
    msg_hola    db "Hola, mundo desde Assembly x64!", 10, 0
    
    ; Calculamos la longitud automáticamente
    len_hola    equ $ - msg_hola

section .text
    global _start

_start:
    ; --------------------------------------------------------------------------
    ; 1. Imprimir un mensaje de texto simple (Syscall directa)
    ; --------------------------------------------------------------------------
    mov rax, SYS_WRITE      ; Syscall ID: 1 (Write)
    mov rdi, STDOUT         ; Descriptor: 1 (Salida estándar)
    lea rsi, [msg_hola]     ; Dirección del mensaje
    mov rdx, len_hola       ; Longitud del mensaje
    syscall

    ; --------------------------------------------------------------------------
    ; 2. Usar la librería propia para imprimir un número
    ; --------------------------------------------------------------------------
    ; La función espera el número en el registro EDI (32 bits)
    mov edi, -12345         
    call lib_text_print_dec32 

    ; --------------------------------------------------------------------------
    ; 3. Salida limpia del programa
    ; --------------------------------------------------------------------------
    mov rax, SYS_EXIT       ; Syscall ID: 60 (Exit)
    mov rdi, EXIT_SUCCESS   ; Código de retorno: 0 (Todo bien)
    syscall