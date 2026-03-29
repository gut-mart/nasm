# Documentación: lib_fb_info

Esta librería proporciona una interfaz nativa y de bajo nivel en Ensamblador (x86_64) para extraer información del entorno gráfico y la terminal en sistemas Linux. Se comunica directamente con el kernel a través de llamadas al sistema (`ioctl`) sobre el dispositivo Framebuffer (`/dev/fb0`).

---

## ⚠️ REQUISITOS PREVIOS (Para usar esta librería)

Para poder utilizar `lib_fb_info.asm` en tu programa, debes cumplir **estrictamente** con estos 4 puntos:

### 1. Dependencias de Archivos (Includes)
Tu archivo principal (`.asm`) debe incluir obligatoriamente estos archivos en la cabecera:
* `%include "lib/constants.inc"`
* `%include "lib/sys_macros.inc"`
* `%include "lib/graph/info_screen/lib_fb_info.inc"`

### 2. Directivas y Enlazado
* Debes usar la directiva `default rel` en tu archivo para evitar errores de direccionamiento absoluto.
* Debes declarar la función como externa: `extern fb_info`.

### 3. Reserva de Memoria
* Es **obligatorio** reservar espacio en la sección `.bss` de tu programa usando la constante `ScreenInfo_size` proporcionada por el archivo `.inc`.

### 4. Permisos del Sistema Operativo
* La librería lee el archivo especial `/dev/fb0`. Si el usuario que ejecuta el programa no pertenece al grupo `video`, el programa **deberá ejecutarse con `sudo`**.

---

## 🏷️ Nomenclatura (Nombres libres vs. obligatorios)

Al usar esta librería en tu propio código, es crucial entender qué nombres te exige la librería y cuáles puedes elegir tú:

* 🟢 **Nombres LIBRES (Los eliges tú):** El nombre de la variable donde guardas los datos (ej. `datos_fb`, `mi_pantalla`, `buffer_video`). A la librería le da igual cómo se llame, solo necesita que le pases el puntero en el registro `RDI`.
* 🔴 **Nombres OBLIGATORIOS (Vienen de la librería):** * `ScreenInfo_size`: Debes usarlo para reservar los bytes exactos.
  * `ScreenInfo.width`, `ScreenInfo.height`, etc.: Debes usarlos para leer los datos una vez extraídos, ya que calculan el desplazamiento de memoria exacto de cada valor.

## 📦 Estructura de Datos (`ScreenInfo`)

Los datos extraídos se mapean en la memoria que hayas reservado (24 bytes). La estructura se divide así:

* **width (4 bytes):** Resolución horizontal de la pantalla en píxeles.
* **height (4 bytes):** Resolución vertical de la pantalla en píxeles.
* **bpp (4 bytes):** Profundidad de color en bits por píxel (ej. 32).
* **pad (4 bytes):** Padding de alineación (reservado/no utilizado).
* **phy_width (4 bytes):** Ancho físico real del monitor en milímetros.
* **phy_height (4 bytes):** Alto físico real del monitor en milímetros.

## 🛠️ Funciones Principales

### `fb_info`
Consulta las variables físicas y virtuales del entorno gráfico y rellena tu estructura en memoria.
* **Entrada:** `RDI` = Puntero a la memoria reservada para la estructura.
* **Salida:** `RAX` = `0` (Éxito) o `< 0` (Error, generalmente falta de permisos).

### Funciones de Terminal (Modo Texto)
* **`get_screen_size`**: Realiza la llamada `TIOCGWINSZ` y almacena las dimensiones internamente.
* **`get_screen_rows`**: Devuelve en el registro `AX` el número de filas (caracteres).
* **`get_screen_cols`**: Devuelve en el registro `AX` el número de columnas (caracteres).

## 🚀 Ejemplo de Uso Completo

El siguiente fragmento muestra cómo cumplir con todos los requisitos y extraer correctamente el ancho de la pantalla:

```nasm
%include "lib/constants.inc"
%include "lib/sys_macros.inc"
%include "lib/graph/info_screen/lib_fb_info.inc"

default rel
extern fb_info

section .bss
    ; REQUISITO: Reservar la memoria exacta usando la constante del .inc.
    ; LIBRE: El nombre 'datos_fb' lo eliges tú.
    datos_fb resb ScreenInfo_size

section .text
    global _start

_start:
    ; 1. Pasar el puntero de TU variable en RDI y llamar a la función
    mov rdi, datos_fb
    call fb_info
    
    ; 2. Comprobar si hubo errores (Ej: Falta de 'sudo')
    cmp rax, 0
    jl error_hardware

    ; 3. Extraer los datos deseados usando los desplazamientos OBLIGATORIOS
    mov eax, dword [datos_fb + ScreenInfo.width]
    
    ; [...] Tu código continúa aquí [...]

error_hardware:
    sys_exit 1