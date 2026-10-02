# Cost model

> Prices are approximate and change; confirm on the AWS pricing pages before applying anything for real.

| Mode | What runs | Cost |
|---|---|---|
| `MODE=local` (default for dev) | Docker, kind, LocalStack | **$0** (electricity + RAM) |
| CI | LocalStack service container | $0 on public repos / free-tier minutes |
| `MODE=aws` | Real AWS | **can be expensive**: read below |

## Things that bill on real AWS even when "idle"

| Resource | Terraform | Approx. |
|---|---|---|
| EKS control plane | `modules/compute` mode=eks | ~$73/mo |
| EKS nodes (2x m6i.large) | node group | ~$140/mo |
| NAT gateway | `enable_nat=true` | ~$32/mo **each** + per-GB |
| Load balancer (Traefik on EKS) | `traefik_eks` | ~$16+/mo |
| RDS | `database_mode=rds` | free tier limited & time-boxed; verify |
| Route 53 zone | `global/dns` | ~$0.50/mo |
| KMS keys | `security`, `state-bootstrap` | ~$1/mo per key |
| Secrets Manager | per secret | ~$0.40/mo |
| CloudWatch Logs (EKS control plane) | `enabled_cluster_log_types` | per GB ingested |

## Controls in this repo

- NAT, EKS, RDS, DNS are **opt-in** and default off in dev.
- staging/prod are reference configs, plan-only.
- OPA `warn` rule prints a **COST:** line in every PR plan when a paid resource is being created.
- Default tags (`Project`, `Environment`) make cost allocation possible in Cost Explorer.
- If you do apply to a real account: set an AWS Budget alert **first**, then `make destroy` when done.
