data "aws_caller_identity" "current" {}

locals {
  prefix = "${var.project}-${var.environment}-${data.aws_caller_identity.current.account_id}"
}

module "storage" {
  source = "../../../modules/storage"

  name_prefix   = local.prefix
  kms_key_arn   = module.security.kms_key_arn
  force_destroy = var.force_destroy
  tags          = local.tags
}

# security <-> storage reference each other at MODULE level but not at RESOURCE level:
#   kms key -> buckets -> iam policy.  Terraform's graph is per-resource, so there is no cycle.
module "security" {
  source = "../../../modules/security"

  name                        = "${var.project}-${var.environment}"
  bucket_arns                 = module.storage.bucket_arns
  trusted_principal_arns      = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
  secret_recovery_window_days = var.secret_recovery_window_days
  tags                        = local.tags
}

# Refactor example: this module used to be called `lake`. Recording the move avoids destroy+create.
moved {
  from = module.lake
  to   = module.storage
}
