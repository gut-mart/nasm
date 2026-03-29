struc ScreenInfo
    .width       resd 1  ; Offset 0
    .height      resd 1  ; Offset 4
    .bpp         resd 1  ; Offset 8
    .pitch       resd 1  ; Offset 12
    .size_mem    resd 1  ; Offset 16
    .phy_width   resd 1  ; Offset 20
    .phy_height  resd 1  ; Offset 24
    .red_off     resd 1  ; Offset 28
    .green_off   resd 1  ; Offset 32
    .blue_off    resd 1  ; Offset 36
    .transp_off  resd 1  ; Offset 40
    .padding     resd 1  ; <--- NUEVO: Offset 44 (Alineación para 64 bits)
    .ptr_mem     resq 1  ; <--- CORREGIDO: Offset 48 (Múltiplo de 8)
endstruc

%define ScreenInfo_size 56  ; <--- CORREGIDO: Tamaño total