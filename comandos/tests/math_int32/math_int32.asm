; ==============================================================================
; RUTA: ./comandos/tests/math_int32/math_int32.asm
; DESCRIPCIÓN: Test unitario de lib_math_int32 (abs, min, max, clamp).
;              Imprime OK/FAIL por cada caso. Devuelve exit 0 si todos pasan,
;              exit 1 si alguno falla. No requiere framebuffer ni sudo.
; USO:
;   make SRC=comandos/tests/math_int32/math_int32.asm
;   ./bin/math_int32
; ==============================================================================

%include "lib/constants.inc"
%include "lib/sys_macros.inc"
%include "lib/math/int32/lib_math_int32.inc"

default rel

extern lib_math_abs_i32
extern lib_math_min_i32
extern lib_math_max_i32
extern lib_math_clamp_i32
extern print_string, print_nl

section .data
    msg_ok      db "  OK    ", 0
    msg_fail    db "  FAIL  ", 0
    msg_sep     db "=== lib_math_int32 ===", 10, 0

    ; --- abs ---
    t_abs_pos   db "abs( 5)             = 5", 0
    t_abs_neg   db "abs(-5)             = 5", 0
    t_abs_zero  db "abs( 0)             = 0", 0
    t_abs_min   db "abs(INT32_MIN)      = INT32_MIN  (overflow conocido)", 0

    ; --- min ---
    t_min_ab    db "min(3, 7)           = 3", 0
    t_min_ba    db "min(7, 3)           = 3", 0
    t_min_eq    db "min(4, 4)           = 4", 0
    t_min_neg   db "min(-1, 1)          = -1", 0

    ; --- max ---
    t_max_ab    db "max(3, 7)           = 7", 0
    t_max_ba    db "max(7, 3)           = 7", 0
    t_max_eq    db "max(4, 4)           = 4", 0
    t_max_neg   db "max(-1, 1)          = 1", 0

    ; --- clamp ---
    t_clamp_in  db "clamp( 5, 0,10)     = 5   CF=0", 0
    t_clamp_lo  db "clamp(-3, 0,10)     = 0   CF=0", 0
    t_clamp_hi  db "clamp(15, 0,10)     = 10  CF=0", 0
    t_clamp_eq  db "clamp( 5, 5, 5)     = 5   CF=0", 0
    t_clamp_inv db "clamp( 5,10, 0)     CF=1  (rango invalido)", 0

section .bss
    fallos resd 1

section .text
    global _start

_start:
    mov rbp, rsp
    and rsp, -16

    mov dword [fallos], 0

    mov rdi, msg_sep
    call print_string

    ; =========================================================================
    ; ABS
    ; =========================================================================

    mov edi, 5
    call lib_math_abs_i32
    cmp eax, 5
    call .registrar
    mov rdi, t_abs_pos
    call .imprimir

    mov edi, -5
    call lib_math_abs_i32
    cmp eax, 5
    call .registrar
    mov rdi, t_abs_neg
    call .imprimir

    mov edi, 0
    call lib_math_abs_i32
    cmp eax, 0
    call .registrar
    mov rdi, t_abs_zero
    call .imprimir

    mov edi, INT32_MIN
    call lib_math_abs_i32
    cmp eax, INT32_MIN
    call .registrar
    mov rdi, t_abs_min
    call .imprimir

    ; =========================================================================
    ; MIN
    ; =========================================================================

    mov edi, 3
    mov esi, 7
    call lib_math_min_i32
    cmp eax, 3
    call .registrar
    mov rdi, t_min_ab
    call .imprimir

    mov edi, 7
    mov esi, 3
    call lib_math_min_i32
    cmp eax, 3
    call .registrar
    mov rdi, t_min_ba
    call .imprimir

    mov edi, 4
    mov esi, 4
    call lib_math_min_i32
    cmp eax, 4
    call .registrar
    mov rdi, t_min_eq
    call .imprimir

    mov edi, -1
    mov esi, 1
    call lib_math_min_i32
    cmp eax, -1
    call .registrar
    mov rdi, t_min_neg
    call .imprimir

    ; =========================================================================
    ; MAX
    ; =========================================================================

    mov edi, 3
    mov esi, 7
    call lib_math_max_i32
    cmp eax, 7
    call .registrar
    mov rdi, t_max_ab
    call .imprimir

    mov edi, 7
    mov esi, 3
    call lib_math_max_i32
    cmp eax, 7
    call .registrar
    mov rdi, t_max_ba
    call .imprimir

    mov edi, 4
    mov esi, 4
    call lib_math_max_i32
    cmp eax, 4
    call .registrar
    mov rdi, t_max_eq
    call .imprimir

    mov edi, -1
    mov esi, 1
    call lib_math_max_i32
    cmp eax, 1
    call .registrar
    mov rdi, t_max_neg
    call .imprimir

    ; =========================================================================
    ; CLAMP
    ; =========================================================================

    ; val dentro del rango → CF=0, EAX=5
    mov edi, 5
    mov esi, 0
    mov edx, 10
    call lib_math_clamp_i32
    jc  .fallo_cf
    cmp eax, 5
    call .registrar
    jmp .done_clamp_in
