# ADR 0001: Local-first: LocalStack + kind, real AWS optional

**Status:** Accepted

## Context
A portfolio/learning project must be reproducible by anyone without a cloud bill. Managed Kafka/EMR/EKS/NAT cost real money even idle.

## Decision
Write modules against the AWS API; run them against LocalStack (AWS emulation) and kind (Kubernetes in Docker). Paid modules (EKS, RDS, NAT) are written, validated, tested and planned, but not applied to a real account by default.

## Consequences
+ $0 to run, fast feedback, CI can run it. − Emulators are partial (no IAM enforcement, limited services); some bugs only appear on real AWS. LocalStack licensing may change: see VERIFY.md.
