# ADR 0005: Terraform owns the platform; apps are deployed by CI/GitOps

**Status:** Accepted

## Context
Terraform can manage everything in Kubernetes, but app image tags change many times a day and Terraform needs state, locks and plans for each change.

## Decision
Terraform manages: cluster, namespaces, quotas, RBAC, NetworkPolicies, and slow-changing add-ons (CNI, ingress, cert-manager, monitoring, data services). Application Deployments belong to CI/CD or Argo CD/Flux. CRD-backed objects use a helm chart (see charts/cluster-issuers) instead of kubernetes_manifest.

## Consequences
+ fast app delivery, small Terraform state. − two tools to learn; guardrails (quotas/netpols) are the contract between them.
