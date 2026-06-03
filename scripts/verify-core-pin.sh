#!/usr/bin/env bash
#
# verify-core-pin.sh — verifies that the vendored beeping-core XCFramework
# matches the pinned manifest (BEE-2311). BEE-79 brought the binary in from
# a beeping-core GitHub Release but left no record of *which* release nor
# any drift detection. This script closes that gap: it recomputes the
# SHA256 of every slice and compares it against `Vendor/beeping-core.version.json`.
#
# Fails (exit 1) on any missing slice or checksum mismatch — so an
# accidental binary swap, a corrupted vendor blob, or a manifest that
# lies about the contents is caught in CI.
#
# Usage:
#
#   ./scripts/verify-core-pin.sh [MANIFEST] [XCF_ROOT]
#
# Both args are optional and default to the repo layout. They exist so the
# self-test (scripts/test-core-pin.sh) can point the script at fixtures.
#
#   MANIFEST  path to the pin manifest JSON
#             (default: Vendor/beeping-core.version.json)
#   XCF_ROOT  path to the .xcframework directory
#             (default: Vendor/BeepingCore.xcframework)
#

set -euo pipefail

MANIFEST="${1:-Vendor/beeping-core.version.json}"
XCF_ROOT="${2:-Vendor/BeepingCore.xcframework}"

for cmd in python3 shasum; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "missing dependency: $cmd" >&2
    exit 1
  fi
done

if [[ ! -f "$MANIFEST" ]]; then
  echo "✗ manifest not found: $MANIFEST" >&2
  exit 1
fi

TAG=$(python3 -c "import json,sys; print(json.load(open('$MANIFEST'))['tag'])")
echo "==> Verifying beeping-core pin ($TAG) against $XCF_ROOT"

# Emit "<slice>\t<expected-sha>" lines from the manifest.
slices=$(python3 -c "
import json
m = json.load(open('$MANIFEST'))
for slice_path, sha in m['slices'].items():
    print(f'{slice_path}\t{sha}')
")

if [[ -z "$slices" ]]; then
  echo "✗ manifest declares no slices" >&2
  exit 1
fi

fail=0
while IFS=$'\t' read -r slice expected; do
  bin="$XCF_ROOT/$slice"
  if [[ ! -f "$bin" ]]; then
    echo "  ✗ missing slice: $bin" >&2
    fail=1
    continue
  fi
  actual=$(shasum -a 256 "$bin" | awk '{print $1}')
  if [[ "$actual" != "$expected" ]]; then
    echo "  ✗ $slice" >&2
    echo "      expected $expected" >&2
    echo "      actual   $actual" >&2
    fail=1
  else
    echo "  ✓ $slice ($expected)"
  fi
done <<< "$slices"

if [[ "$fail" -ne 0 ]]; then
  echo "✗ beeping-core pin verification FAILED — vendored binary drifted from $TAG" >&2
  exit 1
fi

echo "==> beeping-core pin OK ($TAG)"
