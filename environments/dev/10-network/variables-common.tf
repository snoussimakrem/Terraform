variable "project" {
  type    = string
  default = "dp"
}
variable "environment" { type = string }
variable "region" {
  type    = string
  default = "us-east-1"
}
variable "localstack" {
  description = "true = talk to LocalStack on localhost:4566 (free). Set by scripts/stack.sh via TF_VAR_localstack."
  type        = bool
  default     = false
}

locals {
  tags = {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}
