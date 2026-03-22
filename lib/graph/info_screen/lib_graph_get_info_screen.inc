; ==============================================================================
; Estructura ScreenInfo Actualizada
; Ahora incluye dimensiones físicas
; ==============================================================================

struc ScreenInfo
    .width      resd 1  ; 0: Ancho en Píxeles (px)
    .height     resd 1  ; 4: Alto en Píxeles (px)
    .bpp        resd 1  ; 8: Bits por Píxel
    .pitch      resd 1  ; 12: Bytes por Línea (LineLength)
    .phy_width  resd 1  ; 16: Ancho Físico (mm) [NUEVO]
    .phy_height resd 1  ; 20: Alto Físico (mm)  [NUEVO]
endstruc

; El tamaño total ahora es 24 bytes
ScreenInfo_size equ 24