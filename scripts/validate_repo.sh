#!/bin/sh

set -e

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

for file in README.md CHANGELOG.md .gitignore; do
  if [ ! -f "$ROOT/$file" ]; then
    echo "Error: falta $file en la raíz del repo."
    exit 1
  fi
done

echo "OK: README.md, CHANGELOG.md y .gitignore presentes."