.fallo_cf:
    call .forzar_fallo
.done_clamp_in:
    mov rdi, t_clamp_in
    call .imprimir

    ; val por debajo → CF=0, EAX=0
    mov edi, -3
    mov esi, 0
    mov edx, 10
    call lib_math_clamp_i32
    jc  .fallo_cf2
    cmp eax, 0
    call .registrar
    jmp .done_clamp_lo
.fallo_cf2:
    call .forzar_fallo
.done_clamp_lo:
    mov rdi, t_clamp_lo
    call .imprimir

    ; val por encima → CF=0, EAX=10
    mov edi, 15
    mov esi, 0
    mov edx, 10
    call lib_math_clamp_i32
    jc  .fallo_cf3
    cmp eax, 10
    call .registrar
    jmp .done_clamp_hi
.fallo_cf3:
    call .forzar_fallo
.done_clamp_hi:
    mov rdi, t_clamp_hi
    call .imprimir

    ; rango colapsado lo==hi → CF=0, EAX=5
    mov edi, 5
    mov esi, 5
    mov edx, 5
    call lib_math_clamp_i32
    jc  .fallo_cf4
    cmp eax, 5
    call .registrar
    jmp .done_clamp_eq
.fallo_cf4:
    call .forzar_fallo
.done_clamp_eq:
    mov rdi, t_clamp_eq
    call .imprimir

    ; rango inválido lo>hi → CF=1, EAX=val original
    mov edi, 5
    mov esi, 10
    mov edx, 0
    call lib_math_clamp_i32
    jnc .fallo_cf5         ; CF=0 cuando esperábamos CF=1 → fallo
    cmp eax, 5             ; EAX debe ser el val original
    call .registrar
    jmp .done_clamp_inv
.fallo_cf5:
    call .forzar_fallo
.done_clamp_inv:
    mov rdi, t_clamp_inv
    call .imprimir

    ; =========================================================================
    ; RESULTADO FINAL
    ; =========================================================================
    call print_nl
    cmp dword [fallos], 0
    je .todo_ok
    sys_exit 1

.todo_ok:
    sys_exit 0

; --------------------------------------------------------------------------
; SUBRUTINAS INTERNAS
; --------------------------------------------------------------------------

; .registrar — lee ZF tras el cmp del llamante.
;   ZF=1 (iguales)    → r15b = 0  (OK)
;   ZF=0 (diferentes) → r15b = 1  (FAIL) e incrementa [fallos]
.registrar:
    setnz r15b
    test  r15b, r15b
    jz    .reg_ret
    inc   dword [fallos]
.reg_ret:
    ret

; .forzar_fallo — marca el test actual como fallido sin cmp previo.
.forzar_fallo:
    mov  r15b, 1
    inc  dword [fallos]
    ret

; .imprimir — imprime "  OK  " o "  FAIL  " según r15b, luego el texto del test.
;   RDI debe apuntar al literal descriptivo ANTES de llamar.
.imprimir:
    push rdi
    test r15b, r15b
    jnz  .imp_fail
    mov  rdi, msg_ok
    jmp  .imp_print
.imp_fail:
    mov  rdi, msg_fail
.imp_print:
    call print_string
    pop  rdi
    call print_string
    call print_nl
    ret
