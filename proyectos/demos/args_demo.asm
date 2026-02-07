; ==============================================================================
; PROGRAMA: args_demo.asm
; DESCRIPCIÓN: Lee un texto desde la terminal y calcula su longitud.
; USO: ./build/args_demo "Texto a medir"
; ==============================================================================

%include "lib/constants.inc"
%include "lib/string/string_len.inc"
%include "lib/text/print_dec32/lib_text_print_dec32.inc"

default rel

section .data
    msg_error db "Error: Debes escribir un texto. Ejemplo: ./args_demo 'Hola'", 10, 0
    
section .text
    global _start

_start:
    ; --------------------------------------------------------------------------
    ; PASO 1: Leer cuántos argumentos hay (ARGC)
    ; --------------------------------------------------------------------------
    pop rcx             ; Sacamos el primer valor de la pila (ARGC) a RCX
    
    cmp rcx, 2          ; ¿Hay al menos 2 argumentos? (NombreProg + Texto)
    jl .sin_argumentos  ; Si hay menos de 2, saltamos al error

    ; --------------------------------------------------------------------------
    ; PASO 2: Obtener el texto (ARGV)
    ; --------------------------------------------------------------------------
    pop rsi             ; Sacamos argv[0] (Nombre del programa) -> Lo ignoramos
    pop rdi             ; Sacamos argv[1] (TU TEXTO) -> Lo guardamos en RDI

    ; ¡IMPORTANTE! 
    ; Al hacer 'pop rdi', RDI ya contiene la DIRECCIÓN de memoria de tu texto.
    ; Ya no hace falta usar 'lea', porque el sistema ya nos dio el puntero.

    ; --------------------------------------------------------------------------
    ; PASO 3: Calcular Longitud
    ; --------------------------------------------------------------------------
    call string_len     ; Llama a tu librería (RDI ya tiene el texto)
    
    ; --------------------------------------------------------------------------
    ; PASO 4: Imprimir Resultado
    ; --------------------------------------------------------------------------
    mov rdi, rax        ; Movemos el resultado (RAX) a RDI para imprimir
    call lib_text_print_dec32

    jmp .salir

.sin_argumentos:
    ; Si el usuario no puso texto, le enseñamos cómo usarlo
    mov rax, SYS_WRITE
    mov rdi, STDOUT
    lea rsi, [msg_error]
    mov rdx, 60         ; Longitud aproximada del mensaje
    syscall

.salir:
    mov rax, SYS_EXIT
    xor rdi, rdi
    syscall