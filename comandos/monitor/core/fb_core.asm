%include "lib/constants.inc"
%include "lib/sys_macros.inc"
%include "lib/graph/core/lib_fb_core.inc"

default rel

extern print_string, print_int, print_nl
extern fb_core, fb_map
extern print_hex

section .data
    ; --- TEXTOS DE AYUDA (-h) ---
    msg_ayuda_1 db "Uso: lib_fb_core [OPCION]", 10, 0
    msg_ayuda_2 db "Descripcion: Motor de hardware grafico. Lee datos y mapea RAM de video.", 10, 10, 0
    msg_ayuda_3 db "Argumentos:", 10, 0
    msg_ayuda_4 db "  (vacio)    Muestra el diagnostico grafico completo (Requiere sudo).", 10, 0
    msg_ayuda_5 db "  -h         Muestra este panel de ayuda.", 10, 0
    msg_ayuda_6 db "  -p         Muestra formato parseable CLAVE=VALOR.", 10, 10, 0
    msg_ayuda_7 db "Ejemplo desde Ensamblador:", 10, 0
    msg_ayuda_8 db "  mov rdi, datos_fb", 10, 0
    msg_ayuda_9 db "  call fb_core      ; Extraer datos", 10, 0
    msg_ayuda_A db "  call fb_map       ; Mapear memoria de video", 10, 0

    ; --- TEXTOS MODO PARSEABLE (-p) ---
    p_xres      db "WIDTH=", 0
    p_yres      db "HEIGHT=", 0
    p_bpp       db "BPP=", 0          
    p_pitch     db "PITCH=", 0
    p_mem       db "MEM_SIZE=", 0
    p_rojo      db "OFFSET_R=", 0
    p_verde     db "OFFSET_G=", 0
    p_azul      db "OFFSET_B=", 0

    ; --- TEXTOS MODO HUMANO ---
    msg_titulo  db "=== DIAGNOSTICO MOTOR GRAFICO (COMPLETO) ===", 0
    msg_res     db "Resolucion:      ", 0
    msg_x       db "x", 0
    msg_bpp     db "Profundidad:     ", 0
    msg_bits    db " bits", 0
    msg_pitch   db "Pitch:           ", 0
    msg_smem    db "RAM Video:       ", 0
    msg_bytes   db " bytes", 0
    msg_ptr     db "Puntero Memoria: ", 0
    
    msg_color   db "--- Offsets de Color ---", 0
    msg_r       db "  Rojo:  ", 0
    msg_g       db "  Verde: ", 0
    msg_b       db "  Azul:  ", 0
    
    msg_error   db "Error: Permiso denegado al leer /dev/fb0. Ejecuta con 'sudo'.", 0

section .bss
    datos_fb resb ScreenInfo_size

section .text
    global _start

_start:
    ; 1. Procesar argumentos CLI (Lectura no destructiva)
    mov rbx, [rsp]          ; Extraemos argc (cantidad de argumentos)
    
    ; --- ALINEACIÓN MAESTRA DE PILA (ABI) ---
    mov rbp, rsp
    and rsp, -16            
    
    cmp rbx, 2          
    jl modo_humano      

    mov rdi, [rbp + 16]     ; Extraemos argv[1] 
    mov al, byte [rdi]
    cmp al, '-'         
    jne modo_humano     
    
    mov al, byte [rdi+1]
    cmp al, 'h'
    je modo_ayuda      
    cmp al, 'p'
    je modo_parseable  
    
    jmp modo_humano    

modo_ayuda:
    mov rdi, msg_ayuda_1
    call print_string
    mov rdi, msg_ayuda_2
    call print_string
    mov rdi, msg_ayuda_3
    call print_string
    mov rdi, msg_ayuda_4
    call print_string
    mov rdi, msg_ayuda_5
    call print_string
    mov rdi, msg_ayuda_6
    call print_string
    mov rdi, msg_ayuda_7
    call print_string
    mov rdi, msg_ayuda_8
    call print_string
    mov rdi, msg_ayuda_9
    call print_string
    mov rdi, msg_ayuda_A
    call print_string
    call print_nl
    jmp fin_programa

modo_parseable:
    mov rdi, datos_fb
    call fb_core
    cmp rax, 0
    jl error_grafico

    mov rdi, p_xres
    call print_string
    mov edi, dword [datos_fb + ScreenInfo.width]
    call print_int
    call print_nl

    mov rdi, p_yres
    call print_string
    mov edi, dword [datos_fb + ScreenInfo.height]
    call print_int
    call print_nl

    mov rdi, p_bpp
    call print_string
    mov edi, dword [datos_fb + ScreenInfo.bpp]
    call print_int
    call print_nl

    mov rdi, p_pitch
    call print_string
    mov edi, dword [datos_fb + ScreenInfo.pitch]
    call print_int
    call print_nl

    mov rdi, p_mem
    call print_string
    mov edi, dword [datos_fb + ScreenInfo.size_mem]
    call print_int
    call print_nl

    mov rdi, p_rojo
    call print_string
    mov edi, dword [datos_fb + ScreenInfo.red_off]
    call print_int
    call print_nl

    mov rdi, p_verde
    call print_string
    mov edi, dword [datos_fb + ScreenInfo.green_off]
    call print_int
    call print_nl

    mov rdi, p_azul
    call print_string
    mov edi, dword [datos_fb + ScreenInfo.blue_off]
    call print_int
    call print_nl
    
    jmp fin_programa

modo_humano:
    mov rdi, datos_fb
    call fb_core
    cmp rax, 0
    jl error_grafico

    mov rdi, datos_fb
    call fb_map
    cmp rax, 0
    jl error_grafico

    mov rdi, msg_titulo
    call print_string
    call print_nl

    mov rdi, msg_res
    call print_string
    mov edi, dword [datos_fb + ScreenInfo.width]
    call print_int
    mov rdi, msg_x
    call print_string
    mov edi, dword [datos_fb + ScreenInfo.height]
    call print_int
    call print_nl

    mov rdi, msg_bpp
    call print_string
    mov edi, dword [datos_fb + ScreenInfo.bpp]
    call print_int
    mov rdi, msg_bits
    call print_string
    call print_nl

    mov rdi, msg_pitch
    call print_string
    mov edi, dword [datos_fb + ScreenInfo.pitch]
    call print_int
    mov rdi, msg_bytes
    call print_string
    call print_nl

    mov rdi, msg_smem
    call print_string
    mov edi, dword [datos_fb + ScreenInfo.size_mem]
    call print_int
    mov rdi, msg_bytes
    call print_string
    call print_nl

    mov rdi, msg_ptr
    call print_string
    mov rdi, [datos_fb + ScreenInfo.ptr_mem]
    call print_hex  
    call print_nl
    call print_nl

    mov rdi, msg_color
    call print_string
    call print_nl

    mov rdi, msg_r
    call print_string
    mov edi, dword [datos_fb + ScreenInfo.red_off]
    call print_int
    call print_nl

    mov rdi, msg_g
    call print_string
    mov edi, dword [datos_fb + ScreenInfo.green_off]
    call print_int
    call print_nl

    mov rdi, msg_b
    call print_string
    mov edi, dword [datos_fb + ScreenInfo.blue_off]
    call print_int
    call print_nl
    call print_nl
    
    jmp fin_programa

error_grafico:
    mov rdi, msg_error
    call print_string
    call print_nl
    sys_exit 1

fin_programa:
    sys_exit 0