#!/bin/bash

DIR_COMANDOS="/home/isidro/Datos/nasm/comandos"

# Busca la subcarpeta más reciente basándose en la fecha de modificación
ULTIMO_DIR=$(find "$DIR_COMANDOS" -mindepth 1 -type d -printf '%T@ %p\n' | sort -n | tail -1 | cut -d' ' -f2-)

# Si la carpeta comandos está vacía, usamos la ruta base como respaldo
if [ -z "$ULTIMO_DIR" ]; then
    ULTIMO_DIR="$DIR_COMANDOS"
fi

# Abre la terminal de XFCE situándose en esa carpeta
xfce4-terminal --working-directory="$ULTIMO_DIR" &
