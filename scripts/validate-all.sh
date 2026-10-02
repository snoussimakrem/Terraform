#!/usr/bin/env bash
# `init -backend=false` downloads providers but never touches state => safe & credential-free.
set -euo pipefail
cd "$(dirname "$0")/.."
fail=0
for d in modules/* environments/*/* global/*; do
  [[ -d "$d" ]] || continue
  ls "$d"/*.tf >/dev/null 2>&1 || continue
  echo "== validate $d"
  terraform -chdir="$d" init -backend=false -input=false >/dev/null || { fail=1; continue; }
  terraform -chdir="$d" validate || fail=1
done
exit $fail
