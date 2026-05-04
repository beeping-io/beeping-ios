#!/bin/bash
# generate-secrets.sh
#
# Build phase: emits Secrets.swift in Sources/Generated/ (gitignored) with
# values read from `.env.local` at the repo root. Constants are wrapped in
# `#if DEBUG` so Release builds compile without `BeepboxSecrets` symbol.
#
# Also runs at xcodegen-bootstrap time so the file exists when xcodegen
# scans the Sources/ folder.
#
# Usage: generate-secrets.sh [CONFIGURATION]

set -euo pipefail

CONFIG="${1:-Debug}"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SAMPLE_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
REPO_ROOT="$(cd "$SAMPLE_ROOT/.." && pwd)"
ENV_FILE="$REPO_ROOT/.env.local"
OUT_DIR="$SAMPLE_ROOT/Sources/Generated"
OUT="$OUT_DIR/Secrets.swift"

mkdir -p "$OUT_DIR"

read_var() {
  local key="$1"
  if [ -f "$ENV_FILE" ]; then
    grep -E "^${key}=" "$ENV_FILE" | head -1 | sed "s/^${key}=//" | sed 's/^"//; s/"$//'
  fi
}

DEV_KEY="$(read_var BEEPBOX_API_KEY_DEV || true)"
DEV_ENDPOINT="$(read_var BEEPBOX_ENDPOINT_DEV || true)"
PROD_KEY="$(read_var BEEPBOX_API_KEY_PROD || true)"
PROD_ENDPOINT="$(read_var BEEPBOX_ENDPOINT_PROD || true)"

# In Release we deliberately blank everything: even though #if DEBUG
# already keeps the constants out of the binary, never let the script
# leak values into Release-config DerivedData on disk either.
if [ "$CONFIG" = "Release" ]; then
  DEV_KEY=""
  DEV_ENDPOINT=""
  PROD_KEY=""
  PROD_ENDPOINT=""
fi

# Escape for Swift string literals (backslashes + double quotes).
escape() {
  printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g'
}

cat > "$OUT" <<EOF
// AUTO-GENERATED — do not edit. Regenerated each build by
// BeepingSampleApp/Scripts/generate-secrets.sh from .env.local.

#if DEBUG
public enum BeepboxSecrets {
    public static let devApiKey: String = "$(escape "$DEV_KEY")"
    public static let devEndpoint: String = "$(escape "$DEV_ENDPOINT")"
    public static let prodApiKey: String = "$(escape "$PROD_KEY")"
    public static let prodEndpoint: String = "$(escape "$PROD_ENDPOINT")"
}
#endif
EOF

echo "[generate-secrets] wrote $OUT (CONFIG=$CONFIG, dev_key_len=${#DEV_KEY}, dev_endpoint_len=${#DEV_ENDPOINT}, prod_key_len=${#PROD_KEY}, prod_endpoint_len=${#PROD_ENDPOINT})"
