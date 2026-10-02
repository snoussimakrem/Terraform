# ADR 0003: S3 native state locking (use_lockfile)

**Status:** Accepted

## Context
Locking used to require a DynamoDB table. Terraform >= 1.10 can lock with a conditional-write <key>.tflock object in the same bucket.

## Decision
Use S3 backend with use_lockfile = true, versioning, KMS encryption, TLS-only policy, per-environment key prefixes.

## Consequences
+ one fewer resource to run/secure/pay for. − requires Terraform >= 1.10; the CI role needs s3:PutObject/DeleteObject on the lock key (granted in modules/ci-cd). DynamoDB locking is deprecated, not the recommended path.
