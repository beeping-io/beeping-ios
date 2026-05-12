#!/usr/bin/env bash
#
# test-pod-consumer.sh — end-to-end gate for the BEE-81 CocoaPods spec.
#
# 1. Builds `dist/Beeping.xcframework` via the root build.sh.
# 2. Generates the PodConsumer Xcode project (xcodegen).
# 3. Runs `pod install` against the local Beeping podspec.
# 4. Builds the generated workspace for the iOS Simulator.
#
# Compilation success is the pass condition: if the podspec stops
# producing a consumable framework, the `import Beeping` in
# PodConsumerApp would fail to link here.
#
# Run from the repo root:
#
#   ./scripts/test-pod-consumer.sh
#

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONSUMER_DIR="$ROOT_DIR/Examples/PodConsumer"

if [[ ! -d "$CONSUMER_DIR" ]]; then
  echo "missing $CONSUMER_DIR — was the BEE-81 sample renamed?" >&2
  exit 1
fi

for cmd in xcodegen pod xcodebuild; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "missing dependency: $cmd" >&2
    exit 1
  fi
done

ts() { date +"%H:%M:%S"; }

echo "[$(ts)] step 1/4 — building dist/Beeping.xcframework"
"$ROOT_DIR/build.sh"

echo "[$(ts)] step 2/4 — generating PodConsumer.xcodeproj via xcodegen"
(
  cd "$CONSUMER_DIR"
  xcodegen generate
)

echo "[$(ts)] step 3/4 — pod install against local Beeping.podspec"
(
  cd "$CONSUMER_DIR"
  pod install
)

echo "[$(ts)] step 4/4 — building PodConsumer workspace for iOS Simulator"
(
  cd "$CONSUMER_DIR"
  xcodebuild \
    -workspace PodConsumer.xcworkspace \
    -scheme PodConsumer \
    -destination "generic/platform=iOS Simulator" \
    -configuration Release \
    -quiet \
    build
)

echo "[$(ts)] done — PodConsumer compiled against Beeping.podspec"
