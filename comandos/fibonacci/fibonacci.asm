; ==============================================================================
; RUTA: ./comandos/fibonacci/fibonacci.asm
; DESCRIPCIÓN: Calcula números de Fibonacci del 1 al 15 usando recursión.
;              Demuestra el uso de funciones, pila, y salida formateada.
; ==============================================================================

%include "lib/constants.inc"
%include "lib/sys_macros.inc"

default rel

extern print_string, print_int, print_nl

section .data
    msg_titulo db "Serie Fibonacci (números 1-15):", 0
    msg_num    db "Número ", 0
    msg_colon  db ": ", 0

section .text
    global _start
    extern fibonacci

; Función Fibonacci recursiva
; Entrada: RDI = n
; Salida: RAX = fib(n)
fibonacci:
    ; Base cases
    cmp rdi, 1
    je .fib_base_1
    cmp rdi, 2
    je .fib_base_1
    
    ; Caso recursivo: fib(n-1) + fib(n-2)
    ; Guardar n en pila para usarlo después
    push rdi
    
    ; Calcular fib(n-1)
    mov rdi, [rsp]
    dec rdi
    call fibonacci
    push rax        ; Guardar resultado fib(n-1)
    
    ; Calcular fib(n-2)
    mov rdi, [rsp + 8]  ; Recuperar n original
    sub rdi, 2
    call fibonacci
    
    ; Sumar fib(n-1) + fib(n-2)
    mov rbx, rax        ; rbx = fib(n-2)
    pop rax             ; rax = fib(n-1)
    add rax, rbx        ; rax = fib(n-1) + fib(n-2)
    
    pop rdi             ; Limpiar pila
    ret
    
.fib_base_1:
    mov rax, 1
    ret

_start:
    ; Imprimir título
    mov rdi, msg_titulo
    call print_string
    call print_nl
    
    ; Contador
    mov rcx, 1
    
.loop:
    cmp rcx, 16
    je .fin
    
    ; Imprimir "Número N: "
    mov rdi, msg_num
    call print_string
    mov rdi, rcx
    call print_int
    mov rdi, msg_colon
    call print_string
    
    ; Calcular fibonacci(n)
    mov rdi, rcx
    call fibonacci
    
    ; Imprimir resultado
    call print_int
    call print_nl
    
    ; Siguiente valor
    inc rcx
    jmp .loop
    
.fin:
    sys_exit 0
