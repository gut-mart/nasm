

---

# 📘 Documentación: Conversión Numérica (`lib_cnv_uint32_to_str`)

**Archivo:** `lib/cnv/lib_cnv_uint32_to_str.asm`

Esta librería proporciona una función robusta y optimizada en ensamblador x86_64 para convertir números enteros de 32 bits sin signo (UInt32) a cadenas de texto ASCII (terminadas en nulo). Su característica principal es que permite **especificar cualquier base numérica** para la conversión (Decimal, Hexadecimal, Binario, Octal, etc.).

---

## ⚙️ API de la Función

### Firma

`lib_cnv_uint32_to_str`

### 📥 Entradas (Inputs)

Antes de llamar a la función con `call`, se deben configurar los siguientes registros:

| Registro | Descripción | Detalles |
| --- | --- | --- |
| **`RDI`** | **Puntero al Buffer** | Dirección de memoria donde se escribirá el resultado. **Debe tener espacio reservado suficiente**. |
| **`ESI`** | **Número (UInt32)** | El valor entero a convertir. Aunque el registro es de 64 bits, solo se procesan los 32 bits bajos. |
| **`EDX`** | **Base Numérica** | La base del sistema numérico deseado. <br>

<br>• Ejemplos: `10` (Decimal), `16` (Hex), `2` (Binario).<br>

<br>• *Nota:* Si `EDX < 2`, la función fuerza automáticamente Base 10. |

### 📤 Salidas (Outputs)

Tras la ejecución (`ret`):

| Registro | Descripción |
| --- | --- |
| **`RAX`** | Devuelve el **puntero al inicio de la cadena** (el mismo valor que se pasó en `RDI`). Útil para encadenar operaciones. |
| **Memoria** | El buffer apuntado por `RDI` contiene ahora la cadena de texto seguida de un byte `0x00`. |

---

## 🛡️ Gestión de Registros y Stack

* **Registros Preservados:** La función respeta la convención de llamada (ABI). Guarda y restaura `RBX`, `RBP`, `RSP`, `R12`, `R13`, `R14`, `R15`.
* **Registros Volátiles:** `RCX`, `RDX`, `R8`, `R9`, `R10`, `R11` pueden cambiar su valor.
* **Stack Frame:** Utiliza `RBP` para gestionar la pila de forma segura. Implementa una corrección técnica (`mov rdi, [rbp - 16]`) para recuperar el puntero del buffer sin corromper la pila durante la inversión de dígitos.

---

## 📏 Requisitos de Memoria (Buffer)

Es responsabilidad del programador reservar suficiente espacio en `RDI` para evitar desbordamientos de buffer (*buffer overflow*).

| Base | Dígitos Máximos (UInt32) | Terminador Nulo | **Tamaño Mínimo Recomendado** |
| --- | --- | --- | --- |
| **Binario (Base 2)** | 32 | +1 byte | **33 bytes** |
| **Octal (Base 8)** | 11 | +1 byte | **12 bytes** |
| **Decimal (Base 10)** | 10 | +1 byte | **11 bytes** |
| **Hexadecimal (Base 16)** | 8 | +1 byte | **9 bytes** |

---

## 🚀 Ejemplos de Uso

### 1. Conversión a Decimal (Estándar)

```nasm
section .bss
    buffer_dec resb 12

section .text
    extern lib_cnv_uint32_to_str

_imprimir_numero:
    lea rdi, [buffer_dec]   ; Destino
    mov esi, 12345          ; Número
    mov edx, 10             ; Base 10
    call lib_cnv_uint32_to_str
    
    ; Ahora [buffer_dec] contiene "12345", 0

```

### 2. Conversión a Hexadecimal (Base 16)

```nasm
section .bss
    buffer_hex resb 10

section .text
_imprimir_hex:
    lea rdi, [buffer_hex]
    mov esi, 0x1A2B
    mov edx, 16             ; Base 16
    call lib_cnv_uint32_to_str
    
    ; Resultado: "1A2B", 0

```

### 3. Conversión a Binario (Base 2)

```nasm
section .bss
    buffer_bin resb 33      ; ¡Importante reservar 33 bytes!

section .text
_imprimir_bin:
    lea rdi, [buffer_bin]
    mov esi, 5
    mov edx, 2              ; Base 2
    call lib_cnv_uint32_to_str
    
    ; Resultado: "101", 0

```

---

## 🔧 Integración en comandos

Para usar esta librería en tu proyecto NASM:

1. Asegúrate de que el archivo `lib_cnv_uint32_to_str.asm` está en tu ruta de librerías.
2. En tu archivo principal (`main.asm`):
```nasm
extern lib_cnv_uint32_to_str

```


3. Al compilar y enlazar (Makefile):
```bash
# Compilar librería
nasm -f elf64 lib/cnv/lib_cnv_uint32_to_str.asm -o lib_cnv.o

# Compilar main
nasm -f elf64 main.asm -o main.o

# Enlazar
ld -o programa main.o lib_cnv.o

```