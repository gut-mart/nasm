%include "lib/constants.inc"
%include "lib/sys_macros.inc"
%include "lib/graph/core/lib_fb_core.inc"

default rel

; Importamos las librerías necesarias
extern fb_core, fb_map
extern lib_draw_rectcval
extern lib_string_int32cval
extern lib_color_pack
extern print_string, print_nl, print_int

section .bss
    datos_fb resb ScreenInfo_size
    coord_x  resd 1
    coord_y  resd 1
    width    resd 1
    height   resd 1
    color    resd 1

section .data
    ; --- TEXTOS DE AYUDA (-h) ---
    msg_ayuda_1 db "Uso: draw_rect [X] [Y] [W] [H] [COLOR]", 10, 0
    msg_ayuda_2 db "Descripcion: Dibuja un rectangulo solido con recorte inteligente (Clipping).", 10, 10, 0
    msg_ayuda_3 db "Argumentos:", 10, 0
    
    msg_ayuda_x db "  X       Coordenada horizontal origen (Acepta negativos).", 10, 0
    msg_ayuda_y db "  Y       Coordenada vertical origen   (Acepta negativos).", 10, 0
    
    ; Textos fragmentados para inyectar números dinámicos
    msg_ayuda_w db "  W       Ancho del rectangulo (Max visible: ", 0
    msg_ayuda_h db "  H       Alto del rectangulo  (Max visible: ", 0
    msg_cierre   db ").", 10, 0
    msg_req_sudo db "Limite real requiere sudo).", 10, 0

    msg_ayuda_c db "  COLOR   Valor del color (Soporta multiples bases numericas).", 10, 0
    msg_ayuda_h_flag db "  -h      Muestra este panel de ayuda dinámico.", 10, 10, 0
    
    msg_ayuda_ej db "Ejemplos desde Bash:", 10, 0
    msg_ayuda_e1 db "  sudo ./bin/draw_rect 0 0 1920 1080 0xFF0000   ; Limpiar pantalla en rojo", 10, 0
    msg_ayuda_e2 db "  sudo ./bin/draw_rect -50 -50 200 200 0x00FF00 ; Cuadrado recortado en la esquina", 10, 0

    msg_error_args db "Error: Numero de argumentos incorrecto. Usa '-h' para ayuda.", 10, 0
    msg_error_fb   db "Error: No se pudo inicializar /dev/fb0. ¿Ejecutaste con sudo (o tienes permisos)?", 10, 0
    msg_exito      db "Rectangulo procesado correctamente.", 10, 0

section .text
    global _start

_start:
    ; 1. Extraer argumentos (CLI)
    mov rbx, [rsp]          ; argc
    mov r12, [rsp + 16]     ; argv[1] (X o -h)
    
    ; --- ALINEACIÓN MAESTRA DE PILA (ABI) ---
    mov rbp, rsp
    and rsp, -16            

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
    ; Verificar 6 argumentos (Comando + 5 parámetros)
    cmp rbx, 6
    jne .error_args

    ; --- 3. CONVERSIÓN CON VALIDACIÓN (CVAL) ---
    mov rdi, r12
    call lib_string_int32cval
    mov dword [coord_x], eax

    mov rdi, [rbp + 24]     ; Y
    call lib_string_int32cval
    mov dword [coord_y], eax

    mov rdi, [rbp + 32]     ; W
    call lib_string_int32cval
    mov dword [width], eax

    mov rdi, [rbp + 40]     ; H
    call lib_string_int32cval
    mov dword [height], eax

    mov rdi, [rbp + 48]     ; Color
    call lib_string_int32cval
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

    ; --- 4.5 TRADUCCIÓN AL HARDWARE NATIVO ---
    mov rdi, datos_fb
    mov esi, dword [color]
    call lib_color_pack
    mov dword [color], eax

    ; --- 5. DIBUJAR RECTÁNGULO (CAPA SEGURA) ---
    mov rdi, datos_fb
    mov esi, dword [coord_x]
    mov edx, dword [coord_y]
    mov ecx, dword [width]
    mov r8d, dword [height]
    mov r9d, dword [color]
    call lib_draw_rectcval         

    ; --- 6. ÉXITO Y SALIDA ---
    mov rdi, msg_exito
    call print_string
    call print_nl
    sys_exit 0

.modo_ayuda:
    ; Intentamos obtener los datos de la pantalla dinámicamente
    mov rdi, datos_fb
    call fb_core
    mov r15, rax            ; Guardamos el resultado de fb_core

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
    
    ; AYUDA EJE W (Ancho)
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

    ; AYUDA EJE H (Alto)
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
    mov rdi, msg_ayuda_h_flag
    call print_string
    mov rdi, msg_ayuda_ej
    call print_string
    mov rdi, msg_ayuda_e1
    call print_string
    mov rdi, msg_ayuda_e2
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