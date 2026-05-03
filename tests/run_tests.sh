#!/bin/bash
# ==============================================================================
# RUTA: ./tests/run_tests.sh
# DESCRIPCIÓN: Suite de tests smoke del proyecto NASM.
#
# Verifica que la estructura básica del proyecto está intacta, que los
# comandos compilan correctamente y que responden razonablemente a
# argumentos de línea de comandos (ayuda, errores, etc.).
#
# IMPORTANTE: Estos tests NO requieren acceso al framebuffer (/dev/fb0)
# ni privilegios de sudo. Por eso se pueden ejecutar en cualquier máquina
# con NASM y GCC instalados, incluso en entornos de integración continua
# sin entorno gráfico.
#
# Las pruebas reales sobre el framebuffer (dibujado de píxeles, color,
# clipping) deben hacerse manualmente en hardware con /dev/fb0 accesible.
#
# USO:
#   ./tests/run_tests.sh           Ejecuta todos los tests
#   bash tests/run_tests.sh        Idem (alternativa)
#   make test                      Idem (vía Makefile)
# ==============================================================================

set -u

# --- Resolver el directorio raíz del proyecto ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# --- Colores ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# --- Contadores globales ---
TOTAL=0
PASSED=0
FAILED=0
FAILED_TESTS=()

# ==============================================================================
# FUNCIÓN: assert_pass / assert_fail
# Imprime resultado de un test con formato unificado y actualiza contadores.
# ==============================================================================
assert_pass() {
    local NAME="$1"
    TOTAL=$((TOTAL + 1))
    PASSED=$((PASSED + 1))
    echo -e "  ${GREEN}OK${NC}    $NAME"
}

assert_fail() {
    local NAME="$1"
    local REASON="${2:-}"
    TOTAL=$((TOTAL + 1))
    FAILED=$((FAILED + 1))
    FAILED_TESTS+=("$NAME")
    echo -e "  ${RED}FAIL${NC}  $NAME"
    if [ -n "$REASON" ]; then
        echo -e "        ${YELLOW}↳ $REASON${NC}"
    fi
}

# ==============================================================================
# FUNCIÓN: section
# Imprime un encabezado de sección.
# ==============================================================================
section() {
    echo ""
    echo -e "${BLUE}── $1 ──${NC}"
}

# ==============================================================================
# FUNCIÓN: test_file_exists
# ==============================================================================
test_file_exists() {
    local FILE="$1"
    local DESC="existe $FILE"
    if [ -f "$PROJECT_ROOT/$FILE" ]; then
        assert_pass "$DESC"
    else
        assert_fail "$DESC" "no se encuentra el archivo"
    fi
}

# ==============================================================================
# FUNCIÓN: test_dir_exists
# ==============================================================================
test_dir_exists() {
    local DIR="$1"
    local DESC="existe directorio $DIR/"
    if [ -d "$PROJECT_ROOT/$DIR" ]; then
        assert_pass "$DESC"
    else
        assert_fail "$DESC" "directorio ausente"
    fi
}

# ==============================================================================
# FUNCIÓN: test_command_compiles
# Compila un comando y verifica que el binario aparece en bin/.
# ==============================================================================
test_command_compiles() {
    local CMD_PATH="$1"
    local CMD_NAME
    CMD_NAME="$(basename "$CMD_PATH" .asm)"
    local DESC="compila $CMD_NAME"

    local LOG_FILE
    LOG_FILE="$(mktemp)"

    if (cd "$PROJECT_ROOT" && make SRC="$CMD_PATH" > "$LOG_FILE" 2>&1); then
        if [ -x "$PROJECT_ROOT/bin/$CMD_NAME" ]; then
            assert_pass "$DESC"
        else
            assert_fail "$DESC" "make terminó OK pero bin/$CMD_NAME no existe"
        fi
    else
        local LAST_LINE
        LAST_LINE="$(tail -1 "$LOG_FILE")"
        assert_fail "$DESC" "make falló: $LAST_LINE"
    fi

    rm -f "$LOG_FILE"
}

# ==============================================================================
# FUNCIÓN: test_command_help
# Verifica que el comando responde a -h con código 0 y produce salida.
# ==============================================================================
test_command_help() {
    local CMD_NAME="$1"
    local DESC="$CMD_NAME -h muestra ayuda"
    local BIN="$PROJECT_ROOT/bin/$CMD_NAME"

    if [ ! -x "$BIN" ]; then
        assert_fail "$DESC" "binario no existe (compilación previa falló?)"
        return
    fi

    local OUTPUT
    local EXIT_CODE
    OUTPUT="$("$BIN" -h 2>&1)"
    EXIT_CODE=$?

    if [ $EXIT_CODE -ne 0 ]; then
        assert_fail "$DESC" "código de salida $EXIT_CODE (esperado 0)"
    elif [ -z "$OUTPUT" ]; then
        assert_fail "$DESC" "salida vacía"
    else
        assert_pass "$DESC"
    fi
}

