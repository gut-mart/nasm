
# 🔌 Especificación de Interfaz de Datos (I/O)

## 1. Entrada de Datos (Input)

La función espera recibir **un solo argumento** antes de ser llamada con `call`.

### Registro Principal: `RDI`

* **Tipo:** Puntero (Dirección de memoria de 64 bits).
* **Descripción:** Debe contener la dirección de memoria de una estructura `ScreenInfo` vacía o reservada previamente.
* **Requisito de Memoria:** La dirección apuntada por `RDI` debe tener reservados **al menos 16 bytes** de espacio de escritura (`resb 16`).

### Entradas Implícitas (Entorno)

La función no recibe estos datos en registros, pero los necesita del sistema operativo para funcionar:

* **Archivo de dispositivo:** Debe existir `/dev/fb0` (el framebuffer del Kernel).
* **Permisos:** El usuario que ejecuta el programa debe tener permisos de **lectura** sobre `/dev/fb0` (generalmente requiere `sudo` o estar en el grupo `video`).

### Estado de la Memoria (Antes de la llamada)

Visualización de lo que hay en la dirección `[RDI]` antes de ejecutar:

| Offset | Tamaño | Contenido Inicial |
| --- | --- | --- |
| `+0` | 4 bytes | *Indefinido* (Basura o ceros) |
| `+4` | 4 bytes | *Indefinido* (Basura o ceros) |
| `+8` | 4 bytes | *Indefinido* (Basura o ceros) |
| `+12` | 4 bytes | *Indefinido* (Basura o ceros) |

---

## 2. Salida de Datos (Output)

La función devuelve información de dos formas: mediante el **Registro Acumulador (`RAX`)** (para control de errores) y escribiendo directamente en la **Memoria RAM** (para los datos).

### A. Valor de Retorno: `RAX`

Este registro indica si la operación tuvo éxito o fracasó.

| Valor en `RAX` | Significado | Acción recomendada |
| --- | --- | --- |
| **`0`** | **Éxito (Success)** | Proceder a leer los datos en la estructura. |
| **`-1`** | **Error (Failure)** | Detener el programa o mostrar un mensaje. Falló `open` o `ioctl`. |

### B. Modificación de Memoria (Datos Gráficos)

Si `RAX` es 0, la función habrá reescrito los 16 bytes de memoria apuntados por `RDI` con los siguientes valores enteros (Little Endian):

#### 📍 Detalle de la Estructura Escrita

**1. Ancho (`Width`)**

* **Ubicación:** `[RDI + 0]`
* **Tamaño:** 32 bits (4 bytes).
* **Dato:** Resolución horizontal en píxeles.
* *Ejemplo:* `1920` (`0x00000780`)

**2. Alto (`Height`)**

* **Ubicación:** `[RDI + 4]`
* **Tamaño:** 32 bits (4 bytes).
* **Dato:** Resolución vertical en píxeles.
* *Ejemplo:* `1080` (`0x00000438`)

**3. Profundidad (`BPP`)**

* **Ubicación:** `[RDI + 8]`
* **Tamaño:** 32 bits (4 bytes).
* **Dato:** Bits por cada píxel.
* *Ejemplo:* `32` (`0x00000020`)

**4. Paso de Línea (`Pitch` / `LineLength`) [DATO CRÍTICO]**

* **Ubicación:** `[RDI + 12]`
* **Tamaño:** 32 bits (4 bytes).
* **Dato:** Cantidad exacta de bytes que ocupa una línea horizontal en la memoria de video.
* **Origen:** Calculado matemáticamente: `Ancho * (BPP / 8)`.
* *Ejemplo:* `7680` (`0x00001E00`)

---

## 3. Resumen Gráfico del Flujo

```text
       ENTRADA (RDI)                         SALIDA (Memoria en RDI)
    +-----------------+                     +---------------------+
    | Dirección de    |                     | Offset 0:  1920     | (Ancho)
    | memoria vacía   |   ------------->    | Offset 4:  1080     | (Alto)
    | (buffer de 16B) |      FUNCIÓN        | Offset 8:  32       | (BPP)
    +-----------------+                     | Offset 12: 7680     | (Pitch)
                                            +---------------------+
                                                       ^
                                                       |
       SALIDA (RAX) -----------------------------------+
       0 = Datos válidos
      -1 = Error, ignorar memoria

```

## 4. Registros Preservados y Destruidos

Es importante saber qué registros puedes seguir usando después de llamar a la función.

* **Preservados (Seguros):** `RBX`, `RBP`, `R12`, `R13`, `R14`, `R15`. (Si tenías algo aquí antes de llamar a la función, seguirá intacto).
* **Destruidos (Volátiles):** `RAX` (contiene el retorno), `RCX`, `RDX`, `RSI`, `RDI`, `R8`, `R9`, `R10`, `R11`. (Sus valores se pierden o cambian durante la ejecución).