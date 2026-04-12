# Librería: lib_fb_core - Motor Gráfico del Framebuffer

## Descripción

`lib_fb_core` es el núcleo de bajo nivel para manipulación de gráficos en ensamblador x86_64. Se encarga de:
- Comunicación con el kernel Linux vía syscalls y ioctl
- Extracción de metadatos del hardware (`/dev/fb0`)
- Mapeo de memoria de video física al espacio de usuario mediante `mmap`

## Requisitos Previos

### Includes Obligatorios
```nasm
%include "lib/constants.inc"
%include "lib/sys_macros.inc"
%include "lib/graph/core/lib_fb_core.inc"
default rel
```

### Privilegios
- Requiere acceso de lectura/escritura a `/dev/fb0`
- Típicamente necesita `sudo` o pertenecer al grupo `video`

### Reserva de Memoria
```nasm
section .bss
    fb_datos resb ScreenInfo_size  ; 52 bytes obligatorios
```

## Estructura de Datos: ScreenInfo (52 bytes)

| Offset | Campo | Tipo | Descripción |
|--------|-------|------|-------------|
| 0-3 | `width` | u32 | Resolución horizontal (píxeles) |
| 4-7 | `height` | u32 | Resolución vertical (píxeles) |
| 8-11 | `bpp` | u32 | Bits por píxel (profundidad color) |
| 12-15 | `pitch` | u32 | Bytes por línea (stride) |
| 16-19 | `size_mem` | u32 | Tamaño total RAM video (bytes) |
| 20-23 | `phy_width` | u32 | Ancho físico (mm) |
| 24-27 | `phy_height` | u32 | Alto físico (mm) |
| 28-31 | `red_off` | u32 | Offset de bits para canal Rojo |
| 32-35 | `green_off` | u32 | Offset de bits para canal Verde |
| 36-39 | `blue_off` | u32 | Offset de bits para canal Azul |
| 40-43 | `transp_off` | u32 | Offset de bits para canal Alfa |
| 44-51 | `ptr_mem` | u64 | **Puntero 64-bit a la RAM de video** |

## API de Funciones

### `fb_core` - Leer Información del Hardware

**Propósito:** Extrae metadatos del framebuffer físico.

**Entrada:**
- `RDI` = Puntero a estructura `ScreenInfo` reservada

**Salida:**
- `RAX` = 0 si éxito, < 0 si error

**Ejemplo:**
```nasm
mov rdi, fb_datos
call fb_core
cmp rax, 0
jl .error
```

**Nota:** Debe llamarse **antes** que `fb_map`.

### `fb_map` - Mapear Memoria de Video

**Propósito:** Proyecta la RAM de video al espacio de usuario.

**Entrada:**
- `RDI` = Puntero a estructura `ScreenInfo` inicializada por `fb_core`

**Salida:**
- `RAX` = 0 si éxito, < 0 si error
- El campo `ptr_mem` en la estructura se rellena con la dirección base

**Ejemplo:**
```nasm
mov rdi, fb_datos
call fb_map
cmp rax, 0
jl .error_map
mov rsi, [fb_datos + ScreenInfo.ptr_mem]  ; Obtener puntero
```

### Funciones Auxiliares

#### `get_screen_size` - Obtener Tamaño de Terminal

```nasm
call get_screen_size  ; Resultado en terminal_winsize
mov ax, [terminal_winsize]      ; Filas
mov bx, [terminal_winsize + 2]  ; Columnas
```

#### `get_screen_rows` / `get_screen_cols`

```nasm
call get_screen_rows  ; RAX = número de filas
call get_screen_cols  ; RAX = número de columnas
```

## Plantilla de Inicialización

```nasm
%include "lib/constants.inc"
%include "lib/sys_macros.inc"
%include "lib/graph/core/lib_fb_core.inc"

default rel
extern fb_core, fb_map

section .bss
    fb_datos resb ScreenInfo_size

section .text
    global _start

_start:
    ; 1. Extraer información del hardware
    mov rdi, fb_datos
    call fb_core
    cmp rax, 0
    jl .error

    ; 2. Mapear memoria de video
    mov rdi, fb_datos
    call fb_map
    cmp rax, 0
    jl .error

    ; 3. Acceder al puntero de video
    mov rsi, [fb_datos + ScreenInfo.ptr_mem]
    mov rax, [fb_datos + ScreenInfo.width]
    mov rbx, [fb_datos + ScreenInfo.height]
    
    ; ... dibujar píxeles usando rsi como base ...
    
.error:
    sys_exit 1
```

## Cálculo de Dirección de Píxel

Para un píxel en coordenadas (x, y):

```nasm
; Entrada: RDI = fb_datos, RSI = x, RDX = y
mov r8, [rdi + ScreenInfo.pitch]     ; bytes por línea
mov r9, [rdi + ScreenInfo.ptr_mem]   ; dirección base
imul rdx, r8                          ; offset línea = y * pitch
add r9, rdx                           ; r9 = &primera_pixel_línea
mov r10, [rdi + ScreenInfo.bpp]
mov r10, r10, 10                      ; bpp >> 10 = bytes por píxel (asume bpp=32)
add r9, rsi                           ; r9 = &pixel
```

## Manejo de Errores Comunes

| Código Error | Causa | Solución |
|--------------|-------|----------|
| -1 | `/dev/fb0` no encontrado | Verificar drivers de gráficos |
| -13 (EACCES) | Sin permisos | Ejecutar con `sudo` o agregar grupo `video` |
| -22 (EINVAL) | Parámetros inválidos | Verificar estructura de datos |
| -12 (ENOMEM) | No hay memoria | Sistema con peu recursos |

## Performance

- El mapeo es una operación única (lenta)
- El acceso directo a píxeles es O(1)
- Para gráficos de alto rendimiento, usar `libdraw_pixel` que optimiza escrituras

## Dependencias y Librerías Relacionadas

- [lib_color_pack](lib_graph_color.md) - Empaquetar colores RGB a formato hardware
- [lib_draw_pixel](lib_graph_draw_pixel.md) - Optimizaciones de escritura de píxeles
- [lib_draw_rect](lib_graph_draw_rect.md) - Dibujo eficiente de rectángulos

## Véase También

- [Ejemplo: fb_core.asm](../comandos/monitor/core/fb_core.asm)
- [Referencia: lib_fb_core.inc](../lib/graph/core/lib_fb_core.inc)
