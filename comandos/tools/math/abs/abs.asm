; ==============================================================================
; RUTA: ./comandos/tools/math/abs/abs.asm
; DESCRIPCIÓN: Calcula el valor absoluto de un entero con signo de 32 bits.
; USO:
;   ./bin/abs VALOR
;   ./bin/abs -h
; EJEMPLOS:
;   ./bin/abs -42        → 42
;   ./bin/abs 0xFF       → 255
;   ./bin/abs 0          → 0
; ==============================================================================

%include "lib/constants.inc"
%include "lib/sys_macros.inc"
%include "lib/math/int32/lib_math_int32.inc"

default rel

extern lib_math_abs_int32cval
extern lib_string_int32cval
extern print_string, print_int, print_nl

section .data
    msg_ayuda_1 db "Uso: abs VALOR", 10, 0
    msg_ayuda_2 db "Descripcion: Calcula el valor absoluto de un entero con signo.", 10, 10, 0
    msg_ayuda_3 db "Argumentos:", 10, 0
    msg_ayuda_4 db "  VALOR   Entero con signo (32 bits). Soporta multiples bases.", 10, 0
    msg_ayuda_5 db "  -h      Muestra este panel de ayuda.", 10, 10, 0
    msg_ayuda_6 db "Formatos numericos soportados:", 10, 0
    msg_ayuda_7 db "  Decimal     : -42", 10, 0
    msg_ayuda_8 db "  Hexadecimal : 0xFF", 10, 0
    msg_ayuda_9 db "  Binario     : 0b101010", 10, 0
    msg_ayuda_A db "  Octal       : 0o52", 10, 10, 0
    msg_ayuda_B db "Ejemplos:", 10, 0
    msg_ayuda_C db "  ./bin/abs -42       ; resultado: 42", 10, 0
    msg_ayuda_D db "  ./bin/abs 0xFF      ; resultado: 255", 10, 0
    msg_ayuda_E db "  ./bin/abs 0         ; resultado: 0", 10, 0

    msg_error_args   db "Error: numero de argumentos incorrecto. Usa '-h'.", 10, 0
    msg_error_numero db "Error: argumento no es un numero valido.", 10, 0
    msg_aviso_min    db "Aviso: abs(INT32_MIN) = INT32_MIN (overflow inherente al complemento a dos).", 10, 0

section .text
    global _start

_start:
    mov rbp, rsp
    and rsp, -16

    mov rbx, [rbp]          ; argc
    mov r12, [rbp + 16]     ; argv[1]

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
    cmp rbx, 2
    jne .error_args

    ; --- Convertir argumento (string → int32) ---
    mov rdi, r12
    call lib_string_int32cval
    jc .error_numero

    ; --- Calcular abs (cval: detecta INT32_MIN con CF) ---
    mov edi, eax
    call lib_math_abs_int32cval

    ; --- Imprimir resultado ---
    movsxd rdi, eax
    call print_int
    call print_nl

    ; --- Si CF=1 era INT32_MIN, avisar ---
    jnc .fin
    mov rdi, msg_aviso_min
    call print_string

.fin:
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
