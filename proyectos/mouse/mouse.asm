; ==============================================================================
; RUTA: ./proyectos/mouse/mouse_v2.asm
; DESCRIPCIÓN: Detector de Mouse usando tu librería de conversión.
;              Muestra coordenadas X, Y en texto legible.
; ==============================================================================

%include "lib/constants.inc"
%include "lib/cnv/lib_cnv_uint32_to_str.inc"

; Constantes de Terminal
%define TCGETS 0x5401
%define TCSETS 0x5402

default rel

section .data
    msg_on      db 27, "[?1000h", 0    ; Activar Mouse
    msg_off     db 27, "[?1000l", 0    ; Desactivar Mouse
    msg_clear   db 27, "[2J", 27, "[H", 0 ; Limpiar pantalla
    
    txt_click   db "CLIC DETECTADO -> X: ", 0
    txt_y       db "  Y: ", 0
    txt_btn     db "  BTN: ", 0
    newline     db 10, 0
    
    ; Borrar línea actual (Carriage Return + Clear Line)
    reset_line  db 13, 27, "[K", 0 

section .bss
    termios_old resb 60
    termios_new resb 60
    buffer_in   resb 1
    
    ; Buffers para convertir los números a texto
    str_x       resb 16
    str_y       resb 16
    str_btn     resb 16

section .text
    global _start

_start:
    ; 1. Configurar Modo Raw
    call _enable_raw_mode

    ; 2. Limpiar e iniciar
    lea rsi, [msg_clear]
    call _print_str
    lea rsi, [msg_on]
    call _print_str

.loop:
    ; Leer 1 byte
    mov rax, SYS_READ
    mov rdi, STDIN
    lea rsi, [buffer_in]
    mov rdx, 1
    syscall

    cmp rax, 0
    jle .loop

    mov al, [buffer_in]

    ; Salir con 'q'
    cmp al, 'q'
    je .exit

    ; Chequear secuencia ESC [ M
    cmp al, 27      ; ESC
    jne .loop
    
    call _read_byte
    cmp al, '['
    jne .loop
    
    call _read_byte
    cmp al, 'M'
    jne .loop

    ; --- PROCESAR CLIC ---
    
    ; 1. LEER BOTÓN
    call _read_byte
    and rax, 0xFF       ; Limpiar basura de bits altos
    sub rax, 32         ; Decodificar (Byte - 32)
    
    ; Convertir Botón a String usando TU LIBRERÍA
    lea rdi, [str_btn]  ; Buffer destino
    mov esi, eax        ; Número
    mov edx, 10         ; Base 10
    call lib_cnv_uint32_to_str

    ; 2. LEER X
    call _read_byte
    and rax, 0xFF
    sub rax, 32         ; Decodificar X
    
    ; Convertir X a String
    lea rdi, [str_x]
    mov esi, eax
    mov edx, 10
    call lib_cnv_uint32_to_str

    ; 3. LEER Y
    call _read_byte
    and rax, 0xFF
    sub rax, 32         ; Decodificar Y
    
    ; Convertir Y a String
    lea rdi, [str_y]
    mov esi, eax
    mov edx, 10
    call lib_cnv_uint32_to_str

    ; --- IMPRIMIR TODO EN UNA LÍNEA ---
    lea rsi, [reset_line]   ; Borrar línea anterior
    call _print_str
    
    lea rsi, [txt_click]
    call _print_str
    lea rsi, [str_x]        ; Imprimir valor X
    call _print_str
    
    lea rsi, [txt_y]
    call _print_str
    lea rsi, [str_y]        ; Imprimir valor Y
    call _print_str

    lea rsi, [txt_btn]
    call _print_str
    lea rsi, [str_btn]      ; Imprimir valor Botón
    call _print_str

    ; Forzar que se vea (flush) es automático con newlines, 
    ; pero en raw mode a veces hay que tener cuidado.
    jmp .loop


.exit:
    lea rsi, [msg_off]
    call _print_str
    call _disable_raw_mode
    mov rax, SYS_EXIT
    xor rdi, rdi
    syscall

; ==============================================================================
; RUTINAS INTERNAS
; ==============================================================================
_read_byte:
    push rdi
    push rsi
    push rdx
    mov rax, SYS_READ
    mov rdi, STDIN
    lea rsi, [buffer_in]
    mov rdx, 1
    syscall
    mov al, [buffer_in]
    pop rdx
    pop rsi
    pop rdi
    ret

_print_str:
    push rdx
    push rdi
    push rax
    
    ; Calcular longitud (strlen simple)
    xor rdx, rdx
.len:
    cmp byte [rsi+rdx], 0
    je .go
    inc rdx
    jmp .len
.go:
    mov rax, SYS_WRITE
    mov rdi, STDOUT
    syscall
    
    pop rax
    pop rdi
    pop rdx
    ret

_enable_raw_mode:
    mov rax, 16
    mov rdi, STDIN
    mov rsi, TCGETS
    lea rdx, [termios_old]
    syscall
    mov rcx, 60
    lea rsi, [termios_old]
    lea rdi, [termios_new]
    rep movsb
    and dword [termios_new+12], 0xFFFFFFF5 ; Apagar ECHO y ICANON
    mov rax, 16
    mov rdi, STDIN
    mov rsi, TCSETS
    lea rdx, [termios_new]
    syscall
    ret

_disable_raw_mode:
    mov rax, 16
    mov rdi, STDIN
    mov rsi, TCSETS
    lea rdx, [termios_old]
    syscall
    ret