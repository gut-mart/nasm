; ==============================================================================
; RUTA: ./lib/graph/bmp/lib_bmp_write.asm
; DESCRIPCIÓN: Escribe el contenido del framebuffer en un archivo BMP de 24 bits
;              sin compresión, compatible con cualquier visor de imágenes.
; CONTRATO:
;   Entrada: RDI = ScreenInfo (mapeada con fb_map)
;            RSI = puntero a ruta del archivo (cadena NUL)
;   Salida:  RAX = 0 éxito, RAX = -1 error de archivo.
; SOPORTE bpp: lee ScreenInfo.bpp y recorre el framebuffer con el tamaño real
;   de píxel (2/3/4 bytes). A 32/24 bpp copia B,G,R directos; a 16 bpp
;   desempaqueta cada canal con los offsets y longitudes de ScreenInfo
;   (RGB565 o similar) y lo expande a 8 bits replicando los bits altos
;   (0b11111 → 0xFF, para que el blanco sature de verdad).
; CORRECCIÓN v4: bytes_por_fila se guardaba como dword pero se leía como qword,
;                los 4 bytes superiores contenían basura del stack causando un
;                bucle de padding de ~4 millones de iteraciones y segfault.
;                Corregido: se guarda y lee como qword consistentemente.
; CORRECCIÓN v5: cada fila se lee desde ptr_mem + fila*pitch en lugar de
;                asumir filas contiguas (pitch == ancho*bytes). En hardware
;                con padding de fila la imagen salía escalonada.
; ==============================================================================

%include "lib/constants.inc"
%include "lib/sys_macros.inc"
%include "lib/graph/core/lib_fb_core.inc"

%define O_WRONLY        1
%define O_CREAT         0x40
%define O_TRUNC         0x200
%define MODE_0644       0x1A4
%define BMP_HEADER_SIZE 54
%define BMP_INFO_SIZE   40
%define BMP_PLANES      1
%define BMP_BPP         24
%define BMP_COMPRESSION 0
%define ROW_BUFFER_SIZE 5763

default rel

section .bss
    bmp_header  resb 54
    row_buffer  resb ROW_BUFFER_SIZE

section .text
    global lib_bmp_write

; ------------------------------------------------------------------------------
; MAPA DE REGISTROS:
;   RBX  = puntero actual al framebuffer
;   R12  = ScreenInfo
;   R13  = ruta archivo
;   R14D = ancho (width)
;   R15D = alto (height)
;   [rbp - 48] = file descriptor          (qword)
;   [rbp - 56] = bytes por fila + padding (qword)
;   [rbp - 64] = pitch del framebuffer    (qword)
;   [rbp - 72] = bytes por píxel          (qword)
;   R10D = fila actual
;   R11  = contador píxeles / padding
; ------------------------------------------------------------------------------
lib_bmp_write:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp, 32             ; ver mapa de registros

    mov r12, rdi
    mov r13, rsi

    mov r14d, dword [r12 + ScreenInfo.width]
    mov r15d, dword [r12 + ScreenInfo.height]

    ; --- pitch y bytes por píxel del framebuffer real ---
    mov eax, dword [r12 + ScreenInfo.pitch]
    mov qword [rbp - 64], rax
    mov eax, dword [r12 + ScreenInfo.bpp]
    shr eax, 3
    mov qword [rbp - 72], rax

    ; --- bytes por fila BMP con padding: (ancho*3 + 3) & ~3 ---
    mov eax, r14d
    imul eax, 3
    add eax, 3
    and eax, 0xFFFFFFFC
    ; Guardar como QWORD para leer como qword después sin basura en bits altos
    movzx rax, eax                  ; zero-extend a 64 bits
    mov qword [rbp - 56], rax       ; guardar qword limpio

    ; --- tamaño datos imagen ---
    mov eax, dword [rbp - 56]
    imul eax, r15d
    mov dword [bmp_header + 34], eax

    ; --- tamaño total archivo ---
    add eax, BMP_HEADER_SIZE
    mov dword [bmp_header + 2], eax

    ; --- cabecera BMP ---
    mov byte  [bmp_header +  0], 'B'
    mov byte  [bmp_header +  1], 'M'
    mov dword [bmp_header +  6], 0
    mov dword [bmp_header + 10], BMP_HEADER_SIZE
    mov dword [bmp_header + 14], BMP_INFO_SIZE
    mov dword [bmp_header + 18], r14d
    mov eax, r15d
    neg eax
    mov dword [bmp_header + 22], eax
    mov word  [bmp_header + 26], BMP_PLANES
    mov word  [bmp_header + 28], BMP_BPP
    mov dword [bmp_header + 30], BMP_COMPRESSION
    mov dword [bmp_header + 38], 0
    mov dword [bmp_header + 42], 0
    mov dword [bmp_header + 46], 0
    mov dword [bmp_header + 50], 0

    ; --- Abrir archivo ---
    mov rdi, r13
    mov rsi, O_WRONLY | O_CREAT | O_TRUNC
    mov rdx, MODE_0644
    mov rax, SYS_OPEN
    syscall
    cmp rax, 0
    jl .error
    mov qword [rbp - 48], rax

    ; --- Escribir cabecera ---
    mov rdi, qword [rbp - 48]
    mov rsi, bmp_header
    mov rdx, BMP_HEADER_SIZE
    mov rax, SYS_WRITE
    syscall
    cmp rax, BMP_HEADER_SIZE
    jne .error_close

    xor r10d, r10d

