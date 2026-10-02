terraform {
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 6.0" }
  }
}
provider "aws" {
  region                      = "us-east-1"
  access_key                  = "test"
  secret_key                  = "test"
  skip_credentials_validation = true
  skip_requesting_account_id  = true
  endpoints {
    ec2 = "http://localhost:4566"
  }
}
module "network" {
  source     = "../../../../modules/network"
  name       = "it"
  cidr_block = "10.99.0.0/16"
  azs        = ["us-east-1a", "us-east-1b"]
  enable_nat = true
}
output "vpc_id" { value = module.network.vpc_id }
output "private_subnet_ids" { value = module.network.private_subnet_ids }
