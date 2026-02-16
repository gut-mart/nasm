; ==============================================================================
; RUTA: ./lib/graph/lib_graph_get_info_screen.asm
; DESCRIPCIÓN: Obtiene resolución (PX) y tamaño físico (MM) del Framebuffer
; ==============================================================================

default rel
%include "lib/graph/lib_graph_get_info_screen.inc"

section .data
    fb_path db "/dev/fb0", 0

section .text
    global lib_graph_get_info_screen

; ENTRADA: RDI = Puntero a estructura ScreenInfo (debe tener 24 bytes)
; SALIDA:  RAX = 0 (Éxito) o -1 (Error)
lib_graph_get_info_screen:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    push r13

    mov r12, rdi            ; Guardamos el puntero de usuario (ScreenInfo)

    ; --------------------------------------------------------------------------
    ; 1. ABRIR /dev/fb0
    ; --------------------------------------------------------------------------
    mov rax, 2              ; SYS_OPEN
    lea rdi, [fb_path]
    mov rsi, 0              ; O_RDONLY
    syscall
    
    cmp rax, 0
    jl .error
    mov rbx, rax            ; Guardamos el File Descriptor (FD)

    ; --------------------------------------------------------------------------
    ; 2. RESERVAR BUFFER TEMPORAL EN STACK
    ; La estructura del kernel fb_var_screeninfo mide 160 bytes.
    ; Reservamos espacio para que ioctl escriba todo ahí sin romper nada.
    ; --------------------------------------------------------------------------
    sub rsp, 160            ; Reservamos 160 bytes en la pila

    ; --------------------------------------------------------------------------
    ; 3. LLAMADA IOCTL (FBIOGET_VSCREENINFO)
    ; --------------------------------------------------------------------------
    mov rax, 16             ; SYS_IOCTL
    mov rdi, rbx            ; FD
    mov rsi, 0x4600         ; Comando: Dame info variable
    mov rdx, rsp            ; Escribe los datos en el STACK (RSP)
    syscall

    cmp rax, 0
    jl .error_close

    ; --------------------------------------------------------------------------
    ; 4. EXTRAER DATOS (COPIAR DEL STACK A LA ESTRUCTURA DE USUARIO)
    ; --------------------------------------------------------------------------
    
    ; --- Resolución en Píxeles ---
    mov eax, [rsp + 0]      ; xres (Offset 0 del kernel)
    mov [r12 + ScreenInfo.width], eax

    mov eax, [rsp + 4]      ; yres (Offset 4 del kernel)
    mov [r12 + ScreenInfo.height], eax

    mov eax, [rsp + 24]     ; bits_per_pixel (Offset 24 del kernel)
    mov [r12 + ScreenInfo.bpp], eax

    ; --- Dimensiones Físicas (¡LO NUEVO!) ---
    ; Según <linux/fb.h>: 
    ; offset 88 (0x58) = height in mm
    ; offset 92 (0x5C) = width in mm
    
    mov eax, [rsp + 92]     ; width (mm)
    mov [r12 + ScreenInfo.phy_width], eax
    
    mov eax, [rsp + 88]     ; height (mm)
    mov [r12 + ScreenInfo.phy_height], eax

    ; --- Calcular Pitch (LineLength) ---
    ; Pitch = Width * (BPP / 8)
    mov eax, [r12 + ScreenInfo.width]
    mov ecx, [r12 + ScreenInfo.bpp]
    shr ecx, 3              ; Dividir BPP entre 8
    imul eax, ecx           ; Multiplicar
    mov [r12 + ScreenInfo.pitch], eax

    ; --------------------------------------------------------------------------
    ; 5. LIMPIEZA Y SALIDA
    ; --------------------------------------------------------------------------
    add rsp, 160            ; Devolvemos la memoria del stack

    ; Cerrar archivo
    mov rax, 3              ; SYS_CLOSE
    mov rdi, rbx
    syscall

    mov rax, 0              ; Return 0 (Éxito)
    jmp .fin

.error_close:
    add rsp, 160            ; Restaurar stack antes de salir
    mov rax, 3
    mov rdi, rbx
    syscall

.error:
    mov rax, -1

.fin:
    pop r13
    pop r12
    pop rbx
    leave
    ret