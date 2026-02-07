; ==============================================================================
; LIBRERÍA: nombre_funcion.asm
; DESCRIPCIÓN: [Explica qué hace aquí]
; ENTRADA:  RDI, RSI, RDX... (Argumentos estándar)
; SALIDA:   RAX (Resultado)
; PRESERVA: RBX, R12-R15, RBP (Estándar ABI)
; ==============================================================================

section .text
    global nombre_funcion

nombre_funcion:
    ; --------------------------------------------------------------------------
    ; 1. PRÓLOGO (Crear tu "Habitación Privada")
    ; --------------------------------------------------------------------------
    push rbp            ; Guardamos la base de la pila de quien nos llamó (Madre)
    mov rbp, rsp        ; Establecemos nuestra propia base (Yo)
    
    ; Reservar espacio para variables locales (X bytes).
    ; REGLA: (X + 8) debe ser múltiplo de 16 si vas a llamar a otras funciones.
    sub rsp, 32         ; Ejemplo: Reservamos 32 bytes para mis cuentas

    ; --------------------------------------------------------------------------
    ; 2. PRESERVACIÓN (Guardar los juguetes prestados)
    ; --------------------------------------------------------------------------
    ; Si vas a usar estos registros, TIENES que guardarlos. Si no, no hace falta.
    push rbx            
    push r12
    ; (R13, R14, R15 también si los usas)

    ; --------------------------------------------------------------------------
    ; 3. CUERPO DE LA FUNCIÓN (Tu lógica)
    ; --------------------------------------------------------------------------
    ; AQUÍ PROGRAMAS TU MAGIA.
    
    ; IMPORTANTE:
    ; - No uses variables [variables_globales].
    ; - Usa tus variables locales: [rbp - 8], [rbp - 16], etc.
    ; - Los argumentos llegaron en RDI, RSI. Si necesitas el espacio, guárdalos
    ;   en tu pila local inmediatamente.

    mov [rbp - 8], rdi  ; Ejemplo: Guardar el primer argumento en mi pila segura

    ; ... lógica ...
    ; call nombre_funcion (¡Llamada recursiva segura!)
    ; ... lógica ...

    ; --------------------------------------------------------------------------
    ; 4. RESTAURACIÓN (Devolver los juguetes)
    ; --------------------------------------------------------------------------
    ; Debes hacer POP en orden INVERSO al PUSH
    pop r12
    pop rbx

    ; --------------------------------------------------------------------------
    ; 5. EPÍLOGO (Destruir la habitación y salir)
    ; --------------------------------------------------------------------------
    mov rsp, rbp        ; Liberamos toda la memoria local de golpe (el 'sub rsp')
    pop rbp             ; Restauramos la base de la "Madre"
    ret                 ; Volvemos