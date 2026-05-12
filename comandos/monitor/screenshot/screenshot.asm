; ==============================================================================
; RUTA: ./comandos/monitor/screenshot/screenshot.asm
; DESCRIPCIÓN: Captura el framebuffer actual y lo guarda como archivo BMP.
;              La extensión .bmp se añade automáticamente.
; USO: ./screenshot [NOMBRE] [RUTA]
;      ./screenshot captura /home/isidro/fotos
;      → genera /home/isidro/fotos/captura.bmp
; ==============================================================================

%include "lib/constants.inc"
%include "lib/sys_macros.inc"
%include "lib/graph/core/lib_fb_core.inc"

default rel

extern fb_core, fb_map
extern lib_bmp_write
extern print_string, print_int, print_nl

%define RUTA_MAX 512

section .bss
    datos_fb  resb ScreenInfo_size
    ruta_full resb RUTA_MAX

section .data
    msg_ayuda_1 db "Uso: screenshot [NOMBRE] [RUTA]", 10, 0
    msg_ayuda_2 db "Descripcion: Captura el framebuffer y lo guarda como BMP.", 10, 10, 0
    msg_ayuda_3 db "Argumentos:", 10, 0
    msg_ayuda_4 db "  NOMBRE   Nombre del archivo (sin extension).", 10, 0
    msg_ayuda_5 db "  RUTA     Directorio donde guardar el archivo.", 10, 0
    msg_ayuda_6 db "  -h       Muestra este panel de ayuda.", 10, 10, 0
    msg_ayuda_7 db "Ejemplo:", 10, 0
    msg_ayuda_8 db "  ./screenshot captura /home/isidro/fotos", 10, 0
    msg_ayuda_9 db "  -> genera /home/isidro/fotos/captura.bmp", 10, 10, 0
    msg_ayuda_A db "Resolucion actual: ", 0
    msg_ayuda_x db "x", 0
    msg_ayuda_B db " (requiere acceso a /dev/fb0)", 10, 0

    msg_ok_1    db "Captura guardada en: ", 0
    msg_ok_2    db 10, 0

    msg_error_args  db "Error: se requieren exactamente 2 argumentos. Usa '-h'.", 10, 0
    msg_error_fb    db "Error: no se pudo acceder a /dev/fb0.", 10, 0
    msg_error_bmp   db "Error: no se pudo escribir el archivo. ¿Existe la ruta?", 10, 0
    msg_error_largo db "Error: la ruta resultante supera el limite de 512 caracteres.", 10, 0

section .text
    global _start

_start:
    mov rbp, rsp
    and rsp, -16

    mov rbx, [rbp]
    mov r12, [rbp + 16]     ; argv[1]

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
    cmp rbx, 3
    jne .error_args

    mov r12, [rbp + 16]     ; NOMBRE
    mov r13, [rbp + 24]     ; RUTA

    ; --- Construir "RUTA/NOMBRE.bmp" en ruta_full ---
    lea rdi, [ruta_full]
    mov r15, rdi

    ; Copiar RUTA
    mov rsi, r13
.copiar_ruta:
    mov al, byte [rsi]
    test al, al
    jz .ruta_copiada
    mov byte [rdi], al
    inc rsi
    inc rdi
    mov rax, rdi
    sub rax, r15
    cmp rax, RUTA_MAX - 8
    jge .error_largo
    jmp .copiar_ruta

.ruta_copiada:
    cmp rdi, r15
    je .sin_sep
    mov al, byte [rdi - 1]
    cmp al, '/'
    je .sin_sep
    mov byte [rdi], '/'
    inc rdi
.sin_sep:

    ; Copiar NOMBRE
    mov rsi, r12
.copiar_nombre:
    mov al, byte [rsi]
    test al, al
    jz .nombre_copiado
    mov byte [rdi], al
    inc rsi
    inc rdi
    mov rax, rdi
    sub rax, r15
    cmp rax, RUTA_MAX - 6
    jge .error_largo
    jmp .copiar_nombre

.nombre_copiado:
    mov byte [rdi + 0], '.'
    mov byte [rdi + 1], 'b'
    mov byte [rdi + 2], 'm'
    mov byte [rdi + 3], 'p'
    mov byte [rdi + 4], 0

    ; --- Framebuffer ---
    mov rdi, datos_fb
    call fb_core
    test rax, rax
    js .error_fb

    mov rdi, datos_fb
    call fb_map
    test rax, rax
    js .error_fb

    ; --- Escribir BMP ---
    mov rdi, datos_fb
    lea rsi, [ruta_full]
    call lib_bmp_write
    test rax, rax
    js .error_bmp

    mov rdi, msg_ok_1
    call print_string
    lea rdi, [ruta_full]
    call print_string
    mov rdi, msg_ok_2
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
    mov rdi, datos_fb
    call fb_core
    mov r15, rax
    cmp r15, 0
    jl .ayuda_sin_res
    mov edi, dword [datos_fb + ScreenInfo.width]
    call print_int
    mov rdi, msg_ayuda_x
    call print_string
    mov edi, dword [datos_fb + ScreenInfo.height]
    call print_int
.ayuda_sin_res:
    mov rdi, msg_ayuda_B
    call print_string
    sys_exit 0

.error_args:
    mov rdi, msg_error_args
    call print_string
    sys_exit 1

.error_fb:
    mov rdi, msg_error_fb
    call print_string
    sys_exit 1

.error_bmp:
    mov rdi, msg_error_bmp
    call print_string
    sys_exit 1

.error_largo:
    mov rdi, msg_error_largo
    call print_string
    sys_exit 1