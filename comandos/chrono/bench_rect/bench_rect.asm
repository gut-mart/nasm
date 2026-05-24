; ==============================================================================
; RUTA: ./comandos/chrono/bench_rect/bench_rect.asm
; DESCRIPCIÓN: Mide en ticks de CPU cuánto tarda lib_draw_rectfast en pintar
;              un rectángulo de pantalla completa (el caso más costoso).
;              Requiere acceso a /dev/fb0 (ejecutar con sudo o grupo video).
; USO:
;   sudo ./bin/bench_rect
;   ./bin/bench_rect -h
; SALIDA:
;   Método:     RDTSCP  (o RDTSC si el procesador no soporta RDTSCP)
;   Resolución: 1920x1080
;   Ticks:      XXXXXXXXX
; ==============================================================================

%include "lib/constants.inc"
%include "lib/sys_macros.inc"
%include "lib/graph/core/lib_fb_core.inc"

default rel

extern fb_core, fb_map
extern lib_draw_rectfast
extern lib_rdtsc_init, lib_rdtsc_start, lib_rdtsc_stop, lib_rdtsc_method
extern print_string, print_int, print_nl
extern lib_uint32_string

section .data
    msg_ayuda_1  db "Uso: bench_rect [-h]", 10, 0
    msg_ayuda_2  db "Descripcion: Mide en ticks de CPU el coste de pintar", 10, 0
    msg_ayuda_3  db "             un rectangulo de pantalla completa.", 10, 10, 0
    msg_ayuda_4  db "Requisitos:", 10, 0
    msg_ayuda_5  db "  Acceso a /dev/fb0 (sudo o grupo video).", 10, 10, 0
    msg_ayuda_6  db "Salida:", 10, 0
    msg_ayuda_7  db "  Metodo     RDTSCP o RDTSC segun el procesador.", 10, 0
    msg_ayuda_8  db "  Resolucion Ancho x Alto del framebuffer.", 10, 0
    msg_ayuda_9  db "  Ticks      Ciclos de CPU consumidos por la operacion.", 10, 0

    msg_metodo   db "Metodo:     ", 0
    msg_resol    db "Resolucion: ", 0
    msg_x        db "x", 0
    msg_ticks    db "Ticks:      ", 0

    msg_error_fb db "Error: no se pudo acceder a /dev/fb0. Ejecuta con sudo.", 10, 0

    ; Color de relleno para el benchmark (negro — minimiza contención de bus)
    color_bench  dd 0x00000000

section .bss
    datos_fb  resb ScreenInfo_size
    buf_num   resb 32           ; buffer para lib_uint32_string (ticks en decimal)

section .text
    global _start

_start:
    mov rbp, rsp
    and rsp, -16

    mov rbx, [rbp]          ; argc
    mov r12, [rbp + 16]     ; argv[1]

    ; --- Comprobar -h ---
    cmp rbx, 2
    jne .iniciar
    mov al, byte [r12]
    cmp al, '-'
    jne .iniciar
    mov al, byte [r12 + 1]
    cmp al, 'h'
    je .modo_ayuda
    ; cualquier otro flag: caer en iniciar

.iniciar:
    ; --- 1. Detectar capacidades del procesador ---
    call lib_rdtsc_init

    ; --- 2. Inicializar framebuffer ---
    mov rdi, datos_fb
    call fb_core
    test rax, rax
    js .error_fb

    mov rdi, datos_fb
    call fb_map
    test rax, rax
    js .error_fb

    ; --- 3. MEDICIÓN ---
    ; Preparar argumentos de lib_draw_rectfast ANTES de start para no
    ; contaminar la medición con movs de setup.
    ; ABI: RDI=ScreenInfo, ESI=X, EDX=Y, ECX=W, R8D=H, R9D=Color
    mov rdi, datos_fb
    xor esi, esi                            ; X = 0
    xor edx, edx                            ; Y = 0
    mov ecx, dword [datos_fb + ScreenInfo.width]   ; W = ancho pantalla
    mov r8d, dword [datos_fb + ScreenInfo.height]  ; H = alto pantalla
    mov r9d, dword [color_bench]            ; Color = negro

    ; Guardar argumentos en registros callee-saved para que lib_rdtsc_start
    ; no los destruya (start no tiene argumentos pero sí usa RAX/RDX).
    ; RDI ya es callee-saved por el ABI de System V si no llamamos nada.
    ; Pero lib_rdtsc_start es una función: puede tocar RCX, RDX, R8, R9, R10, R11.
    ; Guardamos todo lo necesario.
    push rdi            ; ScreenInfo
    push rcx            ; W
    push r8             ; H (como 64 bits para alinear)

    call lib_rdtsc_start

    pop r8
    pop rcx
    pop rdi
    ; ESI=0, EDX=0, R9D=color siguen válidos (no los tocamos entre push y pop)
    ; pero los recargamos por claridad:
    xor esi, esi
    xor edx, edx
    mov r9d, dword [color_bench]

    call lib_draw_rectfast

    call lib_rdtsc_stop     ; RAX = ticks transcurridos
    mov r13, rax            ; guardar resultado antes de cualquier call

    ; --- 4. IMPRIMIR RESULTADOS ---

    ; Método
    mov rdi, msg_metodo
    call print_string
    call lib_rdtsc_method   ; RAX = puntero al string "RDTSCP" o "RDTSC"
    mov rdi, rax
    call print_string
    call print_nl

    ; Resolución
    mov rdi, msg_resol
    call print_string
    mov edi, dword [datos_fb + ScreenInfo.width]
    call print_int
    mov rdi, msg_x
    call print_string
    mov edi, dword [datos_fb + ScreenInfo.height]
    call print_int
    call print_nl

    ; Ticks — R13 contiene el valor uint64; imprimimos como dos mitades
    ; uint32 si supera 32 bits, o directamente si cabe.
    ; Para simplicidad usamos print_int (acepta 64 bits con signo, pero
    ; los ticks siempre son positivos y en la Tecra M10 caben en 63 bits).
    mov rdi, msg_ticks
    call print_string
    mov rdi, r13
    call print_int
    call print_nl

    sys_exit 0

.modo_ayuda:
    mov rdi, msg_ayuda_1
    call print_string
    mov rdi, msg_ayuda_2
    call print_string
    mov rdi, msg_ayuda_3
    call print_string
    mov rdi, msg_ayuda_4
    call print_string
    mov rdi, msg_ayuda_5
    call print_string
    mov rdi, msg_ayuda_6
    call print_string
    mov rdi, msg_ayuda_7
    call print_string
    mov rdi, msg_ayuda_8
    call print_string
    mov rdi, msg_ayuda_9
    call print_string
    sys_exit 0

.error_fb:
    mov rdi, msg_error_fb
    call print_string
    sys_exit 1
