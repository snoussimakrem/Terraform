# Terraform internals, mapped to this repo

## Three states of the world
| | Where | Example |
|---|---|---|
| **Desired** | your `.tf` files | `enable_nat = false` |
| **Prior (state)** | `dev/10-network.tfstate` in the bucket | records a NAT gateway exists |
| **Actual** | the cloud | someone deleted that NAT in the console |

`terraform plan` = (1) **refresh**: ask providers for the *actual* state of every resource in state,
(2) **diff** desired vs refreshed state, (3) emit a plan. `apply` executes the plan; state is
written as resources finish.

## The dependency graph
Terraform builds a DAG: nodes = resources/data/providers/outputs; edges = references (`aws_subnet.private` →
`aws_vpc.this.id`) plus explicit `depends_on`. Independent nodes run in parallel (default `-parallelism=10`),
dependents wait. Destroy walks the graph in reverse.
```bash
terraform -chdir=environments/dev/10-network graph | dot -Tsvg > graph.svg   # needs graphviz
```
Why `module.security` ↔ `module.storage` is not a cycle: the graph is per **resource**, not per module.

## Plan file
`terraform plan -out=tfplan` freezes decisions. `terraform apply tfplan` applies exactly that, and refuses if
state changed since. That's why CI plans in one job and applies the **same artifact** in another.
`terraform show -json tfplan` = machine-readable plan = what OPA/Conftest evaluates.

## State: serial and lineage
```bash
terraform state pull | jq '{version, terraform_version, serial, lineage}'
```
`lineage` = random ID created with the state (identity); `serial` = increments on every write (version).
`state push` refuses a different lineage or older serial. This is a safety net against overwriting state with the wrong/old file.

## Locking
Before writing, the backend takes a lock. S3 native locking creates `<key>.tflock` using a *conditional put*
(fails if it already exists), which is an atomic compare-and-set. Two applies cannot both win.

## Providers
Separate processes speaking gRPC to Core. Core sends: schema request, `ValidateResourceConfig`,
`PlanResourceChange`, `ApplyResourceChange`, `ReadResource` (refresh). The provider turns these into cloud API calls.
Schema decides which changes are in-place update vs **ForceNew** (replacement).
```bash
terraform providers schema -json | jq '.provider_schemas | keys'
```
`.terraform.lock.hcl` pins provider versions + hashes (checked on `init`): supply-chain control.

## Ephemeral values (1.10+) and write-only arguments (1.11+)
Normal values are stored in plan/state. `ephemeral` resources/variables exist only during the run; **write-only**
arguments are sent to the provider but never persisted. The compiler enforces that ephemeral values can only
flow into ephemeral contexts or write-only arguments, so secrets can't leak into state by accident.

## Provider configuration timing
Providers are configured **before** resources exist. Hence the rule in `providers-k8s.tf`: don't configure the
kubernetes/helm provider from a cluster created in the same configuration.

## Hands-on probes (all safe, read-only)
```bash
TF_LOG=trace terraform plan 2> trace.log      # see provider RPCs
terraform plan -parallelism=1                 # watch strict ordering
terraform console                             # evaluate cidrsubnet("10.0.0.0/16", 4, 8)
terraform state list; terraform state show 'module.network.aws_vpc.this'
```
