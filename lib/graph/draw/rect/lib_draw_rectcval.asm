; ==============================================================================
; LIBRERÍA: lib_draw_rectcval.asm
; DESCRIPCIÓN: Capa 1 (Escudo). Realiza Clipping inteligente del rectángulo.
;              Recorta W y H si la figura se sale parcialmente de los límites.
; ==============================================================================

%include "lib/graph/core/lib_fb_core.inc"

default rel

extern lib_draw_rectfast

section .text
    global lib_draw_rectcval

; ------------------------------------------------------------------------------
; ABI: RDI (ScreenInfo), ESI (X), EDX (Y), ECX (W), R8D (H), R9D (Color)
; ------------------------------------------------------------------------------
lib_draw_rectcval:
    ; --- 1. CLIPPING EJE X ---
    cmp esi, 0
    jge .verificar_xmax
    add ecx, esi                ; W = W - abs(X) (Recortar por la izquierda)
    jle .abortar                ; Si W <= 0, el rectángulo está totalmente fuera
    xor esi, esi                ; Forzar X = 0

.verificar_xmax:
    mov eax, esi
    add eax, ecx                ; EAX = X + W
    cmp eax, dword [rdi + ScreenInfo.width]
    jle .clipping_y
    mov ecx, dword [rdi + ScreenInfo.width]
    sub ecx, esi                ; W = ScreenWidth - X (Recortar por la derecha)
    jle .abortar

    ; --- 2. CLIPPING EJE Y ---
.clipping_y:
    cmp edx, 0
    jge .verificar_ymax
    add r8d, edx                ; H = H - abs(Y) (Recortar por arriba)
    jle .abortar                ; Si H <= 0, está totalmente fuera
    xor edx, edx                ; Forzar Y = 0

.verificar_ymax:
    mov eax, edx
    add eax, r8d                ; EAX = Y + H
    cmp eax, dword [rdi + ScreenInfo.height]
    jle .dibujar
    mov r8d, dword [rdi + ScreenInfo.height]
    sub r8d, edx                ; H = ScreenHeight - Y (Recortar por abajo)
    jle .abortar

    ; --- 3. DELEGACIÓN ---
.dibujar:
    jmp lib_draw_rectfast       ; Tail call a la Capa 2 con los datos perfectos

.abortar:
    ret