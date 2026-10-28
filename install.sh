#!/bin/bash
set -e

APP_NAME="CodexTouchBar"
DISPLAY_NAME="Codex Touch Bar"
TARGET_DIR="/Applications"

# Si /Applications requiere sudo y no tenemos permisos de escritura directa, usamos ~/Applications
if [ ! -w "$TARGET_DIR" ]; then
    TARGET_DIR="$HOME/Applications"
    mkdir -p "$TARGET_DIR"
fi

DEST_APP="${TARGET_DIR}/${DISPLAY_NAME}.app"

echo "=============================================="
echo "  🚀 Instalador de ${DISPLAY_NAME} para macOS"
echo "=============================================="

# 1. Compilar si no existe o reconstruir
echo "📦 Compilando versión de producción..."
./build.sh

# 2. Detener instancias previas
echo "🛑 Deteniendo instancias previas de ${DISPLAY_NAME} si existen..."
pkill -f "CodexTouchBar" 2>/dev/null || true
sleep 0.5

# 3. Copiar a la carpeta de Aplicaciones
echo "📂 Instalando en: ${DEST_APP}..."
rm -rf "${DEST_APP}"
cp -R "${APP_NAME}.app" "${DEST_APP}"

# Limpiar atributos de cuarentena y verificar firma
xattr -cr "${DEST_APP}"
codesign --force --deep -s - "${DEST_APP}" 2>/dev/null || true

echo ""
echo "✅ ¡Instalación completada con éxito!"
echo "   La aplicación está disponible en tus Aplicaciones:"
echo "   -> ${DEST_APP}"
echo ""

# 4. Preguntar si se desea iniciar ahora
read -p "¿Deseas abrir ${DISPLAY_NAME} ahora? (s/n): " -n 1 -r
echo ""
if [[ $REPLY =~ ^[SsYy]$ ]]; then
    open "${DEST_APP}"
    echo "✨ ${DISPLAY_NAME} iniciada en tu barra de menús y Touch Bar."
fi
