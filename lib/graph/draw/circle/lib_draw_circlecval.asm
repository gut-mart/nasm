; ==============================================================================
; RUTA: ./lib/graph/draw/circle/lib_draw_circlecval.asm
; DESCRIPCIÓN: Capa 1 (Escudo). Comprueba si el círculo puede ser visible
;              antes de delegar en la capa rápida. Usa la caja delimitadora
;              del círculo para el test de visibilidad.
; CONTRATO:
;   Entrada: RDI = Puntero a ScreenInfo
;            ESI = CX (centro X)
;            EDX = CY (centro Y)
;            ECX = Radio (debe ser >= 0)
;            R8D = Color
;   Salida:  CF = 0 si se dibujó algo (círculo total o parcialmente visible).
;            CF = 1 si el círculo está completamente fuera de pantalla.
; CLIPPING:
;   Comprueba la caja delimitadora [CX-R, CX+R] x [CY-R, CY+R] contra los
;   límites de la pantalla. Si la caja entera está fuera → CF=1.
;   El clipping píxel a píxel lo hace lib_draw_pixelcval dentro del motor.
; ==============================================================================

%include "lib/graph/core/lib_fb_core.inc"

default rel

extern lib_draw_circlefast

section .text
    global lib_draw_circlecval

lib_draw_circlecval:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    push r13
    push r14
    push r15

    mov rbx, rdi            ; ScreenInfo
    mov r12d, esi           ; CX
    mov r13d, edx           ; CY
    mov r14d, ecx           ; Radio
    mov r15d, r8d           ; Color

    ; --- Radio negativo o cero: no dibujar ---
    test r14d, r14d
    jle .rechazar

    ; --- Caja delimitadora ---
    ; x_min = CX - R,  x_max = CX + R
    ; y_min = CY - R,  y_max = CY + R

    ; Comprobar x_max < 0  (caja completamente a la izquierda)
    mov eax, r12d
    add eax, r14d           ; CX + R
    test eax, eax
    js .rechazar

    ; Comprobar x_min >= width  (caja completamente a la derecha)
    mov eax, r12d
    sub eax, r14d           ; CX - R
    cmp eax, dword [rbx + ScreenInfo.width]
    jge .rechazar

    ; Comprobar y_max < 0  (caja completamente arriba)
    mov eax, r13d
    add eax, r14d           ; CY + R
    test eax, eax
    js .rechazar

    ; Comprobar y_min >= height  (caja completamente abajo)
    mov eax, r13d
    sub eax, r14d           ; CY - R
    cmp eax, dword [rbx + ScreenInfo.height]
    jge .rechazar

    ; --- Delegar en el motor ---
    mov rdi, rbx
    mov esi, r12d
    mov edx, r13d
    mov ecx, r14d
    mov r8d, r15d
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    pop rbp
    ; DELEGACIÓN (OPCIÓN B): lib_draw_circlefast usa cmp (punto medio), que
    ; altera CF. Un clc previo al tail-call se perdería (NORMAS sección 7).
    call lib_draw_circlefast
    clc
    ret

.rechazar:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    pop rbp
    stc
    ret
