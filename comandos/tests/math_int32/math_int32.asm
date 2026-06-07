; ==============================================================================
; RUTA: ./comandos/tests/math_int32/math_int32.asm
; DESCRIPCIÓN: Test unitario de lib/math/int32 (abs, min, max, clamp, div, mod, pow).
;              Prueba las capas fast y cval de cada operación.
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

extern lib_math_abs_int32fast
extern lib_math_abs_int32cval
extern lib_math_min_int32fast
extern lib_math_min_int32cval
extern lib_math_max_int32fast
extern lib_math_max_int32cval
extern lib_math_clamp_int32fast
extern lib_math_clamp_int32cval
extern lib_math_div_int32fast
extern lib_math_div_int32cval
extern lib_math_mod_int32fast
extern lib_math_mod_int32cval
extern lib_math_pow_int32fast
extern lib_math_pow_int32cval
extern print_string, print_nl

section .data
    msg_ok      db "  OK    ", 0
    msg_fail    db "  FAIL  ", 0

    msg_sep_abs_fast   db "--- abs (fast) ---", 10, 0
    msg_sep_abs_cval   db "--- abs (cval) ---", 10, 0
    msg_sep_min_fast   db "--- min (fast) ---", 10, 0
    msg_sep_min_cval   db "--- min (cval) ---", 10, 0
    msg_sep_max_fast   db "--- max (fast) ---", 10, 0
    msg_sep_max_cval   db "--- max (cval) ---", 10, 0
    msg_sep_clamp_fast db "--- clamp (fast) ---", 10, 0
    msg_sep_clamp_cval db "--- clamp (cval) ---", 10, 0
    msg_sep_div_fast   db "--- div (fast) ---", 10, 0
    msg_sep_div_cval   db "--- div (cval) ---", 10, 0
    msg_sep_mod_fast   db "--- mod (fast) ---", 10, 0
    msg_sep_mod_cval   db "--- mod (cval) ---", 10, 0
    msg_sep_pow_fast   db "--- pow (fast) ---", 10, 0
    msg_sep_pow_cval   db "--- pow (cval) ---", 10, 0

    ; abs fast
    t_abs_f1 db "abs( 5)        = 5", 0
    t_abs_f2 db "abs(-5)        = 5", 0
    t_abs_f3 db "abs( 0)        = 0", 0

    ; abs cval
    t_abs_c1 db "abs( 5)        CF=0, EAX=5", 0
    t_abs_c2 db "abs(-5)        CF=0, EAX=5", 0
    t_abs_c3 db "abs(INT32_MIN) CF=1, EAX=INT32_MIN", 0

    ; min fast
    t_min_f1 db "min(3, 7)      = 3", 0
    t_min_f2 db "min(7, 3)      = 3", 0
    t_min_f3 db "min(4, 4)      = 4", 0
    t_min_f4 db "min(-1, 1)     = -1", 0

    ; min cval
    t_min_c1 db "min(3, 7)      CF=0, EAX=3", 0
    t_min_c2 db "min(-1, 1)     CF=0, EAX=-1", 0

    ; max fast
    t_max_f1 db "max(3, 7)      = 7", 0
    t_max_f2 db "max(7, 3)      = 7", 0
    t_max_f3 db "max(4, 4)      = 4", 0
    t_max_f4 db "max(-1, 1)     = 1", 0

    ; max cval
    t_max_c1 db "max(3, 7)      CF=0, EAX=7", 0
    t_max_c2 db "max(-1, 1)     CF=0, EAX=1", 0

    ; clamp fast
    t_clamp_f1 db "clamp( 5, 0,10) = 5", 0
    t_clamp_f2 db "clamp(-3, 0,10) = 0", 0
    t_clamp_f3 db "clamp(15, 0,10) = 10", 0
    t_clamp_f4 db "clamp( 5, 5, 5) = 5", 0

    ; clamp cval
    t_clamp_c1 db "clamp( 5, 0,10) CF=0, EAX=5", 0
    t_clamp_c2 db "clamp(-3, 0,10) CF=0, EAX=0", 0
    t_clamp_c3 db "clamp(15, 0,10) CF=0, EAX=10", 0
    t_clamp_c4 db "clamp( 5, 5, 5) CF=0, EAX=5", 0
    t_clamp_c5 db "clamp( 5,10, 0) CF=1 (rango invalido)", 0

    ; div fast
    t_div_f1 db "div( 7, 2)     = 3", 0
    t_div_f2 db "div(-7, 2)     = -3  (trunca a cero)", 0
    t_div_f3 db "div( 7,-2)     = -3", 0
    t_div_f4 db "div( 6, 3)     = 2", 0

    ; div cval
    t_div_c1 db "div( 7, 2)     CF=0, EAX=3", 0
    t_div_c2 db "div(-7, 2)     CF=0, EAX=-3", 0
    t_div_c3 db "div( 5, 0)     CF=1 (division por cero)", 0
    t_div_c4 db "div(INT32_MIN,-1) CF=1 (overflow)", 0

    ; mod fast
    t_mod_f1 db "mod( 7, 2)     = 1", 0
    t_mod_f2 db "mod(-7, 2)     = -1  (signo dividendo)", 0
    t_mod_f3 db "mod( 7,-2)     = 1", 0
    t_mod_f4 db "mod( 6, 3)     = 0", 0

    ; mod cval
    t_mod_c1 db "mod( 7, 2)     CF=0, EAX=1", 0
    t_mod_c2 db "mod(-7, 2)     CF=0, EAX=-1", 0
    t_mod_c3 db "mod( 5, 0)     CF=1 (division por cero)", 0
    t_mod_c4 db "mod(INT32_MIN,-1) CF=1 (overflow)", 0

    ; pow fast
    t_pow_f1 db "pow( 2,10)     = 1024", 0
    t_pow_f2 db "pow( 2, 0)     = 1", 0
    t_pow_f3 db "pow(-2, 3)     = -8  (impar)", 0
    t_pow_f4 db "pow(-2, 4)     = 16  (par)", 0
    t_pow_f5 db "pow( 5, 1)     = 5", 0

    ; pow cval
    t_pow_c1 db "pow( 2,10)     CF=0, EAX=1024", 0
    t_pow_c2 db "pow( 2, 0)     CF=0, EAX=1", 0
    t_pow_c3 db "pow( 7,-2)     CF=1  (exp negativo no representable)", 0
    t_pow_c4 db "pow( 0, 5)     CF=0, EAX=0", 0
    t_pow_c5 db "pow( 2,30)     CF=0, EAX=1073741824", 0
    t_pow_c6 db "pow( 2,31)     CF=1  (overflow)", 0

