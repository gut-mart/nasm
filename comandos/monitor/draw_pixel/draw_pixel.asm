; ==============================================================================
; RUTA: ./comandos/monitor/draw_pixel/draw_pixel.asm
; DESCRIPCIÓN: Dibuja un píxel en el Framebuffer.
;              Coordenadas fuera de pantalla se ignoran silenciosamente (exit 0).
;              Eliminado flag --tics: usar bench_rect para mediciones de CPU.
; ==============================================================================

%include "lib/constants.inc"
%include "lib/sys_macros.inc"
%include "lib/graph/core/lib_fb_core.inc"

default rel

extern lib_color_pack
extern fb_core, fb_map
extern lib_draw_pixelcval
extern lib_string_int32cval
extern print_string, print_nl, print_int

section .bss
    datos_fb resb ScreenInfo_size
    coord_x  resd 1
    coord_y  resd 1
    color    resd 1

section .data
    msg_ayuda_1 db "Uso: draw_pixel [X] [Y] [COLOR]", 10, 0
    msg_ayuda_2 db "Descripcion: Dibuja un pixel en el Framebuffer.", 10, 10, 0
    msg_ayuda_3 db "Argumentos:", 10, 0
    msg_ayuda_4 db "  X       Coordenada horizontal. Acepta negativos (ignorado si fuera).", 10, 0
    msg_ayuda_5 db "  Y       Coordenada vertical.   Acepta negativos (ignorado si fuera).", 10, 0
    msg_ayuda_6 db "  COLOR   Valor del color (soporta multiples bases numericas).", 10, 0
    msg_ayuda_7 db "  -h      Muestra este panel de ayuda.", 10, 10, 0
    msg_ayuda_8 db "Formatos numericos soportados:", 10, 0
    msg_ayuda_9 db "  Decimal (por defecto) : 16711680", 10, 0
    msg_ayuda_A db "  Hexadecimal (0x)      : 0xFF0000 (Rojo puro)", 10, 0
    msg_ayuda_B db "  Binario (0b)          : 0b111111110000000000000000", 10, 0
    msg_ayuda_C db "  Octal (0o)            : 0o77600000", 10, 10, 0
    msg_ayuda_D db "Nota: coordenadas fuera de pantalla se ignoran (exit 0).", 10, 0
    msg_ayuda_E db "Ejemplos:", 10, 0
    msg_ayuda_F db "  draw_pixel 960 540 0xFF0000   ; Rojo en el centro", 10, 0
    msg_ayuda_G db "  draw_pixel -10 -10 0xFFFFFF  ; Ignorado silenciosamente", 10, 0

    msg_error_args   db "Error: Numero de argumentos incorrecto. Usa '-h'.", 10, 0
    msg_error_numero db "Error: Argumento no es un numero valido.", 10, 0
    msg_error_fb     db "Error: No se pudo inicializar /dev/fb0.", 10, 0
    msg_exito        db "Pixel dibujado correctamente.", 10, 0

section .text
    global _start

_start:
    mov rbp, rsp
    and rsp, -16

    mov rbx, [rbp]          ; argc
    mov r12, [rbp + 16]     ; argv[1]
    mov r13, [rbp + 24]     ; argv[2]
    mov r14, [rbp + 32]     ; argv[3]

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
    cmp rbx, 4
    jne .error_args

    ; --- Convertir argumentos ---
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

    ; --- Inicializar framebuffer ---
    mov rdi, datos_fb
    call fb_core
    cmp rax, 0
    jl .error_fb

    mov rdi, datos_fb
    call fb_map
    cmp rax, 0
    jl .error_fb

    ; --- Traducir color al formato nativo ---
    mov rdi, datos_fb
    mov esi, dword [color]
    call lib_color_pack
    mov dword [color], eax

    ; --- Dibujar (cval: fuera de pantalla → CF=1, ignorar silenciosamente) ---
    mov rdi, datos_fb
    mov esi, dword [coord_x]
    mov edx, dword [coord_y]
    mov ecx, dword [color]
    call lib_draw_pixelcval
    ; CF=1 significa fuera de pantalla → exit 0 silencioso (no es error)

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
