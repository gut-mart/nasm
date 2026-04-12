# Mejores Prácticas y Seguridad

## Convenciones de Código

### Comentarios

Mantén comentarios claros en español o inglés (consistentemente):

```nasm
; Establecer contador
mov rcx, 10

; Saltar si igual a cero
cmp rax, 0
je .exit_loop
```

### Nombres Descriptivos

```nasm
; MAL: Poco claridad
mov r8, rax
add r8, rbx

; BIEN: Descriptivo
mov sum_result, rax
add sum_result, rbx
```

### Alineación y Formato

- Mantén líneas bajo 80 caracteres en bucles complejos
- Alinea comentarios en la columna 40+
- Usa identación consistente (4 espacios = 1 tab)

```nasm
    mov rax, rbx            ; Comentario alineado
    add rax, rcx            ; Más claro así
```

## Gestión de Registros

### Convenión x86_64 (System V AMD64 ABI)

**Preservar (Callee-saved):**
- RBP, RBX, R12-R15
- RSP (implícito)

**No preservar (Caller-saved):**
- RAX, RCX, RDX, RSI, RDI, R8-R11

**Parámetros:**
1. RDI
2. RSI
3. RDX
4. RCX
5. R8
6. R9

(En la pila: arg7+)

### Ejemplo Correcto

```nasm
funcion_suma:
    push rbx                ; Preservar
    mov rax, rdi            ; arg1
    mov rbx, rsi            ; arg2
    add rax, rbx            ; resultado
    pop rbx                 ; Restaurar
    ret
```

## Validación de Entrada

### Revisar Argumentos

```nasm
; Verificar que RDI no es null
cmp rdi, 0
je .error_null_ptr

; Verificar rango
cmp rdi, 255
ja .error_out_of_range
```

### Manejo de Errores Syscall

```nasm
; sys_open retorna -1 en caso de error
mov rax, 2              ; sys_open
syscall
cmp rax, -1
je .error_open

; Para mmap, MAP_FAILED = -1
cmp rax, -1
je .error_mmap
```

## Seguridad en Memoria

### Buffer Overflow Prevention

```nasm
; VULNERABLE: Copia sin límite
mov rsi, src
mov rdi, dst
.copy_loop:
    lodsb               ; Cargar desde source
    stosb               ; Almacenar en dest (¡sin límite!)
    test al, al
    jnz .copy_loop

; SEGURO: Verificar límite
mov rcx, max_size
cmp rcx, 0
je .done
.copy_safe:
    lodsb
    test al, al
    je .done
    stosb
    dec rcx
    jnz .copy_safe
```

### Validación de Punteros

```nasm
; Verificar alineación
mov rax, [rdi]
and rax, 0xFF
cmp rax, 0
jne .misaligned_ptr
```

## Performance

### Evitar Stalls

```nasm
; LENTO: Dependency chain
mov rax, [rdi]
mov rbx, [rax]
mov rcx, [rbx]

; RÁPIDO: Paralelizar donde sea posible
mov rax, [rdi]
mov rbx, [rsi]          ; Operación independiente
mov rcx, [rax]
```

### Bifurcaciones

```nasm
; Minimizar branch mispredictions
; Mantener bucles calientes simples
.hot_loop:
    add rax, [rdi + rcx*8]
    inc rcx
    cmp rcx, r8
    jl .hot_loop
```

## Debugging

### Usar GDB Efectivamente

```bash
gdb ./bin/programa
(gdb) b _start          # Breakpoint al inicio
(gdb) r                 # Run
(gdb) n                 # Siguiente instrucción
(gdb) p $rax            # Inspeccionar registro
(gdb) info reg          # Ver todos los registros
(gdb) x/10x $rsp        # Inspeccionar memoria (hex)
(gdb) disas _start      # Desensamblar función
```

### Símbolos de Depuración

Asegúrate de compilar con flags de debug:

```bash
nasm -f elf64 -g -F dwarf -o output.o input.asm
```

## Testing

### Escribir Tests Robustos

```bash
# Tests unitarios simples
#!/bin/bash

test_hello_world() {
    output=$(./bin/hello_world)
    if [[ "$output" == *"Hola"* ]]; then
        echo "✓ PASS"
        return 0
    else
        echo "✗ FAIL: $output"
        return 1
    fi
}

test_fibonacci() {
    output=$(./bin/fibonacci)
    if [[ "$output" == *"Serie Fibonacci"* ]]; then
        echo "✓ PASS"
        return 0
    else
        echo "✗ FAIL: $output"
        return 1
    fi
}
```

## Permisos y Privilegios

### Para Framebuffer

```bash
# Opción 1: Usar sudo (inseguro)
sudo ./bin/draw_pixel

# Opción 2: Agregar al grupo video
sudo usermod -a -G video $USER
# Logout y login requeridos

# Verificar
id
# Debe mostrar "video" en los grupos
```

## Documentación de API

### Template

```nasm
; ==============================================================================
; FUNCIÓN: mi_funcion
; DESCRIPCIÓN: Breve descripción
; 
; ENTRADA:
;   RDI = Parámetro 1 (tipo, rango)
;   RSI = Parámetro 2 (tipo, rango)
;
; SALIDA:
;   RAX = Resultado (tipo, rango)
;   /C  = Flag Carry si error
;
; PRESERVA: RBX, R12-R15, RBP
; MODIFICA: RAX, RCX, RDX, RSI, RDI
;
; ERRORES:
;   -1  = EINVAL (argumento inválido)
;   -12 = ENOMEM (sin memoria)
;
; EJEMPLO:
;   mov rdi, 42
;   call mi_funcion
;   cmp rax, 0
;   jl .error
; ==============================================================================
```

## Véase También

- [CONTRIBUTING.md](../CONTRIBUTING.md)
- GDB Manual: https://sourceware.org/gdb/onlinedocs/
- x86_64 ABI: https://en.wikipedia.org/wiki/X86_calling_conventions
