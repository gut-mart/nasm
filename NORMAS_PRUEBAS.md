# Normas de pruebas de comandos y librerías

Este documento define el proceso que se debe seguir cada vez que se crea o
modifica una librería o un comando. Es la referencia canónica del flujo de
trabajo. Si se pierde el contexto de la conversación, este documento explica
qué hacer y en qué orden.

---

## 1. Flujo de trabajo obligatorio

Cada vez que se crea o modifica código, se sigue este orden sin excepciones:

```
1. Librería       → crear/modificar en lib/
2. Comando        → crear/modificar en comandos/
3. Pruebas        → compilar y probar manualmente
4. Docs           → README, TODO, MANUAL_USUARIO y MANUAL_PROGRAMADOR
5. Commits        → uno por responsabilidad
6. Revisión       → ./empaquetar.sh → subir revision.txt
```

No se pasa al paso siguiente si el anterior no está completo y correcto.

---

## 2. Pruebas de compilación

### Compilación limpia

Siempre compilar desde cero tras añadir o modificar librerías en `lib/`:

```bash
make clean-all
make SRC=<ruta/al/comando.asm>
```

`make clean-all` regenera `libcore.a` con todos los archivos de `lib/`.
`make clean` (sin `-all`) solo limpia el comando actual y es suficiente
cuando no se ha tocado nada en `lib/`.

### Verificar que el binario existe

```bash
ls -la bin/<nombre>
```

Si el enlazado falla con "referencia sin definir", el archivo de librería
no está en `lib/` o no fue rastreado por git.

---

## 3. Pruebas manuales de comandos

### Prueba de ayuda

Todo comando debe responder a `-h` con exit 0 y producir salida:

```bash
./bin/<comando> -h
```

### Prueba de argumentos inválidos

Todo comando que requiere argumentos debe rechazar:

```bash
./bin/<comando>                    # sin args → exit 1
./bin/<comando> basura1 basura2    # args no numéricos → exit 1
```

### Prueba de casos normales

Cubrir al menos:
- Valor típico dentro del rango esperado.
- Valor en el límite inferior.
- Valor en el límite superior.
- Valor fuera del rango (si aplica).

### Prueba de bases numéricas

Los comandos que usan `lib_string_int32cval` aceptan múltiples bases.
Verificar al menos dos:

```bash
./bin/abs -42          # decimal con signo
./bin/abs 0xFF         # hexadecimal
./bin/clamp 5 0 0xFF   # mezcla de bases
```

### Prueba de rango inválido (solo `clamp`)

```bash
./bin/clamp 5 10 0     # LO > HI → debe dar error con exit 1
```

---

## 4. Pruebas en el Tecra M10 (hardware real)

Los comandos que usan `/dev/fb0` deben probarse en el Tecra M10.
El flujo es:

```bash
# En el equipo de desarrollo
make deploy SRC=<ruta/al/comando.asm>

# En el Tecra (por SSH o directamente)
sudo ./<comando> <args>
```

Los comandos `tools/math` no necesitan framebuffer y se pueden probar
en local. Solo los comandos de `monitor/` y `chrono/` requieren el Tecra.

---

## 5. Suite de tests automatizados

Ejecutar `make test` antes de cualquier commit que toque código:

```bash
make test
```

La suite (`tests/run_tests.sh`) comprueba:
- Estructura básica del proyecto (archivos y directorios clave).
- Compilación de todos los comandos conocidos.
- Respuesta a `-h` con exit 0 y salida no vacía.
- Rechazo de argumentos inválidos con exit ≠ 0.
- Ejecución de tests unitarios de librerías (exit code del binario).

### Añadir un comando nuevo a la suite

Cuando se crea un comando nuevo, añadir en `tests/run_tests.sh`:

