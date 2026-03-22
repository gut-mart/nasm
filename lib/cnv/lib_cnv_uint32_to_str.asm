; ==============================================================================
; RUTA: ./lib/cnv/lib_cnv_uint32_to_str.asm
; DESCRIPCIÓN: Convierte un uint32 a string en la BASE especificada.
;
; ENTRADA:
;   RDI = Puntero al buffer de destino
;   ESI = Número entero sin signo (32 bits) a convertir
;   EDX = Base numérica (Ej: 10 para Decimal, 2 para Binario, 16 para Hex)
;
; SALIDA:
;   RAX = Puntero al inicio de la cadena (el mismo que RDI original)
;   El buffer en RDI contendrá la cadena terminada en 0.
; ==============================================================================

default rel
section .text
    global lib_cnv_uint32_to_str

lib_cnv_uint32_to_str:
    ; --- PRÓLOGO STANDARD ---
    push rbp
    mov rbp, rsp
    
    push rbx            ; Guardamos RBX (Callee-saved)
    push rdi            ; Guardamos RDI (Buffer). 
                        ; En la pila: [RBP] -> [RBX] -> [RDI]
                        ; Por tanto, RDI está en [RBP - 16]

    ; --- VALIDACIÓN DE BASE ---
    cmp edx, 2
    jge .preparar
    mov edx, 10         ; Si base < 2, forzar base 10

.preparar:
    mov eax, esi        ; EAX = Número a convertir (Dividendo)
    mov r8d, edx        ; R8D = Base (Divisor). Usamos R8 porque DIV destruye RDX
    xor ebx, ebx        ; EBX = Contador de dígitos

    ; --- BUCLE DE DIVISIÓN ---
.bucle_division:
    xor edx, edx        ; Limpiar parte alta (EDX:EAX)
    div r8d             ; EAX / Base --> Cociente en EAX, Resto en EDX
    
    ; Convertir resto a ASCII
    cmp edx, 9
    ja .es_letra        ; Si es > 9 (Hexadecimal)

    add edx, '0'        ; 0-9 -> ASCII
    jmp .push_digito

.es_letra:
    add edx, 'A' - 10   ; 10-35 -> 'A'-'Z'

.push_digito:
    push rdx            ; Guardamos el carácter en la pila
    inc ebx             ; Aumentamos contador
    
    test eax, eax       ; ¿Queda número?
    jnz .bucle_division ; Si cociente != 0, repetir

    ; --- RECUPERACIÓN (CORRECCIÓN DEL ERROR) ---
    ; NO hacemos 'pop rdi' aquí porque la pila está llena de dígitos.
    ; Leemos el valor original directamente usando RBP.
    
    mov rdi, [rbp - 16] ; Recuperamos la dirección inicial del buffer
    mov rax, rdi        ; Preparamos valor de retorno

    ; --- BUCLE DE ESCRITURA ---
.escribir:
    pop rdx             ; Sacamos un dígito de la pila
    mov [rdi], dl       ; Escribimos en el buffer
    inc rdi             ; Avanzamos puntero del buffer
    dec ebx             ; Decrementamos contador
    jnz .escribir       ; Si quedan dígitos, repetir

    mov byte [rdi], 0   ; Terminador nulo al final

    ; --- EPÍLOGO ---
    ; La pila ahora tiene [RBX] y [RDI] guardados.
    ; Los dígitos ya se fueron.
    
    pop rdi             ; Limpiamos el RDI que guardamos al principio
    pop rbx             ; Restauramos el RBX original
    
    leave               ; Restaura RSP y RBP
    ret