; ==============================================================================
; LIBRERÍA: lib_draw_pixelcval.asm
; DESCRIPCIÓN: Capa 1 (Escudo). Valida coordenadas y delega en la versión rápida.
; ==============================================================================

%include "lib/graph/core/lib_fb_core.inc"

default rel

; Importamos la versión rápida (Capa 2) para delegar el trabajo
extern lib_draw_pixelfast

section .text
    global lib_draw_pixelcval

; ------------------------------------------------------------------------------
; FUNCIÓN: lib_draw_pixelcval
; ENTRADA: RDI (ScreenInfo), ESI (X), EDX (Y), ECX (Color)
; ------------------------------------------------------------------------------
lib_draw_pixelcval:
    ; --- BARRERA DE VALIDACIÓN (CLIPPING BÁSICO) ---
    cmp esi, 0
    jl .fuera_de_limites                    ; Si X < 0, abortar
    
    cmp esi, dword [rdi + ScreenInfo.width]
    jge .fuera_de_limites                   ; Si X >= Ancho de pantalla, abortar

    cmp edx, 0
    jl .fuera_de_limites                    ; Si Y < 0, abortar
    
    cmp edx, dword [rdi + ScreenInfo.height]
    jge .fuera_de_limites                   ; Si Y >= Alto de pantalla, abortar

    ; --- DELEGACIÓN (TAIL CALL) ---
    ; Los datos han superado la validación de la capa 1. 
    ; Saltamos (jmp) a la rutina de la capa 2. 
    ; El 'ret' de lib_draw_pixelfast devolverá el control al comando principal.
    jmp lib_draw_pixelfast

.fuera_de_limites:
    ret