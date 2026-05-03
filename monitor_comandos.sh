#!/bin/bash
# ==============================================================================
# RUTA: ./monitor_comandos.sh
# DESCRIPCIÓN: Genera Makefiles delegadores en las carpetas de comandos
#              y opcionalmente monitoriza cambios en .asm para mantenerlos
#              sincronizados.
#
# MODOS DE USO:
#   ./monitor_comandos.sh              Bootstrap + watcher (default)
#   ./monitor_comandos.sh --bootstrap  Solo regenera Makefiles y termina
#   ./monitor_comandos.sh --watch      Solo arranca el watcher (sin bootstrap)
#   ./monitor_comandos.sh --help       Muestra esta ayuda
#
# El modo --bootstrap es el que usa setup.sh para garantizar que tras la
# instalación los Makefiles delegadores existan, sin necesidad de tener
# el watcher corriendo en background.
# ==============================================================================

set -e

# --- Resolver el directorio del script (ruta absoluta) ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DIR_TO_WATCH="$SCRIPT_DIR/comandos"

# ==============================================================================
# FUNCIÓN: generar_makefile
# Genera (o regenera) un Makefile delegador en la carpeta de un .asm.
# Solo escribe el archivo si no existe o si el contenido difiere.
# ==============================================================================
generar_makefile() {
    local ARCHIVO_ASM="$1"
    local DIR_COMANDO
    local NOMBRE_BASE
    local RUTA_RELATIVA
    local MAKEFILE_PATH

    DIR_COMANDO="$(dirname "$ARCHIVO_ASM")"
    NOMBRE_BASE="$(basename "$ARCHIVO_ASM" .asm)"

    # Calcular profundidad relativa para construir ROOT_DIR (../../..)
    RUTA_RELATIVA="${DIR_COMANDO#$SCRIPT_DIR/}"
    local DEPTH
    DEPTH=$(echo "$RUTA_RELATIVA" | tr -cd '/' | wc -c)
    DEPTH=$((DEPTH + 1))
    local ROOT_DIR
    ROOT_DIR=$(printf '..'; for ((i=1; i<DEPTH; i++)); do printf '/..'; done)

    MAKEFILE_PATH="$DIR_COMANDO/Makefile"

    # Generar contenido del Makefile delegador
    local NUEVO_CONTENIDO
    NUEVO_CONTENIDO="ROOT_DIR = $ROOT_DIR
PROJECT_SRC = $RUTA_RELATIVA/$NOMBRE_BASE.asm
EXEC_NAME = $NOMBRE_BASE

all:
	@\$(MAKE) --no-print-directory -C \$(ROOT_DIR) SRC=\$(PROJECT_SRC)

clean:
	@\$(MAKE) --no-print-directory -C \$(ROOT_DIR) SRC=\$(PROJECT_SRC) clean

run: all
	@echo \"--- EJECUTANDO ---\"
	@\$(ROOT_DIR)/bin/\$(EXEC_NAME)
"

    # Solo escribir si no existe o el contenido difiere
    if [ ! -f "$MAKEFILE_PATH" ] || [ "$(cat "$MAKEFILE_PATH")" != "$NUEVO_CONTENIDO" ]; then
        echo "$NUEVO_CONTENIDO" > "$MAKEFILE_PATH"
        echo "  ✏️  Generado: $MAKEFILE_PATH"
    fi
}

# ==============================================================================
# FUNCIÓN: fase_bootstrap
# Recorre todas las carpetas de comandos/ y regenera los Makefiles
# delegadores necesarios. Termina cuando ha procesado todos los .asm.
# ==============================================================================
fase_bootstrap() {
    echo "🔍 Fase Bootstrap: regenerando Makefiles delegadores..."

    if [ ! -d "$DIR_TO_WATCH" ]; then
        echo "  ⚠️  No existe la carpeta $DIR_TO_WATCH, nada que hacer."
        return 0
    fi

    local CONTADOR=0
    while IFS= read -r ARCHIVO; do
        generar_makefile "$ARCHIVO"
        CONTADOR=$((CONTADOR + 1))
    done < <(find "$DIR_TO_WATCH" -type f -name "*.asm")

    echo "✅ Bootstrap completado: $CONTADOR archivo(s) .asm procesado(s)."
}

# ==============================================================================
# FUNCIÓN: fase_watcher
# Monitoriza la carpeta comandos/ con inotifywait y regenera los Makefiles
# en respuesta a creaciones o modificaciones de archivos .asm.
# Bucle infinito; se detiene con Ctrl+C o killall.
# ==============================================================================
fase_watcher() {
    if ! command -v inotifywait > /dev/null 2>&1; then
        echo "❌ Error: inotifywait no está instalado."
        echo "   Instálalo con: sudo apt install inotify-tools (o el equivalente"
        echo "   de tu distro). O ejecuta este script con --bootstrap si solo"
        echo "   quieres regenerar Makefiles una vez."
        exit 1
    fi

    if [ ! -d "$DIR_TO_WATCH" ]; then
        echo "❌ Error: no existe la carpeta $DIR_TO_WATCH."
        exit 1
    fi

    echo "👀 Fase Watcher: vigilando cambios en $DIR_TO_WATCH ..."
    echo "   (Ctrl+C para detener)"

    inotifywait -m -r -e create -e modify --format '%w%f' "$DIR_TO_WATCH" \
        | while read -r ARCHIVO; do
            if [[ "$ARCHIVO" == *.asm ]]; then
                echo "📝 Detectado cambio en: $ARCHIVO"
                generar_makefile "$ARCHIVO"
            fi
        done
}

# ==============================================================================
# FUNCIÓN: mostrar_ayuda
# ==============================================================================
mostrar_ayuda() {
    cat << 'EOF'
Uso: ./monitor_comandos.sh [OPCIÓN]

Genera Makefiles delegadores en las carpetas de comandos del proyecto y
opcionalmente monitoriza cambios para mantenerlos sincronizados.

OPCIONES:
  (sin args)     Bootstrap + watcher persistente (compatibilidad)
  --bootstrap    Solo regenera Makefiles y termina
  --watch        Solo arranca el watcher (sin bootstrap previo)
  --help, -h     Muestra esta ayuda

EJEMPLOS:
  # Setup inicial: regenerar Makefiles tras git clone
  ./monitor_comandos.sh --bootstrap

  # Desarrollo activo: vigilar nuevos comandos automáticamente
  ./monitor_comandos.sh --watch

EOF
}

# ==============================================================================
# DISPATCHER PRINCIPAL
# ==============================================================================
case "${1:-}" in
    --bootstrap)
        fase_bootstrap
        ;;
    --watch)
        fase_watcher
        ;;
    --help|-h)
        mostrar_ayuda
        ;;
    "")
        # Comportamiento por defecto: bootstrap + watcher (compatibilidad)
        fase_bootstrap
        echo ""
        fase_watcher
        ;;
    *)
        echo "❌ Opción desconocida: $1"
        echo ""
        mostrar_ayuda
        exit 1
        ;;
esac