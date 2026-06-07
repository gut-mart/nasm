; ==============================================================================
; RUTA: ./comandos/tools/math/pow/pow.asm
; DESCRIPCIÓN: Potencia entera con signo: BASE elevado a EXP.
; USO:
;   ./bin/pow BASE EXP
;   ./bin/pow -h
; EJEMPLOS:
;   ./bin/pow 2 10       → 1024
;   ./bin/pow -2 3       → -8
;   ./bin/pow 5 0        → 1
;   ./bin/pow 7 -2       → Error (exponente negativo no representable en int32)
;   ./bin/pow 2 31       → Error (overflow, no cabe en int32)
; ==============================================================================

%include "lib/constants.inc"
%include "lib/sys_macros.inc"
%include "lib/math/int32/lib_math_int32.inc"

default rel

extern lib_math_pow_int32cval
extern lib_string_int32cval
extern print_string, print_int, print_nl

section .data
    msg_ayuda_1 db "Uso: pow BASE EXP", 10, 0
    msg_ayuda_2 db "Descripcion: Eleva BASE a la potencia EXP (enteros con signo de 32 bits).", 10, 10, 0
    msg_ayuda_3 db "Argumentos:", 10, 0
    msg_ayuda_4 db "  BASE    Base de la potencia (int32). Soporta multiples bases numericas.", 10, 0
    msg_ayuda_5 db "  EXP     Exponente (int32). Debe ser >= 0.", 10, 0
    msg_ayuda_6 db "  -h      Muestra este panel de ayuda.", 10, 10, 0
    msg_ayuda_7 db "Comportamiento:", 10, 0
    msg_ayuda_8 db "  pow(x, 0)   = 1   (incluido 0^0 = 1 por convencion)", 10, 0
    msg_ayuda_9 db "  pow(x, n<0) = Error: el resultado seria una fraccion, no", 10, 0
    msg_ayuda_A db "                representable como entero.", 10, 0
    msg_ayuda_B db "  Si el resultado entero no cabe en int32 -> Error de overflow.", 10, 10, 0
    msg_ayuda_C db "Rango valido: el resultado debe estar en [-2147483648, 2147483647].", 10, 0
    msg_ayuda_D db "  Ejemplo del limite:  pow 2 30 = 1073741824 (cabe)", 10, 0
    msg_ayuda_E db "                       pow 2 31 = Error (se pasa por 1)", 10, 10, 0
    msg_ayuda_F db "Formatos numericos soportados:", 10, 0
    msg_ayuda_G db "  Decimal -42 / Hex 0xFF / Binario 0b101 / Octal 0o52", 10, 10, 0
    msg_ayuda_H db "Ejemplos:", 10, 0
    msg_ayuda_I db "  ./bin/pow 2 10      ; resultado: 1024", 10, 0
    msg_ayuda_J db "  ./bin/pow -2 3      ; resultado: -8", 10, 0
    msg_ayuda_K db "  ./bin/pow 5 0       ; resultado: 1", 10, 0

    msg_error_args     db "Error: se necesitan exactamente dos argumentos. Usa '-h'.", 10, 0
    msg_error_numero   db "Error: argumento no es un numero valido.", 10, 0
    msg_error_norep    db "Error: resultado no representable en int32 (exponente negativo u overflow).", 10, 0

section .bss
    base resd 1
    exp  resd 1

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

    ; --- Convertir BASE ---
    mov rdi, r12
    call lib_string_int32cval
    jc .error_numero
    mov dword [base], eax

    ; --- Convertir EXP ---
    mov rdi, r13
    call lib_string_int32cval
    jc .error_numero
    mov dword [exp], eax

    ; --- Calcular pow (cval: valida exp negativo y overflow) ---
    mov edi, dword [base]
    mov esi, dword [exp]
    call lib_math_pow_int32cval
    jc .error_norep

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
    mov rdi, msg_ayuda_H
    call print_string
    mov rdi, msg_ayuda_I
    call print_string
    mov rdi, msg_ayuda_J
    call print_string
    mov rdi, msg_ayuda_K
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

.error_norep:
    mov rdi, msg_error_norep
    call print_string
    sys_exit 1
