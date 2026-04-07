# 🔢 Librería de Conversión: String a Int32 (Multi-Base)

Este módulo convierte cadenas de texto ASCII terminadas en nulo (`\0`) a números enteros de 32 bits (`int32`). Destaca por su capacidad para detectar automáticamente la base numérica basándose en prefijos estándar, permitiendo al usuario o programador introducir datos de forma natural.

Siguiendo la **Arquitectura de Dos Capas** del framework, la funcionalidad está separada en una barrera de validación estricta y un núcleo de procesamiento ultrarrápido.

## 🔠 Formatos Soportados

El motor detecta los siguientes prefijos (sensibles a mayúsculas y minúsculas) y ajusta la base matemática en tiempo real:

* **Decimal (Base 10):** Sin prefijo o `0d` / `0D` (Ej: `1024`, `0d255`)
* **Hexadecimal (Base 16):** `0x` o `0X` (Ej: `0xFF0000`, `0x1a`)
* **Binario (Base 2):** `0b` o `0B` (Ej: `0b11110000`)
* **Octal (Base 8):** `0o` o `0O` (Ej: `0o777`)

---

## 🏗️ Filosofía de Diseño

1. **Capa 1: El Escudo (`lib_string_int32cval.asm`)**
   * **Propósito:** Proteger la ejecución contra datos basura, errores tipográficos o inyecciones inválidas.
   * **Comportamiento:** Escanea la memoria carácter por carácter. Verifica que la cadena no esté vacía, aísla el prefijo y asegura matemáticamente que los siguientes caracteres pertenezcan exclusivamente a esa base (por ejemplo, aborta si encuentra un '2' en un formato binario o una 'G' en un hexadecimal). Si encuentra un error, retorna `0`. Si la validación es exitosa, restaura la pila y realiza un *Tail Call* (`jmp`) a la Capa 2.
   * **Cuándo usar:** Siempre que los datos provengan del exterior (argumentos de CLI `argv`, lectura desde teclado vía STDIN, o lectura de archivos de configuración).

2. **Capa 2: El Motor (`lib_string_int32fast.asm`)**
   * **Propósito:** Rendimiento extremo.
   * **Comportamiento:** Asume que la cadena es matemática y sintácticamente perfecta. Elimina las lentas instrucciones de multiplicación (`imul`). En su lugar, utiliza operaciones de desplazamiento de bits (*Bitwise Shifts*) que se ejecutan en un solo ciclo de CPU: `shl 4` para base 16, `shl 1` para base 2, y `shl 3` para base 8. Para decimales, usa trucos aritméticos con la instrucción `lea`.
   * **Cuándo usar:** Cuando el código interno deba procesar rápidamente arrays o buffers de memoria de cuyo contenido se tiene un control y certeza absolutos.

---

## 🛠️ Especificaciones Técnicas (ABI)

Ambas capas utilizan la misma convención de registros:

| Registro | Descripción | Formato Esperado |
| :--- | :--- | :--- |
| **RDI (Entrada)** | Puntero a la cadena ASCII | Cadena de caracteres terminada en nulo (`0x00`) |
| **EAX (Salida)** | Resultado de la conversión | Entero de 32-bits (`0` en caso de error en la Capa 1) |

> **Aviso de Rendimiento (Capa 2):** La rutina rápida hace uso de la instrucción `movzx ecx, byte [rdi]` para garantizar que la mitad superior de los registros quede limpia de basura residual (como los caracteres de los prefijos 'x', 'b', etc.), evitando la corrupción de datos en operaciones aritméticas.

---

## 💻 Ejemplos de Uso (NASM)

### Ejemplo 1: Entrada del Usuario (Capa 1 - Segura)

```nasm
extern lib_string_int32cval

section .data
    input_usuario db "0xFF00", 0   ; Podría venir de sys_read (argv)
    input_malo    db "0xFG00", 0   ; Contiene una letra inválida ('G')

section .text
    mov rdi, input_usuario
    call lib_string_int32cval      ; EAX = 65280
    
    mov rdi, input_malo
    call lib_string_int32cval      ; La Capa 1 detecta la 'G', aborta y EAX = 0