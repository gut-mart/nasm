; ==============================================================================
; RUTA: ./lib/graph/lib_graph_info.inc
; DESCRIPCIÓN: Definición de la estructura de información de pantalla.
; ==============================================================================

struc ScreenInfo
    .width      resd 1  ; 4 bytes - Ancho (xres)
    .height     resd 1  ; 4 bytes - Alto (yres)
    .bpp        resd 1  ; 4 bytes - Bits por Pixel
    .pitch      resd 1  ; 4 bytes - LineLength (Bytes por línea REALES)
endstruc

; Tamaño total de la estructura (para reservar memoria con resb)
ScreenInfo_size equ 16