section .bss
    fallos resd 1

section .text
    global _start

_start:
    mov rbp, rsp
    and rsp, -16
    mov dword [fallos], 0

    ; =========================================================================
    ; ABS FAST
    ; =========================================================================
    mov rdi, msg_sep_abs_fast
    call print_string

    mov edi, 5
    call lib_math_abs_int32fast
    cmp eax, 5
    call .registrar
    mov rdi, t_abs_f1
    call .imprimir

    mov edi, -5
    call lib_math_abs_int32fast
    cmp eax, 5
    call .registrar
    mov rdi, t_abs_f2
    call .imprimir

    mov edi, 0
    call lib_math_abs_int32fast
    cmp eax, 0
    call .registrar
    mov rdi, t_abs_f3
    call .imprimir

    ; =========================================================================
    ; ABS CVAL
    ; =========================================================================
    mov rdi, msg_sep_abs_cval
    call print_string

    mov edi, 5
    call lib_math_abs_int32cval
    jc .abs_c1_fail
    cmp eax, 5
    call .registrar
    jmp .abs_c1_done
.abs_c1_fail:
    call .forzar_fallo
.abs_c1_done:
    mov rdi, t_abs_c1
    call .imprimir

    mov edi, -5
    call lib_math_abs_int32cval
    jc .abs_c2_fail
    cmp eax, 5
    call .registrar
    jmp .abs_c2_done
