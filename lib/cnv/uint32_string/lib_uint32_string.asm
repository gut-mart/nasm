; ==============================================================================
; RUTA: ./lib/cnv/uint32_string/lib_uint32_string.asm
; DESCRIPCIÓN: Convierte un uint32 a string en la BASE especificada.
;
; ENTRADA:
; RDI = Puntero al buffer de destino
; ESI = Número entero sin signo (32 bits) a convertir
; EDX = Base numérica (Ej: 10 para Decimal, 2 para Binario, 16 para Hex)
;
; SALIDA:
; RAX = Puntero al inicio de la cadena (el mismo que RDI original)
; El buffer en RDI contendrá la cadena terminada en 0.
; ==============================================================================

default rel
section .text
    global lib_uint32_string

lib_uint32_string:
    ; --- PRÓLOGO STANDARD ---
    push rbp
    mov rbp, rsp
    
    push rbx            ; Guardamos RBX (Callee-saved)
    ; CORRECCIÓN: Ya NO hacemos push rdi aquí.
    ; En su lugar, guardamos el puntero al buffer en RBX para recuperarlo
    ; después del bucle de división, sin interferir con los dígitos en pila.
    mov rbx, rdi        ; RBX = Puntero al inicio del buffer (callee-saved, seguro)

    ; --- VALIDACIÓN DE BASE (CON LÍMITE SUPERIOR E INFERIOR) ---
    cmp edx, 2
    jge .comprobar_maximo
    mov edx, 10         ; Si base < 2, forzar base 10
    jmp .preparar

.comprobar_maximo:
    cmp edx, 36
    jle .preparar       ; Si la base es <= 36, todo está correcto
    mov edx, 36         ; Si la base > 36, forzar al límite superior (Base 36)

.preparar:
    mov eax, esi        ; EAX = Número a convertir (Dividendo)
    mov r8d, edx        ; R8D = Base (Divisor). Usamos R8 porque DIV destruye RDX
    xor ecx, ecx        ; ECX = Contador de dígitos (antes era EBX, ahora RBX está ocupado)

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
    inc ecx             ; Aumentamos contador
    
    test eax, eax       ; ¿Queda número?
    jnz .bucle_division ; Si cociente != 0, repetir

    ; --- RECUPERACIÓN ---
    ; CORRECCIÓN: RBX ya contiene la dirección del buffer desde el principio.
    ; No necesitamos leer de [rbp-N] ni hacer pop de la pila de dígitos
    ; para recuperarlo. Simplemente usamos RBX directamente.
    mov rdi, rbx        ; RDI = Puntero al inicio del buffer
    mov rax, rdi        ; RAX = Valor de retorno

    ; --- BUCLE DE ESCRITURA ---
.escribir:
    pop rdx             ; Sacamos un dígito de la pila
    mov [rdi], dl       ; Escribimos en el buffer
    inc rdi             ; Avanzamos puntero del buffer
    dec ecx             ; Decrementamos contador
    jnz .escribir       ; Si quedan dígitos, repetir

    mov byte [rdi], 0   ; Terminador nulo al final

    ; --- EPÍLOGO ---
    ; CORRECCIÓN: Solo restauramos RBX. Ya no hay un 'pop rdi' espurio
    ; que corrompía el frame extrayendo un valor inexistente de la pila.
    pop rbx
    
    leave               ; Restaura RSP y RBP
    ret
