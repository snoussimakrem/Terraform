locals {
  values = {
    statefulset = { replicas = var.replicas }
    resources = {
      cpu    = { cores = 1 }
      memory = { container = { max = var.memory } }
    }
    storage = { persistentVolume = { size = var.storage_size } }
    external = { enabled = false } # in-cluster only: nothing exposed outside
    # cert-manager issues the broker certificates => encryption in transit
    tls = {
      enabled = var.tls_enabled
      certs = {
        default  = { caEnabled = true, issuerRef = { name = var.cluster_issuer, kind = "ClusterIssuer" } }
        external = { caEnabled = true, issuerRef = { name = var.cluster_issuer, kind = "ClusterIssuer" } }
      }
    }
    console = { enabled = true }
  }
}

resource "helm_release" "redpanda" {
  name       = "redpanda"
  namespace  = var.namespace
  repository = "https://charts.redpanda.com"
  chart      = "redpanda"
  version    = var.chart_version

  values = [yamlencode(local.values)]

  # wait: block until pods are Ready. timeout: how long to wait. wait_for_jobs: also wait for hook Jobs.
  # atomic: roll back automatically on failure. cleanup_on_fail: delete half-created objects.
  wait             = true
  wait_for_jobs    = true
  timeout          = var.timeout_seconds
  atomic           = true
  cleanup_on_fail  = true
}