.abs_c2_fail:
    call .forzar_fallo
.abs_c2_done:
    mov rdi, t_abs_c2
    call .imprimir

    ; INT32_MIN → CF=1, EAX=INT32_MIN
    mov edi, INT32_MIN
    call lib_math_abs_int32cval
    jnc .abs_c3_fail
    cmp eax, INT32_MIN
    call .registrar
    jmp .abs_c3_done
.abs_c3_fail:
    call .forzar_fallo
.abs_c3_done:
    mov rdi, t_abs_c3
    call .imprimir

    ; =========================================================================
    ; MIN FAST
    ; =========================================================================
    mov rdi, msg_sep_min_fast
    call print_string

    mov edi, 3
    mov esi, 7
    call lib_math_min_int32fast
    cmp eax, 3
    call .registrar
    mov rdi, t_min_f1
    call .imprimir

    mov edi, 7
    mov esi, 3
    call lib_math_min_int32fast
    cmp eax, 3
    call .registrar
    mov rdi, t_min_f2
    call .imprimir

    mov edi, 4
    mov esi, 4
    call lib_math_min_int32fast
    cmp eax, 4
    call .registrar
    mov rdi, t_min_f3
    call .imprimir

    mov edi, -1
    mov esi, 1
    call lib_math_min_int32fast
    cmp eax, -1
    call .registrar
    mov rdi, t_min_f4
    call .imprimir

    ; =========================================================================
    ; MIN CVAL
    ; =========================================================================
    mov rdi, msg_sep_min_cval
    call print_string

    mov edi, 3
    mov esi, 7
    call lib_math_min_int32cval
    jc .min_c1_fail
    cmp eax, 3
    call .registrar
    jmp .min_c1_done
.min_c1_fail:
    call .forzar_fallo
.min_c1_done:
    mov rdi, t_min_c1
    call .imprimir

    mov edi, -1
    mov esi, 1
    call lib_math_min_int32cval
    jc .min_c2_fail
    cmp eax, -1
    call .registrar
    jmp .min_c2_done
.min_c2_fail:
    call .forzar_fallo
.min_c2_done:
    mov rdi, t_min_c2
    call .imprimir

    ; =========================================================================
    ; MAX FAST
    ; =========================================================================
    mov rdi, msg_sep_max_fast
    call print_string

    mov edi, 3
    mov esi, 7
    call lib_math_max_int32fast
    cmp eax, 7
    call .registrar
    mov rdi, t_max_f1
    call .imprimir

    mov edi, 7
    mov esi, 3
    call lib_math_max_int32fast
    cmp eax, 7
    call .registrar
    mov rdi, t_max_f2
    call .imprimir

    mov edi, 4
    mov esi, 4
    call lib_math_max_int32fast
    cmp eax, 4
    call .registrar
    mov rdi, t_max_f3
    call .imprimir

    mov edi, -1
    mov esi, 1
    call lib_math_max_int32fast
    cmp eax, 1
    call .registrar
    mov rdi, t_max_f4
    call .imprimir

    ; =========================================================================
    ; MAX CVAL
    ; =========================================================================
    mov rdi, msg_sep_max_cval
    call print_string

    mov edi, 3
    mov esi, 7
    call lib_math_max_int32cval
    jc .max_c1_fail
    cmp eax, 7
    call .registrar
    jmp .max_c1_done
.max_c1_fail:
    call .forzar_fallo
.max_c1_done:
    mov rdi, t_max_c1
    call .imprimir

    mov edi, -1
    mov esi, 1
    call lib_math_max_int32cval
    jc .max_c2_fail
    cmp eax, 1
    call .registrar
    jmp .max_c2_done
