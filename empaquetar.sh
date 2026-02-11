#!/bin/bash

OUTPUT="revision.txt"

# 1. Borrar archivo anterior si existe
rm -f "$OUTPUT"
touch "$OUTPUT"

echo "Generando reporte del proyecto en: $OUTPUT"
echo "------------------------------------------------"

# 2. Buscar archivos: asm, inc, json, h Y AHORA TAMBIÉN Makefile
#    (Se evita carpetas 'build' y '.git')
find . -type f \( -name "*.asm" -o -name "*.inc" -o -name "*.json" -o -name "*.h" -o -name "Makefile" \) \
    -not -path "*/build/*" \
    -not -path "*/.git/*" \
    | sort \
    | while read -r FILE; do

        echo "Procesando: $FILE"

        # Escribir cabecera visual para separar archivos
        echo "==============================================================================" >> "$OUTPUT"
        echo " RUTA: $FILE" >> "$OUTPUT"
        echo "==============================================================================" >> "$OUTPUT"

        # Volcar contenido del archivo
        cat "$FILE" >> "$OUTPUT"

        # Añadir saltos de línea al final
        echo -e "\n\n" >> "$OUTPUT"
    done

echo "------------------------------------------------"
echo "¡Listo! Sube el archivo '$OUTPUT' al chat."
