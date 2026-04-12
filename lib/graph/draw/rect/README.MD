# 🔲 Librería Gráfica: Trazado de Rectángulos (Framebuffer)

Este módulo proporciona las rutinas para dibujar bloques rectangulares sólidos de color en la memoria de vídeo (`/dev/fb0`).

Fiel a la **Arquitectura de Dos Capas** del framework, la funcionalidad está dividida para maximizar la seguridad en el borde y el rendimiento bruto en el interior.

## 🏗️ Filosofía de Diseño

1. **Capa 1: El Escudo con Clipping Inteligente (`lib_draw_rectcval.asm`)**
   * **Propósito:** Proteger la memoria y evitar *Segmentation Faults* asegurando que la geometría encaje en la pantalla.
   * **Comportamiento:** No se limita a abortar si la figura se sale. Implementa un algoritmo de **Clipping** (Recorte) matemático:
     * Si `X` o `Y` son negativos, recorta el Ancho (`W`) o el Alto (`H`) por la izquierda/arriba y empuja el origen a `0`.
     * Si `X + W` o `Y + H` exceden la resolución, recorta `W` y `H` por la derecha/abajo.
     * Si la figura queda totalmente fuera, aborta silenciosamente.
     * Si es válida o se ha recortado con éxito, realiza un *Tail Call* (`jmp`) a la Capa 2.

2. **Capa 2: El Motor Lineal Rápido (`lib_draw_rectfast.asm`)**
   * **Propósito:** Rendimiento extremo de llenado de memoria (Fill Rate).
   * **Comportamiento:** Asume coordenadas y dimensiones perfectas (32-bit BPP). 
   * **Optimización Extrema:** NO invoca a `lib_draw_pixelfast` píxel por píxel. Calcula la dirección de memoria absoluta del píxel superior izquierdo una sola vez. Luego, usa un doble bucle aritmético que inyecta los `dword` de color secuencialmente y aplica un "salto de fila" (`Pitch - (W*4)`) al final de cada línea para alinear la siguiente.

---

## 🛠️ Especificaciones Técnicas (ABI)

Ambas librerías comparten la misma Interfaz Binaria de Aplicación y requieren 6 argumentos pasados por registros:

| Registro | Descripción | Formato Esperado |
| :--- | :--- | :--- |
| **RDI** | Puntero a estructura `ScreenInfo` | Memoria (Mapeada por `fb_core`/`fb_map`) |
| **ESI** | Coordenada X (Origen Top-Left) | Entero 32-bits (Con signo en Capa 1) |
| **EDX** | Coordenada Y (Origen Top-Left) | Entero 32-bits (Con signo en Capa 1) |
| **ECX** | Ancho (`Width`) | Entero 32-bits (Positivo) |
| **R8D** | Alto (`Height`) | Entero 32-bits (Positivo) |
| **R9D** | Color Empaquetado | 32-bits (**Obligatorio:** Previamente procesado por `lib_color_pack`) |

**Dependencias:**
* Requiere `%include "lib/graph/core/lib_fb_core.inc"`.

---

## 💻 Ejemplos de Uso (NASM)

### Llamada Segura desde Aplicación (Capa 1)

```nasm
extern lib_draw_rectcval
extern lib_color_pack

; Asumiendo que 'datos_fb' ya está inicializado y mapeado

; 1. Empaquetar el color (Rojo estándar a nativo)
mov rdi, datos_fb
mov esi, 0xFF0000       
call lib_color_pack     
mov r9d, eax            ; Color listo en R9D

; 2. Preparar dimensiones y dibujar
; (Intencionalmente fuera de los límites por la izquierda)
mov rdi, datos_fb
mov esi, -50            ; X = -50 (La capa 1 lo ajustará a 0)
mov edx, 100            ; Y = 100
mov ecx, 200            ; W = 200 (La capa 1 lo recortará a 150)
mov r8d, 50             ; H = 50

call lib_draw_rectcval  ; Dibuja el bloque visible de 150x50