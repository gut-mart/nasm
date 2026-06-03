; ==============================================================================
; RUTA: ./comandos/tools/math/min/min.asm
; DESCRIPCIÓN: Devuelve el menor de dos enteros con signo de 32 bits.
; USO:
;   ./bin/min A B
;   ./bin/min -h
; EJEMPLOS:
;   ./bin/min 3 7        → 3
;   ./bin/min -5 2       → -5
;   ./bin/min 0xFF 0b10  → 2
; ==============================================================================

%include "lib/constants.inc"
%include "lib/sys_macros.inc"
%include "lib/math/int32/lib_math_int32.inc"

default rel

extern lib_math_min_int32cval
extern lib_string_int32cval
extern print_string, print_int, print_nl

section .data
    msg_ayuda_1 db "Uso: min A B", 10, 0
    msg_ayuda_2 db "Descripcion: Devuelve el menor de dos enteros con signo.", 10, 10, 0
    msg_ayuda_3 db "Argumentos:", 10, 0
    msg_ayuda_4 db "  A, B    Enteros con signo (32 bits). Soportan multiples bases.", 10, 0
    msg_ayuda_5 db "  -h      Muestra este panel de ayuda.", 10, 10, 0
    msg_ayuda_6 db "Formatos numericos soportados:", 10, 0
    msg_ayuda_7 db "  Decimal     : -42", 10, 0
    msg_ayuda_8 db "  Hexadecimal : 0xFF", 10, 0
    msg_ayuda_9 db "  Binario     : 0b101010", 10, 0
    msg_ayuda_A db "  Octal       : 0o52", 10, 10, 0
    msg_ayuda_B db "Ejemplos:", 10, 0
    msg_ayuda_C db "  ./bin/min 3 7        ; resultado: 3", 10, 0
    msg_ayuda_D db "  ./bin/min -5 2       ; resultado: -5", 10, 0
    msg_ayuda_E db "  ./bin/min 0xFF 0b10  ; resultado: 2", 10, 0

    msg_error_args   db "Error: se necesitan exactamente dos argumentos. Usa '-h'.", 10, 0
    msg_error_numero db "Error: argumento no es un numero valido.", 10, 0

section .bss
    val_a resd 1
    val_b resd 1

section .text
    global _start

_start:
    mov rbp, rsp
    and rsp, -16

    mov rbx, [rbp]          ; argc
    mov r12, [rbp + 16]     ; argv[1]
    mov r13, [rbp + 24]     ; argv[2]

    ; --- Comprobar -h ---
    cmp rbx, 2
    jne .verificar_args
    mov al, byte [r12]
    cmp al, '-'
    jne .verificar_args
    mov al, byte [r12 + 1]
    cmp al, 'h'
    je .modo_ayuda
    jmp .verificar_args

.verificar_args:
    cmp rbx, 3
    jne .error_args

    ; --- Convertir A ---
    mov rdi, r12
    call lib_string_int32cval
    jc .error_numero
    mov dword [val_a], eax

    ; --- Convertir B ---
    mov rdi, r13
    call lib_string_int32cval
    jc .error_numero
    mov dword [val_b], eax

    ; --- Calcular min ---
    mov edi, dword [val_a]
    mov esi, dword [val_b]
    call lib_math_min_int32cval

    movsxd rdi, eax
    call print_int
    call print_nl
    sys_exit 0

.modo_ayuda:
    mov rdi, msg_ayuda_1
    call print_string
    mov rdi, msg_ayuda_2
    call print_string
    mov rdi, msg_ayuda_3
    call print_string
    mov rdi, msg_ayuda_4
    call print_string
    mov rdi, msg_ayuda_5
    call print_string
    mov rdi, msg_ayuda_6
    call print_string
    mov rdi, msg_ayuda_7
    call print_string
    mov rdi, msg_ayuda_8
    call print_string
    mov rdi, msg_ayuda_9
    call print_string
    mov rdi, msg_ayuda_A
    call print_string
    mov rdi, msg_ayuda_B
    call print_string
    mov rdi, msg_ayuda_C
    call print_string
    mov rdi, msg_ayuda_D
    call print_string
    mov rdi, msg_ayuda_E
    call print_string
    sys_exit 0

.error_args:
    mov rdi, msg_error_args
    call print_string
    sys_exit 1

.error_numero:
    mov rdi, msg_error_numero
    call print_string
    sys_exit 1
