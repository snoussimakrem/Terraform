# ADR 0007: Secrets: ephemeral + write-only, with documented exceptions

**Status:** Accepted

## Context
State files persist every value Terraform handles, including 'sensitive' ones.

## Decision
Generate secrets with ephemeral random_password; store with write-only args (secret_string_wo, password_wo, data_wo); read with ephemeral data; pass through ephemeral module variables. Known exception: Helm values (Airflow admin password) still land in state because the helm provider has no write-only values; mitigate with encrypted/locked state, rotation, and future external-secrets.

## Consequences
+ main secrets never in state or plan. − requires modern provider versions; exceptions must stay documented and shrinking.
