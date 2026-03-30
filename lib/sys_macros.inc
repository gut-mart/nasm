; ==============================================================================
; LIBRERÍA: sys_macros.inc
; DESCRIPCIÓN: Macros para simplificar las llamadas al sistema (Syscalls) x86_64.
; ==============================================================================

; Evitar inclusiones múltiples
%ifndef SYS_MACROS_INC
%define SYS_MACROS_INC

; ------------------------------------------------------------------------------
; MACRO: sys_write
; Uso:   sys_write <fd>, <buffer>, <tamaño>
; ------------------------------------------------------------------------------
%macro sys_write 3
    mov rdx, %3     ; Parámetro 3: Tamaño
    mov rsi, %2     ; Parámetro 2: Puntero al buffer
    mov rdi, %1     ; Parámetro 1: File Descriptor (Ej. 1 para STDOUT)
    mov rax, 1      ; Syscall: sys_write
    syscall
%endmacro

; ------------------------------------------------------------------------------
; MACRO: sys_read
; Uso:   sys_read <fd>, <buffer>, <tamaño>
; ------------------------------------------------------------------------------
%macro sys_read 3
    mov rdx, %3
    mov rsi, %2
    mov rdi, %1
    mov rax, 0      ; Syscall: sys_read
    syscall
%endmacro

; ------------------------------------------------------------------------------
; MACRO: sys_open
; Uso:   sys_open <archivo>, <flags>, <permisos>
; ------------------------------------------------------------------------------
%macro sys_open 3
    mov rdx, %3     ; Permisos (ej. 420 para 0644)
    mov rsi, %2     ; Flags (ej. 0 para O_RDONLY, 577 para escritura/creación)
    mov rdi, %1     ; Puntero a la ruta del archivo
    mov rax, 2      ; Syscall: sys_open
    syscall
%endmacro

; ------------------------------------------------------------------------------
; MACRO: sys_close
; Uso:   sys_close <fd>
; ------------------------------------------------------------------------------
%macro sys_close 1
    mov rdi, %1     ; File Descriptor a cerrar
    mov rax, 3      ; Syscall: sys_close
    syscall
%endmacro

; ------------------------------------------------------------------------------
; MACRO: sys_lseek
; Uso:   sys_lseek <fd>, <offset>, <origen>
; ------------------------------------------------------------------------------
%macro sys_lseek 3
    mov rdx, %3     ; Origen (0 = SEEK_SET)
    mov rsi, %2     ; Offset en bytes
    mov rdi, %1     ; File Descriptor
    mov rax, 8      ; Syscall: sys_lseek
    syscall
%endmacro

; ------------------------------------------------------------------------------
; MACRO: sys_exit
; Uso:   sys_exit <código_salida>
; ------------------------------------------------------------------------------
%macro sys_exit 1
    mov rdi, %1     ; Código de salida (0 = Éxito)
    mov rax, 60     ; Syscall: sys_exit
    syscall
%endmacro

%endif