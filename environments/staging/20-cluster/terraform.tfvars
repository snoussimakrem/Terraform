# REFERENCE CONFIGURATION: plan-only in this project. Applying creates an EKS cluster (~$73/mo + nodes).
environment        = "staging"
cluster_mode       = "eks"
kubernetes_version = "1.31"
state_bucket       = "REPLACE-WITH-STATE-BUCKET"
public_endpoint    = false
node_groups = {
  general = {
    instance_types = ["m6i.large"]
    min_size       = 2
    max_size       = 3
    desired_size   = 2
    labels         = { workload = "general" }
  }
}
