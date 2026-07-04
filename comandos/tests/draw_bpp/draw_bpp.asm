; ==============================================================================
; RUTA: ./comandos/tests/draw_bpp/draw_bpp.asm
; DESCRIPCIÓN: Test unitario de la escritura por bpp variable (16/24/32) de
;              lib_draw_pixelfast y lib_draw_rectfast, del empaquetado de
;              color por canales de lib_color_pack (identidad a 24/32 bpp,
;              RGB565 a 16 bpp), y del contrato CF de los cuatro cval
;              gráficos tras la migración a opción B.
;              Usa un framebuffer FALSO en memoria (8x4, pitch con padding),
;              relleno con sentinela 0xA5, y verifica byte a byte qué se
;              escribió y qué quedó intacto. No requiere framebuffer ni sudo.
;              La verificación VISUAL en hardware real sigue pendiente
;              (ver TODO.md), pero este test cubre offsets, tamaño de
;              escritura, no-solapamiento y salto de fila en los tres modos.
; USO:
;   make SRC=comandos/tests/draw_bpp/draw_bpp.asm
;   ./bin/draw_bpp
; ==============================================================================

%include "lib/constants.inc"
%include "lib/sys_macros.inc"
%include "lib/graph/core/lib_fb_core.inc"

default rel

extern lib_draw_pixelfast
extern lib_draw_rectfast
extern lib_draw_pixelcval
extern lib_draw_rectcval
extern lib_draw_linecval
extern lib_draw_circlecval
extern lib_color_pack
extern print_string, print_nl

; --- Pantalla falsa: 8x4 píxeles, pitch = fila + 4 bytes de padding ---
%define ANCHO      8
%define ALTO       4
%define PITCH32    36                  ; 8*4 + 4
%define PITCH24    28                  ; 8*3 + 4
%define PITCH16    20                  ; 8*2 + 4
%define SENTINELA  0xA5

section .data
    msg_ok      db "  OK    ", 0
    msg_fail    db "  FAIL  ", 0

    msg_sep_fast db "--- draw fast (escritura por bpp) ---", 10, 0
    msg_sep_pack db "--- color_pack (canales por modo) ---", 10, 0
    msg_sep_cval db "--- draw cval (contrato CF, opcion B) ---", 10, 0

    ; Patrones esperados en memoria (little-endian, byte a byte)
    patron_rect32 db 0x44, 0x33, 0x22, 0x11, 0x44, 0x33, 0x22, 0x11
    patron_rect24 db 0xAA, 0xBB, 0xCC, 0xAA, 0xBB, 0xCC
    patron_rect16 db 0xEF, 0xBE, 0xEF, 0xBE

    ; --- Descripciones: fast ---
    t_f1  db 'pixel 32bpp: dword en offset Y*pitch + X*4', 0
    t_f2  db 'pixel 32bpp: bytes vecinos intactos', 0
    t_f3  db 'pixel 24bpp: 3 bytes (B,G,R) en offset X*3', 0
    t_f4  db 'pixel 24bpp: el 4o byte NO se solapa', 0
    t_f5  db 'pixel 16bpp: 2 bytes bajos en offset X*2', 0
    t_f6  db 'pixel 16bpp: el 3er byte NO se toca', 0
    t_f7  db 'rect 32bpp 2x2: fila 1 correcta', 0
    t_f8  db 'rect 32bpp 2x2: fila 2 correcta (salto con padding)', 0
    t_f9  db 'rect 32bpp: nada escrito fuera del area', 0
    t_f10 db 'rect 24bpp 2x2: fila 1 correcta (3 bytes/pixel)', 0
    t_f11 db 'rect 24bpp 2x2: fila 2 correcta (salto con padding)', 0
    t_f12 db 'rect 24bpp: bordes sin solapar', 0
    t_f13 db 'rect 16bpp 2x2: fila 1 correcta (2 bytes/pixel)', 0
    t_f14 db 'rect 16bpp 2x2: fila 2 correcta (salto con padding)', 0
    t_f15 db 'rect 16bpp: bordes sin solapar', 0

    ; --- Descripciones: color_pack ---
    t_p1 db 'pack 32bpp: 0x112233 identidad', 0
    t_p2 db 'pack 24bpp: 0xABCDEF identidad', 0
    t_p3 db 'pack 16bpp: blanco 0xFFFFFF -> 0xFFFF', 0
    t_p4 db 'pack 16bpp: rojo 0xFF0000 -> 0xF800 (RGB565)', 0
    t_p5 db 'pack 16bpp: 0xFF8040 -> 0xFC08 (trunca 8->5/6/5)', 0
    t_p6 db 'pack+pixel 16bpp: verde 0x00FF00 -> word 0x07E0', 0

    ; --- Descripciones: cval (CF) ---
    t_c1 db 'pixelcval dentro   CF=0', 0
    t_c2 db 'pixelcval fuera    CF=1', 0
    t_c3 db 'rectcval dentro    CF=0', 0
    t_c4 db 'rectcval fuera     CF=1', 0
    t_c5 db 'linecval dentro    CF=0', 0
    t_c6 db 'linecval fuera     CF=1', 0
    t_c7 db 'circlecval dentro  CF=0', 0
    t_c8 db 'circlecval fuera   CF=1', 0

