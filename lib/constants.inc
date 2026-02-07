; ==============================================================================
; RUTA: lib/constants.inc
; DESCRIPCIÓN: Constantes globales del sistema (Linux x86_64)
; ==============================================================================

; --- Descriptores de Archivo ---
STDIN       equ 0
STDOUT      equ 1
STDERR      equ 2

; --- Números de Syscall ---
SYS_READ    equ 0
SYS_WRITE   equ 1
SYS_EXIT    equ 60

; --- Códigos de Salida ---
EXIT_SUCCESS equ 0