# Manual de usuario

Guía de todos los comandos del proyecto para el usuario final. Cada comando se
ejecuta desde la terminal y acepta `-h` para ver su ayuda integrada.

> **Mantenimiento:** este manual debe actualizarse cada vez que se crea un
> comando nuevo. Añade una sección siguiendo el formato de las existentes.
> Ver `NORMAS_PRUEBAS.md` para el flujo completo.

---

## Formatos numéricos

Todos los comandos que aceptan números admiten cuatro bases. Puedes mezclarlas
libremente en un mismo comando.

| Base | Prefijo | Ejemplo | Valor |
|---|---|---|---|
| Decimal | (ninguno) | `-42` | -42 |
| Hexadecimal | `0x` | `0xFF` | 255 |
| Binario | `0b` | `0b1010` | 10 |
| Octal | `0o` | `0o17` | 15 |

---

## Amplitud: el dominio de los enteros de 32 bits

Todos los comandos matemáticos trabajan con **enteros con signo de 32 bits**.
Esto define un rango fijo de valores representables:

```
mínimo:  -2147483648   (INT32_MIN)
máximo:  +2147483647   (INT32_MAX)
```

El rango **no es simétrico**: hay un número negativo más que positivos. Esta
asimetría del complemento a dos es la causa de varios casos límite:

- `abs(-2147483648)` no puede dar +2147483648 (no existe en int32). Devuelve
  el propio -2147483648 y avisa.
- `div(-2147483648, -1)` daría +2147483648, que no cabe. Es error.
- `pow(2, 31)` = 2147483648, que se pasa del máximo por 1. Es error.

**Regla general del proyecto:** cuando el resultado correcto de una operación
no cabe en el rango de int32, el comando lo comunica como error en lugar de
devolver un valor incorrecto. Nunca verás un número "inventado".

---

## Comandos de framebuffer

Requieren acceso a `/dev/fb0` (con `sudo` o perteneciendo al grupo `video`) y
una TTY sin entorno gráfico.

### fb_core

Muestra el diagnóstico del framebuffer: resolución, profundidad de color y
offsets de cada canal.

```bash
sudo ./bin/fb_core          # diagnóstico completo
./bin/fb_core -p            # formato parseable CLAVE=VALOR
./bin/fb_core -h            # ayuda
```

### draw_pixel

Dibuja un píxel en la posición (X, Y) del color indicado.

```bash
sudo ./bin/draw_pixel 960 540 0xFF0000    # píxel rojo en el centro
```

### draw_rect

Dibuja un rectángulo sólido. Recorta automáticamente la parte que se salga de
la pantalla (clipping), así que acepta coordenadas negativas.

```bash
sudo ./bin/draw_rect 0 0 1920 1080 0xFF0000     # pantalla completa en rojo
sudo ./bin/draw_rect -50 -50 200 200 0x00FF00   # recortado en la esquina
```

### draw_line

Dibuja una línea entre dos puntos. Recorta las partes fuera de pantalla.

```bash
sudo ./bin/draw_line 0 0 1919 1079 0xFFFFFF     # diagonal blanca
```

### draw_circle

Dibuja un círculo dado su centro y radio.

```bash
sudo ./bin/draw_circle 960 540 200 0x00FFFF     # círculo cian centrado
```

### screenshot

Captura el contenido del framebuffer y lo guarda como archivo BMP.

```bash
sudo ./bin/screenshot captura /home/isidro     # genera /home/isidro/captura.bmp
```

---

## Comandos de medición

### bench_rect

Mide cuántos ciclos de CPU tarda en pintarse un rectángulo de pantalla completa.
Útil para evaluar el rendimiento del hardware.

```bash
sudo ./bin/bench_rect
# Salida:
#   Metodo:     RDTSC
#   Resolucion: 1280x800
#   Ticks:      3494920
```

---

## Comandos matemáticos (tools/math)

Calculadora de operaciones enteras desde la terminal. No necesitan framebuffer
ni sudo. Aceptan cualquier base numérica. El resultado debe caber en int32; si
no, el comando devuelve error.

### abs — valor absoluto

```bash
./bin/abs -42         # → 42
./bin/abs 0xFF        # → 255
./bin/abs -2147483648 # → -2147483648 + aviso de overflow (caso límite)
```

**Dominio:** cualquier int32. **Rango:** 0 a 2147483647, salvo el caso especial
de INT32_MIN que se devuelve sin cambios con un aviso.

### min / max — menor y mayor de dos valores

```bash
./bin/min 3 7         # → 3
./bin/min -5 -2       # → -5  (en números con signo, -5 < -2)
./bin/max 3 7         # → 7
./bin/max -5 -2       # → -2
```

**Dominio:** cualquier par de int32. **Rango:** siempre válido, nunca dan error.

### clamp — limitar a un rango

Limita un valor al rango cerrado [LO, HI].

```bash
./bin/clamp 5 0 10    # → 5   (dentro del rango)
./bin/clamp -3 0 10   # → 0   (por debajo → LO)
./bin/clamp 15 0 10   # → 10  (por encima → HI)
./bin/clamp 7 7 7     # → 7   (rango de un solo punto, válido)
./bin/clamp 5 10 0    # → Error: rango invalido (LO > HI)
```

**Caso de error:** si LO > HI el rango es imposible y el comando lo rechaza.

### div — división entera

Divide y trunca hacia cero (igual que en C).

```bash
./bin/div 10 2        # → 5
./bin/div -7 2        # → -3  (trunca hacia cero, no hacia -4)
./bin/div 7 -2        # → -3
```

**Casos de error:**

```bash
./bin/div 5 0              # → Error: division por cero
./bin/div -2147483648 -1  # → Error: overflow (el resultado no cabe)
```

### mod — resto de la división

El resto toma el signo del dividendo (el primer número), igual que en C.

```bash
./bin/mod 10 3        # → 1
./bin/mod -7 2        # → -1  (signo del dividendo)
./bin/mod 7 -2        # → 1
```

Se cumple siempre la relación `a = (a div b) * b + (a mod b)`.

**Casos de error:** los mismos que `div` (divisor cero, overflow INT32_MIN/-1).

### pow — potencia entera

Eleva una base a un exponente.

```bash
./bin/pow 2 10        # → 1024
./bin/pow -2 3        # → -8   (base negativa, exponente impar)
./bin/pow -2 4        # → 16   (exponente par)
./bin/pow 5 0         # → 1    (cualquier base elevada a 0)
```

**Dominio del exponente:** debe ser **mayor o igual que 0**. Un exponente
negativo daría una fracción (ej. `7^-2 = 1/49`), que no es un entero, así que
es error:

```bash
./bin/pow 7 -2        # → Error: no representable en int32
```

**Límite de overflow:** el resultado debe caber en int32.

```bash
./bin/pow 2 30        # → 1073741824  (cabe justo)
./bin/pow 2 31        # → Error: overflow (2147483648 se pasa por 1)
```

---

## Códigos de salida

Todos los comandos siguen la misma convención:

| Exit code | Significado |
|---|---|
| 0 | Éxito. El resultado se imprimió correctamente. |
| 1 | Error: argumentos inválidos, número mal formado, o resultado no representable. |

Esto permite encadenar comandos en scripts de bash y comprobar `$?` para
detectar fallos.
