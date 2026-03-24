%include "lib/constants.inc"
default rel
section .bss
    ; Estructura winsize que espera ioctl
    ; struct winsize {
    ;     unsigned short ws_row;
    ;     unsigned short ws_col;
    ;     unsigned short ws_xpixel;
    ;     unsigned short ws_ypixel;
    ; };
    terminal_winsize resw 4 

section .text
global get_screen_size
global get_screen_rows
global get_screen_cols

; -----------------------------------------------------------------
; get_screen_size: Obtiene las dimensiones de la terminal
; Salida: RAX = 0 en éxito, negativo en error
; -----------------------------------------------------------------
get_screen_size:
    mov rax, SYS_IOCTL
    mov rdi, STDOUT             ; Descriptor de salida estándar
    mov rsi, TIOCGWINSZ         ; Petición de tamaño de ventana
    mov rdx, terminal_winsize   ; Puntero al buffer en memoria
    syscall
    ret

; -----------------------------------------------------------------
; get_screen_rows: Devuelve el número de filas de la terminal
; Salida: RAX = número de filas
; -----------------------------------------------------------------
get_screen_rows:
    xor rax, rax
    mov ax, word [terminal_winsize]     ; El primer 'word' son las filas
    ret

; -----------------------------------------------------------------
; get_screen_cols: Devuelve el número de columnas de la terminal
; Salida: RAX = número de columnas
; -----------------------------------------------------------------
get_screen_cols:
    xor rax, rax
    mov ax, word [terminal_winsize + 2] ; El segundo 'word' son las columnas
    ret