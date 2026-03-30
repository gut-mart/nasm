%include "lib/constants.inc"
%include "lib/sys_macros.inc"
%include "lib/graph/core/lib_fb_core.inc" ; Ajusta la ruta si cambiaste la carpeta

default rel

extern fb_core
extern fb_map

section .bss
    ; Reservamos la memoria exacta para la estructura del motor
    datos_fb resb ScreenInfo_size

section .data
    msg_error db "Error: No se pudo iniciar el motor grafico (Usa sudo).", 10, 0

section .text
    global _start

_start:
    ; =======================================================
    ; 1. INICIALIZAR EL HARDWARE Y EXTRAER METADATOS
    ; =======================================================
    mov rdi, datos_fb
    call fb_core
    cmp rax, 0
    jl error_grafico

    ; =======================================================
    ; 2. OBTENER EL PUNTERO A LA MEMORIA DE VIDEO (RAM)
    ; =======================================================
    mov rdi, datos_fb
    call fb_map
    cmp rax, 0
    jl error_grafico

    ; =======================================================
    ; 3. PREPARAR LOS DATOS PARA DIBUJAR
    ; =======================================================
    ; RDI necesita la direccion de memoria base para dibujar
    mov rdi, [datos_fb + ScreenInfo.ptr_mem] 
    
    ; RCX necesita la cantidad de pixeles totales.
    ; Obtenemos el tamaño en bytes y dividimos por 4 (32 bits = 4 bytes por pixel)
    mov rcx, [datos_fb + ScreenInfo.size_mem]
    shr rcx, 2          ; shr 2 es equivalente a dividir entre 4

    ; EAX necesita el color.
    ; Sabiendo que B=0, G=8, R=16:
    ; 0x00FF0000 = Rojo puro
    ; 0x0000FF00 = Verde puro
    ; 0x000000FF = Azul puro
    mov eax, 0x000000FF ; Cargamos color Azul

    ; =======================================================
    ; 4. BUCLE DE DIBUJO MASIVO (Renderizado)
    ; =======================================================
    cld                 ; Nos aseguramos de que escribiremos hacia adelante
    rep stosd           ; ¡Magia de x86! Copia EAX en [RDI], RCX veces.
                        ; Esto llena toda la pantalla al instante.

    ; Salida exitosa
    sys_exit 0

error_grafico:
    ; (Aqui podrias usar tu funcion print_string si la importas)
    ; Para mantener este ejemplo independiente, usamos un exit con error
    sys_exit 1