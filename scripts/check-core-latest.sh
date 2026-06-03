#!/usr/bin/env bash
#
# check-core-latest.sh — warns (but never fails) when beeping-core has
# published a release newer than the one we pin in
# `Vendor/beeping-core.version.json` (BEE-2311).
#
# The pin (verify-core-pin.sh) guarantees the vendored binary matches a
# known tag; this script is the *freshness* half — a non-blocking nudge so
# we notice when it's time to bump. It emits a GitHub Actions `::warning::`
# (visible in the PR checks) and always exits 0.
#
# Usage:
#
#   ./scripts/check-core-latest.sh [MANIFEST]
#
# Environment:
#
#   CORE_LATEST_TAG  override the "latest upstream tag" instead of querying
#                    GitHub. Used by the self-test for determinism; also
#                    handy offline. When unset, `gh release list` is used.
#

set -euo pipefail

MANIFEST="${1:-Vendor/beeping-core.version.json}"
CORE_REPO="${CORE_REPO_OVERRIDE:-beeping-io/beeping-core}"

if ! command -v python3 >/dev/null 2>&1; then
  echo "missing dependency: python3" >&2
  exit 1
fi

if [[ ! -f "$MANIFEST" ]]; then
  echo "✗ manifest not found: $MANIFEST" >&2
  exit 1
fi

PINNED=$(python3 -c "import json; print(json.load(open('$MANIFEST'))['tag'])")

if [[ -n "${CORE_LATEST_TAG:-}" ]]; then
  LATEST="$CORE_LATEST_TAG"
else
  if ! command -v gh >/dev/null 2>&1; then
    echo "==> gh not available and CORE_LATEST_TAG unset; skipping freshness check"
    exit 0
  fi
  # Newest release tag, e.g. "v0.8.1". `gh release list` sorts newest-first.
  LATEST=$(gh release list --repo "$CORE_REPO" --limit 1 --json tagName \
    --jq '.[0].tagName' 2>/dev/null || true)
  if [[ -z "$LATEST" ]]; then
    echo "==> could not resolve latest $CORE_REPO release; skipping freshness check"
    exit 0
  fi
fi

echo "==> beeping-core pinned=$PINNED latest=$LATEST"

# Compare as semver (strip a leading "v"). `newer` is non-empty when LATEST
# sorts strictly after PINNED.
newer=$(python3 - "$PINNED" "$LATEST" <<'PY'
import sys

def parse(tag):
    tag = tag.lstrip("vV").split("-")[0]
    parts = []
    for p in tag.split("."):
        try:
            parts.append(int(p))
        except ValueError:
            parts.append(0)
    while len(parts) < 3:
        parts.append(0)
    return tuple(parts[:3])

pinned, latest = parse(sys.argv[1]), parse(sys.argv[2])
print("newer" if latest > pinned else "")
PY
)

if [[ -n "$newer" ]]; then
  msg="beeping-core $LATEST is newer than the pinned $PINNED — consider bumping Vendor/beeping-core.version.json + the XCFramework"
  # GitHub Actions workflow command (rendered as an annotation in CI);
  # harmless plain text locally.
  echo "::warning title=beeping-core out of date::$msg"
  echo "⚠️  $msg"
else
  echo "✓ pinned beeping-core is up to date ($PINNED)"
fi

exit 0