section .bss
    fallos resd 1
    sinfo  resb ScreenInfo_size
    fbuf   resb 256                    ; máximo necesario: ALTO*PITCH32 = 144

section .text
    global _start

_start:
    mov rbp, rsp
    and rsp, -16
    mov dword [fallos], 0

    ; =========================================================================
    ; FAST — escritura por bpp sobre el framebuffer falso
    ; =========================================================================
    mov rdi, msg_sep_fast
    call print_string

    ; --- pixel a 32 bpp: (2,1) color 0xAABBCCDD → offset 36+8 = 44 ---
    mov edi, 32
    mov esi, PITCH32
    call .preparar

    lea rdi, [sinfo]
    mov esi, 2
    mov edx, 1
    mov ecx, 0xAABBCCDD
    call lib_draw_pixelfast

    cmp dword [fbuf + 44], 0xAABBCCDD
    call .registrar
    mov rdi, t_f1
    call .imprimir

    movzx eax, byte [fbuf + 43]        ; byte anterior al píxel
    xor   eax, SENTINELA
    movzx edx, byte [fbuf + 48]        ; byte posterior al píxel
    xor   edx, SENTINELA
    or    eax, edx
    call .registrar
    mov rdi, t_f2
    call .imprimir

    ; --- pixel a 24 bpp: (2,1) color 0x00CCBBAA → offset 28+6 = 34 ---
    mov edi, 24
    mov esi, PITCH24
    call .preparar

    lea rdi, [sinfo]
    mov esi, 2
    mov edx, 1
    mov ecx, 0x00CCBBAA
    call lib_draw_pixelfast

    movzx eax, byte [fbuf + 34]        ; B
    xor   eax, 0xAA
    movzx edx, byte [fbuf + 35]        ; G
    xor   edx, 0xBB
    or    eax, edx
    movzx edx, byte [fbuf + 36]        ; R
    xor   edx, 0xCC
    or    eax, edx
    call .registrar
    mov rdi, t_f3
    call .imprimir

    movzx eax, byte [fbuf + 37]        ; 4o byte: píxel vecino, debe seguir intacto
    xor   eax, SENTINELA
    movzx edx, byte [fbuf + 33]        ; byte anterior al píxel
    xor   edx, SENTINELA
    or    eax, edx
    call .registrar
    mov rdi, t_f4
    call .imprimir

    ; --- pixel a 16 bpp: (2,1) color 0x0000BEEF → offset 20+4 = 24 ---
    mov edi, 16
    mov esi, PITCH16
    call .preparar

    lea rdi, [sinfo]
    mov esi, 2
    mov edx, 1
    mov ecx, 0x0000BEEF
    call lib_draw_pixelfast

    cmp word [fbuf + 24], 0xBEEF
    call .registrar
    mov rdi, t_f5
    call .imprimir

    movzx eax, byte [fbuf + 26]        ; 3er byte: píxel vecino
    xor   eax, SENTINELA
    movzx edx, byte [fbuf + 23]        ; byte anterior al píxel
    xor   edx, SENTINELA
    or    eax, edx
    call .registrar
    mov rdi, t_f6
    call .imprimir

    ; --- rect a 32 bpp: (1,1) 2x2 color 0x11223344 ---
    mov edi, 32
    mov esi, PITCH32
    call .preparar

    lea rdi, [sinfo]
    mov esi, 1
    mov edx, 1
    mov ecx, 2
    mov r8d, 2
    mov r9d, 0x11223344
    call lib_draw_rectfast

    lea rsi, [fbuf + 40]               ; fila 1 (base 36), columna 1
    lea rdi, [patron_rect32]
    mov ecx, 8
    repe cmpsb                         ; ZF=1 si los 8 bytes coinciden
    call .registrar
    mov rdi, t_f7
    call .imprimir

    lea rsi, [fbuf + 76]               ; fila 2 (base 72), columna 1
    lea rdi, [patron_rect32]
    mov ecx, 8
    repe cmpsb
    call .registrar
    mov rdi, t_f8
    call .imprimir

    movzx eax, byte [fbuf + 39]        ; último byte de la columna 0
    xor   eax, SENTINELA
    movzx edx, byte [fbuf + 48]        ; primer byte de la columna 3
    xor   edx, SENTINELA
    or    eax, edx
    movzx edx, byte [fbuf + 112]       ; columna 1 de la fila 3 (no dibujada)
    xor   edx, SENTINELA
    or    eax, edx
    call .registrar
    mov rdi, t_f9
    call .imprimir

    ; --- rect a 24 bpp: (1,1) 2x2 color 0x00CCBBAA ---
    mov edi, 24
    mov esi, PITCH24
    call .preparar

    lea rdi, [sinfo]
    mov esi, 1
    mov edx, 1
    mov ecx, 2
    mov r8d, 2
    mov r9d, 0x00CCBBAA
    call lib_draw_rectfast

    lea rsi, [fbuf + 31]               ; fila 1 (base 28), columna 1
    lea rdi, [patron_rect24]
    mov ecx, 6
    repe cmpsb
    call .registrar
    mov rdi, t_f10
    call .imprimir

    lea rsi, [fbuf + 59]               ; fila 2 (base 56), columna 1
    lea rdi, [patron_rect24]
    mov ecx, 6
    repe cmpsb
    call .registrar
    mov rdi, t_f11
    call .imprimir

    movzx eax, byte [fbuf + 30]        ; último byte de la columna 0
    xor   eax, SENTINELA
    movzx edx, byte [fbuf + 37]        ; primer byte de la columna 3
    xor   edx, SENTINELA
    or    eax, edx
    movzx edx, byte [fbuf + 65]        ; columna 3 de la fila 2
    xor   edx, SENTINELA
    or    eax, edx
    call .registrar
    mov rdi, t_f12
    call .imprimir

    ; --- rect a 16 bpp: (1,1) 2x2 color 0x0000BEEF ---
    mov edi, 16
    mov esi, PITCH16
    call .preparar

    lea rdi, [sinfo]
    mov esi, 1
    mov edx, 1
    mov ecx, 2
    mov r8d, 2
    mov r9d, 0x0000BEEF
    call lib_draw_rectfast

    lea rsi, [fbuf + 22]               ; fila 1 (base 20), columna 1
    lea rdi, [patron_rect16]
    mov ecx, 4
    repe cmpsb
    call .registrar
    mov rdi, t_f13
    call .imprimir

    lea rsi, [fbuf + 42]               ; fila 2 (base 40), columna 1
    lea rdi, [patron_rect16]
    mov ecx, 4
    repe cmpsb
    call .registrar
    mov rdi, t_f14
    call .imprimir

    movzx eax, byte [fbuf + 21]        ; último byte de la columna 0
    xor   eax, SENTINELA
    movzx edx, byte [fbuf + 26]        ; primer byte de la columna 3
    xor   edx, SENTINELA
    or    eax, edx
    movzx edx, byte [fbuf + 46]        ; columna 3 de la fila 2
    xor   edx, SENTINELA
    or    eax, edx
    call .registrar
    mov rdi, t_f15
    call .imprimir

    ; =========================================================================
    ; COLOR_PACK — empaquetado 0xRRGGBB → patrón nativo según canales del modo
    ; =========================================================================
    mov rdi, msg_sep_pack
    call print_string

    ; p1: a 32 bpp (canales de 8 bits) el empaquetado es la identidad
    mov edi, 32
    mov esi, PITCH32
    call .preparar
    lea rdi, [sinfo]
    mov esi, 0x00112233
    call lib_color_pack
    cmp eax, 0x00112233
    call .registrar
    mov rdi, t_p1
    call .imprimir

    ; p2: a 24 bpp (canales de 8 bits) también es la identidad
    mov edi, 24
    mov esi, PITCH24
    call .preparar
    lea rdi, [sinfo]
    mov esi, 0x00ABCDEF
    call lib_color_pack
    cmp eax, 0x00ABCDEF
    call .registrar
    mov rdi, t_p2
    call .imprimir

    ; p3: RGB565 — blanco satura los 16 bits
    mov edi, 16
    mov esi, PITCH16
    call .preparar
    lea rdi, [sinfo]
    mov esi, 0x00FFFFFF
    call lib_color_pack
    cmp eax, 0xFFFF
    call .registrar
    mov rdi, t_p3
    call .imprimir

    ; p4: RGB565 — rojo puro solo enciende los 5 bits altos
    lea rdi, [sinfo]
    mov esi, 0x00FF0000
    call lib_color_pack
    cmp eax, 0xF800
    call .registrar
    mov rdi, t_p4
    call .imprimir

    ; p5: RGB565 — truncado 8→5/6/5: R=FF→1F, G=80→20, B=40→08
    lea rdi, [sinfo]
    mov esi, 0x00FF8040
    call lib_color_pack
    cmp eax, 0xFC08
    call .registrar
    mov rdi, t_p5
    call .imprimir

    ; p6: integración pack → pixel a 16 bpp: verde puro = 0x07E0 en memoria
    lea rdi, [sinfo]
    mov esi, 0x0000FF00
    call lib_color_pack
    lea rdi, [sinfo]
    mov esi, 2
    mov edx, 1
    mov ecx, eax                       ; color ya empaquetado por color_pack
    call lib_draw_pixelfast
    cmp word [fbuf + 24], 0x07E0
    call .registrar
    mov rdi, t_p6
    call .imprimir

    ; =========================================================================
    ; CVAL — contrato CF tras la migración a opción B (call + clc + ret)
    ; =========================================================================
    mov rdi, msg_sep_cval
    call print_string

    mov edi, 32
    mov esi, PITCH32
    call .preparar

    ; c1: pixelcval dentro → CF=0
    lea rdi, [sinfo]
    mov esi, 2
    mov edx, 1
    mov ecx, 0x11223344
    call lib_draw_pixelcval
    setc al
    test al, al                        ; ZF=1 si CF=0
    call .registrar
    mov rdi, t_c1
    call .imprimir

    ; c2: pixelcval fuera → CF=1
    lea rdi, [sinfo]
    mov esi, 100
    mov edx, 1
    mov ecx, 0x11223344
    call lib_draw_pixelcval
    setc al
    cmp al, 1                          ; ZF=1 si CF=1
    call .registrar
    mov rdi, t_c2
    call .imprimir

    ; c3: rectcval dentro → CF=0
    lea rdi, [sinfo]
    mov esi, 1
    mov edx, 1
    mov ecx, 2
    mov r8d, 2
    mov r9d, 0x11223344
    call lib_draw_rectcval
    setc al
    test al, al
    call .registrar
    mov rdi, t_c3
    call .imprimir

    ; c4: rectcval fuera → CF=1
    lea rdi, [sinfo]
    mov esi, 100
    mov edx, 100
    mov ecx, 2
    mov r8d, 2
    mov r9d, 0x11223344
    call lib_draw_rectcval
    setc al
    cmp al, 1
    call .registrar
    mov rdi, t_c4
    call .imprimir

    ; c5: linecval dentro → CF=0
    lea rdi, [sinfo]
    xor esi, esi
    xor edx, edx
    mov ecx, 3
    mov r8d, 3
    mov r9d, 0x11223344
    call lib_draw_linecval
    setc al
    test al, al
    call .registrar
    mov rdi, t_c5
    call .imprimir

    ; c6: linecval fuera → CF=1
    lea rdi, [sinfo]
    mov esi, -10
    mov edx, -10
    mov ecx, -5
    mov r8d, -5
    mov r9d, 0x11223344
    call lib_draw_linecval
    setc al
    cmp al, 1
    call .registrar
    mov rdi, t_c6
    call .imprimir

    ; c7: circlecval dentro → CF=0
    lea rdi, [sinfo]
    mov esi, 4
    mov edx, 2
    mov ecx, 1
    mov r8d, 0x11223344
    call lib_draw_circlecval
    setc al
    test al, al
    call .registrar
    mov rdi, t_c7
    call .imprimir

    ; c8: circlecval fuera → CF=1
    lea rdi, [sinfo]
    mov esi, 100
    mov edx, 100
    mov ecx, 2
    mov r8d, 0x11223344
    call lib_draw_circlecval
    setc al
    cmp al, 1
    call .registrar
    mov rdi, t_c8
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

