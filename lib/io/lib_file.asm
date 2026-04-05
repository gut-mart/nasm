%include "lib/constants.inc"
%include "lib/sys_macros.inc"

section .text
global file_open
global file_read
global file_write
global file_close

; -----------------------------------------------------------------
; file_open: Abre un archivo
; Entrada: RDI = puntero al nombre del archivo (string terminado en 0)
;          RSI = banderas (O_RDONLY, O_WRONLY, etc.)
;          RDX = modo/permisos (ej. MODE_0644)
; Salida:  RAX = File Descriptor (FD) o error (negativo)
; -----------------------------------------------------------------
file_open:
    mov rax, SYS_OPEN
    ; rdi, rsi y rdx ya contienen los parámetros correctos
    syscall
    ret

; -----------------------------------------------------------------
; file_read: Lee de un archivo abierto
; Entrada: RDI = File Descriptor (FD)
;          RSI = puntero al buffer donde guardar los datos
;          RDX = cantidad de bytes a leer
; Salida:  RAX = bytes leídos o error
; -----------------------------------------------------------------
file_read:
    mov rax, SYS_READ
    ; rdi, rsi y rdx ya contienen los parámetros correctos
    syscall
    ret

; -----------------------------------------------------------------
; file_write: Escribe en un archivo abierto
; Entrada: RDI = File Descriptor (FD)
;          RSI = puntero al buffer con los datos a escribir
;          RDX = cantidad de bytes a escribir
; Salida:  RAX = bytes escritos o error
; -----------------------------------------------------------------
file_write:
    mov rax, SYS_WRITE
    ; rdi, rsi y rdx ya contienen los parámetros correctos
    syscall
    ret

; -----------------------------------------------------------------
; file_close: Cierra un archivo
; Entrada: RDI = File Descriptor (FD) a cerrar
; Salida:  RAX = 0 en éxito, error en negativo
; -----------------------------------------------------------------
file_close:
    mov rax, SYS_CLOSE
    ; rdi ya contiene el FD
    syscall
    ret
    