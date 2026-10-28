#!/bin/bash
set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$DIR"

if [ ! -d "CodexTouchBar.app" ]; then
    echo "App no encontrada. Compilando..."
    ./build.sh
fi

echo "🚀 Lanzando Codex Touch Bar..."
# Si ya había una instancia previa, la cerramos limpiamente
pkill -f CodexTouchBar 2>/dev/null || true
sleep 0.3

open "$DIR/CodexTouchBar.app"
echo "✨ Codex Touch Bar está corriendo en segundo plano."
echo "   - Revisa tu Touch Bar física: verás el icono Lucide Bot con 'Codex' en la Control Strip."
echo "   - Revisa tu Barra de Menús superior para configuraciones y modo demo."
