data "terraform_remote_state" "network" {
  backend = "s3"
  config  = merge(local.state_conn, { key = "${var.environment}/10-network.tfstate" })
}
data "terraform_remote_state" "lake" {
  backend = "s3"
  config  = merge(local.state_conn, { key = "${var.environment}/15-data-lake.tfstate" })
}

module "compute" {
  source = "../../../modules/compute"

  mode               = var.cluster_mode
  cluster_name       = "${var.project}-${var.environment}"
  kubernetes_version = var.kubernetes_version
  worker_count       = var.worker_count
  kubeconfig_path    = var.kubeconfig_path
  tags               = local.tags

  # Only meaningful for eks; harmless empties for kind.
  subnet_ids          = var.cluster_mode == "eks" ? data.terraform_remote_state.network.outputs.private_subnet_ids : []
  kms_key_arn         = var.cluster_mode == "eks" ? data.terraform_remote_state.lake.outputs.kms_key_arn : null
  node_groups         = var.node_groups
  public_endpoint     = var.public_endpoint
  public_access_cidrs = var.public_access_cidrs
}
