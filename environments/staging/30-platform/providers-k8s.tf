variable "cluster_mode" {
  description = "kind (local) or eks (real AWS)."
  type        = string
  default     = "kind"
}
variable "kubeconfig_path" {
  type    = string
  default = "~/.kube/config"
}

locals {
  use_kubeconfig = var.cluster_mode == "kind"
  cluster_name   = "${var.project}-${var.environment}"
}

# ANTI-PATTERN AVOIDED: we do NOT feed these providers from a cluster resource created in the same
# configuration. Providers are configured before resources exist; that creates plan-time failures
# and orphaned resources on cluster replacement. The cluster lives in stack 20; this stack
# only *reads* its address (eks) or uses the kubeconfig that stack 20 produced (kind).
provider "kubernetes" {
  config_path            = local.use_kubeconfig ? pathexpand(var.kubeconfig_path) : null
  config_context         = local.use_kubeconfig ? "kind-${local.cluster_name}" : null
  host                   = local.use_kubeconfig ? null : data.terraform_remote_state.cluster.outputs.endpoint
  cluster_ca_certificate = local.use_kubeconfig ? null : base64decode(data.terraform_remote_state.cluster.outputs.ca_data)
  dynamic "exec" {
    for_each = local.use_kubeconfig ? [] : [1]
    content {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = ["eks", "get-token", "--cluster-name", local.cluster_name]
    }
  }
}

provider "helm" {
  kubernetes {
    config_path            = local.use_kubeconfig ? pathexpand(var.kubeconfig_path) : null
    config_context         = local.use_kubeconfig ? "kind-${local.cluster_name}" : null
    host                   = local.use_kubeconfig ? null : data.terraform_remote_state.cluster.outputs.endpoint
    cluster_ca_certificate = local.use_kubeconfig ? null : base64decode(data.terraform_remote_state.cluster.outputs.ca_data)
    dynamic "exec" {
      for_each = local.use_kubeconfig ? [] : [1]
      content {
        api_version = "client.authentication.k8s.io/v1beta1"
        command     = "aws"
        args        = ["eks", "get-token", "--cluster-name", local.cluster_name]
      }
    }
  }
}

data "terraform_remote_state" "cluster" {
  backend = "s3"
  config  = merge(local.state_conn, { key = "${var.environment}/20-cluster.tfstate" })
}
