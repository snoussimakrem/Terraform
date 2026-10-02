# Architecture

## Data flow

```mermaid
flowchart LR
  client([Client / Browser]) -->|HTTPS *.localtest.me| ingress[Traefik Ingress<br/>TLS via cert-manager]
  ingress --> api[API / apps ns]
  api -->|produce| kafka[(Redpanda<br/>Kafka API)]
  kafka -->|consume| spark[Spark jobs<br/>spark-operator]
  airflow[Airflow<br/>KubernetesExecutor] -->|submits| spark
  spark -->|write| lake[(Data lake<br/>S3: raw → curated → analytics)]
  spark -->|load| wh[(Postgres warehouse)]
  wh --> bi[Grafana / BI]
  prom[Prometheus + Grafana + Loki + Alloy] -. scrapes / logs .-> api & kafka & spark & airflow & wh
```

## Infrastructure layers (and the Terraform stack that owns each)

```mermaid
flowchart TB
  subgraph global[global/ - exists once]
    boot[state-bootstrap]-->iam[iam: OIDC + CI roles]-->dns
  end
  subgraph env[environments/ENV - one copy per environment, each box = its own state]
    n[10-network<br/>VPC, subnets, NAT, SG, NACL] --> l[15-data-lake<br/>KMS, S3 zones, IAM, secret]
    l --> c[20-cluster<br/>kind or EKS]
    c --> p[30-platform<br/>namespaces, RBAC, netpol, CNI, ingress, cert-manager, monitoring]
    p --> d[40-data-services<br/>Postgres, Redpanda, Spark, Airflow]
  end
  global -.state bucket + CI roles.-> env
```

## Why stacks are split this way

| Stack | Changes | Blast radius | Credentials needed |
|---|---|---|---|
| 10-network | rarely | huge (everything lives in it) | cloud |
| 15-data-lake | rarely | data + keys | cloud |
| 20-cluster | rarely | all workloads | cloud |
| 30-platform | weekly | cluster add-ons | cluster admin |
| 40-data-services | often | data services | cluster admin + secrets |

Applications (`apps` namespace workloads, image tags) are **deliberately not here**. See ADR 0005.

## Kubernetes namespaces

| Namespace | Isolation | Purpose |
|---|---|---|
| ingress, cert-manager | open | Cluster edge |
| monitoring | privileged PSA (node-exporter), open | Observability |
| streaming | default-deny + peers | Redpanda |
| data | default-deny + peers + egress | Spark jobs, Postgres |
| orchestration | default-deny + peers + egress | Airflow |
| apps | default-deny + peers | Your services |

## Network security layers

1. **Security groups** (stateful, per-resource) → 2. **NACLs** (stateless, per-subnet) →
3. **Kubernetes NetworkPolicies** (per-pod, enforced by Cilium) → 4. **TLS in transit** (cert-manager) →
5. **KMS encryption at rest**.
