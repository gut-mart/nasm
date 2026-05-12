; ==============================================================================
; RUTA: ./comandos/monitor/draw_line/draw_line.asm
; DESCRIPCIÓN: Dibuja una línea en el Framebuffer entre dos puntos dados.
;              Usa clipping Cohen-Sutherland y rasterización Bresenham.
; ==============================================================================

%include "lib/constants.inc"
%include "lib/sys_macros.inc"
%include "lib/graph/core/lib_fb_core.inc"

default rel

extern fb_core, fb_map
extern lib_draw_linecval
extern lib_string_int32cval
extern lib_color_pack
extern print_string, print_nl, print_int

section .bss
    datos_fb resb ScreenInfo_size
    coord_x1 resd 1
    coord_y1 resd 1
    coord_x2 resd 1
    coord_y2 resd 1
    color    resd 1

section .data
    ; --- TEXTOS DE AYUDA (-h) ---
    msg_ayuda_1 db "Uso: draw_line [X1] [Y1] [X2] [Y2] [COLOR]", 10, 0
    msg_ayuda_2 db "Descripcion: Dibuja una linea entre dos puntos (Bresenham + clipping).", 10, 10, 0
    msg_ayuda_3 db "Argumentos:", 10, 0
    msg_ayuda_4 db "  X1, Y1  Coordenadas del punto origen (aceptan negativos).", 10, 0
    msg_ayuda_5 db "  X2, Y2  Coordenadas del punto destino (aceptan negativos).", 10, 0
    msg_ayuda_6 db "  COLOR   Valor del color (soporta multiples bases numericas).", 10, 0
    msg_ayuda_7 db "  -h      Muestra este panel de ayuda.", 10, 10, 0
    msg_ayuda_8 db "Ejemplos desde Bash:", 10, 0
    msg_ayuda_9 db "  sudo ./bin/draw_line 0 0 1919 1079 0xFFFFFF   ; Diagonal blanca", 10, 0
    msg_ayuda_A db "  sudo ./bin/draw_line 960 0 960 1079 0xFF0000  ; Linea vertical roja", 10, 0
    msg_ayuda_B db "  sudo ./bin/draw_line -100 540 2000 540 0x00FF00 ; Horizontal recortada", 10, 0

    msg_error_args   db "Error: Numero de argumentos incorrecto. Usa '-h' para ayuda.", 10, 0
    msg_error_numero db "Error: Argumento no es un numero valido.", 10, 0
    msg_error_fb     db "Error: No se pudo inicializar /dev/fb0. ¿Ejecutaste con sudo?", 10, 0
    msg_error_fuera  db "Error: La linea esta completamente fuera de los limites.", 10, 0
    msg_exito        db "Linea dibujada correctamente.", 10, 0

section .text
    global _start

_start:
    ; --- Establecer frame de pila ANTES de leer args ---
    mov rbp, rsp
    and rsp, -16

    ; 1. Extraer argumentos — TODOS a través de RBP
    mov rbx, [rbp]          ; argc
    mov r12, [rbp + 16]     ; argv[1] (X1 o -h)

    ; 2. Comprobar si se pide ayuda
    cmp rbx, 2
    jne .verificar_argumentos

    mov al, byte [r12]
    cmp al, '-'
    jne .error_args
    mov al, byte [r12+1]
    cmp al, 'h'
    je .modo_ayuda
    jmp .error_args

.verificar_argumentos:
    ; Verificar 6 argumentos (comando + 5 parámetros)
    cmp rbx, 6
    jne .error_args

    ; --- 3. CONVERSIÓN CON VALIDACIÓN ---
    mov rdi, r12                ; argv[1] = X1
    call lib_string_int32cval
    jc .error_numero
    mov dword [coord_x1], eax

    mov rdi, [rbp + 24]         ; argv[2] = Y1
    call lib_string_int32cval
    jc .error_numero
    mov dword [coord_y1], eax

    mov rdi, [rbp + 32]         ; argv[3] = X2
    call lib_string_int32cval
    jc .error_numero
    mov dword [coord_x2], eax

    mov rdi, [rbp + 40]         ; argv[4] = Y2
    call lib_string_int32cval
    jc .error_numero
    mov dword [coord_y2], eax

    mov rdi, [rbp + 48]         ; argv[5] = Color
    call lib_string_int32cval
    jc .error_numero
    mov dword [color], eax

    ; --- 4. INICIALIZAR FRAMEBUFFER ---
    mov rdi, datos_fb
    call fb_core
    test rax, rax
    js .error_fb

    mov rdi, datos_fb
    call fb_map
    test rax, rax
    js .error_fb

    ; --- 5. TRADUCCIÓN AL HARDWARE NATIVO ---
    mov rdi, datos_fb
    mov esi, dword [color]
    call lib_color_pack
    mov dword [color], eax

    ; --- 6. DIBUJAR LÍNEA ---
    mov rdi, datos_fb
    mov esi, dword [coord_x1]
    mov edx, dword [coord_y1]
    mov ecx, dword [coord_x2]
    mov r8d, dword [coord_y2]
    mov r9d, dword [color]
    call lib_draw_linecval
    jc .error_fuera

    ; --- 7. ÉXITO ---
    mov rdi, msg_exito
    call print_string
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
    sys_exit 0

.error_args:
    mov rdi, msg_error_args
    call print_string
    sys_exit 1

.error_numero:
    mov rdi, msg_error_numero
    call print_string
    sys_exit 1

.error_fb:
    mov rdi, msg_error_fb
    call print_string
    sys_exit 1

.error_fuera:
    mov rdi, msg_error_fuera
    call print_string
    sys_exit 1