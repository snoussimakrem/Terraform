terraform {
  required_version = ">= 1.11.0"
  required_providers {
    aws  = { source = "hashicorp/aws", version = "~> 6.0" }
    kind = { source = "tehcyx/kind", version = "~> 0.8" }
  }
}
