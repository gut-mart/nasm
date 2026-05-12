; ==============================================================================
; RUTA: ./lib/io/lib_console.asm
; DESCRIPCIÓN: Control del cursor del terminal y lectura de tecla sin eco.
;              Útil para comandos gráficos que dibujan en el framebuffer y
;              necesitan ocultar el cursor mientras muestran la imagen.
;
; FUNCIONES EXPORTADAS:
;   lib_cursor_hide  — Oculta el cursor del terminal
;   lib_cursor_show  — Restaura el cursor del terminal
;   lib_wait_key     — Espera a que se pulse cualquier tecla (sin eco,
;                      sin necesidad de pulsar Enter)
;
; USO TÍPICO EN UN COMANDO GRÁFICO:
;   call lib_cursor_hide
;   ; ... dibujar en framebuffer ...
;   call lib_wait_key     ; pantalla limpia, sin cursor, hasta que el usuario pulse
;   call lib_cursor_show
;
; CONTRATO lib_cursor_hide / lib_cursor_show:
;   Entrada: ninguna
;   Salida:  ninguna. No modifica registros visibles al llamante.
;
; CONTRATO lib_wait_key:
;   Entrada: ninguna
;   Salida:  AL = código ASCII de la tecla pulsada (0 si tecla especial)
;            Restaura el modo del terminal antes de retornar.
; ==============================================================================

%include "lib/constants.inc"
%include "lib/sys_macros.inc"

default rel

section .data
    ; Secuencias de escape ANSI
    seq_hide    db 0x1B, "[?25l", 0     ; ESC[?25l — ocultar cursor
    seq_show    db 0x1B, "[?25h", 0     ; ESC[?25h — mostrar cursor

section .bss
    termios_orig  resb TERMIOS_SIZE     ; copia de seguridad del estado original
    termios_raw   resb TERMIOS_SIZE     ; estado modificado (modo raw)
    key_buf       resb 1                ; buffer para leer un byte

section .text
    global lib_cursor_hide
    global lib_cursor_show
    global lib_wait_key

; ------------------------------------------------------------------------------
; lib_cursor_hide — Oculta el cursor escribiendo ESC[?25l en STDOUT
; ------------------------------------------------------------------------------
lib_cursor_hide:
    push rbp
    mov rbp, rsp
    push rbx
    sub rsp, 8                  ; alineación ABI

    ; Calcular longitud de seq_hide (6 bytes sin el NUL)
    mov rdi, STDOUT
    mov rsi, seq_hide
    mov rdx, 6                  ; longitud de ESC[?25l
    mov rax, SYS_WRITE
    syscall

    add rsp, 8
    pop rbx
    leave
    ret

; ------------------------------------------------------------------------------
; lib_cursor_show — Restaura el cursor escribiendo ESC[?25h en STDOUT
; ------------------------------------------------------------------------------
lib_cursor_show:
    push rbp
    mov rbp, rsp
    push rbx
    sub rsp, 8

    mov rdi, STDOUT
    mov rsi, seq_show
    mov rdx, 6                  ; longitud de ESC[?25h
    mov rax, SYS_WRITE
    syscall

    add rsp, 8
    pop rbx
    leave
    ret

; ------------------------------------------------------------------------------
; lib_wait_key — Espera una tecla en modo raw (sin eco, sin Enter)
;
; Proceso:
;   1. Leer configuración actual del terminal (TCGETS)
;   2. Guardar copia de seguridad
;   3. Desactivar ICANON y ECHO (modo raw mínimo)
;   4. Aplicar nueva configuración (TCSETS)
;   5. Leer 1 byte de STDIN
;   6. Restaurar configuración original
;   7. Retornar el byte leído en AL
; ------------------------------------------------------------------------------
lib_wait_key:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    sub rsp, 8                  ; alineación

    ; --- 1. Leer configuración actual ---
    mov rax, SYS_IOCTL
    mov rdi, STDIN
    mov rsi, TCGETS
    mov rdx, termios_orig
    syscall
    cmp rax, 0
    jl .leer_directo            ; Si falla (no es terminal), leer directamente

    ; --- 2. Copiar a termios_raw ---
    ; Copiar los 36 bytes de termios_orig a termios_raw
    mov rsi, termios_orig
    mov rdi, termios_raw
    mov ecx, TERMIOS_SIZE
.copiar:
    mov al, byte [rsi]
    mov byte [rdi], al
    inc rsi
    inc rdi
    dec ecx
    jnz .copiar

    ; --- 3. Desactivar ICANON y ECHO en c_lflag ---
    mov eax, dword [termios_raw + TERMIOS_LFLAG]
    and eax, ~(ICANON | ECHO)
    mov dword [termios_raw + TERMIOS_LFLAG], eax

    ; --- 4. Aplicar modo raw ---
    mov rax, SYS_IOCTL
    mov rdi, STDIN
    mov rsi, TCSETS
    mov rdx, termios_raw
    syscall

    ; --- 5. Leer 1 byte ---
.leer_directo:
    mov rax, SYS_READ
    mov rdi, STDIN
    mov rsi, key_buf
    mov rdx, 1
    syscall

    ; --- 6. Restaurar terminal ---
    mov rax, SYS_IOCTL
    mov rdi, STDIN
    mov rsi, TCSETS
    mov rdx, termios_orig
    syscall

    ; --- 7. Retornar tecla en AL ---
    movzx eax, byte [key_buf]

    add rsp, 8
    pop r12
    pop rbx
    leave
    ret
