; ==============================================================================
; RUTA: ./comandos/tests/string_int32/string_int32.asm
; DESCRIPCIÓN: Test unitario de lib/cnv/string_int32 (conversión string → int32).
;              Prueba la capa fast (cadenas válidas) y la capa cval (validación
;              de caracteres y de rango por valor, contrato CF).
;              Imprime OK/FAIL por cada caso. Devuelve exit 0 si todos pasan,
;              exit 1 si alguno falla. No requiere framebuffer ni sudo.
; USO:
;   make SRC=comandos/tests/string_int32/string_int32.asm
;   ./bin/string_int32
; ==============================================================================

%include "lib/constants.inc"
%include "lib/sys_macros.inc"

default rel

extern lib_string_int32fast
extern lib_string_int32cval
extern print_string, print_nl

section .data
    msg_ok      db "  OK    ", 0
    msg_fail    db "  FAIL  ", 0

    msg_sep_fast db "--- string_int32 (fast) ---", 10, 0
    msg_sep_cval db "--- string_int32 (cval) ---", 10, 0

    ; --- Cadenas de entrada ---
    s_42            db "42", 0
    s_neg42         db "-42", 0
    s_hexff         db "0xFF", 0
    s_bin1010       db "0b1010", 0
    s_oct17         db "0o17", 0
    s_cero          db "0", 0
    s_int32max      db "2147483647", 0
    s_int32min      db "-2147483648", 0
    s_hexmax        db "0xFFFFFFFF", 0
    s_hexceros      db "0x00000000FF", 0
    s_octmax        db "0o37777777777", 0
    s_hexmin        db "-0x80000000", 0
    s_dec_ovf1      db "2147483648", 0
    s_dec_ovf2      db "4294967295", 0
    s_dec_ovf3      db "5000000000", 0
    s_oct_ovf       db "0o77777777777", 0
    s_neg_ovf       db "-2147483649", 0
    s_neghex_ovf    db "-0xFFFFFFFF", 0
    s_letras        db "abc", 0
    s_vacia         db "", 0
    s_solo_signo    db "-", 0
    s_solo_prefijo  db "0x", 0
    s_prefijo_d     db "0d", 0
    s_mezcla        db "12a3", 0

    ; --- Descripciones: fast ---
    t_f1 db 'cnv("42")            = 42', 0
    t_f2 db 'cnv("-42")           = -42', 0
    t_f3 db 'cnv("0xFF")          = 255', 0
    t_f4 db 'cnv("0b1010")        = 10', 0
    t_f5 db 'cnv("0o17")          = 15', 0
    t_f6 db 'cnv("0")             = 0', 0

    ; --- Descripciones: cval válidos ---
    t_c1 db 'cnv("42")            CF=0, EAX=42', 0
    t_c2 db 'cnv("-42")           CF=0, EAX=-42', 0
    t_c3 db 'cnv("2147483647")    CF=0, EAX=INT32_MAX', 0
    t_c4 db 'cnv("-2147483648")   CF=0, EAX=INT32_MIN', 0
    t_c5 db 'cnv("0xFFFFFFFF")    CF=0, EAX=-1 (patron de bits)', 0
    t_c6 db 'cnv("0x00000000FF")  CF=0, EAX=255 (ceros a la izq.)', 0
    t_c7 db 'cnv("0o37777777777") CF=0, EAX=-1 (octal maximo)', 0
    t_c8 db 'cnv("-0x80000000")   CF=0, EAX=INT32_MIN', 0

    ; --- Descripciones: cval errores ---
    t_e1  db 'cnv("2147483648")    CF=1 (decimal > INT32_MAX)', 0
    t_e2  db 'cnv("4294967295")    CF=1 (decimal > INT32_MAX)', 0
    t_e3  db 'cnv("5000000000")    CF=1 (no cabe en 32 bits)', 0
    t_e4  db 'cnv("0o77777777777") CF=1 (octal > 32 bits)', 0
    t_e5  db 'cnv("-2147483649")   CF=1 (magnitud > |INT32_MIN|)', 0
    t_e6  db 'cnv("-0xFFFFFFFF")   CF=1 (magnitud > |INT32_MIN|)', 0
    t_e7  db 'cnv("abc")           CF=1 (no numerico)', 0
    t_e8  db 'cnv("")              CF=1 (cadena vacia)', 0
    t_e9  db 'cnv("-")             CF=1 (solo signo)', 0
    t_e10 db 'cnv("0x")            CF=1 (prefijo sin digitos)', 0
    t_e11 db 'cnv("0d")            CF=1 (prefijo sin digitos)', 0
    t_e12 db 'cnv("12a3")          CF=1 (caracter invalido)', 0

