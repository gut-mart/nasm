; ==============================================================================
; RUTA: ./comandos/hello_world/hello_world.asm
; DESCRIPCIÓN: Ejemplo básico de "Hola Mundo" usando la librería de impresión.
;               Demuestra el uso de funciones externas y syscalls.
; ==============================================================================

%include "lib/constants.inc"
%include "lib/sys_macros.inc"

default rel

extern print_string, print_nl

section .data
    msg_hello db "Hola, Mundo desde NASM!", 0

section .text
    global _start

_start:
    ; Imprimir el mensaje
    mov rdi, msg_hello
    call print_string

    ; Imprimir nueva línea
    call print_nl

    ; Salir del programa
    sys_exit 0
