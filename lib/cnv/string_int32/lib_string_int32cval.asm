; ==============================================================================
; LIBRERÍA: lib_string_int32cval.asm
; DESCRIPCIÓN: Convierte texto ASCII a entero (32 bits) CON validación de datos.
; ==============================================================================

default rel

section .text
    global lib_string_int32cval

; ------------------------------------------------------------------------------
; FUNCIÓN: lib_string_int32cval
; ENTRADA: RDI = Puntero a la cadena terminada en nulo
; SALIDA:  RAX = Valor numérico (EAX) extendido a 64 bits
; ------------------------------------------------------------------------------
lib_string_int32cval:
    push rbp
    mov rbp, rsp
    
    xor eax, eax        ; Acumulador = 0
    xor rcx, rcx        ; Registro de lectura = 0

.bucle_lectura:
    mov cl, byte [rdi]  
    test cl, cl         ; Comprobar nulo (Fin de cadena)
    jz .fin             
    
    ; --- BARRERA DE VALIDACIÓN ---
    cmp cl, '0'         
    jl .fin             ; Si es menor a '0', abortar
    cmp cl, '9'         
    jg .fin             ; Si es mayor a '9', abortar
    
    ; --- CONVERSIÓN ---
    sub cl, '0'         
    imul eax, eax, 10   ; Multiplicación estándar (segura pero ligeramente más lenta)
    add eax, ecx        
    
    inc rdi             
    jmp .bucle_lectura  

.fin:
    leave               
    ret