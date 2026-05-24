; ==============================================================================
; RUTA: ./comandos/monitor/draw_rect/draw_rect.asm
; CORRECCIÓN: 
;   - Carry Flag en lib_string_int32cval y lib_draw_rectcval.
;   - Añadido flag --tics para medir ticks de CPU del dibujado.
; ==============================================================================

%include "lib/constants.inc"
%include "lib/sys_macros.inc"
%include "lib/graph/core/lib_fb_core.inc"

default rel

extern fb_core, fb_map
extern lib_draw_rectcval
extern lib_string_int32cval
extern lib_color_pack
extern lib_rdtsc_init, lib_rdtsc_start, lib_rdtsc_stop, lib_rdtsc_method
extern print_string, print_nl, print_int

section .bss
    datos_fb  resb ScreenInfo_size
    coord_x   resd 1
    coord_y   resd 1
    width     resd 1
    height    resd 1
    color     resd 1
    flag_tics resb 1
    ticks_val resq 1

section .data
    msg_ayuda_1  db "Uso: draw_rect [X] [Y] [W] [H] [COLOR] [--tics]", 10, 0
    msg_ayuda_2  db "Descripcion: Dibuja un rectangulo solido con recorte inteligente (Clipping).", 10, 10, 0
    msg_ayuda_3  db "Argumentos:", 10, 0
    msg_ayuda_x  db "  X       Coordenada horizontal origen (Acepta negativos).", 10, 0
    msg_ayuda_y  db "  Y       Coordenada vertical origen   (Acepta negativos).", 10, 0
    msg_ayuda_w  db "  W       Ancho del rectangulo (Max visible: ", 0
    msg_ayuda_h  db "  H       Alto del rectangulo  (Max visible: ", 0
    msg_cierre   db ").", 10, 0
    msg_req_sudo db "Limite real requiere sudo).", 10, 0
    msg_ayuda_c  db "  COLOR   Valor del color (Soporta multiples bases numericas).", 10, 0
    msg_ayuda_t  db "  --tics  Ticks de CPU consumidos por el dibujado.", 10, 0
    msg_ayuda_hf db "  -h      Muestra este panel de ayuda dinamico.", 10, 10, 0
    msg_ayuda_ej db "Ejemplos desde Bash:", 10, 0
    msg_ayuda_e1 db "  draw_rect 0 0 1280 800 0xFF0000          ; Limpiar pantalla en rojo", 10, 0
    msg_ayuda_e2 db "  draw_rect -50 -50 200 200 0x00FF00       ; Cuadrado recortado", 10, 0
    msg_ayuda_e3 db "  draw_rect 0 0 1280 800 0x000000 --tics   ; Con medicion", 10, 0

    msg_error_args   db "Error: Numero de argumentos incorrecto. Usa '-h' para ayuda.", 10, 0
    msg_error_numero db "Error: Argumento no es un numero valido.", 10, 0
    msg_error_fb     db "Error: No se pudo inicializar /dev/fb0.", 10, 0
    msg_error_fuera  db "Error: Rectangulo totalmente fuera de los limites de la pantalla.", 10, 0
    msg_exito        db "Rectangulo procesado correctamente.", 10, 0
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
    mov dword [coord_x], eax

    mov rdi, [rbp + 24]
    call lib_string_int32cval
    jc .error_numero
    mov dword [coord_y], eax

    mov rdi, [rbp + 32]
    call lib_string_int32cval
    jc .error_numero
    mov dword [width], eax

    mov rdi, [rbp + 40]
    call lib_string_int32cval
    jc .error_numero
    mov dword [height], eax

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
    mov esi, dword [coord_x]
    mov edx, dword [coord_y]
    mov ecx, dword [width]
    mov r8d, dword [height]
    mov r9d, dword [color]
    call lib_draw_rectcval
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
    mov rdi, datos_fb
    call fb_core
    mov r15, rax
    mov rdi, msg_ayuda_1
    call print_string
    mov rdi, msg_ayuda_2
    call print_string
    mov rdi, msg_ayuda_3
    call print_string
    mov rdi, msg_ayuda_x
    call print_string
    mov rdi, msg_ayuda_y
    call print_string
    mov rdi, msg_ayuda_w
    call print_string
    test r15, r15
    js .sin_sudo_w
    mov edi, dword [datos_fb + ScreenInfo.width]
    call print_int
    mov rdi, msg_cierre
    call print_string
    jmp .ayuda_eje_h
.sin_sudo_w:
    mov rdi, msg_req_sudo
    call print_string
.ayuda_eje_h:
    mov rdi, msg_ayuda_h
    call print_string
    test r15, r15
    js .sin_sudo_h
    mov edi, dword [datos_fb + ScreenInfo.height]
    call print_int
    mov rdi, msg_cierre
    call print_string
    jmp .resto_ayuda
.sin_sudo_h:
    mov rdi, msg_req_sudo
    call print_string
.resto_ayuda:
    mov rdi, msg_ayuda_c
    call print_string
    mov rdi, msg_ayuda_t
    call print_string
    mov rdi, msg_ayuda_hf
    call print_string
    mov rdi, msg_ayuda_ej
    call print_string
    mov rdi, msg_ayuda_e1
    call print_string
    mov rdi, msg_ayuda_e2
    call print_string
    mov rdi, msg_ayuda_e3
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
