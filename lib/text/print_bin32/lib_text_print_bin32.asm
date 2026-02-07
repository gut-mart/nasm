; ==============================================================================
; RUTA: ./lib/text/print_bin32/lib_text_print_bin32.asm
; DESCRIPCIÓN: Imprime representación binaria (32 bits).
; ==============================================================================

%include "constants.inc"

default rel
section .text
    global lib_text_print_bin32

lib_text_print_bin32:
    push rbp
    mov rbp, rsp
    
    ; Reservamos 40 bytes (32 bits + salto + padding extra)
    ; Nota: 40 no es múltiplo de 16, pero + push rbx (8) = 48 (Ok alineado)
    sub rsp, 40         

    push rbx            
    mov ebx, edi        
    mov rcx, 32         
    lea rsi, [rsp + 8]  

.bucle_bits:
    rol ebx, 1          
    jc .es_uno
    mov byte [rsi], '0'
    jmp .siguiente
.es_uno:
    mov byte [rsi], '1'
.siguiente:
    inc rsi
    dec rcx
    jnz .bucle_bits

    mov byte [rsi], 10  ; Salto de línea
    
    ; Usando constantes para mayor claridad
    mov rax, SYS_WRITE  
    mov rdi, STDOUT     
    lea rsi, [rsp + 8]  
    mov rdx, 33         
    syscall

    pop rbx             
    add rsp, 40         
    leave
    ret