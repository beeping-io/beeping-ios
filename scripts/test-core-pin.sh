#!/usr/bin/env bash
#
# test-core-pin.sh — self-test for the beeping-core pin tooling (BEE-2311).
# Exercises verify-core-pin.sh + check-core-latest.sh against fixtures so
# CI proves the drift detection actually works (not just that it passes on
# the happy path). Exits non-zero on any failed assertion.
#
# Usage:  ./scripts/test-core-pin.sh
#

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

VERIFY="scripts/verify-core-pin.sh"
CHECK="scripts/check-core-latest.sh"
MANIFEST="Vendor/beeping-core.version.json"
XCF="Vendor/BeepingCore.xcframework"

pass=0
fail=0
ok()   { echo "  ✓ $1"; pass=$((pass + 1)); }
bad()  { echo "  ✗ $1" >&2; fail=$((fail + 1)); }

# Runs a command, capturing exit code without tripping `set -e`.
rc() { "$@" >/dev/null 2>&1; echo $?; }

echo "==> [1/5] verify passes against the real vendored binary"
if [[ "$(rc bash "$VERIFY")" -eq 0 ]]; then ok "real binary verifies"; else bad "real binary failed to verify"; fi

WORK=$(mktemp -d "/tmp/core-pin-test-XXXXXX")
trap 'rm -rf "$WORK"' EXIT

echo "==> [2/5] verify FAILS when a slice is tampered (1 byte flipped)"
cp -R "$XCF" "$WORK/tampered.xcframework"
slice="$WORK/tampered.xcframework/ios-arm64/libBeepingCore.a"
# Append a byte → checksum changes.
printf '\x00' >> "$slice"
if [[ "$(rc bash "$VERIFY" "$MANIFEST" "$WORK/tampered.xcframework")" -ne 0 ]]; then
  ok "tampered slice rejected"
else
  bad "tampered slice was NOT rejected"
fi

echo "==> [3/5] verify FAILS when the manifest lies about a checksum"
python3 - "$MANIFEST" "$WORK/lying.json" <<'PY'
import json, sys
m = json.load(open(sys.argv[1]))
k = next(iter(m["slices"]))
m["slices"][k] = "0" * 64
json.dump(m, open(sys.argv[2], "w"))
PY
if [[ "$(rc bash "$VERIFY" "$WORK/lying.json" "$XCF")" -ne 0 ]]; then
  ok "lying manifest rejected"
else
  bad "lying manifest was NOT rejected"
fi

echo "==> [4/5] freshness check WARNS when upstream is newer"
out=$(CORE_LATEST_TAG="v0.9.0" bash "$CHECK" "$MANIFEST" 2>&1 || true)
if grep -q "::warning" <<< "$out"; then ok "newer release warns"; else bad "newer release did not warn"; fi

echo "==> [5/5] freshness check is SILENT when pinned >= upstream"
out=$(CORE_LATEST_TAG="v0.8.0" bash "$CHECK" "$MANIFEST" 2>&1 || true)
if grep -q "::warning" <<< "$out"; then bad "older upstream wrongly warned"; else ok "older upstream silent"; fi

echo
echo "==> results: $pass passed, $fail failed"
[[ "$fail" -eq 0 ]]
