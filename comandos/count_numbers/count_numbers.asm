; ==============================================================================
; RUTA: ./comandos/count_numbers/count_numbers.asm
; DESCRIPCIÓN: Ejemplo que cuenta del 1 al 10 imprimiendo números,
;              demostrando el uso de print_int y print_nl.
; ==============================================================================

%include "lib/constants.inc"
%include "lib/sys_macros.inc"

default rel

extern print_string, print_int, print_nl

section .data
    msg_inicio db "Números del 1 al 10:", 0
    msg_fin db "Listo.", 0

section .text
    global _start

_start:
    ; Imprimir mensaje inicio
    mov rdi, msg_inicio
    call print_string
    call print_nl
    
    ; Inicializar contador en 1
    mov r8, 1
    
.loop:
    ; Si llegamos a 11, salir del bucle
    cmp r8, 11
    je .loop_end
    
    ; Imprimir el número actual
    mov rdi, r8
    call print_int
    call print_nl
    
    ; Incrementar contador
    inc r8
    jmp .loop
    
.loop_end:
    ; Imprimir mensaje fin
    mov rdi, msg_fin
    call print_string
    call print_nl
    
    ; Salir del programa
    sys_exit 0
