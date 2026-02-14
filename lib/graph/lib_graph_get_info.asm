; ==============================================================================
; RUTA: ./lib/graph/lib_graph_get_info.asm
; DESCRIPCIÓN: Librería para obtener geometría de pantalla desde /dev/fb0.
; ==============================================================================

%include "lib/constants.inc"
%include "lib/graph/lib_graph_get_info.inc"

; Constantes internas
FBIOGET_VSCREENINFO equ 0x4600  
SYS_OPEN            equ 2
SYS_CLOSE           equ 3
SYS_IOCTL           equ 16
O_RDONLY            equ 0

default rel

section .data
    dev_fb db "/dev/fb0", 0

section .text
    global lib_graph_get_info

; ------------------------------------------------------------------------------
; FUNCIÓN: lib_graph_get_info
; ENTRADA: RDI = Puntero a una estructura ScreenInfo donde guardar los datos
; SALIDA:  RAX = 0 (Éxito), -1 (Error)
; ------------------------------------------------------------------------------
lib_graph_get_info:
    push rbp
    mov rbp, rsp
    push rbx
    push r12                ; Guardamos registros callee-saved
    
    mov r12, rdi            ; R12 = Puntero del usuario (ScreenInfo)

    ; 1. ABRIR /dev/fb0
    mov rax, SYS_OPEN
    lea rdi, [dev_fb]
    mov rsi, O_RDONLY
    syscall
    
    cmp rax, 0
    jl .error
    mov rbx, rax            ; RBX = File Descriptor

    ; 2. RESERVAR BUFFER TEMPORAL PARA IOCTL
    sub rsp, 160            ; Estructura fb_var_screeninfo del kernel

    ; 3. CONSULTAR AL DRIVER (IOCTL)
    mov rax, SYS_IOCTL
    mov edi, ebx            ; FD
    mov rsi, FBIOGET_VSCREENINFO
    mov rdx, rsp            ; Puntero al stack
    syscall

    test rax, rax
    jnz .error_close

    ; 4. EXTRAER Y CALCULAR
    ; Leemos del stack lo que dijo el kernel
    mov r8d,  [rsp]         ; Offset 0:  xres (Ancho)
    mov r9d,  [rsp + 4]     ; Offset 4:  yres (Alto)
    mov r10d, [rsp + 24]    ; Offset 24: bits_per_pixel

    ; Calculamos el Pitch (LineLength) matemáticamente
    ; Pitch = Ancho * (BPP / 8)
    mov r11d, r10d
    shr r11d, 3             ; Dividir bits entre 8 para sacar bytes
    imul r11d, r8d          ; Multiplicar por el ancho

    ; 5. GUARDAR EN LA ESTRUCTURA DEL USUARIO (R12)
    mov [r12 + ScreenInfo.width],  r8d
    mov [r12 + ScreenInfo.height], r9d
    mov [r12 + ScreenInfo.bpp],    r10d
    mov [r12 + ScreenInfo.pitch],  r11d  ; ¡Aquí va el 7680!

    ; 6. LIMPIEZA
    add rsp, 160            ; Liberar buffer temporal
    
    mov rax, SYS_CLOSE      ; Cerrar archivo
    mov edi, ebx
    syscall

    xor rax, rax            ; Return 0 (Éxito)
    jmp .fin

.error_close:
    add rsp, 160
    mov rax, SYS_CLOSE
    mov edi, ebx
    syscall
    mov rax, -1
    jmp .fin

.error:
    mov rax, -1

.fin:
    pop r12
    pop rbx
    leave
    ret