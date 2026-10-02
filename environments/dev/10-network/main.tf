module "network" {
  source = "../../../modules/network"

  name                  = "${var.project}-${var.environment}"
  cidr_block            = var.vpc_cidr
  azs                   = var.azs
  enable_nat            = var.enable_nat
  single_nat_gateway    = var.single_nat_gateway
  allowed_ingress_cidrs = var.allowed_ingress_cidrs
  tags                  = local.tags
}
