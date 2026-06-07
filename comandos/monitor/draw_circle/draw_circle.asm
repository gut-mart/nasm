; ==============================================================================
; RUTA: ./comandos/monitor/draw_circle/draw_circle.asm
; DESCRIPCIÓN: Dibuja un círculo dado su centro y radio.
;              Usa Bresenham (punto medio) con clipping. Círculos totalmente
;              fuera de pantalla se ignoran silenciosamente.
;              Eliminado flag --tics: usar bench_rect para mediciones de CPU.
; ==============================================================================

%include "lib/constants.inc"
%include "lib/sys_macros.inc"
%include "lib/graph/core/lib_fb_core.inc"

default rel

extern fb_core, fb_map
extern lib_draw_circlecval
extern lib_string_int32cval
extern lib_color_pack
extern print_string, print_nl, print_int

section .bss
    datos_fb resb ScreenInfo_size
    centro_x resd 1
    centro_y resd 1
    radio    resd 1
    color    resd 1

section .data
    msg_ayuda_1 db "Uso: draw_circle [CX] [CY] [RADIO] [COLOR]", 10, 0
    msg_ayuda_2 db "Descripcion: Dibuja un circulo (Bresenham + clipping).", 10, 10, 0
    msg_ayuda_3 db "Argumentos:", 10, 0
    msg_ayuda_4 db "  CX      Coordenada X del centro (acepta negativos).", 10, 0
    msg_ayuda_5 db "  CY      Coordenada Y del centro (acepta negativos).", 10, 0
    msg_ayuda_6 db "  RADIO   Radio en pixeles (positivo).", 10, 0
    msg_ayuda_7 db "  COLOR   Valor del color (soporta multiples bases numericas).", 10, 0
    msg_ayuda_8 db "  -h      Muestra este panel de ayuda.", 10, 10, 0
    msg_ayuda_9 db "Nota: el circulo se recorta si sale de pantalla.", 10, 0
    msg_ayuda_A db "      Si queda totalmente fuera, se ignora (exit 0).", 10, 10, 0
    msg_ayuda_B db "Ejemplos:", 10, 0
    msg_ayuda_C db "  draw_circle 640 400 200 0xFFFFFF   ; Circulo blanco centrado", 10, 0
    msg_ayuda_D db "  draw_circle 0 0 300 0xFF0000       ; Recortado en la esquina", 10, 0

    msg_error_args db "Error: Numero de argumentos incorrecto. Usa '-h' para ayuda.", 10, 0
    msg_error_num  db "Error: Argumento no es un numero valido.", 10, 0
    msg_error_fb   db "Error: No se pudo inicializar /dev/fb0.", 10, 0
    msg_exito      db "Circulo dibujado correctamente.", 10, 0

section .text
    global _start

_start:
    mov rbp, rsp
    and rsp, -16

    mov rbx, [rbp]          ; argc
    mov r12, [rbp + 16]     ; argv[1]

    ; --- Comprobar -h ---
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
    jne .error_args

    ; --- Convertir argumentos ---
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
    mov esi, dword [centro_x]
    mov edx, dword [centro_y]
    mov ecx, dword [radio]
    mov r8d, dword [color]
    call lib_draw_circlecval
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
