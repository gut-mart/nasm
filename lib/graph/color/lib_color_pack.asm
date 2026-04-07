; ==============================================================================
; LIBRERÍA: lib_color_pack.asm
; DESCRIPCIÓN: Traduce un color RGB estándar (0xRRGGBB) al formato nativo del
;              Framebuffer actual (RGB, BGR, etc.) usando sus offsets.
; ==============================================================================

%include "lib/graph/core/lib_fb_core.inc"

default rel

section .text
    global lib_color_pack

; ------------------------------------------------------------------------------
; FUNCIÓN: lib_color_pack
; ENTRADA: 
;   RDI = Puntero a ScreenInfo (datos_fb)
;   ESI = Color estándar RGB de 32 bits (ej: 0xFF0000 para rojo puro)
; SALIDA:
;   EAX = Color empaquetado listo para inyectar en memoria
; ------------------------------------------------------------------------------
lib_color_pack:
    xor eax, eax        ; Limpiamos el acumulador del color final

    ; --- 1. Extraer y colocar AZUL ---
    ; El azul está en los bits 0-7 del color estándar
    mov edx, esi
    and edx, 0xFF       ; Aislamos el canal azul
    mov ecx, dword [rdi + ScreenInfo.blue_off]
    shl edx, cl         ; Desplazamos a su posición en hardware
    or eax, edx         ; Guardamos en el resultado

    ; --- 2. Extraer y colocar VERDE ---
    ; El verde está en los bits 8-15
    mov edx, esi
    shr edx, 8          ; Bajamos el verde a la posición 0-7
    and edx, 0xFF       ; Aislamos el canal verde
    mov ecx, dword [rdi + ScreenInfo.green_off]
    shl edx, cl         ; Desplazamos a su posición en hardware
    or eax, edx         ; Guardamos en el resultado

    ; --- 3. Extraer y colocar ROJO ---
    ; El rojo está en los bits 16-23
    mov edx, esi
    shr edx, 16         ; Bajamos el rojo a la posición 0-7
    and edx, 0xFF       ; Aislamos el canal rojo
    mov ecx, dword [rdi + ScreenInfo.red_off]
    shl edx, cl         ; Desplazamos a su posición en hardware
    or eax, edx         ; Guardamos en el resultado

    ret