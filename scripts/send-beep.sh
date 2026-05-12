#!/usr/bin/env bash
#
# send-beep.sh — host-side beep emitter for the listener-only sample app.
#
# Hits beepbox-server (dev or prod) to encode a 5-char base32 key into an
# audio/wav blob, then plays the WAV through the Mac's default output
# device with `afplay`. Repeats 9 times with the volume ramped from 0.1
# to 0.9 so the operator can correlate the highest reliably-decoded
# volume against the SDK listener running on a simulator or device.
#
# The sample app no longer ships a Send UI (BEE-2220) — this script is
# the deterministic, repeatable replacement for in-app QA.
#
# Usage:
#   scripts/send-beep.sh \
#     --mode <audible|inaudible|all> \
#     --env <dev|prod> \
#     --key <5-char base32> \
#     --target <simulator|device>
#
# Env: reads BEEPBOX_API_KEY_{DEV|PROD} and BEEPBOX_ENDPOINT_{DEV|PROD}
# from .env.local at the repo root.
#

set -euo pipefail

# ---------------------------------------------------------------------- args

MODE=""
ENV=""
KEY=""
TARGET=""

usage() {
  cat <<USAGE >&2
usage: $0 --mode <audible|inaudible|all> --env <dev|prod> --key <5 base32> --target <simulator|device>
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --mode)   MODE="$2";   shift 2;;
    --env)    ENV="$2";    shift 2;;
    --key)    KEY="$2";    shift 2;;
    --target) TARGET="$2"; shift 2;;
    -h|--help) usage; exit 0;;
    *) echo "unknown arg: $1" >&2; usage; exit 2;;
  esac
done

case "$MODE" in
  audible|inaudible|all) ;;
  *) echo "--mode must be audible|inaudible|all (got '$MODE')" >&2; exit 2;;
esac
case "$ENV" in
  dev|prod) ;;
  *) echo "--env must be dev|prod (got '$ENV')" >&2; exit 2;;
esac
case "$TARGET" in
  simulator|device) ;;
  *) echo "--target must be simulator|device (got '$TARGET')" >&2; exit 2;;
esac
if [[ ! "$KEY" =~ ^[0-9a-v]{5}$ ]]; then
  echo "--key must be exactly 5 chars from [0-9a-v] (got '$KEY')" >&2
  exit 2
fi

# ----------------------------------------------------------- env credentials

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="$REPO_ROOT/.env.local"
if [[ ! -f "$ENV_FILE" ]]; then
  echo "missing $ENV_FILE — copy .env.local.example and fill BEEPBOX_API_KEY_{DEV,PROD}" >&2
  exit 1
fi

# Source only the BEEPBOX_* lines so other vars in .env.local don't leak.
# Use a real temp file rather than `source <(...)` because bash 3.2
# (macOS default) loses exports across process substitution.
ENV_TMP=$(mktemp)
grep -E '^BEEPBOX_(API_KEY|ENDPOINT)_(DEV|PROD)=' "$ENV_FILE" > "$ENV_TMP" || true
set -a
# shellcheck disable=SC1090
. "$ENV_TMP"
set +a

case "$ENV" in
  dev)
    API_KEY="${BEEPBOX_API_KEY_DEV:-}"
    ENDPOINT="${BEEPBOX_ENDPOINT_DEV:-}"
    ;;
  prod)
    API_KEY="${BEEPBOX_API_KEY_PROD:-}"
    ENDPOINT="${BEEPBOX_ENDPOINT_PROD:-}"
    ;;
esac

if [[ -z "$API_KEY" || -z "$ENDPOINT" ]]; then
  ENV_UC=$(echo "$ENV" | tr '[:lower:]' '[:upper:]')
  echo "BEEPBOX_API_KEY_$ENV_UC or BEEPBOX_ENDPOINT_$ENV_UC not set in $ENV_FILE" >&2
  exit 1
fi

# Strip any trailing slash on the endpoint.
ENDPOINT="${ENDPOINT%/}"

# ------------------------------------------------------------------ run loop

REPS=9
GAP_SECONDS=1
TMPDIR_RUN="$(mktemp -d "/tmp/beep-${KEY}-XXXXXX")"

ts() { date +"%H:%M:%S"; }

cleanup() {
  rm -rf "$TMPDIR_RUN"
  rm -f "$ENV_TMP"
}
trap cleanup EXIT

echo "[$(ts)] start — mode=$MODE env=$ENV key=$KEY target=$TARGET endpoint=$ENDPOINT"

for ((i = 1; i <= REPS; i++)); do
  vol=$(awk "BEGIN { printf \"%.1f\", $i / 10.0 }")
  wav="$TMPDIR_RUN/beep-$i.wav"

  body="{\"key\":\"$KEY\",\"mode\":\"$MODE\"}"
  http_status=$(curl -sS -o "$wav" -w "%{http_code}" \
    -X POST \
    -H "Authorization: Bearer $API_KEY" \
    -H "Content-Type: application/json" \
    -d "$body" \
    "$ENDPOINT/v1/encode" || echo "000")

  if [[ "$http_status" != "200" ]]; then
    echo "[$(ts)] [$i/$REPS] mode=$MODE vol=$vol → POST $ENV → $http_status ✗"
    if [[ -s "$wav" ]]; then
      echo "  body: $(head -c 200 "$wav")"
    fi
    exit 1
  fi

  size=$(wc -c < "$wav" | tr -d ' ')

  # afplay -v takes a multiplier in [0..1]. Output device is the system
  # default; per spec we don't pin --device.
  afplay -v "$vol" "$wav"

  echo "[$(ts)] [$i/$REPS] mode=$MODE vol=$vol → POST $ENV → 200 (${size} bytes) → played ✓"

  # Sleep between iterations except after the last one.
  if (( i < REPS )); then
    sleep "$GAP_SECONDS"
  fi
done

echo "[$(ts)] done — check the listener panel on $TARGET for decoded events."
