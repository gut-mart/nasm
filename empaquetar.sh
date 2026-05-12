#!/bin/bash
# ==============================================================================
# RUTA: ./empaquetar.sh
# DESCRIPCIÓN: Genera un reporte único con el contenido de todos los archivos
#              relevantes del proyecto, para enviarlo en revisiones de código.
#
# IMPORTANTE: Solo se empaquetan archivos rastreados por git. Esto garantiza
#             que NO se incluyan archivos sensibles como config.local.mk u
#             otros que estén en .gitignore.
#
# REQUISITO: ejecutarse dentro de un repositorio git inicializado.
# ==============================================================================

set -e

OUTPUT="revision.txt"

# 1. Verificar que estamos en un repo git
if ! git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
    echo "❌ Error: este script debe ejecutarse dentro de un repositorio git."
    exit 1
fi

# 2. Borrar reporte anterior
rm -f "$OUTPUT"
touch "$OUTPUT"

echo "Generando reporte del proyecto en: $OUTPUT"
echo "------------------------------------------------"

# 3. Patrón de extensiones y nombres relevantes para revisión.
#    Si añades nuevas categorías, edítalas aquí.
PATRON='\.(asm|inc|h|[mM][dD]|txt|json|mk|sh|ya?ml)$|/Makefile$|^Makefile$|^LICENSE$|^\.gitignore$|^\.env\.example$|/fb_run$|^fb_run$'

# 4. Listar SOLO archivos rastreados por git que coincidan con el patrón.
#    'git ls-files' respeta .gitignore automáticamente, así que archivos
#    como config.local.mk o build/ NUNCA aparecerán aquí.
git ls-files \
    | grep -E "$PATRON" \
    | grep -v "^$OUTPUT\$" \
    | sort \
    | while read -r FILE; do

        # Por seguridad: solo procesar archivos que existen y son legibles
        if [ ! -r "$FILE" ]; then
            continue
        fi

        echo "Procesando: $FILE"

        echo "==============================================================================" >> "$OUTPUT"
        echo " RUTA: ./$FILE" >> "$OUTPUT"
        echo "==============================================================================" >> "$OUTPUT"
        cat "$FILE" >> "$OUTPUT"
        echo -e "\n\n" >> "$OUTPUT"
    done

echo "------------------------------------------------"
echo "✅ Reporte generado: $OUTPUT"
echo ""
echo "Archivos incluidos: $(grep -c '^ RUTA:' "$OUTPUT")"
echo ""
echo "NOTA: Solo se han incluido archivos rastreados por git."
echo "      Archivos en .gitignore (config.local.mk, build/, etc.)"
echo "      NO aparecen en el reporte por motivos de privacidad."