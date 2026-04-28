#!/bin/sh

set -e

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
API_FILE="$REPO_ROOT/API.md"

if [ ! -f "$API_FILE" ]; then
  echo "Error: API.md no existe en la raíz del repo."
  exit 1
fi

required_headers=$(cat <<'EOF'
## Visión general
## Flujo de integración
## API pública (alto nivel)
## API del core wrapper
## C API
## Ejemplo mínimo
## Notas y limitaciones conocidas
EOF
)

echo "$required_headers" | while IFS= read -r header; do
  [ -z "$header" ] && continue
  if ! grep -q "$header" "$API_FILE"; then
    echo "Error: falta el encabezado requerido: $header"
    exit 1
  fi
done

echo "OK: API.md presente y secciones requeridas encontradas."
