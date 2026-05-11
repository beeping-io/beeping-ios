#!/usr/bin/env bash
#
# verify-release.sh — verifies the supply chain of a Beeping iOS
# SDK GitHub Release (BEE-82). Downloads the published assets, then:
#
#   1. Confirms the SHA256 of `Beeping.xcframework.zip` matches the
#      `.sha256` companion file.
#   2. Verifies the cosign keyless bundle (`*.cosign.bundle`) against
#      the GitHub Actions OIDC identity that produced the artifact.
#      Anyone can run this — no pre-shared key, no Beeping signing
#      authority. The certificate identity binds the artifact to the
#      `release.yml` workflow on this repository.
#   3. Prints a head of the CycloneDX SBOM so the operator can eyeball
#      the components.
#
# Usage:
#
#   ./scripts/verify-release.sh v0.0.0
#

set -euo pipefail

TAG="${1:-}"
if [[ -z "$TAG" ]]; then
  echo "usage: $0 <tag, e.g. v0.0.0>" >&2
  exit 2
fi

for cmd in gh cosign shasum; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "missing dependency: $cmd" >&2
    exit 1
  fi
done

WORK_DIR=$(mktemp -d "/tmp/beeping-verify-$TAG-XXXXXX")
trap 'rm -rf "$WORK_DIR"' EXIT
cd "$WORK_DIR"

REPO="${REPO_OVERRIDE:-beeping-io/beeping-ios}"
ASSETS=(
  Beeping.xcframework.zip
  Beeping.xcframework.zip.sha256
  Beeping.xcframework.zip.cosign.bundle
  Beeping.sbom.cdx.json
)

echo "==> Downloading assets for $REPO@$TAG"
for asset in "${ASSETS[@]}"; do
  gh release download "$TAG" \
    --repo "$REPO" \
    --pattern "$asset" \
    --output "$asset"
done

echo "==> Verifying SHA256"
expected=$(awk '{print $1}' Beeping.xcframework.zip.sha256)
actual=$(shasum -a 256 Beeping.xcframework.zip | awk '{print $1}')
if [[ "$expected" != "$actual" ]]; then
  echo "  ✗ checksum mismatch: expected $expected, got $actual" >&2
  exit 1
fi
echo "  ✓ sha256 matches ($expected)"

echo "==> Verifying cosign keyless signature"
# The certificate-identity-regexp matches any workflow that lives at
# `.github/workflows/release.yml` on a refs/tags/v* ref in the
# `beeping-io/beeping-ios` repository. If anyone forks the repo and
# publishes a malicious build, the identity won't match this regexp.
cosign verify-blob \
  --certificate-identity-regexp "https://github.com/${REPO}/.github/workflows/release.yml@refs/tags/v.*" \
  --certificate-oidc-issuer "https://token.actions.githubusercontent.com" \
  --bundle Beeping.xcframework.zip.cosign.bundle \
  Beeping.xcframework.zip
echo "  ✓ cosign signature valid"

echo "==> SBOM head (CycloneDX)"
head -c 2000 Beeping.sbom.cdx.json
echo
echo "==> all checks passed for $TAG"
