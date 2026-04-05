# 📄 ARCHIVO DE AYUDA: MANUAL DEL DESARROLLADOR - `lib_fb_core`


***

```markdown
# ⚙️ Motor Gráfico: lib_fb_core

**`lib_fb_core`** es el núcleo de bajo nivel para la manipulación de gráficos en Ensamblador x86_64 sobre Linux. Se encarga de la comunicación directa con el Kernel para extraer la topología del hardware (`/dev/fb0`) y proyectar la memoria de vídeo física en el espacio de usuario (RAM) mediante `mmap`.

---

## ⚠️ REQUISITOS PREVIOS

Para enlazar y utilizar esta librería en tu programa, debes cumplir estrictamente estos puntos:

1. **Includes y Macros:**
   ```nasm
   %include "lib/constants.inc"
   %include "lib/sys_macros.inc"
   %include "lib/graph/core/lib_fb_core.inc" ; Ajusta la ruta a tu proyecto
   ```
2. **Directivas:** Debes compilar usando `default rel`.
3. **Reserva de Memoria:** Es obligatorio reservar el espacio exacto en la sección `.bss` usando la constante `ScreenInfo_size`.
4. **Privilegios:** La ejecución requiere permisos de lectura/escritura sobre `/dev/fb0` (usualmente requiere `sudo` o pertenecer al grupo `video`).

---

## 📦 Estructura de Datos (`ScreenInfo`)

La librería centraliza todos los datos del hardware en un bloque de **52 bytes**. Los desplazamientos (offsets) están definidos en `lib_fb_core.inc`:

| Offset | Nombre Constante | Tamaño | Descripción |
| :--- | :--- | :--- | :--- |
| `0` | `ScreenInfo.width` | 4 bytes | Resolución Horizontal (Píxeles). |
| `4` | `ScreenInfo.height`| 4 bytes | Resolución Vertical (Píxeles). |
| `8` | `ScreenInfo.bpp` | 4 bytes | Bits por Píxel (Profundidad de color, ej. 32). |
| `12` | `ScreenInfo.pitch` | 4 bytes | Bytes por línea real (Salto de línea de memoria). |
| `16` | `ScreenInfo.size_mem`| 4 bytes | Tamaño total de la RAM de vídeo asignada. |
| `20` | `ScreenInfo.phy_width`| 4 bytes | Ancho físico del monitor (mm). |
| `24` | `ScreenInfo.phy_height`| 4 bytes | Alto físico del monitor (mm). |
| `28` | `ScreenInfo.red_off` | 4 bytes | Bit de inicio del canal Rojo. |
| `32` | `ScreenInfo.green_off`| 4 bytes | Bit de inicio del canal Verde. |
| `36` | `ScreenInfo.blue_off` | 4 bytes | Bit de inicio del canal Azul. |
| `40` | `ScreenInfo.transp_off`| 4 bytes | Bit de inicio del canal Alfa (Transparencia). |
| `44` | `ScreenInfo.ptr_mem` | 8 bytes | **PUNTERO DE 64-BITS A LA MEMORIA DE VÍDEO.** |

---

## 🛠️ API de Funciones (Exportadas)

### 1. `fb_core` (Inicialización e Información)
Extrae los datos físicos y virtuales del Framebuffer y los guarda en tu estructura.
* **Entrada:** `RDI` = Puntero a tu memoria reservada (`datos_fb`).
* **Salida:** `RAX` = `0` (Éxito) o `< 0` (Error).
* **⚠️ Importante:** Esta función DEBE llamarse antes que `fb_map`, ya que calcula el `size_mem` necesario para el mapeo.

### 2. `fb_map` (Mapeo de Memoria)
Proyecta la RAM de vídeo en tu programa y devuelve la llave para dibujar píxeles.
* **Entrada:** `RDI` = Puntero a tu memoria reservada (`datos_fb`).
* **Salida:** `RAX` = `0` (Éxito) o `< 0` (Error).
* **Efecto:** El offset `ScreenInfo.ptr_mem` se rellena con la dirección base de la pantalla.

---

## 🚀 Guía de Integración Rápida

Plantilla base para inicializar el motor gráfico en cualquier programa nuevo:

```nasm
%include "lib/constants.inc"
%include "lib/sys_macros.inc"
%include "lib/graph/core/lib_fb_core.inc"

default rel
extern fb_core, fb_map, sys_exit

section .bss
    ; Nombre libre, tamaño obligatorio
    fb_datos resb ScreenInfo_size

section .text
    global _start

_start:
    ; 1. Cargar metadatos del hardware
    mov rdi, fb_datos
    call fb_core
    cmp rax, 0
    jl .error_critico

    ; 2. Solicitar el mapeo de memoria
    mov rdi, fb_datos
    call fb_map
    cmp rax, 0
    jl .error_critico

    ; 3. Extraer el puntero y prepararse para dibujar
    mov rdi, [fb_datos + ScreenInfo.ptr_mem]
    
    ; [!] Tu lógica de dibujo (lib_draw) va aquí [!]

    sys_exit 0

.error_critico:
    ; Manejo de error (ej. Imprimir "Requiere sudo")
    sys_exit 1
```
```

***
