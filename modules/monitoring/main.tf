locals {
  loki_url = "http://loki.${var.namespace}.svc.cluster.local:3100"

  kps_values = {
    prometheus = {
      prometheusSpec = {
        retention = var.retention
        # Discover ServiceMonitors in ALL namespaces, not only ones labelled for this release.
        serviceMonitorSelectorNilUsesHelmValues = false
        podMonitorSelectorNilUsesHelmValues     = false
        storageSpec = { volumeClaimTemplate = { spec = {
          accessModes = ["ReadWriteOnce"]
          resources   = { requests = { storage = var.prometheus_storage } }
        } } }
      }
    }
    alertmanager = { enabled = true }
    grafana = {
      # No admin password set => chart generates a random one into a Secret. Nothing in state.
      # Read it with: kubectl -n monitoring get secret <release>-grafana -o jsonpath='{.data.admin-password}' | base64 -d
      ingress = { enabled = true, ingressClassName = var.ingress_class, hosts = [var.grafana_host] }
      additionalDataSources = var.enable_loki ? [{
        name = "Loki", type = "loki", access = "proxy", url = local.loki_url
      }] : []
    }
    # kind exposes none of these control-plane endpoints; scraping them just creates red alerts.
    kubeEtcd              = { enabled = false }
    kubeControllerManager = { enabled = false }
    kubeScheduler         = { enabled = false }
    kubeProxy             = { enabled = false }
  }

  loki_values = {
    deploymentMode = "SingleBinary"
    loki = {
      auth_enabled  = false
      commonConfig  = { replication_factor = 1 }
      storage       = { type = "filesystem" }
      schemaConfig = { configs = [{
        from = "2024-04-01", store = "tsdb", object_store = "filesystem", schema = "v13",
        index = { prefix = "loki_index_", period = "24h" }
      }] }
    }
    singleBinary  = { replicas = 1 }
    read          = { replicas = 0 }
    write         = { replicas = 0 }
    backend       = { replicas = 0 }
    chunksCache   = { enabled = false }
    resultsCache  = { enabled = false }
    gateway       = { enabled = false }
    lokiCanary    = { enabled = false }
    test          = { enabled = false }
  }

  # Alloy tails container logs via the Kubernetes API and ships them to Loki.
  alloy_config = <<-EOT
    discovery.kubernetes "pods" { role = "pod" }
    discovery.relabel "pods" {
      targets = discovery.kubernetes.pods.targets
      rule {
        source_labels = ["__meta_kubernetes_namespace"]
        target_label  = "namespace"
      }
      rule {
        source_labels = ["__meta_kubernetes_pod_name"]
        target_label  = "pod"
      }
      rule {
        source_labels = ["__meta_kubernetes_pod_container_name"]
        target_label  = "container"
      }
    }
    loki.source.kubernetes "pods" {
      targets    = discovery.relabel.pods.output
      forward_to = [loki.write.default.receiver]
    }
    loki.write "default" {
      endpoint { url = "${local.loki_url}/loki/api/v1/push" }
    }
  EOT
}

resource "helm_release" "kube_prometheus_stack" {
  name       = "kps"
  namespace  = var.namespace
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  version    = var.chart_versions.kube_prometheus_stack
  values     = [yamlencode(local.kps_values)]

  wait            = true
  wait_for_jobs   = true
  timeout         = var.timeout_seconds
  atomic          = true
  cleanup_on_fail = true
}

resource "helm_release" "loki" {
  count      = var.enable_loki ? 1 : 0
  name       = "loki"
  namespace  = var.namespace
  repository = "https://grafana.github.io/helm-charts"
  chart      = "loki"
  version    = var.chart_versions.loki
  values     = [yamlencode(local.loki_values)]

  wait            = true
  timeout         = var.timeout_seconds
  atomic          = true
  cleanup_on_fail = true
}

resource "helm_release" "alloy" {
  count      = var.enable_loki ? 1 : 0
  name       = "alloy"
  namespace  = var.namespace
  repository = "https://grafana.github.io/helm-charts"
  chart      = "alloy"
  version    = var.chart_versions.alloy
  values     = [yamlencode({ alloy = { configMap = { content = local.alloy_config } } })]

  wait            = true
  timeout         = var.timeout_seconds
  atomic          = true
  cleanup_on_fail = true
  depends_on      = [helm_release.loki] # alloy retries anyway; ordering just avoids noisy startup errors
}
