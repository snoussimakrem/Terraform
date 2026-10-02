environment  = "prod"
cluster_mode = "eks"
state_bucket = "REPLACE-WITH-STATE-BUCKET"
enable_loki  = true

# VERIFY with `helm search repo <chart> --versions`
chart_versions = {
  cilium                = "1.16.5"
  cert_manager          = "v1.16.2"
  traefik               = "33.2.1"
  kube_prometheus_stack = "67.4.0"
  loki                  = "6.24.0"
  alloy                 = "0.10.1"
}
namespace_quotas = {
  streaming     = { cpu = "12", memory = "24Gi", pods = "60" }
  data          = { cpu = "24", memory = "48Gi", pods = "120" }
  orchestration = { cpu = "8", memory = "16Gi", pods = "60" }
  apps          = { cpu = "8", memory = "16Gi", pods = "60" }
}
# IdP group names (EKS access entries / OIDC) - replace with yours
editor_groups = ["data-engineers"]
viewer_groups = ["analysts"]
