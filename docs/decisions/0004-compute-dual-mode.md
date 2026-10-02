# ADR 0004: One compute module with kind and EKS modes

**Status:** Accepted

## Context
Same logical thing (a cluster) has a free local form and a paid cloud form.

## Decision
modules/compute has var.mode = kind|eks with count-gated resources and one output interface (endpoint, ca_data, cluster_name).

## Consequences
+ identical stack code for dev and prod; envs differ only in tfvars. − the caller must configure both aws and kind providers even if one is unused. Alternative: two modules with the same interface; rejected as duplication.
