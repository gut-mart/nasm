# 🖥️ Documentación: Obtención de Datos del Framebuffer (`lib_graph_get_info_screen.asm`)

**Ruta:** `lib/graph/info_screen/lib_graph_get_info_screen.asm`  
**Arquitectura:** x86_64 (Linux)  
**ABI:** System V AMD64  
**Dependencias:** `lib_graph_get_info_screen.inc` (Define la estructura `ScreenInfo`)

Esta librería se encarga de consultar directamente al Kernel de Linux a través del
dispositivo `/dev/fb0` para obtener la información técnica del monitor o pantalla
en uso (resolución, profundidad de color, dimensiones físicas, etc.).

---

## 🛠️ Función Disponible

### `lib_graph_get_info_screen`

Abre el Framebuffer, ejecuta una llamada `sys_ioctl` (`FBIOGET_VSCREENINFO`) y
extrae los datos clave para guardarlos en la estructura `ScreenInfo` proporcionada
por el usuario.

#### 📥 Parámetros de Entrada (Registros)

| Registro | Tipo | Descripción |
| :--- | :--- | :--- |
| **`RDI`** | `Puntero (struc ScreenInfo)` | Puntero a un bloque de memoria de 24 bytes donde se guardarán los resultados. |

#### 📤 Valores de Retorno

| Registro | Valor | Significado |
| :--- | :--- | :--- |
| **`RAX`** | `0` | **Éxito**. Los datos se han guardado en la estructura. |
| **`RAX`** | `-1` | **Error**. No se pudo abrir `/dev/fb0` o falló el `ioctl`. |

---

## 🏗️ La Estructura `ScreenInfo`

Para que la función devuelva los datos correctamente, tu programa principal debe
reservar 24 bytes en la sección `.bss` usando la estructura definida en el archivo
`lib_graph_get_info_screen.inc`.

| Offset | Propiedad | Tamaño | Descripción |
| :---: | :--- | :---: | :--- |
| `0` | `.width` | 4 bytes | Ancho de la pantalla en **píxeles** (px). |
| `4` | `.height` | 4 bytes | Alto de la pantalla en **píxeles** (px). |
| `8` | `.bpp` | 4 bytes | Profundidad de color en **bits** (ej. 32 para RGBA). |
| `12` | `.pitch` | 4 bytes | Bytes por línea (*LineLength*). Útil para salto de línea. |
| `16` | `.phy_width` | 4 bytes | Ancho **físico** de la pantalla en milímetros (mm). |
| `20` | `.phy_height`| 4 bytes | Alto **físico** de la pantalla en milímetros (mm). |

---

## ⚠️ Consideraciones Técnicas y Troubleshooting

Para garantizar la estabilidad del programa, ten en cuenta los siguientes
detalles sobre el funcionamiento interno de esta librería:

* **Permisos de Linux (`/dev/fb0`):** Si la función te devuelve consistentemente
  `-1`, lo más probable es un problema de permisos. El usuario que ejecuta el
  binario debe tener permisos de lectura/escritura sobre el dispositivo
  Framebuffer. Normalmente, esto se soluciona añadiendo al usuario al grupo
  `video` o ejecutando el programa con `sudo`.

* **Gestión de Memoria y Buffer Interno:** El Kernel de Linux devuelve una
  estructura gigante (`fb_var_screeninfo`) de 160 bytes al hacer el `ioctl`.
  Para no contaminar la memoria del usuario, nuestra librería reserva
  internamente 160 bytes en el stack (pila) temporalmente. Asegúrate de que
  el registro `RSP` esté correctamente alineado y tenga espacio suficiente
  al hacer el `call` (esto está garantizado en el flujo normal de ejecución).

* **Cálculo Matemático del Pitch:** La propiedad `.pitch` no la proporciona
  directamente esta llamada específica del Kernel, sino que nuestra librería
  la calcula matemáticamente en tiempo de ejecución usando la fórmula:
  `width * (bpp / 8)`. Esto se hace por conveniencia del desarrollador, para
  que no tengas que calcular los saltos de memoria manualmente al dibujar
  gráficos.

---

## 💻 Ejemplo de Uso

A continuación se muestra cómo integrar esta librería en tu programa principal
(`main.asm`) para leer el ancho de la pantalla:

```nasm
default rel

; 1. Importar la estructura y la función
%include "lib/graph/info_screen/lib_graph_get_info_screen.inc"
extern lib_graph_get_info_screen

section .bss
    ; 2. Reservar la memoria para la estructura (24 bytes)
    mi_pantalla resb ScreenInfo_size 

section .text
    global _start

_start:
    ; 3. Pasar el puntero de la estructura por RDI
    lea rdi, [mi_pantalla]
    call lib_graph_get_info_screen

    ; 4. Comprobar si hubo errores
    cmp rax, 0
    jl .hubo_error

    ; 5. ¡Éxito! Ahora puedes acceder a los datos:
    ; (Por ejemplo, mover el ancho en píxeles a EAX)
    mov eax, dword [mi_pantalla + ScreenInfo.width]
    
    ; ... Continuar con el programa ...

.hubo_error:
    ; ... Manejar el error ...