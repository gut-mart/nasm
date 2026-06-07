; ==============================================================================
; RUTA: ./comandos/monitor/draw_line/draw_line.asm
; DESCRIPCIÓN: Dibuja una línea entre dos puntos con clipping Cohen-Sutherland
;              y rasterización Bresenham. Líneas totalmente fuera se ignoran.
;              Eliminado flag --tics: usar bench_rect para mediciones de CPU.
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
    msg_ayuda_1 db "Uso: draw_line [X1] [Y1] [X2] [Y2] [COLOR]", 10, 0
    msg_ayuda_2 db "Descripcion: Dibuja una linea entre dos puntos (Bresenham + clipping).", 10, 10, 0
    msg_ayuda_3 db "Argumentos:", 10, 0
    msg_ayuda_4 db "  X1, Y1  Coordenadas del punto origen (aceptan negativos).", 10, 0
    msg_ayuda_5 db "  X2, Y2  Coordenadas del punto destino (aceptan negativos).", 10, 0
    msg_ayuda_6 db "  COLOR   Valor del color (soporta multiples bases numericas).", 10, 0
    msg_ayuda_7 db "  -h      Muestra este panel de ayuda.", 10, 10, 0
    msg_ayuda_8 db "Nota: la linea se recorta si sale de pantalla.", 10, 0
    msg_ayuda_9 db "      Si queda totalmente fuera, se ignora (exit 0).", 10, 10, 0
    msg_ayuda_A db "Ejemplos:", 10, 0
    msg_ayuda_B db "  draw_line 0 0 1279 799 0xFFFFFF    ; Diagonal blanca", 10, 0
    msg_ayuda_C db "  draw_line 640 0 640 799 0xFF0000   ; Linea vertical roja", 10, 0

    msg_error_args   db "Error: Numero de argumentos incorrecto. Usa '-h' para ayuda.", 10, 0
    msg_error_numero db "Error: Argumento no es un numero valido.", 10, 0
    msg_error_fb     db "Error: No se pudo inicializar /dev/fb0.", 10, 0
    msg_exito        db "Linea dibujada correctamente.", 10, 0

section .text
    global _start

_start:
    mov rbp, rsp
    and rsp, -16

    mov rbx, [rbp]          ; argc
    mov r12, [rbp + 16]     ; argv[1]

    ; --- Comprobar -h ---
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
    cmp rbx, 6
    jne .error_args

    ; --- Convertir argumentos ---
    mov rdi, r12
    call lib_string_int32cval
    jc .error_numero
    mov dword [coord_x1], eax

    mov rdi, [rbp + 24]
    call lib_string_int32cval
    jc .error_numero
    mov dword [coord_y1], eax

    mov rdi, [rbp + 32]
    call lib_string_int32cval
    jc .error_numero
    mov dword [coord_x2], eax

    mov rdi, [rbp + 40]
    call lib_string_int32cval
    jc .error_numero
    mov dword [coord_y2], eax

    mov rdi, [rbp + 48]
    call lib_string_int32cval
    jc .error_numero
    mov dword [color], eax

    ; --- Inicializar framebuffer ---
    mov rdi, datos_fb
    call fb_core
    test rax, rax
    js .error_fb

    mov rdi, datos_fb
    call fb_map
    test rax, rax
    js .error_fb

    ; --- Traducir color al formato nativo ---
    mov rdi, datos_fb
    mov esi, dword [color]
    call lib_color_pack
    mov dword [color], eax

    ; --- Dibujar (clipping: CF=1 si totalmente fuera → ignorar) ---
    mov rdi, datos_fb
    mov esi, dword [coord_x1]
    mov edx, dword [coord_y1]
    mov ecx, dword [coord_x2]
    mov r8d, dword [coord_y2]
    mov r9d, dword [color]
    call lib_draw_linecval
    ; CF=1 significa totalmente fuera → exit 0 silencioso

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
    mov rdi, msg_ayuda_C
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
