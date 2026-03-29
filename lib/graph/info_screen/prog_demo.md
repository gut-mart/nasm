; ==============================================================================
; ARCHIVO: ejemplo_uso.asm
; DESCRIPCION: Ejemplo minimo funcional para demostrar el uso de lib_fb_info.asm
; ==============================================================================

%include "lib/constants.inc"
%include "lib/sys_macros.inc"
%include "lib/graph/info_screen/lib_fb_info.inc" ; 1. Incluir la estructura

default rel

extern fb_info        ; 2. Importar la funcion de la libreria
extern print_string
extern print_int
extern print_nl

section .data
    msg_ok  db "Exito: El ancho de la pantalla es ", 0
    msg_px  db " px.", 0
    msg_err db "Error: No se pudo leer el framebuffer.", 0

section .bss
    datos_fb resb ScreenInfo_size ; 3. Reservar memoria para la estructura

section .text
    global _start

_start:
    ; --- PASO A: Llamar a la funcion ---
    mov rdi, datos_fb       ; Pasamos el puntero de nuestra memoria a RDI
    call fb_info            ; La funcion rellena la estructura

    ; --- PASO B: Comprobar errores ---
    cmp rax, 0
    jl .hubo_error          ; Si RAX es negativo, saltamos al error

    ; --- PASO C: Extraer y usar los datos ---
    mov rdi, msg_ok
    call print_string
    
    ; Extraemos un dato concreto (Ej: el ancho en pixeles)
    mov edi, dword [datos_fb + ScreenInfo.width]
    call print_int
    
    mov rdi, msg_px
    call print_string
    call print_nl

    sys_exit 0              ; Salir sin errores

.hubo_error:
    mov rdi, msg_err
    call print_string
    call print_nl
    sys_exit 1              ; Salir con codigo de error 1