section .bss
    fallos resd 1

section .text
    global _start

_start:
    mov rbp, rsp
    and rsp, -16
    mov dword [fallos], 0

    ; =========================================================================
    ; FAST — cadenas ya válidas, solo se comprueba el valor
    ; =========================================================================
    mov rdi, msg_sep_fast
    call print_string

    mov rdi, s_42
    call lib_string_int32fast
    cmp eax, 42
    call .registrar
    mov rdi, t_f1
    call .imprimir

    mov rdi, s_neg42
    call lib_string_int32fast
    cmp eax, -42
    call .registrar
    mov rdi, t_f2
    call .imprimir

    mov rdi, s_hexff
    call lib_string_int32fast
    cmp eax, 255
    call .registrar
    mov rdi, t_f3
    call .imprimir

    mov rdi, s_bin1010
    call lib_string_int32fast
    cmp eax, 10
    call .registrar
    mov rdi, t_f4
    call .imprimir

    mov rdi, s_oct17
    call lib_string_int32fast
    cmp eax, 15
    call .registrar
    mov rdi, t_f5
    call .imprimir

    mov rdi, s_cero
    call lib_string_int32fast
    cmp eax, 0
    call .registrar
    mov rdi, t_f6
    call .imprimir

    ; =========================================================================
    ; CVAL — casos válidos (CF=0 y valor correcto)
    ; =========================================================================
    mov rdi, msg_sep_cval
    call print_string

    mov rdi, s_42
    call lib_string_int32cval
    jc .c1_fail
    cmp eax, 42
    call .registrar
    jmp .c1_done
.c1_fail:
    call .forzar_fallo
.c1_done:
    mov rdi, t_c1
    call .imprimir

    mov rdi, s_neg42
    call lib_string_int32cval
    jc .c2_fail
    cmp eax, -42
    call .registrar
    jmp .c2_done
.c2_fail:
    call .forzar_fallo
.c2_done:
    mov rdi, t_c2
    call .imprimir

    mov rdi, s_int32max
    call lib_string_int32cval
    jc .c3_fail
    cmp eax, 0x7FFFFFFF
    call .registrar
    jmp .c3_done
.c3_fail:
    call .forzar_fallo
.c3_done:
    mov rdi, t_c3
    call .imprimir

    mov rdi, s_int32min
    call lib_string_int32cval
    jc .c4_fail
    cmp eax, 0x80000000
    call .registrar
    jmp .c4_done
.c4_fail:
    call .forzar_fallo
.c4_done:
    mov rdi, t_c4
    call .imprimir

    ; 0xFFFFFFFF es un patrón de bits válido: equivale a -1 en int32
    mov rdi, s_hexmax
    call lib_string_int32cval
    jc .c5_fail
    cmp eax, -1
    call .registrar
    jmp .c5_done
.c5_fail:
    call .forzar_fallo
.c5_done:
    mov rdi, t_c5
    call .imprimir

    ; Los ceros a la izquierda no cuentan para el rango
    mov rdi, s_hexceros
    call lib_string_int32cval
    jc .c6_fail
    cmp eax, 255
    call .registrar
    jmp .c6_done
.c6_fail:
    call .forzar_fallo
.c6_done:
    mov rdi, t_c6
    call .imprimir

    ; Octal máximo representable en 32 bits: 0o37777777777 = 0xFFFFFFFF
    mov rdi, s_octmax
    call lib_string_int32cval
    jc .c7_fail
    cmp eax, -1
    call .registrar
    jmp .c7_done
