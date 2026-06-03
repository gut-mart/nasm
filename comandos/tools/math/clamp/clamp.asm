; ==============================================================================
; RUTA: ./comandos/tools/math/clamp/clamp.asm
; DESCRIPCIÓN: Limita un valor al rango cerrado [LO, HI].
; USO:
;   ./bin/clamp VAL LO HI
;   ./bin/clamp -h
; EJEMPLOS:
;   ./bin/clamp 5 0 10      → 5
;   ./bin/clamp -3 0 10     → 0
;   ./bin/clamp 15 0 10     → 10
;   ./bin/clamp 200 0 0xFF  → 200
; ==============================================================================

%include "lib/constants.inc"
%include "lib/sys_macros.inc"
%include "lib/math/int32/lib_math_int32.inc"

default rel

extern lib_math_clamp_int32cval
extern lib_string_int32cval
extern print_string, print_int, print_nl

section .data
    msg_ayuda_1 db "Uso: clamp VAL LO HI", 10, 0
    msg_ayuda_2 db "Descripcion: Limita VAL al rango cerrado [LO, HI].", 10, 10, 0
    msg_ayuda_3 db "Argumentos:", 10, 0
    msg_ayuda_4 db "  VAL     Valor a limitar (int32).", 10, 0
    msg_ayuda_5 db "  LO      Limite inferior, inclusive (int32).", 10, 0
    msg_ayuda_6 db "  HI      Limite superior, inclusive (int32).", 10, 0
    msg_ayuda_7 db "  -h      Muestra este panel de ayuda.", 10, 10, 0
    msg_ayuda_8 db "Comportamiento:", 10, 0
    msg_ayuda_9 db "  VAL < LO        →  devuelve LO", 10, 0
    msg_ayuda_A db "  VAL > HI        →  devuelve HI", 10, 0
    msg_ayuda_B db "  LO <= VAL <= HI →  devuelve VAL", 10, 0
    msg_ayuda_C db "  LO > HI         →  error de rango invalido", 10, 10, 0
    msg_ayuda_D db "Formatos numericos soportados:", 10, 0
    msg_ayuda_E db "  Decimal     : -42", 10, 0
    msg_ayuda_F db "  Hexadecimal : 0xFF", 10, 0
    msg_ayuda_G db "  Binario     : 0b101010", 10, 0
    msg_ayuda_H db "  Octal       : 0o52", 10, 10, 0
    msg_ayuda_I db "Ejemplos:", 10, 0
    msg_ayuda_J db "  ./bin/clamp 5 0 10      ; resultado: 5", 10, 0
    msg_ayuda_K db "  ./bin/clamp -3 0 10     ; resultado: 0", 10, 0
    msg_ayuda_L db "  ./bin/clamp 15 0 10     ; resultado: 10", 10, 0
    msg_ayuda_M db "  ./bin/clamp 200 0 0xFF  ; resultado: 200", 10, 0

    msg_error_args   db "Error: se necesitan exactamente tres argumentos. Usa '-h'.", 10, 0
    msg_error_numero db "Error: argumento no es un numero valido.", 10, 0
    msg_error_rango  db "Error: rango invalido (LO > HI).", 10, 0

section .bss
    val  resd 1
    lo   resd 1
    hi   resd 1

section .text
    global _start

_start:
    mov rbp, rsp
    and rsp, -16

    mov rbx, [rbp]          ; argc
    mov r12, [rbp + 16]     ; argv[1] — VAL o -h
    mov r13, [rbp + 24]     ; argv[2] — LO
    mov r14, [rbp + 32]     ; argv[3] — HI

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
    cmp rbx, 4
    jne .error_args

    ; --- Convertir VAL ---
    mov rdi, r12
    call lib_string_int32cval
    jc .error_numero
    mov dword [val], eax

    ; --- Convertir LO ---
    mov rdi, r13
    call lib_string_int32cval
    jc .error_numero
    mov dword [lo], eax

    ; --- Convertir HI ---
    mov rdi, r14
    call lib_string_int32cval
    jc .error_numero
    mov dword [hi], eax

    ; --- Calcular clamp (cval: valida lo <= hi) ---
    mov edi, dword [val]
    mov esi, dword [lo]
    mov edx, dword [hi]
    call lib_math_clamp_int32cval
    jc .error_rango

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
    mov rdi, msg_ayuda_L
    call print_string
    mov rdi, msg_ayuda_M
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

.error_rango:
    mov rdi, msg_error_rango
    call print_string
    sys_exit 1