# ==============================================================================
# FUNCIÓN: test_command_rejects_no_args
# Verifica que el comando devuelve código != 0 cuando se llama sin argumentos.
# ==============================================================================
test_command_rejects_no_args() {
    local CMD_NAME="$1"
    local DESC="$CMD_NAME sin args devuelve error"
    local BIN="$PROJECT_ROOT/bin/$CMD_NAME"

    if [ ! -x "$BIN" ]; then
        assert_fail "$DESC" "binario no existe"
        return
    fi

    "$BIN" > /dev/null 2>&1
    local EXIT_CODE=$?

    if [ $EXIT_CODE -ne 0 ]; then
        assert_pass "$DESC"
    else
        assert_fail "$DESC" "devolvió 0 (debería rechazar)"
    fi
}

# ==============================================================================
# FUNCIÓN: test_command_rejects_garbage
# Verifica que el comando devuelve código != 0 con argumentos sin sentido.
# ==============================================================================
test_command_rejects_garbage() {
    local CMD_NAME="$1"
    shift
    local ARGS=("$@")
    local DESC="$CMD_NAME rechaza argumentos basura"
    local BIN="$PROJECT_ROOT/bin/$CMD_NAME"

    if [ ! -x "$BIN" ]; then
        assert_fail "$DESC" "binario no existe"
        return
    fi

    "$BIN" "${ARGS[@]}" > /dev/null 2>&1
    local EXIT_CODE=$?

    if [ $EXIT_CODE -ne 0 ]; then
        assert_pass "$DESC"
    else
        assert_fail "$DESC" "devolvió 0 con args ${ARGS[*]} (debería rechazar)"
    fi
}

# ==============================================================================
# FUNCIÓN: test_make_target
# Verifica que un target de make termina con código 0 y produce salida.
# ==============================================================================
test_make_target() {
    local TARGET="$1"
    local DESC="make $TARGET funciona"

    local OUTPUT
    local EXIT_CODE
    OUTPUT="$(cd "$PROJECT_ROOT" && make "$TARGET" 2>&1)"
    EXIT_CODE=$?

    if [ $EXIT_CODE -ne 0 ]; then
        assert_fail "$DESC" "código de salida $EXIT_CODE"
    elif [ -z "$OUTPUT" ]; then
        assert_fail "$DESC" "salida vacía"
    else
        assert_pass "$DESC"
    fi
}

# ==============================================================================
# EJECUCIÓN DE TESTS
# ==============================================================================

echo ""
echo "🧪 Suite de tests smoke del proyecto NASM"
echo "   Raíz del proyecto: $PROJECT_ROOT"

# --- Sección 1: Estructura básica del proyecto ---
section "Estructura del proyecto"

test_file_exists "Makefile"
test_file_exists "README.md"
test_file_exists "LICENSE"
test_file_exists "CONTRIBUTING.md"
test_file_exists "setup.sh"
test_file_exists "config.example.mk"
test_file_exists "monitor_comandos.sh"

test_dir_exists "lib"
test_dir_exists "comandos"
test_dir_exists "tests"

# --- Sección 2: Compilación de los comandos ---
section "Compilación de los comandos"

# Limpiar antes para asegurar compilación desde cero
(cd "$PROJECT_ROOT" && make clean-all > /dev/null 2>&1 || true)

test_command_compiles "comandos/monitor/core/fb_core.asm"
test_command_compiles "comandos/monitor/draw_pixel/draw_pixel.asm"
test_command_compiles "comandos/monitor/draw_rect/draw_rect.asm"

# --- Sección 3: Comportamiento ante -h (ayuda) ---
section "Respuesta a -h (ayuda)"

test_command_help "fb_core"
test_command_help "draw_pixel"
test_command_help "draw_rect"

# --- Sección 4: Comportamiento ante argumentos inválidos ---
section "Validación de argumentos"

# fb_core no acepta argumentos posicionales (solo -h), así que sin args
# DEBE funcionar (es su modo normal). No lo testeamos con "sin args".

test_command_rejects_no_args "draw_pixel"
test_command_rejects_no_args "draw_rect"

test_command_rejects_garbage "draw_pixel" "basura1" "basura2" "basura3"
test_command_rejects_garbage "draw_rect" "basura1" "basura2" "basura3" "basura4" "basura5"

# --- Sección 5: Targets del Makefile ---
section "Targets del Makefile"

test_make_target "help"
test_make_target "info"

# ==============================================================================
# RESUMEN FINAL
# ==============================================================================
echo ""
echo "================================================================"
if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}✅ Todos los tests pasaron: $PASSED/$TOTAL${NC}"
    echo "================================================================"
    exit 0
else
    echo -e "${RED}❌ Tests fallidos: $FAILED/$TOTAL  ($PASSED OK)${NC}"
    echo ""
    echo "Tests que fallaron:"
    for T in "${FAILED_TESTS[@]}"; do
        echo "  - $T"
    done
    echo "================================================================"
    exit 1
fi
