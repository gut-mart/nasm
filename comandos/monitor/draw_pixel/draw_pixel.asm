%include "lib/constants.inc"
%include "lib/sys_macros.inc"
%include "lib/graph/core/lib_fb_core.inc"

default rel

; Importamos las librerías necesarias
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
    ; --- TEXTOS DE AYUDA (-h) ---
    msg_ayuda_1 db "Uso: draw_pixel [X] [Y] [COLOR]", 10, 0
    msg_ayuda_2 db "Descripcion: Dibuja un pixel en el Framebuffer (Capa 1: con validacion).", 10, 10, 0
    msg_ayuda_3 db "Argumentos:", 10, 0
    
    ; Textos fragmentados para inyectar números dinámicos
    msg_ayuda_4 db "  X       Coordenada horizontal (0 a ", 0
    msg_ayuda_5 db "  Y       Coordenada vertical   (0 a ", 0
    msg_cierre   db ").", 10, 0
    msg_req_sudo db "Limite real requiere sudo).", 10, 0

    msg_ayuda_6 db "  COLOR   Valor del color (Soporta multiples bases numericas).", 10, 0
    msg_ayuda_7 db "  -h      Muestra este panel de ayuda.", 10, 10, 0
    
    msg_ayuda_8 db "Formatos numericos soportados (para cualquier argumento):", 10, 0
    msg_ayuda_9 db "  Decimal (por defecto) : 16711680", 10, 0
    msg_ayuda_A db "  Hexadecimal (0x)      : 0xFF0000 (Rojo puro)", 10, 0
    msg_ayuda_B db "  Binario (0b)          : 0b111111110000000000000000", 10, 0
    msg_ayuda_C db "  Octal (0o)            : 0o77600000", 10, 10, 0

    msg_ayuda_D db "Ejemplos desde Bash:", 10, 0
    msg_ayuda_E db "  sudo ./bin/draw_pixel 960 540 0xFF0000      ; Rojo en el centro", 10, 0
    msg_ayuda_F db "  sudo ./bin/draw_pixel 0x10 0x10 0x00FF00    ; Verde en coords hex", 10, 0

    msg_error_args db "Error: Numero de argumentos incorrecto o formato invalido. Usa '-h'.", 10, 0
    msg_error_fb   db "Error: No se pudo inicializar /dev/fb0. ¿Ejecutaste con sudo?", 10, 0
    msg_exito      db "Pixel dibujado correctamente (con validacion cval).", 10, 0

section .text
    global _start

_start:
    ; 1. Extraer argumentos (CLI)
    mov rbx, [rsp]          ; argc
    mov r12, [rsp + 16]     ; argv[1] (X o -h)
    mov r13, [rsp + 24]     ; argv[2] (Y)
    mov r14, [rsp + 32]     ; argv[3] (Color)

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
    ; Verificar 4 argumentos (Comando + 3 parámetros)
    cmp rbx, 4
    jne .error_args

    ; --- 3. CONVERSIÓN CON VALIDACIÓN (CVAL) ---
    mov rdi, r12
    call lib_string_int32cval
    mov dword [coord_x], eax

    mov rdi, r13
    call lib_string_int32cval
    mov dword [coord_y], eax

    mov rdi, r14
    call lib_string_int32cval
    mov dword [color], eax

    ; --- 4. INICIALIZAR FRAMEBUFFER ---
    mov rdi, datos_fb
    call fb_core
    cmp rax, 0
    jl .error_fb

    mov rdi, datos_fb
    call fb_map
    cmp rax, 0
    jl .error_fb

    ; --- 5. DIBUJAR PÍXEL (CAPA SEGURA) ---
    mov rdi, datos_fb
    mov esi, dword [coord_x]
    mov edx, dword [coord_y]
    mov ecx, dword [color]
    call lib_draw_pixelcval         

    ; --- 6. ÉXITO Y SALIDA ---
    mov rdi, msg_exito
    call print_string
    call print_nl
    sys_exit 0

.modo_ayuda:
    ; Intentamos obtener los datos de la pantalla dinámicamente
    mov rdi, datos_fb
    call fb_core
    mov r15, rax            ; Guardamos el resultado de fb_core (0 = OK, negativo = Error)

    mov rdi, msg_ayuda_1
    call print_string
    mov rdi, msg_ayuda_2
    call print_string
    mov rdi, msg_ayuda_3
    call print_string
    
    ; AYUDA EJE X
    mov rdi, msg_ayuda_4
    call print_string
    cmp r15, 0
    jl .sin_sudo_x
    mov edi, dword [datos_fb + ScreenInfo.width]
    dec edi                 ; Límite máximo es Ancho - 1
    call print_int
    mov rdi, msg_cierre
    call print_string
    jmp .ayuda_eje_y
.sin_sudo_x:
    mov rdi, msg_req_sudo
    call print_string

    ; AYUDA EJE Y
.ayuda_eje_y:
    mov rdi, msg_ayuda_5
    call print_string
    cmp r15, 0
    jl .sin_sudo_y
    mov edi, dword [datos_fb + ScreenInfo.height]
    dec edi                 ; Límite máximo es Alto - 1
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
    sys_exit 0

.error_args:
    mov rdi, msg_error_args
    call print_string
    sys_exit 1

.error_fb:
    mov rdi, msg_error_fb
    call print_string
    sys_exit 1