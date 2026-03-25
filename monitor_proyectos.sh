#!/bin/bash

# Detectar automáticamente el directorio raíz (donde está el script)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
DIR_TO_WATCH="$SCRIPT_DIR/proyectos"

# Crear la carpeta proyectos si no existe
mkdir -p "$DIR_TO_WATCH"

if ! command -v inotifywait &> /dev/null; then
    echo "❌ Error: 'inotifywait' no está instalado."
    echo "Instálalo ejecutando: sudo pacman -S inotify-tools"
    exit 1
fi

echo "👀 Monitorizando la carpeta '$DIR_TO_WATCH' y sus subcarpetas..."

# AÑADIDO: La bandera '-r' permite vigilar dentro de las carpetas nuevas que crees
inotifywait -m -r -e create -e moved_to --format '%w%f' "$DIR_TO_WATCH" |
while read NUEVO_ARCHIVO
do
    # CONDICIÓN AÑADIDA: Solo actuamos si el archivo creado/movido termina en "/main.asm"
    if [[ "$NUEVO_ARCHIVO" == */main.asm ]]; then
        
        # Extraemos la ruta de la carpeta donde se acaba de crear el main.asm
        CARPETA_PROYECTO="$(dirname "$NUEVO_ARCHIVO")"
        echo "📄 Archivo main.asm detectado en: $CARPETA_PROYECTO"
        
        # Calcular la ruta relativa del proyecto respecto a la raíz
        # Ejemplo: "proyectos/mi_juego"
        REL_PATH="${CARPETA_PROYECTO#$SCRIPT_DIR/}"

        ARCHIVO_MAKE="$CARPETA_PROYECTO/Makefile"
        
        # Solo creamos el Makefile si no existe ya en esa carpeta
        if [ ! -f "$ARCHIVO_MAKE" ]; then
            echo "⚙️  Generando Makefile automático..."
            
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
            echo "✅ Makefile creado con éxito."
        fi
    fi
done