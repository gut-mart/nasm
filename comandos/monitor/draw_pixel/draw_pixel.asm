; ==============================================================================
; RUTA: ./comandos/monitor/draw_pixel/draw_pixel.asm
; CORRECCIÓN: 
;   - Tras cada llamada a lib_string_int32cval se comprueba el Carry Flag.
;   - Tras llamar a lib_draw_pixelcval se comprueba CF.
;   - Añadido flag --tics para medir ticks de CPU del dibujado.
; ==============================================================================

%include "lib/constants.inc"
%include "lib/sys_macros.inc"
%include "lib/graph/core/lib_fb_core.inc"

default rel

extern lib_color_pack
extern fb_core, fb_map
extern lib_draw_pixelcval
extern lib_string_int32cval
extern lib_rdtsc_init, lib_rdtsc_start, lib_rdtsc_stop, lib_rdtsc_method
extern print_string, print_nl, print_int

section .bss
    datos_fb  resb ScreenInfo_size
    coord_x   resd 1
    coord_y   resd 1
    color     resd 1
    flag_tics resb 1
    ticks_val resq 1

section .data
    msg_ayuda_1 db "Uso: draw_pixel [X] [Y] [COLOR] [--tics]", 10, 0
    msg_ayuda_2 db "Descripcion: Dibuja un pixel en el Framebuffer (Capa 1: con validacion).", 10, 10, 0
    msg_ayuda_3 db "Argumentos:", 10, 0
    msg_ayuda_4 db "  X       Coordenada horizontal (0 a ", 0
    msg_ayuda_5 db "  Y       Coordenada vertical   (0 a ", 0
    msg_cierre   db ").", 10, 0
    msg_req_sudo db "Limite real requiere sudo).", 10, 0
    msg_ayuda_6 db "  COLOR   Valor del color (Soporta multiples bases numericas).", 10, 0
    msg_ayuda_7 db "  --tics  Ticks de CPU consumidos por el dibujado.", 10, 0
    msg_ayuda_8 db "  -h      Muestra este panel de ayuda.", 10, 10, 0
    msg_ayuda_9 db "Formatos numericos soportados:", 10, 0
    msg_ayuda_A db "  Decimal (por defecto) : 16711680", 10, 0
    msg_ayuda_B db "  Hexadecimal (0x)      : 0xFF0000 (Rojo puro)", 10, 0
    msg_ayuda_C db "  Binario (0b)          : 0b111111110000000000000000", 10, 0
    msg_ayuda_D db "  Octal (0o)            : 0o77600000", 10, 10, 0
    msg_ayuda_E db "Ejemplos desde Bash:", 10, 0
    msg_ayuda_F db "  draw_pixel 960 540 0xFF0000         ; Rojo en el centro", 10, 0
    msg_ayuda_G db "  draw_pixel 960 540 0xFF0000 --tics  ; Con medicion", 10, 0

    msg_error_args   db "Error: Numero de argumentos incorrecto o formato invalido. Usa '-h'.", 10, 0
    msg_error_numero db "Error: Argumento no es un numero valido.", 10, 0
    msg_error_fb     db "Error: No se pudo inicializar /dev/fb0.", 10, 0
    msg_error_fuera  db "Error: Pixel fuera de los limites de la pantalla.", 10, 0
    msg_exito        db "Pixel dibujado correctamente (con validacion cval).", 10, 0
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
    mov r13, [rbp + 24]
    mov r14, [rbp + 32]

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
    cmp rbx, 4
    je .parsear
    cmp rbx, 5
    je .comprobar_tics
    jmp .error_args

.comprobar_tics:
    mov rdi, [rbp + 40]     ; argv[4]
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

    mov rdi, r13
    call lib_string_int32cval
    jc .error_numero
    mov dword [coord_y], eax

    mov rdi, r14
    call lib_string_int32cval
    jc .error_numero
    mov dword [color], eax

    mov rdi, datos_fb
    call fb_core
    cmp rax, 0
    jl .error_fb

    mov rdi, datos_fb
    call fb_map
    cmp rax, 0
    jl .error_fb

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
    mov ecx, dword [color]
    call lib_draw_pixelcval
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
    mov rdi, msg_ayuda_4
    call print_string
    cmp r15, 0
    jl .sin_sudo_x
    mov edi, dword [datos_fb + ScreenInfo.width]
    dec edi
    call print_int
    mov rdi, msg_cierre
    call print_string
    jmp .ayuda_eje_y
.sin_sudo_x:
    mov rdi, msg_req_sudo
    call print_string
.ayuda_eje_y:
    mov rdi, msg_ayuda_5
    call print_string
    cmp r15, 0
    jl .sin_sudo_y
    mov edi, dword [datos_fb + ScreenInfo.height]
    dec edi
    call print_int
    mov rdi, msg_cierre
    call print_string
    jmp .resto_ayuda
.sin_sudo_y:
    mov rdi, msg_req_sudo
    call print_string
.resto_ayuda:
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
