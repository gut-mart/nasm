# Librería: lib_file - Operaciones de Archivo

## Descripción

Funciones de bajo nivel para leer y escribir archivos sin dependencias de libc.

## Funciones Exportadas

### `file_open` - Abrir Archivo

```nasm
mov rdi, ruta_archivo
mov rsi, flags          ; O_RDONLY, O_WRONLY, O_RDWR, etc.
mov rdx, permisos       ; 0644, etc.
call file_open
; RAX contiene file descriptor o error
```

### `file_close` - Cerrar Archivo

```nasm
mov rdi, file_descriptor
call file_close
; RAX = 0 si éxito, <0 si error
```

### `file_read` - Leer Archivo

```nasm
mov rdi, file_descriptor
mov rsi, buffer
mov rdx, tamaño
call file_read
; RAX = bytes leídos
```

### `file_write` - Escribir Archivo

```nasm
mov rdi, file_descriptor
mov rsi, buffer
mov rdx, tamaño
call file_write
; RAX = bytes escritos
```

## Flags de Apertura

- `O_RDONLY = 0`    - Lectura
- `O_WRONLY = 1`    - Escritura
- `O_RDWR = 2`      - Lectura y escritura
- `O_APPEND = 1024` - Adjuntar
- `O_CREAT = 64`    - Crear si no existe

## Permisos

- `0644` - rw-r--r--
- `0755` - rwxr-xr-x
- `0700` - rwx------

## Ejemplo: Leer Archivo

```nasm
section .data
    filename db "/etc/hostname", 0
    flags    dd 0            ; O_RDONLY

section .bss
    buffer resb 256
    fd resd 1

section .text
    ; Abrir archivo
    mov rdi, filename
    mov rsi, 0               ; O_RDONLY
    mov rdx, 0
    call file_open
    mov [fd], rax
    
    ; Leer contenido
    mov rdi, [fd]
    mov rsi, buffer
    mov rdx, 256
    call file_read
    
    ; Cerrar archivo
    mov rdi, [fd]
    call file_close
```
