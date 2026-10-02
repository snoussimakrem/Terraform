#!/usr/bin/env bash
# Unit tests live in tests/unit/<module>/ (repo layout), executed with the module as cwd.
set -euo pipefail
cd "$(dirname "$0")/.."
for t in tests/unit/*/; do
  m=$(basename "$t")
  echo "== terraform test: $m"
  terraform -chdir="modules/$m" init -backend=false -input=false >/dev/null
  terraform -chdir="modules/$m" test -test-directory="../../tests/unit/$m"
done
