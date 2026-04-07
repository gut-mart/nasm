#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
DIR_TO_WATCH="$SCRIPT_DIR/comandos"

mkdir -p "$DIR_TO_WATCH"

if ! command -v inotifywait &> /dev/null; then
    echo "❌ Error: 'inotifywait' no está instalado."
    exit 1
fi

# --- 1. FUNCIÓN MAESTRA: Generar o actualizar Makefile ---
generar_makefile() {
    local NUEVO_ARCHIVO="$1"
    local CARPETA_PROYECTO="$(dirname "$NUEVO_ARCHIVO")"
    local NOMBRE_ASM="$(basename "$NUEVO_ARCHIVO")"
    local NOMBRE_BASE="${NOMBRE_ASM%.asm}"
    
    local REL_PATH="${CARPETA_PROYECTO#$SCRIPT_DIR/}"
    local REL_ROOT="$(realpath --relative-to="$CARPETA_PROYECTO" "$SCRIPT_DIR")"
    local ARCHIVO_MAKE="$CARPETA_PROYECTO/Makefile"

    local ACTUALIZAR=false
    
    # Comprobar si existe y es correcto
    if [ -f "$ARCHIVO_MAKE" ]; then
        if ! grep -q "PROJECT_SRC = $REL_PATH/$NOMBRE_ASM" "$ARCHIVO_MAKE"; then
            echo "🔄 Detectado cambio de nombre: $NOMBRE_ASM. Actualizando Makefile..."
            ACTUALIZAR=true
        fi
    else
        echo "⚙️  Creando nuevo Makefile para $NOMBRE_BASE..."
        ACTUALIZAR=true
    fi

    # Sobrescribir si es necesario
    if [ "$ACTUALIZAR" = true ]; then
        cat << EOF > "$ARCHIVO_MAKE"
ROOT_DIR = $REL_ROOT
PROJECT_SRC = $REL_PATH/$NOMBRE_ASM
EXEC_NAME = $NOMBRE_BASE

all:
	@\$(MAKE) --no-print-directory -C \$(ROOT_DIR) SRC=\$(PROJECT_SRC)

clean:
	@\$(MAKE) --no-print-directory -C \$(ROOT_DIR) clean

run: all
	@echo "--- EJECUTANDO ---"
	@\$(ROOT_DIR)/bin/\$(EXEC_NAME)
EOF
        echo "✅ Makefile sincronizado en $REL_PATH"
    fi
}

# --- 2. FASE DE ARRANQUE (BOOTSTRAP) ---
# Al encender el ordenador o tras hacer un git pull, 
# reparamos cualquier Makefile que falte en los .asm existentes.
echo "🔍 Verificando Makefiles en comandos existentes..."
find "$DIR_TO_WATCH" -type f -name "*.asm" | while read -r ARCHIVO; do
    generar_makefile "$ARCHIVO"
done

# --- 3. FASE DE MONITORIZACIÓN EN TIEMPO REAL ---
echo "👀 Monitorizando '$DIR_TO_WATCH' para nuevos cambios..." 
inotifywait -m -r -e create -e moved_to -e close_write --format '%w%f' "$DIR_TO_WATCH" | while read NUEVO_ARCHIVO
do
    if [[ "$NUEVO_ARCHIVO" == *.asm ]]; then
        generar_makefile "$NUEVO_ARCHIVO"
    fi
done