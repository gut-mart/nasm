#!/bin/bash

echo "======================================================="
echo "🛠️  HERRAMIENTA DE REFACTORIZACIÓN AVANZADA (CON VISTA PREVIA)"
echo "======================================================="

# 1. Seguro Anti-Desastres: Comprobar si hay cambios sin guardar en Git
if [ -n "$(git status --porcelain)" ]; then
    echo "❌ ERROR: Tienes código sin guardar en Git."
    echo "Para poder ofrecerte una vista previa segura y poder deshacer los cambios"
    echo "si no te gustan, necesitas hacer un commit de tu trabajo actual primero."
    exit 1
fi

# 2. Pedir los datos
read -p "Introduce la cadena ACTUAL: " STR_VIEJA
read -p "Introduce la NUEVA cadena: " STR_NUEVA

if [ -z "$STR_VIEJA" ] || [ -z "$STR_NUEVA" ]; then
    echo "❌ Error: Las cadenas no pueden estar vacías."
    exit 1
fi

echo "⚙️  Calculando cambios en entorno aislado..."

# 3. Aplicar cambios de texto (sed)
find . -type f \
    -not -path "*/\.git/*" \
    -not -path "*/build/*" \
    -not -path "*/bin/*" \
    -exec sed -i "s|$STR_VIEJA|$STR_NUEVA|g" {} +

# 4. Aplicar cambios de nombre (mv)
find . -type f -name "*$STR_VIEJA*" \
    -not -path "*/\.git/*" \
    -not -path "*/build/*" \
    -not -path "*/bin/*" | while read -r ARCHIVO; do

    DIR=$(dirname "$ARCHIVO")
    BASE=$(basename "$ARCHIVO")
    NUEVO_BASE="${BASE//$STR_VIEJA/$STR_NUEVA}"
    mv "$ARCHIVO" "$DIR/$NUEVO_BASE"
done

# 5. Registrar temporalmente en Git para extraer el Diff
git add -A > /dev/null 2>&1

# 6. MOSTRAR LA VISTA PREVIA
echo ""
echo "======================================================="
echo "👀 VISTA PREVIA DE LOS CAMBIOS:"
echo "======================================================="
echo "📁 ARCHIVOS RENOMBRADOS:"
git status --short | grep "^R" || echo "  (Ningún archivo renombrado)"
echo ""
echo "💻 FRAGMENTOS DE CÓDIGO MODIFICADOS:"
# Muestra el diff coloreado de los archivos modificados
git diff --cached --color=always
echo "======================================================="

# 7. Confirmación final
read -p "¿Aprobar y MANTENER estos cambios? (s/N): " CONFIRMACION

if [[ "$CONFIRMACION" != "s" && "$CONFIRMACION" != "S" ]]; then
    echo "⏪ Cancelando... Restaurando el código original..."
    git reset --hard HEAD > /dev/null 2>&1
    git clean -fd > /dev/null 2>&1
    echo "🛑 Operación abortada. Tu proyecto está intacto."
    exit 0
fi

echo "🎉 ¡Cambios aprobados y aplicados!"
echo "🧹 Ejecutando make clean..."
make clean > /dev/null 2>&1
echo "✅ Todo listo. Recuerda hacer commit de esta refactorización."
