
# 📘 Documentación: Librería de Conversión Entero a Cadena (`lib_cnv_uint32_to_str`)

Esta librería convierte un número entero de 32 bits sin signo (UInt32) en su representación de cadena de caracteres (ASCII) decimal, terminada en nulo. Es esencial para imprimir valores numéricos en pantalla o consola.

---

## 🔌 Especificación de Interfaz de Datos (I/O)

La función principal es `lib_cnv_uint32_to_str`. A continuación se detallan los requisitos exactos de entrada y el estado de salida.

### 1. Entrada de Datos (Input)

La función espera recibir **dos argumentos** en los registros `RDI` y `RSI` antes de ser llamada.

#### Registro 1: `RDI` (El Número)

* **Tipo:** Entero de 32 bits sin signo (UInt32).
* **Descripción:** El valor numérico que deseas convertir a texto.
* **Rango:** `0` a `4,294,967,295` (0xFFFFFFFF).
* **Nota:** Aunque el registro es de 64 bits, solo se consideran los 32 bits inferiores (`EDI`).

#### Registro 2: `RSI` (El Buffer)

* **Tipo:** Puntero (Dirección de memoria de 64 bits).
* **Descripción:** Dirección de memoria donde la función escribirá los caracteres ASCII resultantes.
* **Requisito de Memoria:** El buffer apuntado debe tener **al menos 11 bytes** de espacio reservado (10 dígitos máximos para un UInt32 + 1 byte para el terminador nulo).

---

### 2. Salida de Datos (Output)

La función no devuelve valores en registros (como `RAX`), sino que su "salida" es la modificación de la memoria apuntada por `RSI`.

#### A. Modificación de Memoria (Buffer ASCII)

La función escribe en la dirección `[RSI]` la cadena de texto que representa el número.

* **Formato:** ASCII decimal.
* **Terminación:** Agrega un byte `0x00` (NULL) al final de la cadena.
* **Longitud:** Variable (depende del número).
* Si `RDI` = 0 -> Escribe `"0"` + `0x00` (2 bytes).
* Si `RDI` = 123 -> Escribe `"123"` + `0x00` (4 bytes).
* Si `RDI` = 4294967295 -> Escribe `"4294967295"` + `0x00` (11 bytes).



#### B. Registros Modificados (Volátiles)

Es crucial saber qué registros cambian tras la llamada:

* **Destruidos (No confiar en su valor):** `RAX`, `RCX`, `RDX`.
* `RAX`: Usado para la división.
* `RDX`: Usado para el resto (módulo).
* `RCX`: Usado como contador interno o temporal.


* **Preservados (Seguros):** `RBX`, `RBP`, `RSP`, `R12`-`R15`.

---

### 3. Diagrama de Flujo de Datos

```text
       ENTRADAS                                SALIDA (Memoria en RSI)
    +-----------------+                     +---------------------------+
    | RDI = 7680      |                     | Byte 0: '7' (0x37)        |
    | (Número entero) |   ------------->    | Byte 1: '6' (0x36)        |
    +-----------------+      FUNCIÓN        | Byte 2: '8' (0x38)        |
                                            | Byte 3: '0' (0x30)        |
    +-----------------+                     | Byte 4: 0   (0x00) NULL   |
    | RSI = 0x402000  |                     +---------------------------+
    | (Puntero Buffer)|
    +-----------------+

```

---

### 4. Ejemplo de Implementación

```nasm
section .bss
    buffer_texto resb 32  ; Reservamos espacio suficiente

section .text
    extern lib_cnv_uint32_to_str

_start:
    ; 1. Cargar el número a convertir
    mov edi, 7680         ; Entrada 1: El número

    ; 2. Cargar la dirección del buffer destino
    lea rsi, [buffer_texto] ; Entrada 2: El puntero

    ; 3. Llamar a la librería
    call lib_cnv_uint32_to_str

    ; AHORA: [buffer_texto] contiene "7680", 0