```bash
# En "Compilación de los comandos"
test_command_compiles "comandos/<ruta>/<nombre>.asm"

# En "Respuesta a -h"
test_command_help "<nombre>"

# En "Validación de argumentos" (si requiere args)
test_command_rejects_no_args "<nombre>"
test_command_rejects_garbage "<nombre>" "basura1" "basura2" ...
```

### Tests unitarios de librería

Cuando se crea una librería nueva con su test unitario ejecutable:

```bash
# En "Compilación de tests unitarios"
test_command_compiles "comandos/tests/<nombre>/<nombre>.asm"

# En "Tests unitarios de librerías"
test_unit_binary "<nombre>"
```

---

## 6. Qué prueba el test unitario de una librería

El binario de test unitario (`comandos/tests/<nombre>/`) debe cubrir:

### Para capas `fast`

- Caso típico con valores positivos.
- Caso con valores negativos.
- Caso con valores iguales (si aplica).
- Caso en el límite del tipo (INT32_MIN, INT32_MAX si aplica).

### Para capas `cval`

- Mismo caso típico, verificando CF=0.
- Caso de entrada inválida, verificando CF=1 y EAX apropiado.
- Caso de INT32_MIN u otros casos especiales documentados.

### Formato de salida

```
--- <operación> (fast) ---
  OK    <descripción del caso>
  OK    <descripción del caso>
--- <operación> (cval) ---
  OK    <descripción del caso>
  FAIL  <descripción del caso>    ← si alguno falla
```

Exit 0 si todos pasan. Exit 1 si alguno falla.

---

## 7. Commits

### Un commit por responsabilidad

| Contenido | Prefijo |
|---|---|
| Librería nueva o modificada | `feat(<dominio>):` |
| Refactor de librería existente | `refactor(<dominio>):` |
| Comando nuevo | `feat(<área>):` |
| Test unitario | `test(<dominio>):` |
| Suite de tests actualizada | `test(ci):` |
| README y TODO | `docs:` |
| Fix de bug | `fix(<dominio>):` |

### Ejemplos reales del proyecto

```
feat(math): añadir lib_math_abs_int32fast y lib_math_abs_int32cval
test(math): añadir test unitario math_int32 (29 casos: fast + cval)
feat(tools): añadir comandos abs, min, max, clamp en tools/math
refactor(math): separar lib_math_int32 en fast+cval por operación
docs: actualizar README y TODO tras refactor lib/math/int32
```

### Mensajes largos

Para mensajes con cuerpo explicativo usar `git commit -F archivo` para
evitar problemas de quoting en la terminal.

---

## 8. Revisión final con revision.txt

Tras los commits, generar el archivo de revisión y subirlo:

```bash
./empaquetar.sh
```

Esto genera `revision.txt` con todos los archivos rastreados por git.
El archivo se usa para:
- Verificar que todos los archivos nuevos están rastreados.
- Revisar el estado real del proyecto en la siguiente sesión.
- Detectar inconsistencias entre lo que está en disco y lo que está en git.

Si un archivo no aparece en `revision.txt`, no está rastreado:

```bash
git status          # ver qué falta
git add <archivo>   # añadir
git commit ...      # commitear
```

---

## 9. Checklist antes de cada commit

```
[ ] make clean-all && make SRC=<ruta> → compila sin errores
[ ] ./bin/<comando> -h → exit 0, muestra ayuda
[ ] ./bin/<comando> → exit 1 si requiere args
[ ] ./bin/<comando> basura → exit 1
[ ] Casos normales funcionan correctamente
[ ] make test → todos los tests pasan
[ ] README actualizado si hay comandos/librerías nuevos
[ ] TODO actualizado (nueva entrada en Resuelto si procede)
[ ] MANUAL_USUARIO.md actualizado si hay un comando nuevo
[ ] MANUAL_PROGRAMADOR.md actualizado si hay una librería nueva
[ ] git status → no hay archivos sin rastrear que deberían estar
[ ] ./empaquetar.sh → revision.txt generado
```



