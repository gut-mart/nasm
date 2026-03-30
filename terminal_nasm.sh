#!/bin/bash

# Configuración de rutas
ROOT_PROJECT="/home/isidro/Datos/nasm"
DIR_COMANDOS="$ROOT_PROJECT/comandos"
UMBRAL_SEGUNDOS=3600 # 1 hora (3600 segundos) de "memoria"

# 1. Obtener la fecha actual en segundos
AHORA=$(date +%s)

# 2. Buscar el elemento más reciente dentro de comandos
# %T@ da la fecha de modificación en segundos
ULTIMO_HIT=$(find "$DIR_COMANDOS" -mindepth 1 -printf '%T@ %p\n' 2>/dev/null | sort -n | tail -1)

# Si no hay nada en comandos, ir a la raíz directamente
if [ -z "$ULTIMO_HIT" ]; then
    xfce4-terminal --working-directory="$ROOT_PROJECT" &
    exit 0
fi

# 3. Extraer fecha y ruta
FECHA_HIT=$(echo "$ULTIMO_HIT" | cut -d' ' -f1 | cut -d'.' -f1)
RUTA_HIT=$(echo "$ULTIMO_HIT" | cut -d' ' -f2-)

# 4. Calcular diferencia de tiempo
DIFERENCIA=$((AHORA - FECHA_HIT))

# 5. Lógica de decisión
if [ $DIFERENCIA -lt $UMBRAL_SEGUNDOS ]; then
    # Si es un archivo, vamos a su carpeta; si es carpeta, vamos directo
    [ -f "$RUTA_HIT" ] && FINAL_DIR=$(dirname "$RUTA_HIT") || FINAL_DIR="$RUTA_HIT"
    echo "🎯 Actividad reciente detectada en: $FINAL_DIR"
else
    # Si ha pasado mucho tiempo, volvemos a la raíz
    FINAL_DIR="$ROOT_PROJECT"
    echo "🏠 Sesión antigua. Volviendo a la raíz del proyecto."
fi

# 6. Lanzar terminal
xfce4-terminal --working-directory="$FINAL_DIR" &