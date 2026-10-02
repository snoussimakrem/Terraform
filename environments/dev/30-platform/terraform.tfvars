environment  = "dev"
cluster_mode = "kind"
state_bucket = "tfstate-platform-local"
enable_loki  = true

# VERIFY: these are best-effort versions. Run `helm repo update && helm search repo <chart> --versions`.
chart_versions = {
  cilium                = "1.16.5"
  cert_manager          = "v1.16.2"
  traefik               = "33.2.1"
  kube_prometheus_stack = "67.4.0"
  loki                  = "6.24.0"
  alloy                 = "0.10.1"
}
namespace_quotas = {
  streaming     = { cpu = "4", memory = "6Gi", pods = "20" }
  data          = { cpu = "4", memory = "8Gi", pods = "40" }
  orchestration = { cpu = "3", memory = "6Gi", pods = "30" }
  apps          = { cpu = "2", memory = "4Gi", pods = "20" }
}
