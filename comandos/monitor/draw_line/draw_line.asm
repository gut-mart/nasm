; ==============================================================================
; RUTA: ./comandos/monitor/draw_line/draw_line.asm
; DESCRIPCIÓN: Dibuja una línea en el Framebuffer entre dos puntos dados.
;              Usa clipping Cohen-Sutherland y rasterización Bresenham.
;              Añadido flag --tics para medir ticks de CPU del dibujado.
; ==============================================================================

%include "lib/constants.inc"
%include "lib/sys_macros.inc"
%include "lib/graph/core/lib_fb_core.inc"

default rel

extern fb_core, fb_map
extern lib_draw_linecval
extern lib_string_int32cval
extern lib_color_pack
extern lib_rdtsc_init, lib_rdtsc_start, lib_rdtsc_stop, lib_rdtsc_method
extern print_string, print_nl, print_int

section .bss
    datos_fb  resb ScreenInfo_size
    coord_x1  resd 1
    coord_y1  resd 1
    coord_x2  resd 1
    coord_y2  resd 1
    color     resd 1
    flag_tics resb 1
    ticks_val resq 1

section .data
    msg_ayuda_1 db "Uso: draw_line [X1] [Y1] [X2] [Y2] [COLOR] [--tics]", 10, 0
    msg_ayuda_2 db "Descripcion: Dibuja una linea entre dos puntos (Bresenham + clipping).", 10, 10, 0
    msg_ayuda_3 db "Argumentos:", 10, 0
    msg_ayuda_4 db "  X1, Y1  Coordenadas del punto origen (aceptan negativos).", 10, 0
    msg_ayuda_5 db "  X2, Y2  Coordenadas del punto destino (aceptan negativos).", 10, 0
    msg_ayuda_6 db "  COLOR   Valor del color (soporta multiples bases numericas).", 10, 0
    msg_ayuda_7 db "  --tics  Ticks de CPU consumidos por el dibujado.", 10, 0
    msg_ayuda_8 db "  -h      Muestra este panel de ayuda.", 10, 10, 0
    msg_ayuda_9 db "Ejemplos desde Bash:", 10, 0
    msg_ayuda_A db "  draw_line 0 0 1279 799 0xFFFFFF          ; Diagonal blanca", 10, 0
    msg_ayuda_B db "  draw_line 640 0 640 799 0xFF0000          ; Linea vertical roja", 10, 0
    msg_ayuda_C db "  draw_line 0 0 1279 799 0xFFFFFF --tics   ; Con medicion", 10, 0

    msg_error_args   db "Error: Numero de argumentos incorrecto. Usa '-h' para ayuda.", 10, 0
    msg_error_numero db "Error: Argumento no es un numero valido.", 10, 0
    msg_error_fb     db "Error: No se pudo inicializar /dev/fb0.", 10, 0
    msg_error_fuera  db "Error: La linea esta completamente fuera de los limites.", 10, 0
    msg_exito        db "Linea dibujada correctamente.", 10, 0
    msg_tics         db "Tics: ", 0
    msg_met_pre      db "  [", 0
    msg_met_post     db "]", 10, 0

    str_tics         db "--tics", 0

section .text
    global _start

_start:
    mov rbp, rsp
    and rsp, -16

    call lib_rdtsc_init

    mov rbx, [rbp]
    mov r12, [rbp + 16]

    mov byte [flag_tics], 0

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
    je .parsear
    cmp rbx, 7
    je .comprobar_tics
    jmp .error_args

.comprobar_tics:
    mov rdi, [rbp + 56]     ; argv[6]
    mov rsi, str_tics
.cmp_loop:
    mov al, byte [rdi]
    mov cl, byte [rsi]
    cmp al, cl
    jne .error_args
    test al, al
    jz .tics_ok
    inc rdi
    inc rsi
    jmp .cmp_loop
.tics_ok:
    mov byte [flag_tics], 1

.parsear:
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

    mov rdi, datos_fb
    call fb_core
    test rax, rax
    js .error_fb

    mov rdi, datos_fb
    call fb_map
    test rax, rax
    js .error_fb

    mov rdi, datos_fb
    mov esi, dword [color]
    call lib_color_pack
    mov dword [color], eax

    cmp byte [flag_tics], 1
    jne .dibujar
    call lib_rdtsc_start

.dibujar:
    mov rdi, datos_fb
    mov esi, dword [coord_x1]
    mov edx, dword [coord_y1]
    mov ecx, dword [coord_x2]
    mov r8d, dword [coord_y2]
    mov r9d, dword [color]
    call lib_draw_linecval
    jc .error_fuera

    cmp byte [flag_tics], 1
    jne .exito
    call lib_rdtsc_stop
    mov qword [ticks_val], rax
    mov rdi, msg_exito
    call print_string
    mov rdi, msg_tics
    call print_string
    mov rdi, qword [ticks_val]
    call print_int
    mov rdi, msg_met_pre
    call print_string
    call lib_rdtsc_method
    mov rdi, rax
    call print_string
    mov rdi, msg_met_post
    call print_string
    sys_exit 0

.exito:
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

.error_fuera:
    mov rdi, msg_error_fuera
    call print_string
    sys_exit 1
