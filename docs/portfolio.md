# Portfolio kit

## GitHub repository description (≤ 350 chars)
Production-style data-engineering platform as code: Terraform modules for network, KMS/IAM, S3 data lake, Kubernetes (kind/EKS), Redpanda, Spark, Airflow, Prometheus/Grafana/Loki. Layered stacks, S3-native state locking, OIDC CI/CD with approvals, OPA + Checkov + Trivy, native tests. Runs free on LocalStack + kind.

## CV bullets (pick 3–4; only claim what you have actually run!)
- Designed and built a modular Terraform platform (10 reusable modules, 3 environments, 5 isolated state stacks per environment) provisioning networking, encrypted S3 data lake, Kubernetes, Kafka-compatible streaming, Spark, Airflow and observability.
- Implemented secure CI/CD with GitHub Actions: OIDC federation (zero stored cloud keys), SHA-pinned actions, plan-as-PR-comment, environment-gated applies from a single reviewed plan artifact, and nightly drift detection.
- Enforced security as code: least-privilege IAM with permission boundaries, KMS encryption, default-deny Kubernetes NetworkPolicies (Cilium), ephemeral/write-only secrets kept out of Terraform state, and OPA/Checkov/Trivy/TFLint gates.
- Built a layered test strategy: `terraform test` with mocked providers, Terratest integration tests against LocalStack, and Rego policy unit tests; designed cost controls to run the full platform at $0 locally.

## LinkedIn project description
**Cloud-Native Data Platform with Terraform.** I built a production-style data engineering platform entirely as code. It covers VPC networking, KMS-encrypted S3 data lake zones, a Kubernetes cluster (kind locally, EKS-ready), Redpanda for streaming, Spark and Airflow for processing and orchestration, and a Prometheus/Grafana/Loki observability stack. The repo is organized as reusable modules composed into layered, independently-stated stacks per environment. A GitHub Actions pipeline authenticates with OIDC, scans with Trivy/Checkov/TFLint, evaluates OPA policies against the plan, posts the plan to the PR and applies the reviewed plan only after environment approval. Everything runs locally for free with LocalStack and kind. *What I learned:* state design, blast-radius thinking, keeping secrets out of state, and testing infrastructure.
Skills: Terraform · Kubernetes · Helm · AWS · GitHub Actions · OPA · Kafka · Spark · Airflow · DevSecOps

## 60-second explanation
"It's a data-engineering platform defined entirely in Terraform. Data arrives through Kafka-compatible Redpanda, Spark processes it into a three-zone S3 data lake and a Postgres warehouse, Airflow orchestrates, and Prometheus/Grafana/Loki watch it, all on Kubernetes. The interesting part is how it's built: modules for each concern, composed into five layered stacks per environment, each with its own state so a monitoring change can never touch the network. CI uses GitHub OIDC so there are no stored keys, runs security scans and OPA policies against the plan, and applies the exact reviewed plan only after approval. Secrets are ephemeral and never land in state. And it runs locally for free with LocalStack and kind, with EKS/RDS written but plan-only to avoid cost."

## 5-minute explanation (outline with talking points)
1. **Problem (30s):** realistic data platform, but reproducible by anyone, safe, and cheap.
2. **Architecture (60s):** walk the diagram in `architecture.md`: ingress → services → Kafka → Spark → lake/warehouse; observability across it.
3. **Terraform design (90s):** modules vs stacks; why numbered stacks; remote state as an API; S3 native locking; dev/staging/prod via tfvars not copy-pasted code; the kind/EKS dual-mode tradeoff (ADR 0004).
4. **Security (60s):** OIDC trust policy bound to the GitHub Environment; permission boundary; KMS; default-deny netpols (and *why Cilium*: kindnet doesn't enforce them); ephemeral/write-only secrets, and the honest Helm-values exception (ADR 0007).
5. **Quality (45s):** test pyramid; policy as code; the plan-artifact → apply flow.
6. **Operations & lessons (45s):** drift detection, state recovery, runbook; one thing that went wrong while building it and how you debugged it (fill in from your real experience).

## Interview questions (with answers)
1. **Why split state into multiple stacks?** Blast radius, plan speed, lock contention, and least-privilege credentials. Trade-off: cross-stack ordering and output coupling.
2. **How do you keep secrets out of state?** Ephemeral resources/variables + write-only arguments; secrets in a secret manager; and for anything that still reaches state (Helm values) encrypt, lock down and audit the backend and plan to rotate.
3. **What does `terraform plan` actually do?** Refresh (provider reads real state), diff desired vs refreshed state, build an ordered plan from the dependency graph. It changes nothing.
4. **Why apply a saved plan file in CI?** The reviewer saw exactly that plan. Terraform refuses a stale plan if state changed, so there's no gap between review and apply.
5. **How does OIDC replace access keys?** GitHub issues a short-lived signed JWT per job; AWS validates it against the OIDC provider and the role's trust policy (`sub`, `aud`) and returns temporary credentials. Nothing to leak or rotate.
6. **How do you ensure only approved jobs can apply to prod?** The apply role's trust policy matches `sub = repo:ORG/REPO:environment:prod`; only jobs that passed the Environment's required-reviewers gate carry that claim. Enforcement is in IAM, not just YAML.
7. **`count` vs `for_each`?** `count` addresses by index, so removing item 0 shifts everything and causes replacements. `for_each` keys by a stable string. Use `count` only for on/off toggles.
8. **Rename a resource without downtime?** `moved` block, so state is re-addressed, no destroy/create. Keep it until all environments applied.
9. **Someone changed a resource in the console. Now what?** Drift detection finds it. Decide which side is right; update code or reapply; use `ignore_changes` only for fields legitimately managed elsewhere; restrict console write access.
10. **State is corrupted/deleted. Recovery?** Versioned bucket → restore a prior version → `state push` (serial/lineage checks) → `plan` to verify. Without backups: rebuild with `import` blocks.
11. **Why not manage app Deployments with Terraform?** High-frequency changes need no state/locks; GitOps tools reconcile continuously and give better rollback. Terraform owns slow-moving platform and guardrails.
12. **Why does the kubernetes provider fail when the cluster is created in the same config?** Providers are configured before resources exist, so values from the not-yet-created cluster are unknown; split into separate stacks.
13. **Why Cilium on kind?** kind's default CNI doesn't enforce NetworkPolicy; default-deny would be decorative.
14. **How do you test Terraform?** Static (`fmt`/`validate`/TFLint) → security/policy (Checkov/Trivy/OPA) → unit (`terraform test`, mocked) → plan review → integration (Terratest vs LocalStack). Cheap and frequent at the bottom, expensive and rare at the top.
15. **What would you do differently in production?** Multi-account (state/security/workload accounts), real IdP-backed RBAC, external-secrets, GitOps for apps, flow logs and access logging, cost budgets, and Sentinel/OPA in HCP Terraform.

## What to demonstrate live (in this order, ~10 min)
1. `make test` and `opa test`: tests pass in seconds, no cloud.
2. Open a PR that adds a public ACL → watch Checkov/OPA fail with a clear message.
3. Show a PR plan comment and the approval-gated apply (screenshots if no cloud).
4. `make apply-all` locally → `kubectl get pods -A`, open `http://grafana.localtest.me`.
5. `kubectl exec` from `apps` to `data`: blocked by netpol; add a peer in Terraform → allowed.
6. `terraform state pull | grep -i password`: nothing. Explain ephemeral/write-only.
7. Rename a resource with and without `moved`; show the two plans.
8. Break something (`state rm`), recover from the versioned bucket.
