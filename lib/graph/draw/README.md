# 🖍️ Librería Gráfica: Trazado de Píxeles (Framebuffer)

Este módulo proporciona las rutinas fundamentales para escribir píxeles directamente en la memoria de vídeo (`/dev/fb0`). 

Siguiendo la **Arquitectura de Dos Capas** del framework, la funcionalidad se divide estrictamente en dos módulos para separar la seguridad del rendimiento extremo.

## 🏗️ Filosofía de Diseño

1. **Capa 1: El Escudo (`lib_draw_pixelcval.asm`)**
   * **Propósito:** Proteger la memoria contra *Segmentation Faults*.
   * **Comportamiento:** Realiza una comprobación de límites (Clipping) contra la resolución de la pantalla. Si las coordenadas `X` o `Y` son negativas o exceden los límites de `ScreenInfo`, aborta la operación de forma segura. Si son válidas, realiza un *Tail Call* (`jmp`) a la Capa 2.
   * **Cuándo usar:** Al procesar entrada directa del usuario, archivos externos, o dibujar elementos esporádicos en posiciones impredecibles.

2. **Capa 2: El Motor (`lib_draw_pixelfast.asm`)**
   * **Propósito:** Rendimiento máximo ("Bucle Interno Ciego").
   * **Comportamiento:** Asume que las coordenadas son 100% correctas. Elimina todos los saltos condicionales (`cmp`) y calcula directamente el offset en memoria usando `Pitch` y `BPP` para inyectar el color.
   * **Cuándo usar:** **Exclusivamente** dentro de bucles internos de otras librerías gráficas (ej. `draw_rect`, `draw_line`) *después* de que la función constructora haya realizado el recorte matemático previo de la figura geométrica.

---

## 🛠️ Especificaciones Técnicas

Ambas librerías comparten exactamente la misma Interfaz Binaria de Aplicación (ABI) y requieren los mismos registros como entrada:

| Registro | Descripción | Formato Esperado |
| :--- | :--- | :--- |
| **RDI** | Puntero a la estructura `ScreenInfo` | Memoria (Mapeada previamente por `fb_core` y `fb_map`) |
| **ESI** | Coordenada X | Entero 32-bits (Positivo) |
| **EDX** | Coordenada Y | Entero 32-bits (Positivo) |
| **ECX** | Color | 32-bits (Soporta formatos estándar) |

**Dependencias:**
* Requiere el archivo de cabecera `%include "lib/graph/core/lib_fb_core.inc"` para conocer los offsets de la estructura `ScreenInfo`.

---

## 💻 Ejemplos de Uso (NASM)

### Ejemplo 1: Llamada Segura (Capa 1)
Ideal para invocar desde un comando principal donde el usuario introduce las coordenadas.

```nasm
extern lib_draw_pixelcval

; RDI ya contiene el puntero a datos_fb
mov esi, 5000           ; Coordenada X (Peligro: Fuera de pantalla)
mov edx, 100            ; Coordenada Y
mov ecx, 0xFF0000       ; Color (Rojo)

; La capa 1 detectará el error y abortará silenciosamente sin romper el programa
call lib_draw_pixelcval