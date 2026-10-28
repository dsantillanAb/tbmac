#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
APP_NAME="CodexTouchBar"
APP_DIR="${ROOT_DIR}/${APP_NAME}.app"
CONTENTS_DIR="${APP_DIR}/Contents"
MACOS_DIR="${CONTENTS_DIR}/MacOS"
RESOURCES_DIR="${CONTENTS_DIR}/Resources"
MODULE_CACHE_DIR="${TMPDIR:-/tmp}/CodexTouchBarModuleCache"
BUILD_DIR="${ROOT_DIR}/.build"

cd "${ROOT_DIR}"
command -v swiftc >/dev/null || { echo "Error: swiftc no está instalado. Instala Xcode Command Line Tools." >&2; exit 1; }

echo "Compilando ${APP_NAME}..."
mkdir -p "${BUILD_DIR}" "${MODULE_CACHE_DIR}"
swiftc -O -module-cache-path "${MODULE_CACHE_DIR}" Sources/*.swift -o "${BUILD_DIR}/${APP_NAME}"

rm -rf "${APP_DIR}"
mkdir -p "${MACOS_DIR}" "${RESOURCES_DIR}"
mv "${BUILD_DIR}/${APP_NAME}" "${MACOS_DIR}/${APP_NAME}"
cp Info.plist "${CONTENTS_DIR}/Info.plist"

if [[ -f AppIcon.icns ]]; then
    cp AppIcon.icns "${RESOURCES_DIR}/AppIcon.icns"
fi

echo "Firmando con firma ad hoc..."
xattr -cr "${APP_DIR}"
codesign --force --deep --sign - "${APP_DIR}"

echo "Aplicación creada: ${APP_DIR}"
