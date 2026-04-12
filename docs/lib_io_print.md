# Librería: lib_print - Impresión en Stdout

## Descripción

Conjunto de rutinas de bajo nivel para imprimir datos en la salida estándar (stdout) sin dependencias de libc.

## Funciones Exportadas

### `print_string` - Imprimir Cadena de Texto

```nasm
mov rdi, mensaje  ; RDI = puntero a cadena terminada en null
call print_string
```

**Entrada:**

- `RDI` = Puntero a cadena (terminada en 0x00)

**Salida:** Ninguna (imprime en stdout)

### `print_int` - Imprimir Entero de 64 bits

```nasm
mov rdi, 12345
call print_int
```

**Entrada:**

- `RDI` = Valor entero (interpretado como signed int64)

**Salida:** Número convertido a ASCII impreso en stdout

### `print_hex` - Imprimir Valor Hexadecimal

```nasm
mov rdi, 0xDEADBEEF
call print_hex
```

**Entrada:**

- `RDI` = Valor a imprimir en hexadecimal

**Salida:** Valor en formato 0x... impreso en stdout

### `print_nl` - Imprimir Nueva Línea

```nasm
call print_nl
```

**Entrada:** Ninguna

**Salida:** Imprime un salto de línea (\n)

## Ejemplo Completo

```nasm
%include "lib/constants.inc"
%include "lib/sys_macros.inc"

extern print_string, print_int, print_hex, print_nl

section .data
    msg1 db "Valor numerico: ", 0
    msg2 db "Valor hexadecimal: ", 0

section .text
    global _start

_start:
    ; Imprimir "Valor numerico: "
    mov rdi, msg1
    call print_string
    
    ; Imprimir el número 255
    mov rdi, 255
    call print_int
    call print_nl
    
    ; Imprimir "Valor hexadecimal: "
    mov rdi, msg2
    call print_string
    
    ; Imprimir 255 en hex
    mov rdi, 255
    call print_hex
    call print_nl
    
    sys_exit 0
```

**Salida esperada:**

```text
Valor numerico: 255
Valor hexadecimal: 0xff
```

## Notas de Implementación

- Las funciones no usan la librería estándar de C
- Se comunican directamente con el kernel mediante syscall `sys_write`
- Las conversiones numéricas se realizan completamente en ensamblador
- No hay buffering (escritura inmediata)

## Performance

- Operación de syscall por cada `print_string`
- Para múltiples impresiones, considera construir un buffer local

## Véase También

- [lib_string_int32](lib_cnv_string_int32.md) - Conversión reversa (string → int)
