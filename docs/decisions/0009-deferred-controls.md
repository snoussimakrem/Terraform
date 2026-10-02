# ADR 0009: Deferred controls

**Status:** Accepted

## Context
Some production controls cost money or time disproportionate to a learning platform.

## Decision
Deferred: S3 access logging, cross-region replication, VPC flow logs, multi-region/multi-account, Sentinel enforcement, external-secrets. Each is listed with a reason in .checkov.yml or README 'Future improvements'.

## Consequences
Honest scope. Each skip is explicit and reviewable.
