; ==============================================================================
; RUTA: ./lib/graph/bmp/lib_bmp_write.asm
; DESCRIPCIÓN: Escribe el contenido del framebuffer en un archivo BMP de 24 bits
;              sin compresión, compatible con cualquier visor de imágenes.
; CONTRATO:
;   Entrada: RDI = Puntero a ScreenInfo (con ptr_mem ya mapeado)
;            RSI = Puntero a la ruta completa del archivo (string NUL)
;   Salida:  RAX = 0 si éxito
;            RAX = -1 si error al abrir/escribir el archivo
; NOTAS:
;   - Convierte BGRA (formato nativo del framebuffer) a BGR (24 bpp BMP).
;     El canal alfa se descarta. El resultado abre correctamente en cualquier
;     visor sin necesidad de reinterpretar canales.
;   - El alto se escribe negativo en la cabecera para orden top-down.
;   - Cada fila se rellena con ceros hasta múltiplo de 4 bytes (padding BMP).
; CORRECCIÓN respecto a versión anterior (32 bpp):
;   La versión anterior copiaba los 4 bytes BGRA directamente. El canal alfa=0
;   era interpretado como transparencia total por PIL y otros visores,
;   resultando en imagen negra. Con 24 bpp el canal alfa desaparece.
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
%define ROW_BUFFER_SIZE 5763    ; 1920*3 + 3 bytes padding máx

default rel

section .bss
    bmp_header  resb 54
    row_buffer  resb ROW_BUFFER_SIZE

section .text
    global lib_bmp_write

; ------------------------------------------------------------------------------
; MAPA DE REGISTROS:
;   RBX = file descriptor
;   R12 = ScreenInfo
;   R13 = ruta archivo
;   R14D = ancho (width)
;   R15D = alto (height)
;   durante el bucle:
;   R9  = puntero actual al framebuffer
;   R10D = fila actual
;   R11D = píxeles restantes / contador padding
;   EBX_low no usar — RBX es el FD
;   ECX = bytes por fila con padding
; ------------------------------------------------------------------------------
lib_bmp_write:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    push r13
    push r14
    push r15

    mov r12, rdi
    mov r13, rsi

    mov r14d, dword [r12 + ScreenInfo.width]
    mov r15d, dword [r12 + ScreenInfo.height]

    ; --- bytes por fila con padding: (ancho*3 + 3) & ~3 ---
    mov eax, r14d
    imul eax, 3
    add eax, 3
    and eax, 0xFFFFFFFC
    mov ecx, eax                ; ECX = bytes por fila con padding

    ; --- tamaño datos imagen: row_bytes * alto ---
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
    mov rbx, rax                ; RBX = FD

    ; --- Escribir cabecera ---
    mov rdi, rbx
    mov rsi, bmp_header
    mov rdx, BMP_HEADER_SIZE
    mov rax, SYS_WRITE
    syscall
    cmp rax, BMP_HEADER_SIZE
    jne .error_close

    ; --- Bucle de filas ---
    mov r9, qword [r12 + ScreenInfo.ptr_mem]
    xor r10d, r10d

.bucle_filas:
    cmp r10d, r15d
    jge .filas_fin

    ; Convertir fila BGRA → BGR en row_buffer
    lea rdi, [row_buffer]
    mov r11d, r14d

.bucle_pixeles:
    test r11d, r11d
    jz .pixeles_fin
    mov al, byte [r9 + 0]       ; B
    mov byte [rdi + 0], al
    mov al, byte [r9 + 1]       ; G
    mov byte [rdi + 1], al
    mov al, byte [r9 + 2]       ; R
    mov byte [rdi + 2], al
    add r9, 4
    add rdi, 3
    dec r11d
    jmp .bucle_pixeles

.pixeles_fin:
    ; Padding hasta múltiplo de 4
    lea rsi, [row_buffer]
    mov rdx, rdi
    sub rdx, rsi                ; rdx = ancho * 3
    mov r11, rcx
    sub r11, rdx                ; r11 = bytes de padding
    jz .sin_padding
.pad_bucle:
    mov byte [rdi], 0
    inc rdi
    dec r11
    jnz .pad_bucle
.sin_padding:

    ; Escribir fila
    mov rdi, rbx
    lea rsi, [row_buffer]
    mov rdx, rcx                ; bytes por fila con padding
    mov rax, SYS_WRITE
    syscall
    cmp rax, 0
    jl .error_close

    inc r10d
    jmp .bucle_filas

.filas_fin:
    sys_close rbx
    mov rax, 0
    jmp .fin

.error_close:
    sys_close rbx
.error:
    mov rax, -1
.fin:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    leave
    ret
