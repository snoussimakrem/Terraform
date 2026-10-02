# Learning map: your 35 topics → where to study them in this repo

Work through it in this order (it mirrors the phases from the plan). For each: read the code, run the command, break it, fix it.

| # | Topic | Where | Try this |
|---|---|---|---|
| 1 | Advanced module design | `modules/network` (validation, preconditions, optional attrs) | Add a `enable_flow_logs` variable + test |
| 2 | Composition & layering | `environments/*/15-data-lake` (security+storage), `20-cluster` | Draw the resource graph |
| 3 | Module versioning & interfaces | outputs.tf of each module; ADR 0002 | Pin a module via git tag `?ref=v1.0.0` in staging |
| 4 | Registry modules vs writing your own | `compute` hand-written; compare `terraform-aws-modules/vpc/aws` | Swap `modules/network` for the registry VPC module on a branch |
| 5 | Remote state at scale | `global/state-bootstrap`, `backend-*.hcl`, `remote-state.tf` | `make bootstrap`, then `make init` |
| 6 | State locking & separation | ADR 0002/0003, `scripts/stack.sh` | Run two applies; read the lock error |
| 7 | Environment isolation | `environments/{dev,staging,prod}`, separate state keys & IAM prefixes | Check `modules/ci-cd` prefix policy |
| 8 | Provider aliases | (exercise) | Add `provider "aws" { alias = "dr" region = "eu-west-1" }` and a replica bucket via `providers = { aws = aws.dr }` |
| 9 | `for_each` at scale | `network` (subnets, NAT), `kubernetes` (namespaces), `compute` (node groups) | Add an AZ; confirm no other resource changes |
| 10 | Dynamic patterns | `dynamic` in storage lifecycle, kind nodes, netpol `from`/`to`, IAM statements | |
| 11 | Lifecycle in production | `create_before_destroy` (SGs), `ignore_changes` (node groups), `prevent_destroy` (state bucket), pre/postconditions | Try to `destroy` state-bootstrap |
| 12 | `depends_on` vs implicit | NAT↔IGW, lifecycle config↔versioning, monitoring `depends_on` comments | Remove one; observe |
| 13 | `moved` blocks | `modules/network/moved.tf`, `15-data-lake/main.tf`, `state-surgery.md` Lab 1 | |
| 14 | `import` blocks | `global/iam/import.tf.example`, Lab 2 | |
| 15 | `terraform state` surgery | `state-surgery.md` Labs 3–4 | |
| 16 | Replacement strategies | ADR 0006, `-replace` | `apply -replace` on a subnet (LocalStack) |
| 17 | Drift detection | `drift-detection.yml`, runbook, Lab 5 | |
| 18 | State recovery | runbook "State recovery" | Practise on LocalStack versioned bucket |
| 19 | Secrets (ephemeral/write-only) | `security`, `database`, `40-data-services`, ADR 0007 | Run `terraform state pull \| grep -i password` (should find nothing for DB) |
| 20 | IAM least privilege | `security` (zone-scoped policy), `ci-cd`, `global/iam` boundary | |
| 21 | Encryption at rest/in transit | KMS + S3 SSE-KMS; TLS-only bucket policies; Redpanda TLS via cert-manager | |
| 22 | Network security | `network` (SG+NACL), `kubernetes` (NetworkPolicies) | `kubectl exec` between namespaces; watch the deny |
| 23 | Cost control | `docs/cost.md`, opt-in flags, OPA `warn` rule | |
| 24 | Testing | `tests/unit`, `tests/integration`, `policies/opa/policy_test.rego` | Break an assertion deliberately |
| 25 | validate/plan/test in CI | `terraform-plan.yml` | |
| 26 | Policy as Code | `policies/opa`, `policies/sentinel` | Add a rule: "no `*` in IAM actions" |
| 27 | Security scanning | `security-scan.yml`, `.checkov.yml`, `.tflint.hcl` | Introduce a public bucket; watch 3 tools fail |
| 28 | Lint/format in CI | `terraform fmt -check`, tflint, pre-commit | |
| 29 | CI/CD with Actions | `.github/workflows/` | |
| 30 | PR plan comments | `plan` job (github-script) | |
| 31 | Apply after approval | `_terraform-stack.yml` (`environment:`) | |
| 32 | Promotion | `terraform-apply.yml` dev → staging → prod | |
| 33 | Rollback | runbook "CI/CD rollback" | |
| 34 | Documentation | `docs/`, ADRs, README | Write ADR 0010 |
| 35 | Incident response | `runbook.md` | Run the "break and recover" lab as a game day |
