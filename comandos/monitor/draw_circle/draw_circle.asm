; ==============================================================================
; RUTA: ./comandos/monitor/draw_circle/draw_circle.asm
; DESCRIPCIÓN: Dibuja un círculo en el Framebuffer dado su centro y radio.
;              Usa el algoritmo de Bresenham (punto medio) con clipping.
; CREADO: 2026-05-24
; ==============================================================================

%include "lib/constants.inc"
%include "lib/sys_macros.inc"
%include "lib/graph/core/lib_fb_core.inc"

default rel

extern fb_core, fb_map
extern lib_draw_circlecval
extern lib_string_int32cval
extern lib_color_pack
extern lib_rdtsc_init, lib_rdtsc_start, lib_rdtsc_stop, lib_rdtsc_method
extern print_string, print_nl, print_int

section .bss
    datos_fb  resb ScreenInfo_size
    centro_x  resd 1
    centro_y  resd 1
    radio     resd 1
    color     resd 1
    flag_tics resb 1
    ticks_val resq 1        ; guardar ticks antes de llamar a print

section .data
    msg_ayuda_1 db "Uso: draw_circle [CX] [CY] [RADIO] [COLOR] [--tics]", 10, 0
    msg_ayuda_2 db "Descripcion: Dibuja un circulo (Bresenham + clipping).", 10, 10, 0
    msg_ayuda_3 db "Argumentos:", 10, 0
    msg_ayuda_4 db "  CX      Coordenada X del centro (acepta negativos).", 10, 0
    msg_ayuda_5 db "  CY      Coordenada Y del centro (acepta negativos).", 10, 0
    msg_ayuda_6 db "  RADIO   Radio en pixeles (positivo).", 10, 0
    msg_ayuda_7 db "  COLOR   Valor del color (soporta multiples bases numericas).", 10, 0
    msg_ayuda_8 db "  --tics  Ticks de CPU consumidos por el dibujado.", 10, 0
    msg_ayuda_9 db "  -h      Muestra este panel de ayuda.", 10, 10, 0
    msg_ayuda_A db "Ejemplos:", 10, 0
    msg_ayuda_B db "  draw_circle 640 400 200 0xFFFFFF         ; Circulo blanco", 10, 0
    msg_ayuda_C db "  draw_circle 640 400 200 0xFFFFFF --tics  ; Con medicion", 10, 0
    msg_ayuda_D db "  draw_circle 0 0 300 0xFF0000             ; Recortado en esquina", 10, 0

    msg_error_args  db "Error: Numero de argumentos incorrecto. Usa '-h' para ayuda.", 10, 0
    msg_error_num   db "Error: Argumento no es un numero valido.", 10, 0
    msg_error_fb    db "Error: No se pudo inicializar /dev/fb0.", 10, 0
    msg_error_fuera db "Error: El circulo esta completamente fuera de los limites.", 10, 0
    msg_exito       db "Circulo dibujado correctamente.", 10, 0
    msg_tics        db "Tics: ", 0
    msg_metodo_pre  db "  [", 0
    msg_metodo_post db "]", 10, 0

    str_tics        db "--tics", 0

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
    jne .verificar_args
    mov al, byte [r12]
    cmp al, '-'
    jne .error_args
    mov al, byte [r12+1]
    cmp al, 'h'
    je .modo_ayuda
    jmp .error_args

.verificar_args:
    cmp rbx, 5
    je .parsear
    cmp rbx, 6
    je .comprobar_tics
    jmp .error_args

.comprobar_tics:
    mov rdi, [rbp + 48]
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
    jc .error_num
    mov dword [centro_x], eax

    mov rdi, [rbp + 24]
    call lib_string_int32cval
    jc .error_num
    mov dword [centro_y], eax

    mov rdi, [rbp + 32]
    call lib_string_int32cval
    jc .error_num
    mov dword [radio], eax

    mov rdi, [rbp + 40]
    call lib_string_int32cval
    jc .error_num
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
    mov esi, dword [centro_x]
    mov edx, dword [centro_y]
    mov ecx, dword [radio]
    mov r8d, dword [color]
    call lib_draw_circlecval
    jc .error_fuera

    cmp byte [flag_tics], 1
    jne .exito

    ; Guardar ticks antes de cualquier call
    call lib_rdtsc_stop
    mov qword [ticks_val], rax

    mov rdi, msg_exito
    call print_string

    mov rdi, msg_tics
    call print_string
    mov rdi, qword [ticks_val]
    call print_int

    mov rdi, msg_metodo_pre
    call print_string
    call lib_rdtsc_method   ; RAX = puntero al string del método
    mov rdi, rax
    call print_string
    mov rdi, msg_metodo_post
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
    mov rdi, msg_ayuda_D
    call print_string
    sys_exit 0

.error_args:
    mov rdi, msg_error_args
    call print_string
    sys_exit 1

.error_num:
    mov rdi, msg_error_num
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
