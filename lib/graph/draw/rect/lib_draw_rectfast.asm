; ==============================================================================
; LIBRERÍA: lib_draw_rectfast.asm
; DESCRIPCIÓN: Capa 2 (Motor). Escribe un bloque rectangular en memoria.
;              Algoritmo de escritura lineal sin llamadas a funciones.
; ==============================================================================

%include "lib/graph/core/lib_fb_core.inc"

default rel

section .text
    global lib_draw_rectfast

; ------------------------------------------------------------------------------
; ABI: RDI (ScreenInfo), ESI (X), EDX (Y), ECX (W), R8D (H), R9D (Color)
; ------------------------------------------------------------------------------
lib_draw_rectfast:
    ; 1. Calcular el Offset Inicial (Memoria del píxel top-left)
    movsxd rax, edx                 ; RAX = Y
    movsxd r11, dword [rdi + ScreenInfo.pitch] 
    imul rax, r11                   ; RAX = Y * Pitch
    
    movsxd r10, esi                 ; R10 = X
    shl r10, 2                      ; R10 = X * 4 (Asumiendo 32-bit BPP)
    add rax, r10                    ; RAX = Offset Total en bytes
    
    mov r10, qword [rdi + ScreenInfo.ptr_mem]
    add r10, rax                    ; R10 = Puntero de memoria final

    ; 2. Calcular el Salto de Fila (Padding al final de cada línea dibujada)
    movsxd rax, ecx                 ; RAX = W
    shl rax, 2                      ; RAX = W * 4 bytes
    sub r11, rax                    ; R11 = Pitch - (W * 4) -> Salto de memoria
    
    ; 3. Bucle de Dibujado (Aritmética pura de registros)
.bucle_y:
    mov rax, rcx                    ; RAX = W (Reiniciamos contador de columnas)

.bucle_x:
    mov dword [r10], r9d            ; Escribir el color
    add r10, 4                      ; Avanzar 1 píxel a la derecha
    dec rax
    jnz .bucle_x                    ; Repetir hasta completar el Ancho (W)
    
    add r10, r11                    ; Avanzar el puntero a la siguiente fila real
    dec r8d
    jnz .bucle_y                    ; Repetir hasta completar el Alto (H)
    
    ret