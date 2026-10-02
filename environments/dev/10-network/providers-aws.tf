provider "aws" {
  region = var.region

  # LocalStack mode: dummy creds, no real account lookups, path-style S3, everything -> localhost:4566
  access_key                  = var.localstack ? "test" : null
  secret_key                  = var.localstack ? "test" : null
  skip_credentials_validation = var.localstack
  skip_requesting_account_id  = var.localstack
  s3_use_path_style           = var.localstack

  default_tags { tags = local.tags } # every taggable resource gets these automatically

  dynamic "endpoints" {
    for_each = var.localstack ? [1] : []
    content {
      s3             = "http://localhost:4566"
      iam            = "http://localhost:4566"
      kms            = "http://localhost:4566"
      ec2            = "http://localhost:4566"
      sts            = "http://localhost:4566"
      secretsmanager = "http://localhost:4566"
      route53        = "http://localhost:4566"
      ssm            = "http://localhost:4566"
    }
  }
}
