; ==============================================================================
; LIBRERÍA: lib_draw_pixelcval.asm
; DESCRIPCIÓN: Capa 1 (Escudo). Valida coordenadas y delega en la versión rápida.
; CONTRATO:
;   Entrada: RDI (ScreenInfo), ESI (X), EDX (Y), ECX (Color)
;   Salida:  CF = 0 si el pixel está dentro de la pantalla y se ha dibujado.
;            CF = 1 si está fuera de los límites; no se ha dibujado nada.
; CORRECCIÓN: Antes hacía un ret silencioso al detectar fuera de límites,
;             sin comunicar el clipping al llamante. Ahora se usa Carry Flag
;             para que el comando principal pueda informar al usuario.
; ==============================================================================

%include "lib/graph/core/lib_fb_core.inc"

default rel

extern lib_draw_pixelfast

section .text
    global lib_draw_pixelcval

; ------------------------------------------------------------------------------
; FUNCIÓN: lib_draw_pixelcval
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

    ; --- DELEGACIÓN (OPCIÓN B) ---
    ; lib_draw_pixelfast usa cmp para el despacho por bpp, que altera CF.
    ; Un clc previo al tail-call se perdería: call + clc + ret (NORMAS sec. 7).
    call lib_draw_pixelfast
    clc
    ret

.fuera_de_limites:
    stc                                     ; CF=1: pixel fuera, no dibujado
    ret
