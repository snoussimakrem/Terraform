# One module, two backends. Tradeoff documented in docs/decisions/0004: the caller must configure both
# providers even though only one is used. The alternative (two modules) duplicates the interface.

############################ kind (local, free) ############################
resource "kind_cluster" "this" {
  count           = var.mode == "kind" ? 1 : 0
  name            = var.cluster_name
  node_image      = "kindest/node:${var.kubernetes_version}"
  kubeconfig_path = pathexpand(var.kubeconfig_path)
  wait_for_ready  = false # no CNI yet => nodes stay NotReady until Cilium is installed (stack 30)

  kind_config {
    kind        = "Cluster"
    api_version = "kind.x-k8s.io/v1alpha4"

    networking {
      # kind's default CNI (kindnet) does NOT enforce NetworkPolicy. We disable it and install
      # Cilium so default-deny policies are real, not decorative.
      disable_default_cni = true
    }

    node {
      role = "control-plane"
      kubeadm_config_patches = [
        "kind: InitConfiguration\nnodeRegistration:\n  kubeletExtraArgs:\n    node-labels: \"ingress-ready=true\"\n"
      ]
      extra_port_mappings { # host :80 -> node :30080 (Traefik NodePort)
        container_port = 30080
        host_port      = var.http_host_port
        listen_address = "127.0.0.1" # not reachable from your LAN
      }
      extra_port_mappings {
        container_port = 30443
        host_port      = var.https_host_port
        listen_address = "127.0.0.1"
      }
    }
    dynamic "node" {
      for_each = range(var.worker_count)
      content {
        role = "worker"
      }
    }
  }
}

############################ EKS (real AWS, paid) ############################
data "aws_iam_policy_document" "eks_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }
  }
}
data "aws_iam_policy_document" "node_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "cluster" {
  count              = var.mode == "eks" ? 1 : 0
  name               = "${var.cluster_name}-eks-cluster"
  assume_role_policy = data.aws_iam_policy_document.eks_assume.json
  tags               = var.tags
}
resource "aws_iam_role_policy_attachment" "cluster" {
  count      = var.mode == "eks" ? 1 : 0
  role       = aws_iam_role.cluster[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_eks_cluster" "this" {
  count                     = var.mode == "eks" ? 1 : 0
  name                      = var.cluster_name
  role_arn                  = aws_iam_role.cluster[0].arn
  version                   = var.kubernetes_version
  enabled_cluster_log_types = ["api", "audit", "authenticator"]
  tags                      = var.tags

  vpc_config {
    subnet_ids              = var.subnet_ids
    endpoint_private_access = true
    endpoint_public_access  = var.public_endpoint
    public_access_cidrs     = var.public_endpoint ? var.public_access_cidrs : null
  }
  access_config {
    authentication_mode = "API" # access entries instead of the legacy aws-auth ConfigMap
  }
  dynamic "encryption_config" {
    for_each = var.kms_key_arn == null ? [] : [1]
    content {
      resources = ["secrets"]
      provider { key_arn = var.kms_key_arn }
    }
  }

  depends_on = [aws_iam_role_policy_attachment.cluster]
  lifecycle {
    precondition {
      condition     = length(var.subnet_ids) >= 2
      error_message = "EKS needs subnets in at least two AZs."
    }
    precondition {
      condition     = !var.public_endpoint || length(var.public_access_cidrs) > 0
      error_message = "A public endpoint requires explicit public_access_cidrs (never 0.0.0.0/0 by accident)."
    }
  }
}

resource "aws_iam_role" "node" {
  count              = var.mode == "eks" ? 1 : 0
  name               = "${var.cluster_name}-eks-node"
  assume_role_policy = data.aws_iam_policy_document.node_assume.json
  tags               = var.tags
}
resource "aws_iam_role_policy_attachment" "node" {
  for_each = var.mode == "eks" ? toset([
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
  ]) : toset([])
  role       = aws_iam_role.node[0].name
  policy_arn = each.value
}

resource "aws_eks_node_group" "this" {
  for_each        = var.mode == "eks" ? var.node_groups : {}
  cluster_name    = aws_eks_cluster.this[0].name
  node_group_name = each.key
  node_role_arn   = aws_iam_role.node[0].arn
  subnet_ids      = var.subnet_ids
  instance_types  = each.value.instance_types
  capacity_type   = each.value.capacity_type
  labels          = each.value.labels
  tags            = var.tags

  scaling_config {
    min_size     = each.value.min_size
    max_size     = each.value.max_size
    desired_size = each.value.desired_size
  }
  update_config { max_unavailable = 1 }

  depends_on = [aws_iam_role_policy_attachment.node]
  lifecycle {
    # The autoscaler changes desired_size at runtime. Without this, every plan "fixes" it back.
    ignore_changes = [scaling_config[0].desired_size]
  }
}
