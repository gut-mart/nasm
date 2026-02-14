; ==============================================================================
; RUTA: ./proyectos/graph/main.asm
; ==============================================================================

%include "lib/graph/lib_graph_get_info.inc"

extern lib_graph_get_info

default rel

; ------------------------------------------------------------------------------
; SECCIÓN BSS (Datos no inicializados)
; ------------------------------------------------------------------------------
section .bss
    mi_pantalla resb ScreenInfo_size   ; Estructura para recibir los datos

; ------------------------------------------------------------------------------
; SECCIÓN DATA (Datos inicializados - MÁS SEGURO)
; ------------------------------------------------------------------------------
section .data
    msg_titulo db "--- INFO PANTALLA ---", 10, 0
    msg_ancho  db "Ancho (xres): ", 0
    msg_alto   db "Alto  (yres): ", 0
    msg_bpp    db "BPP:          ", 0
    msg_pitch  db "LineLength:   ", 0
    newline    db 10, 0
    
    ; ¡TRUCO! Inicializamos el buffer con ceros aquí para asegurar que la memoria existe.
    ; Reservamos 32 bytes llenos de ceros.
    buffer_num times 32 db 0 

section .text
    global _start

_start:
    ; 1. OBTENER INFORMACIÓN
    lea rdi, [mi_pantalla]
    call lib_graph_get_info
    
    cmp rax, 0
    jl .error

    ; 2. IMPRIMIR TÍTULO
    lea rsi, [msg_titulo]
    call _print_str

    ; 3. IMPRIMIR ANCHO
    lea rsi, [msg_ancho]
    call _print_str
    
    mov edi, [mi_pantalla + ScreenInfo.width]
    call _print_num_ln

    ; 4. IMPRIMIR ALTO
    lea rsi, [msg_alto]
    call _print_str
    
    mov edi, [mi_pantalla + ScreenInfo.height]
    call _print_num_ln

    ; 5. IMPRIMIR BPP
    lea rsi, [msg_bpp]
    call _print_str
    
    mov edi, [mi_pantalla + ScreenInfo.bpp]
    call _print_num_ln

    ; 6. IMPRIMIR PITCH (LINELENGTH)
    lea rsi, [msg_pitch]
    call _print_str
    
    mov edi, [mi_pantalla + ScreenInfo.pitch]
    call _print_num_ln

    ; SALIR (ÉXITO)
    mov rax, 60         ; SYS_EXIT
    xor rdi, rdi
    syscall

.error:
    ; SALIR (ERROR)
    mov rax, 60
    mov rdi, 1
    syscall

; ==============================================================================
; RUTINAS AUXILIARES ROBUSTAS
; ==============================================================================

; --- _print_str: Imprime hasta encontrar un 0 ---
_print_str:
    push rax
    push rdi
    push rdx
    push rcx
    push rsi            ; Guardamos RSI por seguridad

    ; Calcular longitud (strlen)
    xor rdx, rdx        ; RDX = 0
.len_loop:
    cmp byte [rsi+rdx], 0
    je .do_write
    inc rdx
    jmp .len_loop

.do_write:
    test rdx, rdx       ; Si longitud es 0, no imprimimos nada
    jz .exit_print
    
    mov rax, 1          ; SYS_WRITE
    mov rdi, 1          ; STDOUT
    ; RSI ya apunta al string
    ; RDX ya tiene la longitud
    syscall

.exit_print:
    pop rsi
    pop rcx
    pop rdx
    pop rdi
    pop rax
    ret

; --- _print_num_ln: Convierte EDI a texto y lo imprime + Enter ---
_print_num_ln:
    push rax
    push rbx
    push rcx
    push rdx
    push rsi
    push rdi

    mov eax, edi                ; Número a convertir
    
    ; Usamos el buffer en .data (buffer_num)
    ; Apuntamos al final del buffer (byte 30) para escribir hacia atrás
    lea rsi, [buffer_num + 30]  
    mov byte [rsi], 0           ; Terminador nulo al final
    
    mov ebx, 10                 ; Divisor

.convert_loop:
    xor edx, edx                ; Limpiar parte alta para división
    div ebx                     ; EAX / 10 -> Cociente EAX, Resto EDX
    
    add dl, '0'                 ; Convertir número a ASCII
    dec rsi                     ; Retroceder en el buffer
    mov [rsi], dl               ; Guardar letra
    
    test eax, eax               ; ¿Queda número?
    jnz .convert_loop           ; Si no es 0, repetir

    ; Ahora RSI apunta al principio del número generado. Imprimimos.
    call _print_str
    
    ; Imprimir salto de línea
    lea rsi, [newline]
    call _print_str

    pop rdi
    pop rsi
    pop rdx
    pop rcx
    pop rbx
    pop rax
    ret