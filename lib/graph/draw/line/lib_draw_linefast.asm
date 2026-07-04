; ==============================================================================
; RUTA: ./lib/graph/draw/line/lib_draw_linefast.asm
; DESCRIPCIÓN: Capa 2 (Motor). Dibuja una línea usando el algoritmo de Bresenham.
;              Asume coordenadas ya validadas y recortadas por la capa cval.
; CONTRATO:
;   Entrada: RDI = Puntero a ScreenInfo
;            ESI = X1 (coordenada origen X)
;            EDX = Y1 (coordenada origen Y)
;            ECX = X2 (coordenada destino X)
;            R8D = Y2 (coordenada destino Y)
;            R9D = Color (32 bits, ya empaquetado para el hardware)
;   Salida:  Sin valor de retorno.
; NOTA: Este fast SÍ altera CF (cmp/add de Bresenham). La capa cval debe
;       delegar con opción B: call + clc + ret (NORMAS sección 7).
; SOPORTE bpp: hereda el de lib_draw_pixelfast (16/24/32 bpp), a quien
;       delega la escritura de cada píxel.
; CORRECCIÓN: X2 e Y2 se guardan en registros callee-saved (R12D, R13D) desde
;             el inicio, evitando que ECX y R8D sean destruidos durante la
;             llamada a lib_draw_pixelfast dentro del bucle.
; ==============================================================================

%include "lib/graph/core/lib_fb_core.inc"

default rel

extern lib_draw_pixelfast

section .text
    global lib_draw_linefast

; ------------------------------------------------------------------------------
; MAPA DE REGISTROS durante el bucle:
;   RBX  = ScreenInfo (puntero 64 bits, NO escribir EBX)
;   R12D = X2 destino
;   R13D = Y2 destino
;   R14D = Color
;   R15D = step_x (+1 o -1)
;   R8D  = abs(dx)
;   R9D  = step_y (+1 o -1)
;   ECX  = -abs(dy)
;   EAX  = error de Bresenham
;   ESI  = X actual
;   EDX  = Y actual
; ------------------------------------------------------------------------------
lib_draw_linefast:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    push r13
    push r14
    push r15

    ; --- Guardar todos los parámetros en callee-saved ---
    mov rbx, rdi            ; RBX  = ScreenInfo
    mov r12d, ecx           ; R12D = X2
    mov r13d, r8d           ; R13D = Y2
    mov r14d, r9d           ; R14D = Color
    ; ESI = X1 (x actual), EDX = Y1 (y actual)

    ; --- Calcular abs(dx) y step_x ---
    mov eax, r12d
    sub eax, esi            ; EAX = X2 - X1

    mov r15d, 1             ; step_x = +1 por defecto
    test eax, eax
    jge .dx_positivo
    neg eax
    mov r15d, -1
.dx_positivo:
    mov r8d, eax            ; R8D = abs(dx)

    ; --- Calcular abs(dy) y step_y ---
    mov eax, r13d
    sub eax, edx            ; EAX = Y2 - Y1

    mov r9d, 1              ; step_y = +1 por defecto
    test eax, eax
    jge .dy_positivo
    neg eax
    mov r9d, -1
.dy_positivo:
    neg eax
    mov ecx, eax            ; ECX = -abs(dy)

    ; --- Error inicial = abs(dx) + (-abs(dy)) ---
    mov eax, r8d
    add eax, ecx            ; EAX = error inicial

.bucle:
    ; --- Dibujar píxel actual ---
    ; lib_draw_pixelfast: RDI=ScreenInfo, ESI=X, EDX=Y, ECX=Color
    push rax                ; Guardar error
    push rcx                ; Guardar -abs(dy)
    push r8                 ; Guardar abs(dx)
    push r9                 ; Guardar step_y

    mov rdi, rbx            ; ScreenInfo
    ; ESI = X actual (ya está)
    ; EDX = Y actual (ya está)
    mov ecx, r14d           ; Color
    call lib_draw_pixelfast

    pop r9
    pop r8
    pop rcx
    pop rax

    ; --- Comprobar si llegamos al destino ---
    cmp esi, r12d           ; X == X2?
    jne .continuar
    cmp edx, r13d           ; Y == Y2?
    je .fin

.continuar:
    ; --- e2 = 2 * error ---
    mov r10d, eax
    add r10d, eax

    ; --- Si e2 >= -abs(dy): avanzar X ---
    cmp r10d, ecx           ; e2 >= -abs(dy)?
    jl .no_avanzar_x
    add eax, ecx            ; error += -abs(dy)
    add esi, r15d           ; X += step_x

.no_avanzar_x:
    ; --- Si e2 <= abs(dx): avanzar Y ---
    cmp r10d, r8d           ; e2 <= abs(dx)?
    jg .no_avanzar_y
    add eax, r8d            ; error += abs(dx)
    add edx, r9d            ; Y += step_y

.no_avanzar_y:
    jmp .bucle

.fin:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    leave
    ret