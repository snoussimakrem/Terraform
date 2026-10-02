# Things you must verify (read this before the first apply)

This repository was written **without being able to run Terraform** (no Terraform binary and no
registry access in the authoring environment). It has been reviewed for consistency but **never
executed**. Expect to fix a few things on first `validate`/`apply`. That is normal, and a good debugging exercise.
Use the `debug` loop: `make validate` → read the error → fix → repeat.

## Highest-risk assumptions

| Area | Assumption | How to verify |
|---|---|---|
| `kubernetes_secret_v1.data_wo` | Write-only secret data exists in your kubernetes provider version | `terraform providers schema -json` or provider docs. Fallback: `data = {...}` (value lands in state) |
| AWS provider ≥ 6 | `secret_string_wo`, `password_wo` (+`_version`) and `ephemeral "aws_secretsmanager_secret_version"` exist | Registry docs for your exact version |
| `random` ≥ 3.7 | `ephemeral "random_password"` | Registry docs |
| Helm chart versions | Values in `terraform.tfvars` are best guesses | `helm repo add … && helm search repo <chart> --versions` |
| Helm chart values | Redpanda, Loki (SingleBinary), Alloy, Spark operator, Airflow value keys change between chart majors | Read each chart's `values.yaml` for the pinned version |
| kind provider | `tehcyx/kind` attributes (`kubeconfig_path`, `kind_config`) | Registry docs |
| Cilium on kind | Works with `disable_default_cni` + defaults | Cilium docs (kind guide) |
| LocalStack | Licensing / auth token for the current image; NAT gateway, EKS availability | LocalStack docs |
| LocalStack IAM/KMS | Emulation is partial: it doesn't enforce IAM or the OIDC flow | Expected. Real enforcement needs real AWS |
| Action SHAs | All `REPLACE_WITH_FULL_SHA` placeholders | `make pin-actions` |
| TFLint AWS ruleset version | pinned in `.tflint.hcl` | github.com/terraform-linters/tflint-ruleset-aws/releases |
| Conftest image tag | `openpolicyagent/conftest:v0.56.0` | Docker Hub |

## Expected-to-fail-on-purpose

- Workflows contain `@REPLACE_WITH_FULL_SHA`: they will not run until pinned (this prevents shipping unpinned actions by accident).
- `staging`/`prod` tfvars contain `REPLACE-WITH-STATE-BUCKET`.
