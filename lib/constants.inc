%ifndef CONSTANTS_INC
%define CONSTANTS_INC

; -----------------------------------------------------------------
; Llamadas al sistema (Syscalls) para Linux x86_64
; -----------------------------------------------------------------
%define SYS_READ    0
%define SYS_WRITE   1
%define SYS_OPEN    2
%define SYS_CLOSE   3
%define SYS_LSEEK   8
%define SYS_IOCTL   16
%define SYS_EXIT    60

; -----------------------------------------------------------------
; Banderas de apertura de archivos (File Open Flags)
; -----------------------------------------------------------------
%define O_RDONLY    0       ; Solo lectura
%define O_WRONLY    1       ; Solo escritura
%define O_RDWR      2       ; Lectura y escritura
%define O_CREAT     64      ; Crear archivo si no existe
%define O_TRUNC     512     ; Truncar archivo a tamaño 0
%define O_APPEND    1024    ; Escribir al final del archivo

; -----------------------------------------------------------------
; Desplazamientos para lseek (Seek "Whence")
; -----------------------------------------------------------------
%define SEEK_SET    0       ; Desde el principio del archivo
%define SEEK_CUR    1       ; Desde la posición actual
%define SEEK_END    2       ; Desde el final del archivo

; -----------------------------------------------------------------
; Constantes de Terminal / IOCTL
; -----------------------------------------------------------------

%define STDIN       0
%define STDOUT      1
%define STDERR      2
%define TIOCGWINSZ  0x5413  ; Obtener tamaño de la ventana de la terminal

%endif