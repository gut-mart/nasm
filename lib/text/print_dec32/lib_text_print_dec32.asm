; ==============================================================================
; RUTA: ./lib/text/print_dec32/lib_text_print_dec32.asm
; DESCRIPCIÓN: Imprime entero 32 bits con signo.
; ENTRADA:  EDI = Número a imprimir
; DESTRUYE: RAX, RCX, RDX, RSI, R11 (Estándar Syscall)
; ==============================================================================

%include "constants.inc"

default rel
section .text
    global lib_text_print_dec32

lib_text_print_dec32:
    push rbp
    mov rbp, rsp

    ; --------------------------------------------------------------------------
    ; ALINEACIÓN DE STACK (Mejora de seguridad)
    ; --------------------------------------------------------------------------
    ; Reservamos 32 bytes en lugar de 24.
    ; 32 es múltiplo de 16, manteniendo el stack alineado para llamadas futuras.
    sub rsp, 32 
    
    push rbx            ; Guardar registro protegido (RBX debe preservarse)

    ; Apuntamos al final del buffer reservado (RSP + 32 bytes)
    lea rsi, [rsp + 32] 
    dec rsi
    mov byte [rsi], 10  ; Ponemos el \n al final
    dec rsi

    mov eax, edi        ; Argumento
    xor ebx, ebx        ; Flag de signo (0 = pos)

    test eax, eax
    jns .conversion
    neg eax             ; Hacer positivo
    mov ebx, 1          ; Marcar como negativo

.conversion:
    mov ecx, 10
.bucle:
    xor edx, edx
    div ecx             ; EAX / 10
    add dl, '0'
    mov [rsi], dl
    dec rsi
    test eax, eax
    jnz .bucle

    cmp ebx, 1
    jne .imprimir
    mov byte [rsi], '-'
    dec rsi

.imprimir:
    inc rsi             ; Corregir puntero al inicio real

    ; Calcular longitud: (Fin del buffer) - (Inicio actual)
    lea rdx, [rsp + 32] ; ¡OJO! Aquí también usamos 32 ahora
    sub rdx, rsi        
    
    mov rax, SYS_WRITE  ; Usando constante
    mov rdi, STDOUT     ; Usando constante
    syscall

    pop rbx
    add rsp, 32         ; Liberamos los 32 bytes
    leave
    ret