.c7_fail:
    call .forzar_fallo
.c7_done:
    mov rdi, t_c7
    call .imprimir

    ; Negativo en base hex: magnitud justa |INT32_MIN|
    mov rdi, s_hexmin
    call lib_string_int32cval
    jc .c8_fail
    cmp eax, 0x80000000
    call .registrar
    jmp .c8_done
.c8_fail:
    call .forzar_fallo
.c8_done:
    mov rdi, t_c8
    call .imprimir

    ; =========================================================================
    ; CVAL — casos de error (CF=1 y EAX=0)
    ; =========================================================================

    mov rdi, s_dec_ovf1
    call lib_string_int32cval
    jnc .e1_fail
    cmp eax, 0
    call .registrar
    jmp .e1_done
.e1_fail:
    call .forzar_fallo
.e1_done:
    mov rdi, t_e1
    call .imprimir

    mov rdi, s_dec_ovf2
    call lib_string_int32cval
    jnc .e2_fail
    cmp eax, 0
    call .registrar
    jmp .e2_done
.e2_fail:
    call .forzar_fallo
.e2_done:
    mov rdi, t_e2
    call .imprimir

    mov rdi, s_dec_ovf3
    call lib_string_int32cval
    jnc .e3_fail
    cmp eax, 0
    call .registrar
    jmp .e3_done
.e3_fail:
    call .forzar_fallo
.e3_done:
    mov rdi, t_e3
    call .imprimir

    mov rdi, s_oct_ovf
    call lib_string_int32cval
    jnc .e4_fail
    cmp eax, 0
    call .registrar
    jmp .e4_done
.e4_fail:
    call .forzar_fallo
.e4_done:
    mov rdi, t_e4
    call .imprimir

    mov rdi, s_neg_ovf
    call lib_string_int32cval
    jnc .e5_fail
    cmp eax, 0
    call .registrar
    jmp .e5_done
.e5_fail:
    call .forzar_fallo
.e5_done:
    mov rdi, t_e5
    call .imprimir

    mov rdi, s_neghex_ovf
    call lib_string_int32cval
    jnc .e6_fail
    cmp eax, 0
    call .registrar
    jmp .e6_done
.e6_fail:
    call .forzar_fallo
.e6_done:
    mov rdi, t_e6
    call .imprimir

    mov rdi, s_letras
    call lib_string_int32cval
    jnc .e7_fail
    cmp eax, 0
    call .registrar
    jmp .e7_done
.e7_fail:
    call .forzar_fallo
.e7_done:
    mov rdi, t_e7
    call .imprimir

    mov rdi, s_vacia
    call lib_string_int32cval
    jnc .e8_fail
    cmp eax, 0
    call .registrar
    jmp .e8_done
.e8_fail:
    call .forzar_fallo
.e8_done:
    mov rdi, t_e8
    call .imprimir

    mov rdi, s_solo_signo
    call lib_string_int32cval
    jnc .e9_fail
    cmp eax, 0
    call .registrar
    jmp .e9_done
.e9_fail:
    call .forzar_fallo
.e9_done:
    mov rdi, t_e9
    call .imprimir

    mov rdi, s_solo_prefijo
    call lib_string_int32cval
    jnc .e10_fail
    cmp eax, 0
    call .registrar
    jmp .e10_done
.e10_fail:
    call .forzar_fallo
.e10_done:
    mov rdi, t_e10
    call .imprimir

    mov rdi, s_prefijo_d
    call lib_string_int32cval
    jnc .e11_fail
    cmp eax, 0
    call .registrar
    jmp .e11_done
.e11_fail:
    call .forzar_fallo
.e11_done:
    mov rdi, t_e11
    call .imprimir

    mov rdi, s_mezcla
    call lib_string_int32cval
    jnc .e12_fail
    cmp eax, 0
    call .registrar
    jmp .e12_done
.e12_fail:
    call .forzar_fallo
.e12_done:
    mov rdi, t_e12
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
