# Sentinel (HashiCorp Policy as Code)

Sentinel runs inside **HCP Terraform / Terraform Enterprise**, not in GitHub Actions, and it is a paid
feature. We include one policy for *learning and interviews*; **OPA/Conftest** (in `../opa`) is what
this project's CI actually enforces. Both answer the same question: "should this plan be allowed?"

| | OPA / Conftest | Sentinel |
|---|---|---|
| Language | Rego | Sentinel |
| Runs | anywhere (CI, laptop) | HCP Terraform / TFE only |
| Cost | free | paid tiers |
| Input | `terraform show -json` plan | `tfplan/v2` import |