; .preparar — configura sinfo (incluidos canales por modo) y rellena fbuf
;             con la sentinela.
; ENTRADA: EDI = bpp, ESI = pitch
.preparar:
    mov dword [sinfo + ScreenInfo.width], ANCHO
    mov dword [sinfo + ScreenInfo.height], ALTO
    mov dword [sinfo + ScreenInfo.bpp], edi
    mov dword [sinfo + ScreenInfo.pitch], esi
    lea rax, [fbuf]
    mov qword [sinfo + ScreenInfo.ptr_mem], rax

    ; Canales según el modo: RGB565 a 16 bpp, XRGB8888/RGB888 en el resto
    cmp edi, 16
    je .prep_canales_565
    mov dword [sinfo + ScreenInfo.red_off], 16
    mov dword [sinfo + ScreenInfo.green_off], 8
    mov dword [sinfo + ScreenInfo.blue_off], 0
    mov dword [sinfo + ScreenInfo.red_len], 8
    mov dword [sinfo + ScreenInfo.green_len], 8
    mov dword [sinfo + ScreenInfo.blue_len], 8
    jmp .prep_canales_ok
.prep_canales_565:
    mov dword [sinfo + ScreenInfo.red_off], 11
    mov dword [sinfo + ScreenInfo.green_off], 5
    mov dword [sinfo + ScreenInfo.blue_off], 0
    mov dword [sinfo + ScreenInfo.red_len], 5
    mov dword [sinfo + ScreenInfo.green_len], 6
    mov dword [sinfo + ScreenInfo.blue_len], 5
.prep_canales_ok:
    mov dword [sinfo + ScreenInfo.transp_off], 0
    mov dword [sinfo + ScreenInfo.transp_len], 0
    mov ecx, 256
.prep_fill:
    mov byte [rax], SENTINELA
    inc rax
    dec ecx
    jnz .prep_fill
    ret

; .registrar — ZF=1 → pasa, ZF=0 → falla. Guarda el estado en R15B.
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
