; =================================================================
; ARCHIVO: lib/constants.inc
; DESCRIPCION: Definicion de constantes globales del sistema (x86_64)
; =================================================================

; --- Llamadas al sistema (Syscalls) ---
%define SYS_READ    0
%define SYS_WRITE   1
%define SYS_OPEN    2
%define SYS_CLOSE   3
%define SYS_MMAP    9       ; Mapeo de memoria en espacio de usuario
%define SYS_IOCTL   16
%define SYS_EXIT    60

; --- Descriptores de archivo estandar ---
%define STDIN       0
%define STDOUT      1
%define STDERR      2

; --- Banderas para apertura de archivos (sys_open) ---
%define O_RDONLY    0       ; Solo lectura
%define O_WRONLY    1       ; Solo escritura
%define O_RDWR      2       ; Lectura y escritura

; --- Constantes IOCTL (Terminal y Dispositivos) ---
%define TIOCGWINSZ  0x5413  ; Obtener tamaño de ventana de terminal

; =================================================================
; --- CONSTANTES: MAPEO DE MEMORIA ---
; =================================================================

; Banderas de proteccion (prot)
%define PROT_READ   0x1     ; La memoria puede ser leida
%define PROT_WRITE  0x2     ; La memoria puede ser escrita

; Banderas de visibilidad (flags)
%define MAP_SHARED  0x01    ; Comparte los cambios con el dispositivo real (/dev/fb0)

; =================================================================
; --- CONSTANTES: CONTROL DE TERMINAL (termios) ---
; =================================================================

; IOCTL para leer/escribir configuración del terminal
%define TCGETS      0x5401  ; Leer configuración actual del terminal
%define TCSETS      0x5402  ; Escribir configuración (efecto inmediato)

; Índices en la estructura termios (cada campo es un dword de 32 bits)
; struct termios { c_iflag, c_oflag, c_cflag, c_lflag, c_line, c_cc[19] }
%define TERMIOS_IFLAG   0   ; Offset c_iflag (input flags)
%define TERMIOS_OFLAG   4   ; Offset c_oflag (output flags)
%define TERMIOS_CFLAG   8   ; Offset c_cflag (control flags)
%define TERMIOS_LFLAG   12  ; Offset c_lflag (local flags)
%define TERMIOS_LINE    16  ; Offset c_line  (line discipline)
%define TERMIOS_CC      17  ; Offset c_cc    (control chars, 19 bytes)
%define TERMIOS_SIZE    36  ; Tamaño total de la estructura

; Bits de c_lflag relevantes
%define ICANON      0x0002  ; Modo canónico (lectura línea a línea)
%define ECHO        0x0008  ; Eco de caracteres en pantalla

; Secuencias de escape ANSI para control del cursor
; Se usan directamente como strings en section .data de lib_console.asm
