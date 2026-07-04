; ==============================================================================
; RUTA: ./lib/graph/draw/circle/lib_draw_circlefast.asm
; DESCRIPCIÓN: Capa 2 (Motor). Dibuja un círculo usando el algoritmo de
;              Bresenham (punto medio). Solo sumas y comparaciones enteras,
;              sin multiplicaciones ni raíz cuadrada.
; CONTRATO:
;   Entrada: RDI = Puntero a ScreenInfo
;            ESI = CX (centro X)
;            EDX = CY (centro Y)
;            ECX = Radio
;            R8D = Color (32 bits, ya empaquetado para el hardware)
;   Salida:  Sin valor de retorno.
; NOTA: Este fast SÍ altera CF (cmp del algoritmo de punto medio). La capa
;       cval debe delegar con opción B: call + clc + ret (NORMAS sección 7).
; SOPORTE bpp: hereda el de lib_draw_pixelfast (16/24/32 bpp) a través de
;       lib_draw_pixelcval, a quien delega la escritura de cada píxel.
;
; GESTIÓN DE REGISTROS:
;   lib_draw_pixelcval destruye todos los caller-saved. Por eso:
;   RBX      = ScreenInfo
;   R12D     = CX
;   R13D     = CY
;   R14D     = Color
;   R15D     = x  (0..radio)
;   [rbp-48] = y  (radio..0, qword)
;   [rbp-56] = d  (decision parameter, qword)
; ==============================================================================

%include "lib/graph/core/lib_fb_core.inc"

default rel

extern lib_draw_pixelcval

section .text
    global lib_draw_circlefast

; ------------------------------------------------------------------------------
; MACRO: pixel_en ax_val, ay_val
; Dibuja el píxel en coordenadas absolutas (ax_val, ay_val).
; ax_val y ay_val son registros de 32 bits con las coordenadas ya calculadas.
; Tras la llamada, RBX R12 R13 R14 R15 y la pila local están preservados.
; ------------------------------------------------------------------------------
%macro pixel_en 2
    mov rdi, rbx
    mov esi, %1
    mov edx, %2
    mov ecx, r14d
    call lib_draw_pixelcval
%endmacro

lib_draw_circlefast:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp, 16             ; [rbp-48]=y, [rbp-56]=d

    mov rbx, rdi
    mov r12d, esi
    mov r13d, edx
    mov r14d, r8d

    ; y = radio
    movsx rax, ecx
    mov qword [rbp - 48], rax

    ; x = 0
    xor r15d, r15d

    ; d = 3 - 2*radio
    mov eax, ecx
    add eax, eax
    mov edx, 3
    sub edx, eax
    movsx rax, edx
    mov qword [rbp - 56], rax

.bucle:
    mov eax, dword [rbp - 48]   ; EAX = y
    cmp r15d, eax               ; x > y ?
    jg .fin

    ; Precalcular las 4 combinaciones de coordenadas en registros temporales
    ; px = x,  py = y  (ambos positivos)
    ; nx = -x, ny = -y (negativos)
    ; Coordenadas absolutas = centro ± offset

    ; Usamos la pila para los 8 puntos:
    ; punto = (R12D + offset_x, R13D + offset_y)

    mov eax, dword [rbp - 48]   ; y

    ; Variables locales para los offsets (en registros temporales antes de cada call)
    ; px = r15d, nx = -r15d, py = eax, ny = -eax

    ; (CX+x, CY+y)
    mov esi, r12d
    add esi, r15d
    mov edx, r13d
    add edx, eax
    pixel_en esi, edx

    mov eax, dword [rbp - 48]

    ; (CX-x, CY+y)
    mov esi, r12d
    sub esi, r15d
    mov edx, r13d
    add edx, eax
    pixel_en esi, edx

    mov eax, dword [rbp - 48]

    ; (CX+x, CY-y)
    mov esi, r12d
    add esi, r15d
    mov edx, r13d
    sub edx, eax
    pixel_en esi, edx

    mov eax, dword [rbp - 48]

    ; (CX-x, CY-y)
    mov esi, r12d
    sub esi, r15d
    mov edx, r13d
    sub edx, eax
    pixel_en esi, edx

    mov eax, dword [rbp - 48]

    ; (CX+y, CY+x)
    mov esi, r12d
    add esi, eax
    mov edx, r13d
    add edx, r15d
    pixel_en esi, edx

    mov eax, dword [rbp - 48]

    ; (CX-y, CY+x)
    mov esi, r12d
    sub esi, eax
    mov edx, r13d
    add edx, r15d
    pixel_en esi, edx

    mov eax, dword [rbp - 48]

    ; (CX+y, CY-x)
    mov esi, r12d
    add esi, eax
    mov edx, r13d
    sub edx, r15d
    pixel_en esi, edx

    mov eax, dword [rbp - 48]

    ; (CX-y, CY-x)
    mov esi, r12d
    sub esi, eax
    mov edx, r13d
    sub edx, r15d
    pixel_en esi, edx

    ; --- Actualizar decision parameter ---
    mov rax, qword [rbp - 56]
    test eax, eax
    js .d_negativo

.d_positivo:
    ; d >= 0: d += 4*(x-y) + 10, y--
    mov ecx, r15d
    sub ecx, dword [rbp - 48]
    shl ecx, 2
    add ecx, 10
    add eax, ecx
    mov qword [rbp - 56], rax
    mov rax, qword [rbp - 48]
    dec rax
    mov qword [rbp - 48], rax
    jmp .avanzar_x

.d_negativo:
    ; d < 0: d += 4*x + 6
    mov ecx, r15d
    shl ecx, 2
    add ecx, 6
    add eax, ecx
    mov qword [rbp - 56], rax

.avanzar_x:
    inc r15d
    jmp .bucle

.fin:
    add rsp, 16
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    leave
    ret
