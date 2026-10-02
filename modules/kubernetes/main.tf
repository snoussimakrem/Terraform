locals {
  isolated = { for k, v in var.namespaces : k => v if v.isolate }
  external = { for k, v in local.isolated : k => v if v.allow_external_egress }
  peered   = { for k, v in local.isolated : k => v if length(v.peers) > 0 }
  quotas   = { for k, v in var.namespaces : k => v if v.quota != null }
  viewers  = { for k, v in var.namespaces : k => v if length(v.viewers) > 0 }
  editors  = { for k, v in var.namespaces : k => v if length(v.editors) > 0 }
}

resource "kubernetes_namespace_v1" "this" {
  for_each = var.namespaces
  metadata {
    name = each.key
    labels = merge({
      "app.kubernetes.io/managed-by"       = "terraform"
      "pod-security.kubernetes.io/enforce" = each.value.pod_security
    }, each.value.labels)
  }
}

resource "kubernetes_resource_quota_v1" "this" {
  for_each = local.quotas
  metadata {
    name      = "baseline"
    namespace = kubernetes_namespace_v1.this[each.key].metadata[0].name
  }
  spec {
    hard = {
      "requests.cpu"    = each.value.quota.cpu
      "requests.memory" = each.value.quota.memory
      "pods"            = each.value.quota.pods
    }
  }
}

# A quota on requests REJECTS pods with no requests. LimitRange injects defaults so teams aren't blocked.
resource "kubernetes_limit_range_v1" "this" {
  for_each = local.quotas
  metadata {
    name      = "defaults"
    namespace = kubernetes_namespace_v1.this[each.key].metadata[0].name
  }
  spec {
    limit {
      type = "Container"
      default = {
        cpu    = "500m"
        memory = "512Mi"
      }
      default_request = {
        cpu    = "100m"
        memory = "128Mi"
      }
    }
  }
}

# --- NetworkPolicies: deny everything, then allow back precisely ---
resource "kubernetes_network_policy_v1" "default_deny" {
  for_each = local.isolated
  metadata {
    name      = "default-deny"
    namespace = kubernetes_namespace_v1.this[each.key].metadata[0].name
  }
  spec {
    pod_selector {}
    policy_types = ["Ingress", "Egress"]
  }
}

resource "kubernetes_network_policy_v1" "allow_same_namespace_and_dns" {
  for_each = local.isolated
  metadata {
    name      = "allow-same-namespace-and-dns"
    namespace = kubernetes_namespace_v1.this[each.key].metadata[0].name
  }
  spec {
    pod_selector {}
    policy_types = ["Ingress", "Egress"]
    ingress {
      from {
        pod_selector {}
      }
    }
    egress {
      to {
        pod_selector {}
      }
    }
    egress { # DNS to CoreDNS, else nothing resolves
      to {
        namespace_selector {
          match_labels = { "kubernetes.io/metadata.name" = "kube-system" }
        }
      }
      ports {
        port     = "53"
        protocol = "UDP"
      }
      ports {
        port     = "53"
        protocol = "TCP"
      }
    }
  }
}

resource "kubernetes_network_policy_v1" "allow_monitoring_scrape" {
  for_each = local.isolated
  metadata {
    name      = "allow-monitoring-scrape"
    namespace = kubernetes_namespace_v1.this[each.key].metadata[0].name
  }
  spec {
    pod_selector {}
    policy_types = ["Ingress"]
    ingress {
      from {
        namespace_selector {
          match_labels = { "kubernetes.io/metadata.name" = var.monitoring_namespace }
        }
      }
    }
  }
}

resource "kubernetes_network_policy_v1" "allow_peers" {
  for_each = local.peered
  metadata {
    name      = "allow-peer-namespaces"
    namespace = kubernetes_namespace_v1.this[each.key].metadata[0].name
  }
  spec {
    pod_selector {}
    policy_types = ["Ingress", "Egress"]
    ingress {
      dynamic "from" {
        for_each = each.value.peers
        content {
          namespace_selector {
            match_labels = { "kubernetes.io/metadata.name" = from.value }
          }
        }
      }
    }
    egress {
      dynamic "to" {
        for_each = each.value.peers
        content {
          namespace_selector {
            match_labels = { "kubernetes.io/metadata.name" = to.value }
          }
        }
      }
    }
  }
}

resource "kubernetes_network_policy_v1" "allow_external_egress" {
  for_each = local.external
  metadata {
    name      = "allow-external-egress"
    namespace = kubernetes_namespace_v1.this[each.key].metadata[0].name
  }
  spec {
    pod_selector {}
    policy_types = ["Egress"]
    egress {
      to {
        ip_block {
          cidr   = "0.0.0.0/0"
          except = ["169.254.169.254/32"] # block the cloud metadata service (credential theft vector)
        }
      }
    }
  }
}

# --- RBAC: bind IdP *groups* to built-in ClusterRoles; never bind individuals ---
resource "kubernetes_role_binding_v1" "viewers" {
  for_each = local.viewers
  metadata {
    name      = "viewers"
    namespace = kubernetes_namespace_v1.this[each.key].metadata[0].name
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "view"
  }
  dynamic "subject" {
    for_each = each.value.viewers
    content {
      kind      = "Group"
      api_group = "rbac.authorization.k8s.io"
      name      = subject.value
    }
  }
}
resource "kubernetes_role_binding_v1" "editors" {
  for_each = local.editors
  metadata {
    name      = "editors"
    namespace = kubernetes_namespace_v1.this[each.key].metadata[0].name
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "edit"
  }
  dynamic "subject" {
    for_each = each.value.editors
    content {
      kind      = "Group"
      api_group = "rbac.authorization.k8s.io"
      name      = subject.value
    }
  }
}
