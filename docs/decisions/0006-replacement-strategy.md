# ADR 0006: Stateful resource replacement strategy

**Status:** Accepted

## Context
Some argument changes force destroy+create. For databases and buckets that means data loss.

## Decision
prevent_destroy on the state bucket, deletion_protection on prod DB, versioned buckets, create_before_destroy on security groups, ignore_changes on autoscaled fields. Always read plans for '-/+' (replace) markers; use 'terraform plan -replace=ADDR' only deliberately.

## Consequences
+ accidents become plan errors, not outages. − prevent_destroy blocks legitimate teardown; remove it in a reviewed PR first.
