locals {
  # What lives in which namespace, and how isolated it is. Adding a team = adding a map entry.
  namespace_defs = {
    ingress      = {}
    cert-manager = {}
    monitoring   = { pod_security = "privileged" } # node-exporter needs hostPath/hostNetwork
    streaming    = { isolate = true, peers = ["data", "apps", "orchestration"] }
    data         = { isolate = true, peers = ["streaming", "orchestration"], allow_external_egress = true, editors = var.editor_groups, viewers = var.viewer_groups }
    orchestration = { isolate = true, peers = ["data", "streaming"], allow_external_egress = true }
    apps         = { isolate = true, peers = ["streaming"], editors = var.editor_groups, viewers = var.viewer_groups }
  }
  namespaces = { for k, v in local.namespace_defs : k => merge(v, { quota = lookup(var.namespace_quotas, k, null) }) }

  traefik_kind = {
    service      = { type = "NodePort" }
    ports        = { web = { nodePort = 30080 }, websecure = { nodePort = 30443 } }
    nodeSelector = { "ingress-ready" = "true" }
    tolerations  = [{ key = "node-role.kubernetes.io/control-plane", operator = "Exists", effect = "NoSchedule" }]
  }
  traefik_eks = {
    service = { type = "LoadBalancer" } # COST: provisions an AWS load balancer (~$16+/mo)
  }
}

# --- 1. Namespaces, quotas, netpols, RBAC (modules/kubernetes) ---
module "baseline" {
  source     = "../../../modules/kubernetes"
  namespaces = local.namespaces
}

# --- 2. CNI (kind only). Nodes are NotReady until this runs. EKS ships its own CNI. ---
resource "helm_release" "cilium" {
  count      = var.cluster_mode == "kind" ? 1 : 0
  name       = "cilium"
  namespace  = "kube-system"
  repository = "https://helm.cilium.io"
  chart      = "cilium"
  version    = var.chart_versions.cilium
  values     = [yamlencode({ operator = { replicas = 1 }, ipam = { mode = "kubernetes" } })]

  wait            = true
  timeout         = 600
  atomic          = true
  cleanup_on_fail = true
}

# --- 3. cert-manager + ingress ---
resource "helm_release" "cert_manager" {
  name       = "cert-manager"
  namespace  = module.baseline.namespaces["cert-manager"]
  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  version    = var.chart_versions.cert_manager
  values     = [yamlencode({ crds = { enabled = true } })]

  wait            = true
  wait_for_jobs   = true
  timeout         = 600
  atomic          = true
  cleanup_on_fail = true
  depends_on      = [helm_release.cilium]
}

# CRDs (ClusterIssuer) don't exist at PLAN time, so `kubernetes_manifest` would fail. A local chart
# is installed at APPLY time, after cert-manager is Ready.
resource "helm_release" "cluster_issuers" {
  name      = "cluster-issuers"
  namespace = module.baseline.namespaces["cert-manager"]
  chart     = "${path.module}/../../../charts/cluster-issuers"
  wait      = true
  timeout   = 300
  depends_on = [helm_release.cert_manager]
}

resource "helm_release" "traefik" {
  name       = "traefik"
  namespace  = module.baseline.namespaces["ingress"]
  repository = "https://traefik.github.io/charts"
  chart      = "traefik"
  version    = var.chart_versions.traefik
  values     = [yamlencode(var.cluster_mode == "kind" ? local.traefik_kind : local.traefik_eks)]

  wait            = true
  timeout         = 600
  atomic          = true
  cleanup_on_fail = true
  depends_on      = [helm_release.cilium]
}

# --- 4. Observability ---
module "monitoring" {
  source = "../../../modules/monitoring"

  namespace = module.baseline.namespaces["monitoring"]
  chart_versions = {
    kube_prometheus_stack = var.chart_versions.kube_prometheus_stack
    loki                  = var.chart_versions.loki
    alloy                 = var.chart_versions.alloy
  }
  enable_loki = var.enable_loki
  depends_on  = [helm_release.cilium, helm_release.traefik]
}
