# ADR 0008: GitHub OIDC with separate plan/apply roles

**Status:** Accepted

## Context
Long-lived cloud keys in CI secrets are the most commonly leaked credential.

## Decision
GitHub OIDC provider in AWS; per-environment plan role (trusted from PRs and main, read-only + own state prefix) and apply role (trusted ONLY from the GitHub Environment job, which has required reviewers); permissions boundary as ceiling.

## Consequences
+ no stored keys, approvals are enforced by IAM not just by workflow YAML. − the apply role's permission set must be curated (var.apply_policy_arns).
