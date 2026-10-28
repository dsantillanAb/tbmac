#!/bin/bash
set -e

DISPLAY_NAME="Codex Touch Bar"
TARGET1="/Applications/${DISPLAY_NAME}.app"
TARGET2="$HOME/Applications/${DISPLAY_NAME}.app"

echo "🛑 Deteniendo ${DISPLAY_NAME} si está en ejecución..."
pkill -f "CodexTouchBar" 2>/dev/null || true

REMOVED=0
if [ -d "$TARGET1" ]; then
    rm -rf "$TARGET1"
    echo "🗑️ Eliminada de $TARGET1"
    REMOVED=1
fi

if [ -d "$TARGET2" ]; then
    rm -rf "$TARGET2"
    echo "🗑️ Eliminada de $TARGET2"
    REMOVED=1
fi

if [ $REMOVED -eq 1 ]; then
    echo "✅ ${DISPLAY_NAME} ha sido desinstalada correctamente."
else
    echo "ℹ️ No se encontró ninguna instalación de ${DISPLAY_NAME} en /Applications ni ~/Applications."
fi
