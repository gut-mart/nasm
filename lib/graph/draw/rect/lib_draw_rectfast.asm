; ==============================================================================
; LIBRERÍA: lib_draw_rectfast.asm
; DESCRIPCIÓN: Capa 2 (Motor). Escribe un bloque rectangular en memoria.
;              Algoritmo de escritura lineal sin llamadas a funciones.
; CONTRATO:
;   Entrada: RDI (ScreenInfo), ESI (X), EDX (Y), ECX (W), R8D (H),
;            R9D (Color: patrón de bits nativo del framebuffer)
;   Salida:  Sin valor de retorno.
; SOPORTE bpp: lee ScreenInfo.bpp y elige un bucle de escritura por modo:
;   - 32 bpp → 4 bytes por píxel (R9D completo)
;   - 24 bpp → 3 bytes bajos de R9D por píxel, sin solapar
;   - 16 bpp → 2 bytes bajos de R9D por píxel (patrón ya empaquetado,
;     p. ej. RGB565)
;   Otras profundidades no están soportadas. El despacho se hace UNA vez,
;   fuera de los bucles, para no penalizar el bucle interno.
; NOTA: Este fast SÍ altera CF (cmp del despacho, add/sub de offsets). La
;       capa cval debe delegar con opción B: call + clc + ret (NORMAS sec. 7).
; CORRECCIÓN: Añadida protección defensiva contra W=0 y H=0. Antes, si entraba
;             con cualquiera de los dos a 0, el `dec / jnz` provocaba un bucle
;             de ~4.000 millones de iteraciones que escribía fuera de los
;             límites del framebuffer (kernel oops potencial).
; ==============================================================================

%include "lib/graph/core/lib_fb_core.inc"

default rel

section .text
    global lib_draw_rectfast

; ------------------------------------------------------------------------------
; ABI: RDI (ScreenInfo), ESI (X), EDX (Y), ECX (W), R8D (H), R9D (Color)
; ------------------------------------------------------------------------------
lib_draw_rectfast:
    ; --- 0. PROTECCIÓN DEFENSIVA ---
    ; Si W=0 o H=0, no hay nada que dibujar. Salir sin tocar memoria.
    ; Esto evita que un dec/jnz con contador 0 entre en un bucle de
    ; ~2^32 iteraciones que escribiría fuera del framebuffer.
    test ecx, ecx
    jz .salir
    test r8d, r8d
    jz .salir

    push rbx

    ; Leer bytes por píxel dinámicamente (igual que lib_draw_pixelfast)
    mov ebx, dword [rdi + ScreenInfo.bpp]
    shr ebx, 3                      ; RBX = bytes por píxel

    ; 1. Calcular el Offset Inicial (Memoria del píxel top-left)
    movsxd rax, edx                 ; RAX = Y
    movsxd r11, dword [rdi + ScreenInfo.pitch]
    imul rax, r11                   ; RAX = Y * Pitch

    movsxd r10, esi                 ; R10 = X
    imul r10, rbx                   ; R10 = X * bytes_per_pixel
    add rax, r10                    ; RAX = Offset Total en bytes

    mov r10, qword [rdi + ScreenInfo.ptr_mem]
    add r10, rax                    ; R10 = Puntero de memoria final

    ; 2. Calcular el Salto de Fila (Padding al final de cada línea dibujada)
    movsxd rax, ecx                 ; RAX = W
    imul rax, rbx                   ; RAX = W * bytes_per_pixel
    sub r11, rax                    ; R11 = Pitch - (W * bytes_per_pixel) -> Salto de memoria

    ; 3. Despacho por bytes por píxel (una sola vez, fuera de los bucles)
    cmp ebx, 4
    je .modo32
    cmp ebx, 3
    je .modo24

    ; --- 16 bpp: 2 bytes bajos del color por píxel ---
.bucle_y16:
    mov rax, rcx                    ; RAX = W (reiniciar contador de columnas)
.bucle_x16:
    mov word [r10], r9w             ; Escribir los 2 bytes bajos del color
    add r10, 2                      ; Avanzar 1 píxel (2 bytes)
    dec rax
    jnz .bucle_x16
    add r10, r11                    ; Avanzar el puntero a la siguiente fila real
    dec r8d
    jnz .bucle_y16
    jmp .fin

    ; --- 24 bpp: 3 bytes bajos del color por píxel, sin solapar ---
.modo24:
    mov edx, r9d                    ; EDX libre: Y ya se consumió en el offset
    shr edx, 16                     ; DL = byte 2 del color (R)
.bucle_y24:
    mov rax, rcx                    ; RAX = W (reiniciar contador de columnas)
.bucle_x24:
    mov word [r10], r9w             ; Escribir bytes 0-1 del color (B, G)
    mov byte [r10 + 2], dl          ; Escribir byte 2 del color (R)
    add r10, 3                      ; Avanzar 1 píxel (3 bytes)
    dec rax
    jnz .bucle_x24
    add r10, r11                    ; Avanzar el puntero a la siguiente fila real
    dec r8d
    jnz .bucle_y24
    jmp .fin

    ; --- 32 bpp: los 4 bytes del color por píxel (caso común) ---
.modo32:
.bucle_y32:
    mov rax, rcx                    ; RAX = W (reiniciar contador de columnas)
.bucle_x32:
    mov dword [r10], r9d            ; Escribir los 4 bytes del color
    add r10, 4                      ; Avanzar 1 píxel (4 bytes)
    dec rax
    jnz .bucle_x32
    add r10, r11                    ; Avanzar el puntero a la siguiente fila real
    dec r8d
    jnz .bucle_y32

.fin:
    pop rbx
.salir:
    ret
