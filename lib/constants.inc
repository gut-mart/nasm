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
; --- NUEVAS CONSTANTES: MAPEO DE MEMORIA (FASE 2) ---
; =================================================================

; Banderas de proteccion (prot)
%define PROT_READ   0x1     ; La memoria puede ser leida
%define PROT_WRITE  0x2     ; La memoria puede ser escrita

; Banderas de visibilidad (flags)
%define MAP_SHARED  0x01    ; Comparte los cambios con el dispositivo real (/dev/fb0)