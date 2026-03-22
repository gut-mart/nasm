; ==============================================================================
; LIBRERÍA: lib_file.asm
; DESCRIPCIÓN: Herramientas reutilizables para manejo de archivos.
; ==============================================================================

default rel

section .text
    global extract_chunk

; ------------------------------------------------------------------------------
; FUNCIÓN: extract_chunk
; Extrae una porción de un archivo origen y la guarda en un archivo destino.
; 
; PARÁMETROS:
; RDI = Puntero al nombre del archivo de origen (ej. "os6128.rom")
; RSI = Puntero al nombre del archivo de destino (ej. "fuente.bin")
; RDX = Offset / Posición de inicio en bytes (ej. 0x3800)
; RCX = Tamaño a extraer en bytes (ej. 2048)
; R8  = Puntero a un buffer de memoria temporal en RAM
;
; RETORNO:
; RAX = 0 si fue exitoso, número negativo si hubo error.
; ------------------------------------------------------------------------------
extract_chunk:
    ; Prólogo: Guardamos los registros no volátiles
    push rbp
    mov rbp, rsp
    push r12
    push r13
    push r14
    push r15
    push rbx

    ; Guardamos los parámetros en registros seguros
    mov r12, rdi    ; r12 = archivo_origen
    mov r13, rsi    ; r13 = archivo_destino
    mov r14, rdx    ; r14 = offset
    mov r15, rcx    ; r15 = tamaño
    mov rbx, r8     ; rbx = buffer en RAM

    ; --- PASO 1: ABRIR ARCHIVO ORIGEN ---
    mov rax, 2      ; sys_open
    mov rdi, r12    
    mov rsi, 0      ; O_RDONLY
    mov rdx, 0
    syscall
    cmp rax, 0
    jl .error_apertura_origen
    mov r12, rax    ; r12 = FD origen

    ; --- PASO 2: MOVER EL PUNTERO (SEEK) ---
    mov rax, 8      ; sys_lseek
    mov rdi, r12    
    mov rsi, r14    
    mov rdx, 0      ; SEEK_SET
    syscall
    cmp rax, 0
    jl .error_origen_abierto

    ; --- PASO 3: LEER A LA MEMORIA RAM ---
    mov rax, 0      ; sys_read
    mov rdi, r12    
    mov rsi, rbx    
    mov rdx, r15    
    syscall
    cmp rax, 0
    jl .error_origen_abierto

    ; --- PASO 4: CERRAR ARCHIVO ORIGEN ---
    ; Lo cerramos inmediatamente tras leer para liberar el descriptor
    mov rax, 3      ; sys_close
    mov rdi, r12
    syscall

    ; --- PASO 5: ABRIR/CREAR ARCHIVO DESTINO ---
    mov rax, 2      ; sys_open
    mov rdi, r13    
    ; 577 = O_CREAT (64) | O_WRONLY (1) | O_TRUNC (512)
    mov rsi, 577    
    mov rdx, 420    ; Permisos 0644 en octal
    syscall
    cmp rax, 0
    jl .error_apertura_destino
    mov r13, rax    ; r13 = FD destino

    ; --- PASO 6: ESCRIBIR LOS DATOS DESDE LA RAM ---
    mov rax, 1      ; sys_write
    mov rdi, r13    
    mov rsi, rbx    
    mov rdx, r15    
    syscall
    cmp rax, 0
    jl .error_destino_abierto

    ; --- PASO 7: CERRAR ARCHIVO DESTINO ---
    mov rax, 3      ; sys_close
    mov rdi, r13
    syscall

    mov rax, 0      ; Éxito (Todo OK)
    jmp .fin

; --- MANEJO DE ERRORES ---
.error_destino_abierto:
    push rax        ; Guardar el código de error original
    mov rax, 3      ; sys_close
    mov rdi, r13
    syscall
    pop rax         ; Recuperar el error para devolverlo
    jmp .fin

.error_origen_abierto:
    push rax        
    mov rax, 3      
    mov rdi, r12
    syscall
    pop rax         
    jmp .fin

.error_apertura_origen:
.error_apertura_destino:
    ; Si falla el open, RAX ya tiene el error y no hay nada que cerrar.
    
.fin:
    ; Epílogo: Restaurar los registros del programa principal
    pop rbx
    pop r15
    pop r14
    pop r13
    pop r12
    mov rsp, rbp
    pop rbp
    ret