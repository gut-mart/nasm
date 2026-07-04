; ==============================================================================
; LIBRERÍA: lib_draw_pixelfast.asm
; DESCRIPCIÓN: Capa 2 (Motor). Dibuja un píxel asumiendo coordenadas perfectas.
; CONTRATO:
;   Entrada: RDI = Puntero a ScreenInfo
;            ESI = Coordenada X (32 bits)
;            EDX = Coordenada Y (32 bits)
;            ECX = Color: patrón de bits nativo del framebuffer (32 bits)
;   Salida:  Sin valor de retorno.
; SOPORTE bpp: lee ScreenInfo.bpp y escribe 2, 3 o 4 bytes según el modo:
;   - 32 bpp → 4 bytes (ECX completo)
;   - 24 bpp → 3 bytes bajos de ECX (mismos bytes B,G,R que a 32 bpp)
;   - 16 bpp → 2 bytes bajos de ECX (el llamante pasa el patrón ya
;     empaquetado para el modo, p. ej. RGB565)
;   Otras profundidades no están soportadas.
; NOTA: Este fast SÍ altera CF (usa cmp para el despacho por bpp). La capa
;       cval debe delegar con opción B: call + clc + ret (NORMAS sección 7).
; ==============================================================================

%include "lib/graph/core/lib_fb_core.inc"

default rel

section .text
    global lib_draw_pixelfast

; ------------------------------------------------------------------------------
; FUNCIÓN: lib_draw_pixelfast
; ------------------------------------------------------------------------------
lib_draw_pixelfast:
    ; 1. Calcular Offset Y (Y * pitch)
    movsxd r8, edx              ; Extensión a 64 bits de Y para evitar desbordamiento
    mov eax, dword [rdi + ScreenInfo.pitch]
    imul rax, r8                ; RAX = Y * pitch

    ; 2. Calcular Offset X (X * (BPP / 8))
    mov r9d, dword [rdi + ScreenInfo.bpp]
    shr r9d, 3                  ; R9D = Bytes por píxel
    movsxd r10, esi             ; Extensión a 64 bits de X
    imul r10, r9                ; R10 = X * Bytes por píxel

    ; 3. Combinar offsets X e Y en el offset total
    add rax, r10                ; RAX = (Y * pitch) + (X * Bpp) = offset total

    ; 4. Dirección Absoluta
    mov r11, qword [rdi + ScreenInfo.ptr_mem]
    add r11, rax                ; R11 = dirección del píxel

    ; 5. Escritura según bytes por píxel (32 bpp primero: es el caso común)
    cmp r9d, 4
    jne .no_32bpp
    mov dword [r11], ecx        ; 32 bpp: escribir los 4 bytes del color
    ret

.no_32bpp:
    cmp r9d, 3
    jne .bpp16
    mov word [r11], cx          ; 24 bpp: bytes 0-1 del color (B, G)
    shr ecx, 16
    mov byte [r11 + 2], cl      ; 24 bpp: byte 2 del color (R), sin solapar
    ret

.bpp16:
    mov word [r11], cx          ; 16 bpp: escribir los 2 bytes bajos
    ret
