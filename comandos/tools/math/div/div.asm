; ==============================================================================
; RUTA: ./comandos/tools/math/div/div.asm
; DESCRIPCIÓN: División entera con signo de dos enteros de 32 bits.
; USO:
;   ./bin/div DIVIDENDO DIVISOR
;   ./bin/div -h
; EJEMPLOS:
;   ./bin/div 7 2        → 3
;   ./bin/div -7 2       → -3   (trunca hacia cero)
;   ./bin/div 0xFF 0x10  → 15
;   ./bin/div 5 0        → Error: division por cero
; ==============================================================================

%include "lib/constants.inc"
%include "lib/sys_macros.inc"
%include "lib/math/int32/lib_math_int32.inc"

default rel

extern lib_math_div_int32cval
extern lib_string_int32cval
extern print_string, print_int, print_nl

section .data
    msg_ayuda_1 db "Uso: div DIVIDENDO DIVISOR", 10, 0
    msg_ayuda_2 db "Descripcion: Division entera con signo (trunca hacia cero).", 10, 10, 0
    msg_ayuda_3 db "Argumentos:", 10, 0
    msg_ayuda_4 db "  DIVIDENDO   Entero con signo (32 bits). Soporta multiples bases.", 10, 0
    msg_ayuda_5 db "  DIVISOR     Entero con signo (32 bits). No puede ser 0.", 10, 0
    msg_ayuda_6 db "  -h          Muestra este panel de ayuda.", 10, 10, 0
    msg_ayuda_7 db "Comportamiento:", 10, 0
    msg_ayuda_8 db "  Trunca hacia cero, igual que en C:  -7 / 2 = -3", 10, 0
    msg_ayuda_9 db "  Division por cero          -> error", 10, 0
    msg_ayuda_A db "  INT32_MIN / -1 (overflow)  -> error", 10, 10, 0
    msg_ayuda_B db "Formatos numericos soportados:", 10, 0
    msg_ayuda_C db "  Decimal -42 / Hex 0xFF / Binario 0b101 / Octal 0o52", 10, 10, 0
    msg_ayuda_D db "Ejemplos:", 10, 0
    msg_ayuda_E db "  ./bin/div 7 2        ; resultado: 3", 10, 0
    msg_ayuda_F db "  ./bin/div -7 2       ; resultado: -3", 10, 0
    msg_ayuda_G db "  ./bin/div 0xFF 0x10  ; resultado: 15", 10, 0

    msg_error_args   db "Error: se necesitan exactamente dos argumentos. Usa '-h'.", 10, 0
    msg_error_numero db "Error: argumento no es un numero valido.", 10, 0
    msg_error_div    db "Error: division por cero o desbordamiento (INT32_MIN / -1).", 10, 0

section .bss
    dividendo resd 1
    divisor   resd 1

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

    ; --- Convertir DIVIDENDO ---
    mov rdi, r12
    call lib_string_int32cval
    jc .error_numero
    mov dword [dividendo], eax

    ; --- Convertir DIVISOR ---
    mov rdi, r13
    call lib_string_int32cval
    jc .error_numero
    mov dword [divisor], eax

    ; --- Calcular div (cval: valida divisor != 0 y overflow) ---
    mov edi, dword [dividendo]
    mov esi, dword [divisor]
    call lib_math_div_int32cval
    jc .error_div

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
    mov rdi, msg_ayuda_F
    call print_string
    mov rdi, msg_ayuda_G
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

.error_div:
    mov rdi, msg_error_div
    call print_string
    sys_exit 1
