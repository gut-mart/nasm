%include "lib/constants.inc"
%include "lib/sys_macros.inc"

default rel

; Constante IOCTL para el Framebuffer
%define FBIOGET_VSCREENINFO 0x4600

section .bss
    terminal_winsize resw 4
    fb_var_info      resb 160   

section .data
    fb_path db "/dev/fb0", 0    

section .text
    global get_screen_size
    global get_screen_rows
    global get_screen_cols
    global fb_info

; =================================================================
; 1. FUNCIONES DE TERMINAL (Texto)
; =================================================================
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

; =================================================================
; 2. FUNCIONES DE HARDWARE GRAFICO (Framebuffer)
; =================================================================
fb_info:
    push rbp
    mov rbp, rsp
    push rbx
    push r12

    mov r12, rdi            

    ; 1. Abrir dispositivo
    sys_open fb_path, O_RDONLY, 0
    cmp rax, 0
    jl .error
    mov rbx, rax            

    ; 2. Llamada al sistema IOCTL
    mov rdi, rbx
    mov rsi, FBIOGET_VSCREENINFO
    mov rdx, fb_var_info
    mov rax, SYS_IOCTL
    syscall
    cmp rax, 0
    jl .cerrar_error

    ; 3. Mapear datos
    mov eax, dword [fb_var_info + 0]
    mov dword [r12 + 0], eax        
    
    mov eax, dword [fb_var_info + 4]
    mov dword [r12 + 4], eax        

    mov eax, dword [fb_var_info + 24]
    mov dword [r12 + 8], eax        

    mov eax, dword [fb_var_info + 92]
    mov dword [r12 + 16], eax       
    
    mov eax, dword [fb_var_info + 88]
    mov dword [r12 + 20], eax       

    ; 4. Cerrar y salir
    sys_close rbx
    mov rax, 0
    jmp .fin

.cerrar_error:
    sys_close rbx
.error:
    mov rax, -1

.fin:
    pop r12
    pop rbx
    leave
    ret