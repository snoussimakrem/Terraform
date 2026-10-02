#!/usr/bin/env bash
# Usage: scripts/stack.sh <dev|staging|prod|global> <stack> <init|validate|plan|apply|destroy|output>
# Why a wrapper? Every stack is a separate state. The backend `key` is derived from the
# path so two stacks can never accidentally share a state file.
set -euo pipefail
ENV="${1:?env: dev|staging|prod|global}"; STACK="${2:?stack}"; ACTION="${3:?action}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
if [[ "$ENV" == "global" ]]; then
  DIR="$ROOT/global/$STACK"; CFG_DIR="$ROOT/global"
else
  DIR="$ROOT/environments/$ENV/$STACK"; CFG_DIR="$ROOT/environments/$ENV"
fi
KEY="$ENV/$STACK.tfstate"
# dev + global default to LocalStack (free). staging/prod default to real AWS => paid. Be deliberate.
DEFAULT_MODE=$([[ "$ENV" == "staging" || "$ENV" == "prod" ]] && echo aws || echo local)
MODE="${MODE:-$DEFAULT_MODE}"
if [[ "$MODE" == "local" ]]; then
  export TF_VAR_localstack=true AWS_ACCESS_KEY_ID=test AWS_SECRET_ACCESS_KEY=test AWS_DEFAULT_REGION=us-east-1
else
  export TF_VAR_localstack=false
  echo ">>> MODE=aws: this talks to a REAL AWS account. Check docs/cost.md first." >&2
fi
TF=(terraform -chdir="$DIR")

init() {
  if [[ "$STACK" == "state-bootstrap" ]]; then "${TF[@]}" init -input=false; return; fi
  "${TF[@]}" init -input=false -reconfigure \
    -backend-config="$CFG_DIR/backend-$MODE.hcl" -backend-config="key=$KEY"
}
case "$ACTION" in
  init)     init ;;
  validate) "${TF[@]}" init -backend=false -input=false >/dev/null && "${TF[@]}" validate ;;
  plan)     init; "${TF[@]}" plan -input=false -lock-timeout=60s -out=tfplan
            "${TF[@]}" show -json tfplan > "$ROOT/$ENV-$STACK.plan.json" ;;   # for conftest
  apply)    init; "${TF[@]}" plan -input=false -lock-timeout=60s -out=tfplan
            "${TF[@]}" apply -input=false -lock-timeout=60s tfplan ;;
  destroy)  init; "${TF[@]}" destroy -input=false -lock-timeout=60s ;;
  output)   init; "${TF[@]}" output ;;
  *) echo "unknown action $ACTION" >&2; exit 1 ;;
esac
