; ==============================================================================
; RUTA: ./lib/graph/draw/line/lib_draw_linecval.asm
; DESCRIPCIÓN: Capa 1 (Escudo). Recorta la línea contra los límites de pantalla
;              usando el algoritmo de Cohen-Sutherland y delega en la capa rápida.
; CONTRATO:
;   Entrada: RDI = Puntero a ScreenInfo
;            ESI = X1  EDX = Y1  ECX = X2  R8D = Y2  R9D = Color
;   Salida:  CF = 0 si se dibujó algo (línea dentro o recortada parcialmente).
;            CF = 1 si la línea está totalmente fuera de pantalla.
; CORRECCIÓN: Epílogo unificado sin mezclar leave con pops manuales.
;             Las variables locales se acceden via RBP con offsets negativos
;             desde el frame establecido al inicio.
; ==============================================================================

%include "lib/graph/core/lib_fb_core.inc"

default rel

extern lib_draw_linefast

section .text
    global lib_draw_linecval

; ------------------------------------------------------------------------------
; Códigos de región Cohen-Sutherland
; ------------------------------------------------------------------------------
%define CS_INSIDE 0
%define CS_LEFT   1
%define CS_RIGHT  2
%define CS_BOTTOM 4
%define CS_TOP    8

; ------------------------------------------------------------------------------
; MACRO: compute_code
; Entrada:  R10D = px, R11D = py
; Salida:   R13D = código de región
; Requiere: R14D = width-1, R15D = height-1
; ------------------------------------------------------------------------------
%macro compute_code 0
    xor r13d, r13d
    cmp r10d, 0
    jge %%no_left
    or r13d, CS_LEFT
%%no_left:
    cmp r10d, r14d
    jle %%no_right
    or r13d, CS_RIGHT
%%no_right:
    cmp r11d, 0
    jge %%no_top
    or r13d, CS_TOP
%%no_top:
    cmp r11d, r15d
    jle %%no_bottom
    or r13d, CS_BOTTOM
%%no_bottom:
%endmacro

; ------------------------------------------------------------------------------
; Layout del frame (offsets desde RBP):
;   [rbp -  8] = RBX guardado
;   [rbp - 16] = R12 guardado
;   [rbp - 24] = R13 guardado
;   [rbp - 32] = R14 guardado
;   [rbp - 40] = R15 guardado
;   sub rsp, 32 → espacio para variables locales:
;   [rbp - 48] = x1
;   [rbp - 52] = y1
;   [rbp - 56] = x2
;   [rbp - 60] = y2
;   [rbp - 64] = code1
;   [rbp - 68] = code2
; ------------------------------------------------------------------------------
lib_draw_linecval:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp, 32

    ; --- Guardar parámetros ---
    mov r12, rdi                        ; R12  = ScreenInfo
    mov ebx, r9d                        ; EBX  = color

    ; Límites de pantalla
    mov r14d, dword [rdi + ScreenInfo.width]
    dec r14d                            ; R14D = width - 1
    mov r15d, dword [rdi + ScreenInfo.height]
    dec r15d                            ; R15D = height - 1

    ; Variables locales
    mov dword [rbp - 48], esi           ; x1
    mov dword [rbp - 52], edx           ; y1
    mov dword [rbp - 56], ecx           ; x2
    mov dword [rbp - 60], r8d           ; y2

    ; Calcular code1
    mov r10d, esi
    mov r11d, edx
    compute_code
    mov dword [rbp - 64], r13d

    ; Calcular code2
    mov r10d, ecx
    mov r11d, r8d
    compute_code
    mov dword [rbp - 68], r13d

.bucle_clip:
    mov eax, dword [rbp - 64]           ; code1
    mov r9d, dword [rbp - 68]           ; code2

    ; Caso 1: ambos dentro → aceptar
    mov r13d, eax
    or  r13d, r9d
    jz  .aceptar

    ; Caso 2: ambos fuera del mismo lado → rechazar
    mov r13d, eax
    and r13d, r9d
    jnz .rechazar

    ; Caso 3: clipping — procesar el punto exterior
    test eax, eax
    jnz .clip_con_code
    mov eax, r9d                        ; usar code2

.clip_con_code:
    mov r10d, dword [rbp - 48]          ; x1
    mov r11d, dword [rbp - 52]          ; y1
    mov ecx,  dword [rbp - 56]          ; x2
    mov edx,  dword [rbp - 60]          ; y2

    test eax, CS_TOP
    jnz .clip_top
    test eax, CS_BOTTOM
    jnz .clip_bottom
    test eax, CS_LEFT
    jnz .clip_left

.clip_right:
    mov esi, r14d
    mov eax, edx
    sub eax, r11d
    mov r13d, r14d
    sub r13d, r10d
    imul eax, r13d
    mov r13d, ecx
    sub r13d, r10d
    cdq
    idiv r13d
    add eax, r11d
    jmp .guardar

.clip_left:
    xor esi, esi
    mov eax, edx
    sub eax, r11d
    mov r13d, r10d
    neg r13d
    imul eax, r13d
    mov r13d, ecx
    sub r13d, r10d
    cdq
    idiv r13d
    add eax, r11d
    jmp .guardar

.clip_bottom:
    mov eax, ecx
    sub eax, r10d
    mov r13d, r15d
    sub r13d, r11d
    imul eax, r13d
    mov r13d, edx
    sub r13d, r11d
    cdq
    idiv r13d
    add eax, r10d
    mov esi, eax
    mov eax, r15d
    jmp .guardar

.clip_top:
    mov eax, ecx
    sub eax, r10d
    mov r13d, r11d
    neg r13d
    imul eax, r13d
    mov r13d, edx
    sub r13d, r11d
    cdq
    idiv r13d
    add eax, r10d
    mov esi, eax
    xor eax, eax

.guardar:
    ; ESI = x_new, EAX = y_new
    mov r13d, dword [rbp - 64]          ; code1
    test r13d, r13d
    jz .actualizar_p2

.actualizar_p1:
    mov dword [rbp - 48], esi
    mov dword [rbp - 52], eax
    mov r10d, esi
    mov r11d, eax
    compute_code
    mov dword [rbp - 64], r13d
    jmp .bucle_clip

.actualizar_p2:
    mov dword [rbp - 56], esi
    mov dword [rbp - 60], eax
    mov r10d, esi
    mov r11d, eax
    compute_code
    mov dword [rbp - 68], r13d
    jmp .bucle_clip

.aceptar:
    mov esi, dword [rbp - 48]           ; x1
    mov edx, dword [rbp - 52]           ; y1
    mov ecx, dword [rbp - 56]           ; x2
    mov r8d, dword [rbp - 60]           ; y2
    mov r9d, ebx                        ; color
    mov rdi, r12                        ; ScreenInfo
    add rsp, 32
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    pop rbp
    clc
    jmp lib_draw_linefast

.rechazar:
    add rsp, 32
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    pop rbp
    stc
    ret