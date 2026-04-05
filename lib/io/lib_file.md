# 📚 Documentación: Librería de Archivos (`lib_file.asm`)

**Ruta:** `lib/io/lib_file.asm`
**Arquitectura:** x86_64 (Linux)
**ABI:** System V AMD64

Esta librería proporciona funciones de bajo nivel en ensamblador para la
manipulación y gestión de archivos utilizando directamente las llamadas al
sistema (Syscalls) del Kernel de Linux.

---

## 🛠️ Funciones Disponibles

### `extract_chunk`

Extrae una porción específica de bytes (chunk) desde un archivo de origen y
la guarda directamente en un archivo de destino nuevo. Ideal para extraer
recursos gráficos, fuentes o datos incrustados en ROMs y binarios.

#### 📥 Parámetros de Entrada (Registros)

| Registro | Tipo | Descripción | Ejemplo |
| :--- | :--- | :--- | :--- |
| **`RDI`** | `Puntero (String)` | Ruta al archivo de **origen** (terminada en `0`). | `"os6128.rom", 0` |
| **`RSI`** | `Puntero (String)` | Ruta al archivo de **destino** (terminada en `0`). | `"fuente.bin", 0` |
| **`RDX`** | `Entero (64-bit)` | **Offset** (Posición de inicio en bytes). | `0x3800` |
| **`RCX`** | `Entero (64-bit)` | **Tamaño** (Cantidad de bytes a extraer). | `2048` |
| **`R8`** | `Puntero (Buffer)`| Dirección de memoria RAM temporal. | `[buffer_ram]` |

#### 📤 Valores de Retorno

| Registro | Valor | Significado |
| :--- | :--- | :--- |
| **`RAX`** | `0` | **Éxito**. Los datos se han extraído correctamente. |
| **`RAX`** | `< 0` | **Error**. Código de error negativo del Kernel de Linux. |

---

## ⚠️ Consideraciones Técnicas y Troubleshooting

Para garantizar la estabilidad del programa, ten en cuenta los siguientes
detalles sobre el funcionamiento interno de esta librería:

* **Memoria Temporal (Buffer):** La función asume que el puntero pasado en `R8`
  apunta a una zona de memoria (típicamente en `.bss` o en el Heap) que tiene
  **como mínimo** el tamaño exacto indicado en el registro `RCX`. Si el buffer
  reservado es más pequeño, el programa sufrirá un *Segmentation Fault* al
  sobrescribir memoria no asignada.

* **Cierre Automático de Archivos:** La función `extract_chunk` es "limpia" y
  autónoma. Se encarga internamente de abrir los archivos, procesarlos y
  **cerrar** los *File Descriptors* de ambos (origen y destino) mediante
  `sys_close`. No necesitas preocuparte de fugas de descriptores en tu código.

* **Strings Terminados en Cero (Null-terminated):** Asegúrate siempre de que
  las cadenas de texto con las rutas de los archivos pasadas en `RDI` y `RSI`
  terminen obligatoriamente en `, 0`. Este es el formato estricto que exige
  el Kernel de Linux para interpretar correctamente las rutas.

* **Permisos de Creación:** El archivo de destino se crea automáticamente con
  los permisos octales `0644` (Lectura y Escritura para el propietario, solo
  lectura para el resto de usuarios del sistema).

---

## 💻 Ejemplo de Uso

A continuación se muestra cómo integrar esta librería en tu programa principal
(`main.asm`) para extraer un bloque de datos:

```nasm
default rel

; 1. Importar la función de la librería
extern extract_chunk

section .data
    archivo_in  db "datos_completos.bin", 0
    archivo_out db "sprite_extraido.bin", 0

section .bss
    ; 2. Reservar memoria para el tamaño exacto de la extracción
    buffer_ram resb 1024 

section .text
    global _start

_start:
    ; 3. Cargar los 5 parámetros (ABI de Linux 64-bits)
    lea rdi, [archivo_in]     ; Parámetro 1: Origen
    lea rsi, [archivo_out]    ; Parámetro 2: Destino
    mov rdx, 500              ; Parámetro 3: Empezar a leer en el byte 500
    mov rcx, 1024             ; Parámetro 4: Extraer 1024 bytes en total
    lea r8,  [buffer_ram]     ; Parámetro 5: Pasar el buffer temporal de RAM

    ; 4. Llamar a la librería
    call extract_chunk

    ; 5. Comprobar errores
    cmp rax, 0
    jl .error_extraccion

.exito:
    ; ... Continuar con el programa si todo salió bien ...
    jmp .salir

.error_extraccion:
    ; ... Manejar el error ...

.salir:
    mov rax, 60               ; sys_exit
    xor rdi, rdi              ; Código de salida 0
    syscall