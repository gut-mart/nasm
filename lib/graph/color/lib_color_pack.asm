; ==============================================================================
; LIBRERÍA: lib_color_pack.asm
; DESCRIPCIÓN: Traduce un color RGB estándar (0xRRGGBB) al formato nativo del
;              framebuffer actual, usando los offsets Y las longitudes de canal
;              de ScreenInfo. Cada canal de 8 bits se trunca a la longitud real
;              del modo (descartando los bits bajos) antes de colocarlo en su
;              offset. Con canales de 8 bits (24/32 bpp) el truncado es nulo y
;              el resultado es el clásico; con RGB565 (16 bpp) produce el
;              patrón 5-6-5 correcto.
; CONTRATO:
;   Entrada: RDI = Puntero a ScreenInfo (datos_fb)
;            ESI = Color estándar RGB de 32 bits (ej: 0xFF0000 para rojo puro)
;   Salida:  EAX = Color empaquetado listo para inyectar en memoria
; NOTA: Asume longitudes de canal <= 8 bits (cubre 16/24/32 bpp). Un canal con
;       longitud 0 desaparece del resultado (correcto: el modo no lo tiene).
; ==============================================================================

%include "lib/graph/core/lib_fb_core.inc"

default rel

section .text
    global lib_color_pack

; ------------------------------------------------------------------------------
; FUNCIÓN: lib_color_pack
; ------------------------------------------------------------------------------
lib_color_pack:
    xor eax, eax        ; Limpiamos el acumulador del color final

    ; --- 1. Extraer, truncar y colocar AZUL ---
    ; El azul está en los bits 0-7 del color estándar
    mov edx, esi
    and edx, 0xFF       ; Aislamos el canal azul
    mov ecx, 8
    sub ecx, dword [rdi + ScreenInfo.blue_len]
    shr edx, cl         ; Truncamos 8 → blue_len bits (descarta bits bajos)
    mov ecx, dword [rdi + ScreenInfo.blue_off]
    shl edx, cl         ; Desplazamos a su posición en hardware
    or eax, edx         ; Guardamos en el resultado

    ; --- 2. Extraer, truncar y colocar VERDE ---
    ; El verde está en los bits 8-15
    mov edx, esi
    shr edx, 8          ; Bajamos el verde a la posición 0-7
    and edx, 0xFF       ; Aislamos el canal verde
    mov ecx, 8
    sub ecx, dword [rdi + ScreenInfo.green_len]
    shr edx, cl         ; Truncamos 8 → green_len bits
    mov ecx, dword [rdi + ScreenInfo.green_off]
    shl edx, cl         ; Desplazamos a su posición en hardware
    or eax, edx         ; Guardamos en el resultado

    ; --- 3. Extraer, truncar y colocar ROJO ---
    ; El rojo está en los bits 16-23
    mov edx, esi
    shr edx, 16         ; Bajamos el rojo a la posición 0-7
    and edx, 0xFF       ; Aislamos el canal rojo
    mov ecx, 8
    sub ecx, dword [rdi + ScreenInfo.red_len]
    shr edx, cl         ; Truncamos 8 → red_len bits
    mov ecx, dword [rdi + ScreenInfo.red_off]
    shl edx, cl         ; Desplazamos a su posición en hardware
    or eax, edx         ; Guardamos en el resultado

    ret
