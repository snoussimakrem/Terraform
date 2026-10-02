variable "state_bucket" {
  description = "Bucket holding the other stacks' state (same bucket the backend uses)."
  type        = string
}

locals {
  # terraform_remote_state needs the same connection settings as the backend. In LocalStack mode
  # that means custom endpoint + dummy creds.
  state_conn = merge(
    { bucket = var.state_bucket, region = var.region },
    var.localstack ? {
      endpoints                   = { s3 = "http://localhost:4566" }
      use_path_style              = true
      skip_credentials_validation = true
      skip_requesting_account_id  = true
      skip_metadata_api_check     = true
      skip_region_validation      = true
      access_key                  = "test"
      secret_key                  = "test"
    } : {}
  )
}
