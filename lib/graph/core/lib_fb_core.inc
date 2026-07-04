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
    .red_len     resd 1  ; Offset 44 — bits del canal (5/6/8 según modo)
    .green_len   resd 1  ; Offset 48
    .blue_len    resd 1  ; Offset 52
    .transp_len  resd 1  ; Offset 56
    .padding     resd 1  ; Offset 60 (alineación de ptr_mem a 8 bytes)
    .ptr_mem     resq 1  ; Offset 64 (múltiplo de 8)
endstruc

%define ScreenInfo_size 72
