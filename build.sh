#!/usr/bin/env bash

set -euo pipefail

# Configuración (puedes sobreescribir vía variables de entorno)
ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_PATH="${PROJECT_PATH:-Beeping.xcodeproj}"
SCHEME="${SCHEME:-Beeping}"
CONFIGURATION="${CONFIGURATION:-Release}"
FRAMEWORK_NAME="${FRAMEWORK_NAME:-Beeping}"
EXTRA_LDFLAGS="${EXTRA_LDFLAGS:--L${ROOT_DIR} -lBeepingCoreUniversal}"
BUILD_ROOT="$ROOT_DIR/build"
ARCHIVES_DIR="$BUILD_ROOT/archives"
DIST_DIR="$ROOT_DIR/dist"
DERIVED_DATA="${DERIVED_DATA:-$BUILD_ROOT/DerivedData}"
XCFRAMEWORK_PATH="$DIST_DIR/${FRAMEWORK_NAME}.xcframework"

abort() {
  echo "Error: $*" >&2
  exit 1
}

if [ ! -e "$PROJECT_PATH" ] && [ -z "${WORKSPACE_PATH:-}" ]; then
  abort "No se encontró el proyecto '$PROJECT_PATH'. Define PROJECT_PATH o WORKSPACE_PATH."
fi

if [ -n "${WORKSPACE_PATH:-}" ] && [ ! -e "$WORKSPACE_PATH" ]; then
  abort "No se encontró el workspace '$WORKSPACE_PATH'."
fi

if [ -z "$SCHEME" ]; then
  abort "SCHEME no puede estar vacío. Define la variable de entorno SCHEME."
fi

if [ ! -f "$ROOT_DIR/libBeepingCoreUniversal.a" ] && [ "$EXTRA_LDFLAGS" = "-L${ROOT_DIR} -lBeepingCoreUniversal" ]; then
  echo "Aviso: libBeepingCoreUniversal.a no encontrada en la raíz. Ajusta EXTRA_LDFLAGS o coloca la librería."
fi

echo "==> Configuración"
echo "Project/workspace: ${WORKSPACE_PATH:-$PROJECT_PATH}"
echo "Scheme: $SCHEME"
echo "Configuration: $CONFIGURATION"
echo "Framework: $FRAMEWORK_NAME"
echo "Output: $XCFRAMEWORK_PATH"
echo "Derived data: $DERIVED_DATA"
echo

echo "==> Limpiando artefactos previos"
rm -rf "$BUILD_ROOT" "$XCFRAMEWORK_PATH"
mkdir -p "$ARCHIVES_DIR" "$DIST_DIR" "$DERIVED_DATA"

PROJECT_ARGS=()
if [ -n "${WORKSPACE_PATH:-}" ]; then
  PROJECT_ARGS=(-workspace "$WORKSPACE_PATH")
else
  PROJECT_ARGS=(-project "$PROJECT_PATH")
fi

COMMON_ARCHIVE_ARGS=(
  -scheme "$SCHEME"
  -configuration "$CONFIGURATION"
  SKIP_INSTALL=NO
  BUILD_LIBRARIES_FOR_DISTRIBUTION=YES
  "OTHER_LDFLAGS=$EXTRA_LDFLAGS"
)

echo "==> Archivando (iOS device)"
xcodebuild archive \
  "${PROJECT_ARGS[@]}" \
  "${COMMON_ARCHIVE_ARGS[@]}" \
  -destination "generic/platform=iOS" \
  -archivePath "$ARCHIVES_DIR/iphoneos" \
  -sdk iphoneos \
  -derivedDataPath "$DERIVED_DATA" \
  >/dev/null

echo "==> Archivando (iOS Simulator)"
xcodebuild archive \
  "${PROJECT_ARGS[@]}" \
  "${COMMON_ARCHIVE_ARGS[@]}" \
  -destination "generic/platform=iOS Simulator" \
  -archivePath "$ARCHIVES_DIR/iphonesimulator" \
  -sdk iphonesimulator \
  -derivedDataPath "$DERIVED_DATA" \
  >/dev/null

IOS_FRAMEWORK="$ARCHIVES_DIR/iphoneos.xcarchive/Products/Library/Frameworks/${FRAMEWORK_NAME}.framework"
SIM_FRAMEWORK="$ARCHIVES_DIR/iphonesimulator.xcarchive/Products/Library/Frameworks/${FRAMEWORK_NAME}.framework"

[ -d "$IOS_FRAMEWORK" ] || abort "No se encontró el framework para dispositivo en $IOS_FRAMEWORK"
[ -d "$SIM_FRAMEWORK" ] || abort "No se encontró el framework para simulador en $SIM_FRAMEWORK"

echo "==> Creando XCFramework"
xcodebuild -create-xcframework \
  -framework "$IOS_FRAMEWORK" \
  -framework "$SIM_FRAMEWORK" \
  -output "$XCFRAMEWORK_PATH" \
  >/dev/null

echo
echo "=== Resumen ==="
echo "XCFramework: $XCFRAMEWORK_PATH"
echo "Archivos intermedios: $ARCHIVES_DIR"
echo "Configuración: $CONFIGURATION"
echo "Listo."
