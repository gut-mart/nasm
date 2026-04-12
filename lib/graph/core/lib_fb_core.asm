; ==============================================================================
; RUTA: ./lib/graph/core/lib_fb_core.asm
; CORRECCIONES:
;   - fb_map: Comprobación de error de mmap cambiada de 'jl' a 'cmp rax, -1 / je'
;             ya que mmap devuelve MAP_FAILED (0xFFFFFFFFFFFFFFFF) que como valor
;             sin signo de 64 bits NO es negativo en sentido estricto.
; ==============================================================================

%include "lib/constants.inc"
%include "lib/sys_macros.inc"
%include "lib/graph/core/lib_fb_core.inc"

default rel

; Constantes IOCTL para el Framebuffer
%define FBIOGET_VSCREENINFO 0x4600
%define FBIOGET_FSCREENINFO 0x4602

; MAP_FAILED es el valor que devuelve mmap en caso de error (-1 como sin signo de 64 bits)
%define MAP_FAILED -1

section .bss
    terminal_winsize resw 4
    fb_var_info      resb 160   
    fb_fix_info      resb 100   

section .data
    fb_path db "/dev/fb0", 0    

section .text
    global get_screen_size
    global get_screen_rows
    global get_screen_cols
    global fb_core
    global fb_map

; --- FUNCIONES DE TERMINAL ---
get_screen_size:
    mov rax, SYS_IOCTL
    mov rdi, STDOUT             
    mov rsi, TIOCGWINSZ         
    mov rdx, terminal_winsize   
    syscall
    ret

get_screen_rows:
    xor rax, rax
    mov ax, word [terminal_winsize]     
    ret

get_screen_cols:
    xor rax, rax
    mov ax, word [terminal_winsize + 2] 
    ret

; --- FUNCIONES DE FRAMEBUFFER ---
fb_core:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    mov r12, rdi

    sys_open fb_path, O_RDONLY, 0
    cmp rax, 0
    jl .error
    mov rbx, rax

    ; 1. Info Variable
    mov rdi, rbx
    mov rsi, FBIOGET_VSCREENINFO
    mov rdx, fb_var_info
    mov rax, SYS_IOCTL
    syscall

    ; 2. Info Fija
    mov rdi, rbx
    mov rsi, FBIOGET_FSCREENINFO
    mov rdx, fb_fix_info
    mov rax, SYS_IOCTL
    syscall

    ; 3. Mapeo a estructura ScreenInfo
    mov eax, dword [fb_var_info + 0]
    mov dword [r12 + ScreenInfo.width], eax        
    mov eax, dword [fb_var_info + 4]
    mov dword [r12 + ScreenInfo.height], eax        
    mov eax, dword [fb_var_info + 24]
    mov dword [r12 + ScreenInfo.bpp], eax        
    mov eax, dword [fb_fix_info + 48]
    mov dword [r12 + ScreenInfo.pitch], eax
    mov eax, dword [fb_fix_info + 24]
    mov dword [r12 + ScreenInfo.size_mem], eax
    mov eax, dword [fb_var_info + 92]
    mov dword [r12 + ScreenInfo.phy_width], eax       
    mov eax, dword [fb_var_info + 88]
    mov dword [r12 + ScreenInfo.phy_height], eax       
    mov eax, dword [fb_var_info + 32]
    mov dword [r12 + ScreenInfo.red_off], eax
    mov eax, dword [fb_var_info + 44]
    mov dword [r12 + ScreenInfo.green_off], eax
    mov eax, dword [fb_var_info + 56]
    mov dword [r12 + ScreenInfo.blue_off], eax
    mov eax, dword [fb_var_info + 68]
    mov dword [r12 + ScreenInfo.transp_off], eax

    sys_close rbx
    mov rax, 0
    jmp .fin

.error:
    mov rax, -1
.fin:
    pop r12
    pop rbx
    leave
    ret

fb_map:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    mov r12, rdi

    sys_open fb_path, O_RDWR, 0
    cmp rax, 0
    jl .error_map
    mov rbx, rax

    mov rdi, 0
    mov esi, dword [r12 + ScreenInfo.size_mem]
    mov rdx, PROT_READ | PROT_WRITE
    mov r10, MAP_SHARED
    mov r8, rbx
    mov r9, 0
    mov rax, SYS_MMAP
    syscall

    ; CORRECCIÓN: mmap devuelve MAP_FAILED (-1 sin signo, 0xFFFFFFFFFFFFFFFF) en error.
    ; La comparación anterior con 'cmp rax, 0 / jl' era ambigua para punteros altos.
    ; La forma canónica y correcta es comparar directamente contra -1.
    cmp rax, MAP_FAILED
    je .cerrar_map
    
    mov [r12 + ScreenInfo.ptr_mem], rax
    sys_close rbx
    mov rax, 0
    jmp .fin_map

.cerrar_map:
    sys_close rbx
.error_map:
    mov rax, -1
.fin_map:
    pop r12
    pop rbx
    leave
    ret
