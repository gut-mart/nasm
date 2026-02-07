; ==============================================================================
; LIBRERÍA: string_len.asm
; UBICACIÓN: lib/string/
; DESCRIPCIÓN: Calcula la longitud de una cadena terminada en 0.
; ENTRADA: RDI = Dirección de memoria del string.
; SALIDA:  RAX = Longitud en bytes.
; ==============================================================================

section .text
    global string_len

string_len:
    xor rax, rax            ; Ponemos el contador (RAX) a 0

.loop:
    ; Leemos el byte en la posición actual (RDI + RAX)
    cmp byte [rdi + rax], 0 ; ¿Es un byte nulo (0)?
    je .done                ; Si es 0, terminamos
    
    inc rax                 ; Si no, sumamos 1 al contador
    jmp .loop               ; Repetimos el ciclo

.done:
    ret                     ; Retornamos (RAX ya tiene el resultado)