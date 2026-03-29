#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
DIR_TO_WATCH="$SCRIPT_DIR/comandos"

mkdir -p "$DIR_TO_WATCH"

if ! command -v inotifywait &> /dev/null; then
    echo "❌ Error: 'inotifywait' no está instalado." [cite: 211]
    exit 1
fi

echo "👀 Monitorizando '$DIR_TO_WATCH'..." 

# Añadimos 'close_write' para que detecte cuando terminas de guardar un archivo
inotifywait -m -r -e create -e moved_to -e close_write --format '%w%f' "$DIR_TO_WATCH" | while read NUEVO_ARCHIVO
do
    if [[ "$NUEVO_ARCHIVO" == *.asm ]]; then
        
        CARPETA_PROYECTO="$(dirname "$NUEVO_ARCHIVO")"
        NOMBRE_ASM="$(basename "$NUEVO_ARCHIVO")"
        NOMBRE_BASE="${NOMBRE_ASM%.asm}"
        
        REL_PATH="${CARPETA_PROYECTO#$SCRIPT_DIR/}"
        REL_ROOT="$(realpath --relative-to="$CARPETA_PROYECTO" "$SCRIPT_DIR")"
        ARCHIVO_MAKE="$CARPETA_PROYECTO/Makefile"

        # --- MEJORA: Verificación de consistencia ---
        # Si el Makefile existe pero apunta a un archivo .asm diferente, lo actualizamos.
        ACTUALIZAR=false
        if [ -f "$ARCHIVO_MAKE" ]; then
            if ! grep -q "PROJECT_SRC = $REL_PATH/$NOMBRE_ASM" "$ARCHIVO_MAKE"; then
                echo "🔄 Detectado cambio de nombre: $NOMBRE_ASM. Actualizando Makefile..."
                ACTUALIZAR=true
            fi
        else
            echo "⚙️  Creando nuevo Makefile para $NOMBRE_BASE..."
            ACTUALIZAR=true
        fi

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
            echo "✅ Makefile sincronizado." [cite: 217]
        fi
    fi
done