#!/bin/bash

# Detectar automáticamente el directorio raíz (donde está el script)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
DIR_TO_WATCH="$SCRIPT_DIR/proyectos"

# Crear la carpeta proyectos si no existe al clonar el repo
mkdir -p "$DIR_TO_WATCH"

if ! command -v inotifywait &> /dev/null; then
    echo "❌ Error: 'inotifywait' no está instalado."
    echo "Instálalo ejecutando: sudo pacman -S inotify-tools"
    exit 1
fi

echo "👀 Monitorizando la carpeta '$DIR_TO_WATCH'..."

inotifywait -m -e create --format '%w%f' "$DIR_TO_WATCH" | while read NUEVA_CARPETA
do
    if [ -d "$NUEVA_CARPETA" ]; then
        echo "📁 Nueva carpeta detectada: $NUEVA_CARPETA"
        
        # Calcular la ruta relativa del proyecto respecto a la raíz
        # Ejemplo: "proyectos/mi_juego"
        REL_PATH="${NUEVA_CARPETA#$SCRIPT_DIR/}"

        ARCHIVO_MAKE="$NUEVA_CARPETA/Makefile"
        
        # Usamos EOF (sin comillas) para expandir SCRIPT_DIR y REL_PATH en bash,
        # pero escapamos \$ para que se escriban literalmente en el Makefile.
        cat << EOF > "$ARCHIVO_MAKE"
ROOT_DIR = $SCRIPT_DIR
PROJECT_SRC = $REL_PATH/main.asm

all:
	@\$(MAKE) --no-print-directory -C \$(ROOT_DIR) SRC=\$(PROJECT_SRC)

clean:
	@\$(MAKE) --no-print-directory -C \$(ROOT_DIR) clean

run: all
	@echo "--- EJECUTANDO ---"
	@\$(ROOT_DIR)/bin/main
EOF
        
        ARCHIVO_MAIN="$NUEVA_CARPETA/main.asm"
        cat << 'EOF' > "$ARCHIVO_MAIN"

EOF
    fi
done