; ==============================================================================
; RUTA: ./lib/chrono/lib_rdtsc.asm
; DESCRIPCIÓN: Medición de ticks de CPU con detección automática de RDTSCP.
;              En tiempo de inicialización comprueba via CPUID si el procesador
;              soporta RDTSCP (bit 27 de EDX con EAX=0x80000001).
;              Si está disponible usa RDTSCP (más preciso), si no usa RDTSC.
; CREADO: 2026-05-24
;
; FUNCIONES EXPORTADAS:
;   lib_rdtsc_init      — detecta capacidades del procesador (llamar una vez)
;   lib_rdtsc_start     — guarda el contador actual
;   lib_rdtsc_stop      — devuelve los ticks transcurridos desde start
;   lib_rdtsc_method    — devuelve puntero al string del método usado
;
; CONTRATO lib_rdtsc_method:
;   Entrada: ninguna
;   Salida:  RAX = puntero a string NUL con el método: "RDTSCP" o "RDTSC"
; ==============================================================================

default rel

section .data
    str_rdtscp  db "RDTSCP", 0
    str_rdtsc   db "RDTSC", 0

section .bss
    tsc_start    resq 1
    use_rdtscp   resb 1

section .text
    global lib_rdtsc_init
    global lib_rdtsc_start
    global lib_rdtsc_stop
    global lib_rdtsc_method

; ------------------------------------------------------------------------------
; lib_rdtsc_init — Detecta si RDTSCP está disponible via CPUID
; ------------------------------------------------------------------------------
lib_rdtsc_init:
    push rbp
    mov rbp, rsp
    push rbx

    mov byte [use_rdtscp], 0

    mov eax, 0x80000000
    cpuid
    cmp eax, 0x80000001
    jl .fin

    mov eax, 0x80000001
    cpuid
    test edx, (1 << 27)
    jz .fin

    mov byte [use_rdtscp], 1

.fin:
    pop rbx
    leave
    ret

; ------------------------------------------------------------------------------
; lib_rdtsc_method — Devuelve puntero al string del método activo
; ------------------------------------------------------------------------------
lib_rdtsc_method:
    cmp byte [use_rdtscp], 1
    je .es_rdtscp
    lea rax, [str_rdtsc]
    ret
.es_rdtscp:
    lea rax, [str_rdtscp]
    ret

; ------------------------------------------------------------------------------
; lib_rdtsc_start — Lee el contador TSC y lo guarda
; ------------------------------------------------------------------------------
lib_rdtsc_start:
    push rbp
    mov rbp, rsp

    cmp byte [use_rdtscp], 1
    je .usar_rdtscp

.usar_rdtsc:
    rdtsc
    jmp .guardar

.usar_rdtscp:
    rdtscp

.guardar:
    shl rdx, 32
    or rax, rdx
    mov qword [tsc_start], rax

    leave
    ret

; ------------------------------------------------------------------------------
; lib_rdtsc_stop — Lee el contador y devuelve la diferencia con tsc_start
; ------------------------------------------------------------------------------
lib_rdtsc_stop:
    push rbp
    mov rbp, rsp

    cmp byte [use_rdtscp], 1
    je .usar_rdtscp

.usar_rdtsc:
    rdtsc
    jmp .calcular

.usar_rdtscp:
    rdtscp

.calcular:
    shl rdx, 32
    or rax, rdx
    sub rax, qword [tsc_start]

    leave
    ret
