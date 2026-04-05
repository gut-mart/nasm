; ==============================================================================
; LIBRERÍA: lib_string_int32fast.asm
; DESCRIPCIÓN: Convierte texto ASCII a entero (32 bits) SIN validación (Alto Rendimiento).
; PELIGRO: Asume que la cadena origen contiene EXCLUSIVAMENTE dígitos del 0 al 9.
; ==============================================================================

default rel

section .text
    global lib_string_int32fast

; ------------------------------------------------------------------------------
; FUNCIÓN: lib_string_int32fast
; ENTRADA: RDI = Puntero a la cadena terminada en nulo
; SALIDA:  RAX = Valor numérico (EAX) extendido a 64 bits
; ------------------------------------------------------------------------------
lib_string_int32fast:
    push rbp
    mov rbp, rsp
    
    xor eax, eax        ; Acumulador = 0
    xor rcx, rcx        ; Registro de lectura = 0

.bucle_lectura:
    mov cl, byte [rdi]  
    test cl, cl         ; Solo comprobamos el fin de cadena por seguridad de memoria
    jz .fin             
    
    ; --- CONVERSIÓN DIRECTA (UNSAFE) ---
    sub cl, '0'         
    
    ; --- MULTIPLICACIÓN ULTRARRÁPIDA X10 ---
    ; EAX = EAX * 10 usando aritmética LEA y desplazamientos
    lea eax, [eax + eax*4]  ; EAX = EAX * 5
    add eax, eax            ; EAX = EAX * 2  (Total: EAX * 10)
    
    add eax, ecx        ; Sumamos el dígito extraído
    
    inc rdi             
    jmp .bucle_lectura  

.fin:
    leave               
    ret