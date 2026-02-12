; ==============================================================================
; RUTA: ./lib/text/cnv_uint32_to_str/lib_cnv_uint32_to_str.asm
; DESCRIPCIÓN: Convierte un uint32 a string en la BASE especificada.
;
; ENTRADA:
;   RDI = Puntero al buffer de destino
;   ESI = Número entero sin signo (32 bits) a convertir
;   EDX = Base numérica (Ej: 10 para Decimal, 2 para Binario, 16 para Hex)
;
; SALIDA:
;   RAX = Puntero al inicio de la cadena (el mismo que RDI)
;   El buffer en RDI contendrá la cadena terminada en 0.
; ==============================================================================

default rel
section .text
    global lib_cnv_uint32_to_str

lib_cnv_uint32_to_str:
    push rbp
    mov rbp, rsp
    sub rsp, 16         ; Alineación

    push rbx            ; Guardamos registros protegidos
    push rdi            ; Guardamos el puntero inicial para devolverlo después

    ; Validación básica de la base (opcional, pero recomendada)
    ; Si la base es 0 o 1, forzamos base 10 para evitar bucles infinitos o crash
    cmp edx, 2
    jge .inicio
    mov edx, 10         ; Base por defecto si la entrada es inválida

.inicio:
    mov eax, esi        ; Número a convertir (Dividendo)
    mov ecx, edx        ; Base (Divisor) - Movemos de EDX a ECX para usarlo en div
    xor ebx, ebx        ; Contador de dígitos apilados

.bucle_division:
    xor edx, edx        ; Limpiar parte alta para la división (EDX:EAX)
    div ecx             ; EAX / Base --> EAX=Cociente, EDX=Resto
    
    ; Convertir el resto (0..Base-1) a ASCII
    cmp edx, 9
    jg .es_letra        ; Si es > 9 (para Hex), saltamos a letras

    add edx, '0'        ; 0-9 -> '0'-'9'
    jmp .push_digito

.es_letra:
    add edx, 'A' - 10   ; 10-15 -> 'A'-'F' (Útil si usas base 16)

.push_digito:
    push rdx            ; Guardamos el carácter en la pila
    inc ebx             ; Incrementamos contador
    
    test eax, eax       ; ¿El cociente es 0?
    jnz .bucle_division ; Si no, seguimos dividiendo

    ; Recuperar caracteres de la pila al buffer
    ; RDI ya apunta al inicio del buffer
.escribir:
    pop rdx
    mov [rdi], dl
    inc rdi
    dec ebx
    jnz .escribir

    mov byte [rdi], 0   ; Terminador nulo

    pop rax             ; Restauramos el puntero original en RAX (Return value)
    pop rbx             ; Restauramos RBX
    
    mov rsp, rbp
    pop rbp
    ret