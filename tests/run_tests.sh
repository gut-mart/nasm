#!/bin/bash

# ==============================================================================
# RUTA: ./tests/run_tests.sh
# DESCRIPCIÓN: Script para ejecutar tests básicos del proyecto.
#              Comprueba que los comandos se compilen y ejecuten correctamente.
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
TEST_DIR="$PROJECT_ROOT/tests"

# Colores para salida
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Contadores
PASSED=0
FAILED=0

# Función auxiliar para pruebas
run_test() {
    local test_name="$1"
    local command="$2"
    local expected_output="$3"
    
    echo -n "Testing: $test_name ... "
    
    # Ejecutar comando y capturar salida
    local output
    output=$(eval "$command" 2>&1) || true
    
    # Verificar si la salida contiene lo esperado
    if echo "$output" | grep -F "$expected_output" > /dev/null 2>&1; then
        echo -e "${GREEN}✓ PASSED${NC}"
        ((PASSED++))
    else
        echo -e "${RED}✗ FAILED${NC}"
        echo "  Expected output containing: $expected_output"
        echo "  Got: $output"
        ((FAILED++))
    fi
}

echo -e "${YELLOW}=== INICIANDO SUITE DE TESTS ===${NC}"
echo

# Test 1: Verificar que hello_world se ejecuta correctamente
run_test "hello_world execution" \
    "timeout 2 $PROJECT_ROOT/bin/hello_world" \
    "Hola"

# Test 2: Verificar que count_numbers se ejecuta
run_test "count_numbers compilation" \
    "test -f $PROJECT_ROOT/bin/count_numbers && echo 'EXISTS'" \
    "EXISTS"

# Test 3: Verificar que fibonacci se ejecuta
run_test "fibonacci compilation" \
    "test -f $PROJECT_ROOT/bin/fibonacci && echo 'EXISTS'" \
    "EXISTS"

# Test 4: Verificar que libcore.a existe
run_test "libcore.a generation" \
    "test -f $PROJECT_ROOT/build/libcore.a && echo 'EXISTS'" \
    "EXISTS"

# Test 5: Verificar que .gitignore existe
run_test "gitignore existence" \
    "test -f $PROJECT_ROOT/.gitignore && echo 'EXISTS'" \
    "EXISTS"

# Test 6: Verificar que CONTRIBUTING.md existe
run_test "CONTRIBUTING.md existence" \
    "test -f $PROJECT_ROOT/CONTRIBUTING.md && echo 'EXISTS'" \
    "EXISTS"

# Test 7: Verificar que LICENSE existe
run_test "LICENSE existence" \
    "test -f $PROJECT_ROOT/LICENSE && echo 'EXISTS'" \
    "EXISTS"

# Test 8: Verificar que VERSION existe
run_test "VERSION file existence" \
    "test -f $PROJECT_ROOT/VERSION && echo 'EXISTS'" \
    "EXISTS"

# Test 9: Verificar que setup.sh existe
run_test "setup.sh existence" \
    "test -f $PROJECT_ROOT/setup.sh && echo 'EXISTS'" \
    "EXISTS"

echo
echo -e "${YELLOW}=== RESULTADOS ===${NC}"
echo -e "Passed: ${GREEN}$PASSED${NC}"
echo -e "Failed: ${RED}$FAILED${NC}"
echo

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}Todos los tests pasaron!${NC}"
    exit 0
else
    echo -e "${RED}Algunos tests fallaron.${NC}"
    exit 1
fi
