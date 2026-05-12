#!/usr/bin/env bash
#
# test-spm-consumer.sh — end-to-end gate for the BEE-80 SPM packaging.
#
# 1. Builds `dist/Beeping.xcframework` via the root build.sh.
# 2. Resolves and compiles `Examples/SPMConsumer` against the root
#    Package.swift (which exposes the framework as a `.binaryTarget`).
# 3. Reports the consumer's `swift package describe` so we have a
#    paper trail that the target type really is `binary`.
#
# Compilation success is the pass condition: if the SDK's public
# surface ever stops exporting through the binary target, the
# consumer's `import Beeping` would break here.
#
# Run from the repo root:
#
#   ./scripts/test-spm-consumer.sh
#

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONSUMER_DIR="$ROOT_DIR/Examples/SPMConsumer"

if [[ ! -d "$CONSUMER_DIR" ]]; then
  echo "missing $CONSUMER_DIR — was the BEE-80 sample renamed?" >&2
  exit 1
fi

ts() { date +"%H:%M:%S"; }

echo "[$(ts)] step 1/3 — building dist/Beeping.xcframework"
"$ROOT_DIR/build.sh"

echo "[$(ts)] step 2/3 — describing the SPM consumer package"
(
  cd "$CONSUMER_DIR"
  swift package describe --type text
)

echo "[$(ts)] step 3/3 — building SPMConsumer for iOS Simulator"
(
  cd "$CONSUMER_DIR"
  # `swift build` on a host Mac would fall back to the macOS slice,
  # which the Beeping xcframework doesn't provide. xcodebuild with
  # an iOS destination uses the package's auto-generated scheme
  # (`SPMConsumer`) and exercises the real consumption path.
  xcodebuild \
    -scheme SPMConsumer \
    -destination "generic/platform=iOS Simulator" \
    -configuration Release \
    -quiet \
    build
)

echo "[$(ts)] done — SPM consumer compiled against dist/Beeping.xcframework"
