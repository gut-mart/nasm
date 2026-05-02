; ==============================================================================
; LIBRERÍA: lib_draw_pixelfast.asm
; DESCRIPCIÓN: Capa 2 (Motor). Dibuja un píxel asumiendo coordenadas perfectas.
; CORRECCIÓN: El offset X (R10) ahora se suma al offset Y (RAX) antes de
;             escribir en memoria. Antes solo se usaba el offset Y, lo que
;             provocaba que todos los píxeles cayeran en la columna X=0.
; NOTA: Asume bpp=32 (4 bytes por píxel) en la escritura final.
; ==============================================================================

%include "lib/graph/core/lib_fb_core.inc"

default rel

section .text
    global lib_draw_pixelfast

; ------------------------------------------------------------------------------
; FUNCIÓN: lib_draw_pixelfast
; ENTRADA: 
;   RDI = Puntero a ScreenInfo
;   ESI = Coordenada X (32 bits)
;   EDX = Coordenada Y (32 bits)
;   ECX = Color (32 bits)
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

    ; 4. Dirección Absoluta y Escritura
    mov r11, qword [rdi + ScreenInfo.ptr_mem] 
    mov dword [r11 + rax], ecx  ; Escribir los 4 bytes de color directamente

    ret