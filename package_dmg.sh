#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
APP_NAME="CodexTouchBar"
DISPLAY_NAME="Codex Touch Bar"
DMG_NAME="CodexTouchBar-Installer.dmg"
STAGING_DIR="${ROOT_DIR}/build_dmg_staging"

cd "${ROOT_DIR}"
./build.sh

rm -rf "${STAGING_DIR}" "${DMG_NAME}"
mkdir -p "${STAGING_DIR}"
cp -R "${APP_NAME}.app" "${STAGING_DIR}/${DISPLAY_NAME}.app"
ln -s /Applications "${STAGING_DIR}/Applications"

hdiutil create \
    -volname "${DISPLAY_NAME}" \
    -srcfolder "${STAGING_DIR}" \
    -ov \
    -format UDZO \
    "${DMG_NAME}"

rm -rf "${STAGING_DIR}"
echo "Instalador creado: ${ROOT_DIR}/${DMG_NAME}"
