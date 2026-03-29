; =================================================================
; ARCHIVO: lib_fb_info.inc
; DESCRIPCION: Estructura de datos completa para el motor grafico
; =================================================================

struc ScreenInfo
    .width       resd 1  ; Offset 0: Resolucion X (px)
    .height      resd 1  ; Offset 4: Resolucion Y (px)
    .bpp         resd 1  ; Offset 8: Profundidad de color (bits)
    .pitch       resd 1  ; Offset 12: Bytes por linea (line_length)
    .size_mem    resd 1  ; Offset 16: Tamaño total RAM video (bytes)
    .phy_width   resd 1  ; Offset 20: Ancho fisico (mm)
    .phy_height  resd 1  ; Offset 24: Alto fisico (mm)
    .red_off     resd 1  ; Offset 28: Bit de inicio Rojo
    .green_off   resd 1  ; Offset 32: Bit de inicio Verde
    .blue_off    resd 1  ; Offset 36: Bit de inicio Azul
    .transp_off  resd 1  ; Offset 40: Bit de inicio Alpha
    .ptr_mem     resq 1  ; Offset 44: PUNTERO 64-BIT A LA MEMORIA (mmap)
endstruc

%define ScreenInfo_size 52  ; Tamaño total de la estructura