.max_c2_fail:
    call .forzar_fallo
.max_c2_done:
    mov rdi, t_max_c2
    call .imprimir

    ; =========================================================================
    ; CLAMP FAST
    ; =========================================================================
    mov rdi, msg_sep_clamp_fast
    call print_string

    mov edi, 5
    mov esi, 0
    mov edx, 10
    call lib_math_clamp_int32fast
    cmp eax, 5
    call .registrar
    mov rdi, t_clamp_f1
    call .imprimir

    mov edi, -3
    mov esi, 0
    mov edx, 10
    call lib_math_clamp_int32fast
    cmp eax, 0
    call .registrar
    mov rdi, t_clamp_f2
    call .imprimir

    mov edi, 15
    mov esi, 0
    mov edx, 10
    call lib_math_clamp_int32fast
    cmp eax, 10
    call .registrar
    mov rdi, t_clamp_f3
    call .imprimir

    mov edi, 5
    mov esi, 5
    mov edx, 5
    call lib_math_clamp_int32fast
    cmp eax, 5
    call .registrar
    mov rdi, t_clamp_f4
    call .imprimir

    ; =========================================================================
    ; CLAMP CVAL
    ; =========================================================================
    mov rdi, msg_sep_clamp_cval
    call print_string

    mov edi, 5
    mov esi, 0
    mov edx, 10
    call lib_math_clamp_int32cval
    jc .clamp_c1_fail
    cmp eax, 5
    call .registrar
    jmp .clamp_c1_done
.clamp_c1_fail:
    call .forzar_fallo
.clamp_c1_done:
    mov rdi, t_clamp_c1
    call .imprimir

    mov edi, -3
    mov esi, 0
    mov edx, 10
    call lib_math_clamp_int32cval
    jc .clamp_c2_fail
    cmp eax, 0
    call .registrar
    jmp .clamp_c2_done
.clamp_c2_fail:
    call .forzar_fallo
.clamp_c2_done:
    mov rdi, t_clamp_c2
    call .imprimir

    mov edi, 15
    mov esi, 0
    mov edx, 10
    call lib_math_clamp_int32cval
    jc .clamp_c3_fail
    cmp eax, 10
    call .registrar
    jmp .clamp_c3_done
.clamp_c3_fail:
    call .forzar_fallo
.clamp_c3_done:
    mov rdi, t_clamp_c3
    call .imprimir

    mov edi, 5
    mov esi, 5
    mov edx, 5
    call lib_math_clamp_int32cval
    jc .clamp_c4_fail
    cmp eax, 5
    call .registrar
    jmp .clamp_c4_done
.clamp_c4_fail:
    call .forzar_fallo
.clamp_c4_done:
    mov rdi, t_clamp_c4
    call .imprimir

    ; rango inválido lo>hi → CF=1
    mov edi, 5
    mov esi, 10
    mov edx, 0
    call lib_math_clamp_int32cval
    jnc .clamp_c5_fail
    cmp eax, 5
    call .registrar
    jmp .clamp_c5_done
.clamp_c5_fail:
    call .forzar_fallo
.clamp_c5_done:
    mov rdi, t_clamp_c5
    call .imprimir

    ; =========================================================================
    ; DIV FAST
    ; =========================================================================
    mov rdi, msg_sep_div_fast
    call print_string

    mov edi, 7
    mov esi, 2
    call lib_math_div_int32fast
    cmp eax, 3
    call .registrar
    mov rdi, t_div_f1
    call .imprimir

    mov edi, -7
    mov esi, 2
    call lib_math_div_int32fast
    cmp eax, -3
    call .registrar
    mov rdi, t_div_f2
    call .imprimir

    mov edi, 7
    mov esi, -2
    call lib_math_div_int32fast
    cmp eax, -3
    call .registrar
    mov rdi, t_div_f3
    call .imprimir

    mov edi, 6
    mov esi, 3
    call lib_math_div_int32fast
    cmp eax, 2
    call .registrar
    mov rdi, t_div_f4
    call .imprimir

    ; =========================================================================
    ; DIV CVAL
    ; =========================================================================
    mov rdi, msg_sep_div_cval
    call print_string

    mov edi, 7
    mov esi, 2
    call lib_math_div_int32cval
    jc .div_c1_fail
    cmp eax, 3
    call .registrar
    jmp .div_c1_done
