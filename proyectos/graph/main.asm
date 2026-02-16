; ==============================================================================
; RUTA: ./proyectos/test_dpi.asm
; DESCRIPCIÓN: Muestra TODA la información técnica del monitor (PX, MM, BPP)
; ==============================================================================

default rel
%include "lib/graph/lib_graph_get_info_screen.inc" ; Tu estructura ScreenInfo

extern lib_graph_get_info_screen      ; Tu librería gráfica
extern lib_cnv_uint32_to_str   ; Tu librería de conversión

section .bss
    screen      resb ScreenInfo_size ; Reservamos 24 bytes para la estructura
    buffer_num  resb 32              ; Buffer para convertir números a texto

section .data
    ; --- Textos de Interfaz ---
    header      db 10, "=== REPORTE DE HARDWARE DE VIDEO ===", 10, 0
    
    lbl_res     db "Resolucion Logica:  ", 0
    lbl_phy     db "Tamano Fisico:      ", 0
    lbl_bpp     db "Profundidad Color:  ", 0
    lbl_pitch   db "Pitch (LineLength): ", 0
    
    sep_x       db " x ", 0          ; Separador " x "
    unit_px     db " px", 10, 0      ; Unidad pixeles + Salto linea
    unit_mm     db " mm", 10, 0      ; Unidad milimetros + Salto linea
    unit_bits   db " bits", 10, 0    ; Unidad bits + Salto linea
    unit_bytes  db " bytes", 10, 0   ; Unidad bytes + Salto linea
    
    err_msg     db "ERROR: No se pudo leer /dev/fb0", 10, 0

section .text
    global _start

_start:
    ; --------------------------------------------------------------------------
    ; 1. OBTENER INFORMACIÓN DEL KERNEL
    ; --------------------------------------------------------------------------
    lea rdi, [screen]           ; RDI apunta a nuestra estructura vacía
    call lib_graph_get_info_screen     ; Llenamos la estructura
    
    cmp rax, 0                  ; Verificamos errores
    jl .error_handler

    ; --------------------------------------------------------------------------
    ; 2. IMPRIMIR CABECERA
    ; --------------------------------------------------------------------------
    lea rsi, [header]
    call _print_str

    ; --------------------------------------------------------------------------
    ; 3. IMPRIMIR RESOLUCIÓN (Ancho x Alto px)
    ; --------------------------------------------------------------------------
    lea rsi, [lbl_res]          ; "Resolucion Logica: "
    call _print_str

    mov esi, [screen + ScreenInfo.width]
    call _print_number          ; Imprime Ancho
    
    lea rsi, [sep_x]            ; " x "
    call _print_str
    
    mov esi, [screen + ScreenInfo.height]
    call _print_number          ; Imprime Alto

    lea rsi, [unit_px]          ; " px"
    call _print_str

    ; --------------------------------------------------------------------------
    ; 4. IMPRIMIR TAMAÑO FÍSICO (Ancho x Alto mm)
    ; --------------------------------------------------------------------------
    lea rsi, [lbl_phy]          ; "Tamano Fisico: "
    call _print_str

    mov esi, [screen + ScreenInfo.phy_width]
    call _print_number
    
    lea rsi, [sep_x]            ; " x "
    call _print_str
    
    mov esi, [screen + ScreenInfo.phy_height]
    call _print_number

    lea rsi, [unit_mm]          ; " mm"
    call _print_str

    ; --------------------------------------------------------------------------
    ; 5. IMPRIMIR PROFUNDIDAD (BPP)
    ; --------------------------------------------------------------------------
    lea rsi, [lbl_bpp]          ; "Profundidad Color: "
    call _print_str

    mov esi, [screen + ScreenInfo.bpp]
    call _print_number

    lea rsi, [unit_bits]        ; " bits"
    call _print_str

    ; --------------------------------------------------------------------------
    ; 6. IMPRIMIR PITCH (Bytes por línea)
    ; --------------------------------------------------------------------------
    lea rsi, [lbl_pitch]        ; "Pitch (LineLength): "
    call _print_str

    mov esi, [screen + ScreenInfo.pitch]
    call _print_number

    lea rsi, [unit_bytes]       ; " bytes"
    call _print_str

    ; Salir con éxito
    mov rax, 60
    xor rdi, rdi
    syscall

.error_handler:
    lea rsi, [err_msg]
    call _print_str
    mov rax, 60
    mov rdi, 1
    syscall

; ==============================================================================
; RUTINAS AUXILIARES
; ==============================================================================

; ------------------------------------------------------------------------------
; _print_str: Imprime una cadena terminada en 0 apuntada por RSI
; ------------------------------------------------------------------------------
_print_str:
    push rdi
    push rdx
    push rcx
    push rax

    xor rdx, rdx                ; RDX = Longitud
.count:
    cmp byte [rsi + rdx], 0
    je .do_print
    inc rdx
    jmp .count
.do_print:
    mov rax, 1                  ; sys_write
    mov rdi, 1                  ; stdout
    syscall

    pop rax
    pop rcx
    pop rdx
    pop rdi
    ret

; ------------------------------------------------------------------------------
; _print_number: Convierte el número en ESI a texto e imprime
; Usa 'buffer_num' como memoria temporal
; ------------------------------------------------------------------------------
_print_number:
    push rdi
    push rdx
    push rsi ; Guardamos ESI porque la librería lo usa

    lea rdi, [buffer_num]       ; Buffer destino
    ; ESI ya tiene el número (pasado por el caller)
    mov edx, 10                 ; Base 10 (Decimal)
    call lib_cnv_uint32_to_str
    
    lea rsi, [buffer_num]       ; Preparamos para imprimir
    call _print_str

    pop rsi
    pop rdx
    pop rdi
    ret