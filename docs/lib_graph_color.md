# Librería: lib_color_pack - Empaquetamiento de Colores RGB

## Descripción

Funciones para convertir colores RGB de 24 bits al formato de 32 bits requerido por el hardware del framebuffer.

## API

### `pack_color` - Empaquetar RGB a 32-bit

**Propósito:** Convierte componentes RGB a formato ARGB_8888.

**Entrada:**

- `RDI` = R (0-255)
- `RSI` = G (0-255)
- `RDX` = B (0-255)

**Salida:**

- `RAX` = Color empaquetado de 32 bits

## Formato Estándar

```text
[Byte 3: Alpha] [Byte 2: Red] [Byte 1: Green] [Byte 0: Blue]
    0xFF            0xRR        0xGG            0xBB
```

## Ejemplo

```nasm
; Rojo puro
mov rdi, 255
mov rsi, 0
mov rdx, 0
call pack_color
; RAX = 0xFF0000FF

; Verde puro
mov rdi, 0
mov rsi, 255
mov rdx, 0
call pack_color
; RAX = 0xFF00FF00

; Azul puro
mov rdi, 0
mov rsi, 0
mov rdx, 255
call pack_color
; RAX = 0xFF0000FF
```