.div_c1_fail:
    call .forzar_fallo
.div_c1_done:
    mov rdi, t_div_c1
    call .imprimir

    mov edi, -7
    mov esi, 2
    call lib_math_div_int32cval
    jc .div_c2_fail
    cmp eax, -3
    call .registrar
    jmp .div_c2_done
.div_c2_fail:
    call .forzar_fallo
.div_c2_done:
    mov rdi, t_div_c2
    call .imprimir

    ; división por cero → CF=1
    mov edi, 5
    mov esi, 0
    call lib_math_div_int32cval
    jnc .div_c3_fail
    cmp eax, 0
    call .registrar
    jmp .div_c3_done
.div_c3_fail:
    call .forzar_fallo
.div_c3_done:
    mov rdi, t_div_c3
    call .imprimir

    ; INT32_MIN / -1 → CF=1 (overflow)
    mov edi, INT32_MIN
    mov esi, -1
    call lib_math_div_int32cval
    jnc .div_c4_fail
    cmp eax, INT32_MIN
    call .registrar
    jmp .div_c4_done
.div_c4_fail:
    call .forzar_fallo
.div_c4_done:
    mov rdi, t_div_c4
    call .imprimir

    ; =========================================================================
    ; MOD FAST
    ; =========================================================================
    mov rdi, msg_sep_mod_fast
    call print_string

    mov edi, 7
    mov esi, 2
    call lib_math_mod_int32fast
    cmp eax, 1
    call .registrar
    mov rdi, t_mod_f1
    call .imprimir

    mov edi, -7
    mov esi, 2
    call lib_math_mod_int32fast
    cmp eax, -1
    call .registrar
    mov rdi, t_mod_f2
    call .imprimir

    mov edi, 7
    mov esi, -2
    call lib_math_mod_int32fast
    cmp eax, 1
    call .registrar
    mov rdi, t_mod_f3
    call .imprimir

    mov edi, 6
    mov esi, 3
    call lib_math_mod_int32fast
    cmp eax, 0
    call .registrar
    mov rdi, t_mod_f4
    call .imprimir

    ; =========================================================================
    ; MOD CVAL
    ; =========================================================================
    mov rdi, msg_sep_mod_cval
    call print_string

    mov edi, 7
    mov esi, 2
    call lib_math_mod_int32cval
    jc .mod_c1_fail
    cmp eax, 1
    call .registrar
    jmp .mod_c1_done
.mod_c1_fail:
    call .forzar_fallo
.mod_c1_done:
    mov rdi, t_mod_c1
    call .imprimir

    mov edi, -7
    mov esi, 2
    call lib_math_mod_int32cval
    jc .mod_c2_fail
    cmp eax, -1
    call .registrar
    jmp .mod_c2_done
.mod_c2_fail:
    call .forzar_fallo
.mod_c2_done:
    mov rdi, t_mod_c2
    call .imprimir

    ; módulo por cero → CF=1
    mov edi, 5
    mov esi, 0
    call lib_math_mod_int32cval
    jnc .mod_c3_fail
    cmp eax, 0
    call .registrar
    jmp .mod_c3_done
.mod_c3_fail:
    call .forzar_fallo
.mod_c3_done:
    mov rdi, t_mod_c3
    call .imprimir

    ; INT32_MIN % -1 → CF=1 (overflow interceptado)
    mov edi, INT32_MIN
    mov esi, -1
    call lib_math_mod_int32cval
    jnc .mod_c4_fail
    cmp eax, 0
    call .registrar
    jmp .mod_c4_done
