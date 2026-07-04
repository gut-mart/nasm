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

### Rangos aceptados según la base

El número debe caber en 32 bits; si no cabe, el comando devuelve error en vez
de truncarlo. Las reglas exactas dependen de cómo se escribe:

- **Decimal sin signo** — de `0` a `2147483647` (INT32_MAX). Un decimal se
  interpreta como cantidad con signo: `4294967295` es error, no -1.
- **Hex, binario u octal sin signo** — hasta `0xFFFFFFFF`. Las bases con
  prefijo son **patrones de bits** de 32 bits (útiles para colores y
  máscaras), y se interpretan como int32: `0xFFFFFFFF` equivale a -1.
- **Con signo `-` (cualquier base)** — magnitud hasta `2147483648`
  (\|INT32_MIN\|): `-2147483648` es válido, `-2147483649` es error.

Los ceros a la izquierda no cuentan para el rango: `0x00000000FF` vale 255.

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

> **Nota:** para usar `sudo` sin especificar la ruta completa, el PATH de sudo
> debe incluir `~/bin`. Ver `install-setup` en el Makefile.

### fb_core

Muestra el diagnóstico del framebuffer: resolución, profundidad de color y
offsets de cada canal.

```bash
sudo ./bin/fb_core          # diagnóstico completo
./bin/fb_core -p            # formato parseable CLAVE=VALOR
./bin/fb_core -h            # ayuda
```

### draw_pixel

Dibuja un píxel en la posición (X, Y) del color indicado. Acepta coordenadas
fuera de pantalla — si el píxel queda fuera simplemente se ignora (exit 0).

```bash
sudo ~/bin/draw_pixel 960 540 0xFF0000    # píxel rojo en el centro
sudo ~/bin/draw_pixel -10 -10 0xFF0000   # fuera de pantalla, ignorado
```

### draw_rect

Dibuja un rectángulo sólido. Recorta automáticamente (clipping) la parte que
quede fuera de pantalla. Si queda totalmente fuera, se ignora (exit 0).

```bash
sudo ~/bin/draw_rect 0 0 1280 800 0xFF0000      # pantalla completa en rojo
sudo ~/bin/draw_rect -50 -50 200 200 0x00FF00   # recortado en la esquina
```

### draw_line

Dibuja una línea entre dos puntos con clipping Cohen-Sutherland. Si queda
totalmente fuera de pantalla, se ignora (exit 0).

```bash
sudo ~/bin/draw_line 0 0 1279 799 0xFFFFFF       # diagonal blanca
sudo ~/bin/draw_line -100 -100 500 500 0xFF0000  # recortada en la esquina
```

### draw_circle

Dibuja un círculo dado su centro y radio con clipping. El centro puede estar
fuera de pantalla. Si queda totalmente fuera, se ignora (exit 0).

```bash
sudo ~/bin/draw_circle 640 400 200 0x00FFFF   # círculo cian centrado
sudo ~/bin/draw_circle 0 0 300 0xFF0000       # recortado en la esquina
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