.bucle_filas:
    cmp r10d, r15d
    jge .filas_fin

    ; Inicio REAL de la fila: ptr_mem + fila * pitch (v5: respeta el padding
    ; de fila del framebuffer, no asume filas contiguas)
    mov eax, r10d
    imul rax, qword [rbp - 64]
    add rax, qword [r12 + ScreenInfo.ptr_mem]
    mov rbx, rax

    lea rdi, [row_buffer]
    mov r11d, r14d

    ; Despacho por bytes por píxel (una vez por fila)
    mov rax, qword [rbp - 72]
    cmp eax, 4
    je .pix32
    cmp eax, 3
    je .pix24
    jmp .pix16

    ; --- 32 bpp: copiar B,G,R y saltar el byte de relleno ---
.pix32:
    test r11d, r11d
    jz .pixeles_fin
    mov al, byte [rbx + 0]
    mov byte [rdi + 0], al
    mov al, byte [rbx + 1]
    mov byte [rdi + 1], al
    mov al, byte [rbx + 2]
    mov byte [rdi + 2], al
    add rbx, 4
    add rdi, 3
    dec r11d
    jmp .pix32

    ; --- 24 bpp: copiar B,G,R directos ---
.pix24:
    test r11d, r11d
    jz .pixeles_fin
    mov al, byte [rbx + 0]
    mov byte [rdi + 0], al
    mov al, byte [rbx + 1]
    mov byte [rdi + 1], al
    mov al, byte [rbx + 2]
    mov byte [rdi + 2], al
    add rbx, 3
    add rdi, 3
    dec r11d
    jmp .pix24

    ; --- 16 bpp: desempaquetar cada canal con offsets/longitudes reales ---
.pix16:
    test r11d, r11d
    jz .pixeles_fin
    movzx edx, word [rbx]           ; EDX = palabra cruda del píxel

    mov r8d, dword [r12 + ScreenInfo.blue_off]
    mov r9d, dword [r12 + ScreenInfo.blue_len]
    call .extraer_canal
    mov byte [rdi + 0], al          ; B

    mov r8d, dword [r12 + ScreenInfo.green_off]
    mov r9d, dword [r12 + ScreenInfo.green_len]
    call .extraer_canal
    mov byte [rdi + 1], al          ; G

    mov r8d, dword [r12 + ScreenInfo.red_off]
    mov r9d, dword [r12 + ScreenInfo.red_len]
    call .extraer_canal
    mov byte [rdi + 2], al          ; R

    add rbx, 2
    add rdi, 3
    dec r11d
    jmp .pix16

.pixeles_fin:
    ; calcular padding = bytes_por_fila - (ancho * 3)
    lea rsi, [row_buffer]
    mov rdx, rdi
    sub rdx, rsi                    ; rdx = ancho * 3 (bytes escritos)
    mov r11, qword [rbp - 56]       ; r11 = bytes_por_fila (qword limpio)
    sub r11, rdx                    ; r11 = padding
    jz .sin_padding
.pad_bucle:
    mov byte [rdi], 0
    inc rdi
    dec r11
    jnz .pad_bucle
.sin_padding:

    ; escribir fila
    mov rdi, qword [rbp - 48]
    lea rsi, [row_buffer]
    mov rdx, qword [rbp - 56]
    mov rax, SYS_WRITE
    syscall
    cmp rax, 0
    jl .error_close

    inc r10d
    jmp .bucle_filas

.filas_fin:
    mov rdi, qword [rbp - 48]
    mov rax, SYS_CLOSE
    syscall
    mov rax, 0
    jmp .fin

.error_close:
    mov rdi, qword [rbp - 48]
    mov rax, SYS_CLOSE
    syscall
.error:
    mov rax, -1
.fin:
    add rsp, 32
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    leave
    ret

; ------------------------------------------------------------------------------
; .extraer_canal — extrae un canal de una palabra de 16 bpp y lo expande a 8 bits.
; ENTRADA: EDX = palabra cruda del píxel (se preserva)
;          R8D = offset del canal, R9D = longitud del canal (bits)
; SALIDA:  AL  = canal expandido a 8 bits.
; NOTA: expansión por replicación de bits: (v << (8-len)) | (v >> (2*len-8)),
;       así el máximo del canal (0b11111) mapea a 0xFF exacto y el 0 a 0x00.
;       Destruye EAX, ECX, R8D. Longitud 0 → canal ausente → devuelve 0.
; ------------------------------------------------------------------------------
.extraer_canal:
    mov ecx, r8d
    mov eax, edx
    shr eax, cl                     ; alinear el canal al bit 0
    mov ecx, r9d
    mov r8d, 1
    shl r8d, cl
    dec r8d                         ; R8D = máscara (1<<len)-1
    and eax, r8d                    ; EAX = valor crudo del canal
    mov r8d, eax
    mov ecx, 8
    sub ecx, r9d
    shl eax, cl                     ; v << (8-len): bits altos del resultado
    mov ecx, r9d
    add ecx, ecx
    sub ecx, 8                      ; 2*len - 8
    shr r8d, cl                     ; replicar los bits altos en los bajos
    or eax, r8d
    ret