.mod_c4_fail:
    call .forzar_fallo
.mod_c4_done:
    mov rdi, t_mod_c4
    call .imprimir

    ; =========================================================================
    ; POW FAST
    ; =========================================================================
    mov rdi, msg_sep_pow_fast
    call print_string

    mov edi, 2
    mov esi, 10
    call lib_math_pow_int32fast
    cmp eax, 1024
    call .registrar
    mov rdi, t_pow_f1
    call .imprimir

    mov edi, 2
    mov esi, 0
    call lib_math_pow_int32fast
    cmp eax, 1
    call .registrar
    mov rdi, t_pow_f2
    call .imprimir

    mov edi, -2
    mov esi, 3
    call lib_math_pow_int32fast
    cmp eax, -8
    call .registrar
    mov rdi, t_pow_f3
    call .imprimir

    mov edi, -2
    mov esi, 4
    call lib_math_pow_int32fast
    cmp eax, 16
    call .registrar
    mov rdi, t_pow_f4
    call .imprimir

    mov edi, 5
    mov esi, 1
    call lib_math_pow_int32fast
    cmp eax, 5
    call .registrar
    mov rdi, t_pow_f5
    call .imprimir

    ; =========================================================================
    ; POW CVAL
    ; =========================================================================
    mov rdi, msg_sep_pow_cval
    call print_string

    mov edi, 2
    mov esi, 10
    call lib_math_pow_int32cval
    jc .pow_c1_fail
    cmp eax, 1024
    call .registrar
    jmp .pow_c1_done
.pow_c1_fail:
    call .forzar_fallo
.pow_c1_done:
    mov rdi, t_pow_c1
    call .imprimir

    mov edi, 2
    mov esi, 0
    call lib_math_pow_int32cval
    jc .pow_c2_fail
    cmp eax, 1
    call .registrar
    jmp .pow_c2_done
.pow_c2_fail:
    call .forzar_fallo
.pow_c2_done:
    mov rdi, t_pow_c2
    call .imprimir

    ; exp negativo → error CF=1 (no representable como entero)
    mov edi, 7
    mov esi, -2
    call lib_math_pow_int32cval
    jnc .pow_c3_fail
    cmp eax, 0
    call .registrar
    jmp .pow_c3_done
.pow_c3_fail:
    call .forzar_fallo
.pow_c3_done:
    mov rdi, t_pow_c3
    call .imprimir

    ; base 0, exp positivo → 0
    mov edi, 0
    mov esi, 5
    call lib_math_pow_int32cval
    jc .pow_c4_fail
    cmp eax, 0
    call .registrar
    jmp .pow_c4_done
.pow_c4_fail:
    call .forzar_fallo
.pow_c4_done:
    mov rdi, t_pow_c4
    call .imprimir

    ; 2^30 = 1073741824, cabe justo
    mov edi, 2
    mov esi, 30
    call lib_math_pow_int32cval
    jc .pow_c5_fail
    cmp eax, 1073741824
    call .registrar
    jmp .pow_c5_done
.pow_c5_fail:
    call .forzar_fallo
.pow_c5_done:
    mov rdi, t_pow_c5
    call .imprimir

    ; 2^31 → overflow, CF=1
    mov edi, 2
    mov esi, 31
    call lib_math_pow_int32cval
    jnc .pow_c6_fail
    cmp eax, 0
    call .registrar
    jmp .pow_c6_done
.pow_c6_fail:
    call .forzar_fallo
.pow_c6_done:
    mov rdi, t_pow_c6
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

.registrar:
    setnz r15b
    test  r15b, r15b
    jz    .reg_ret
    inc   dword [fallos]
.reg_ret:
    ret

.forzar_fallo:
    mov  r15b, 1
    inc  dword [fallos]
    ret

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






