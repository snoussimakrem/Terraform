data "aws_caller_identity" "current" {}

# ---- Encryption key -------------------------------------------------------
data "aws_iam_policy_document" "kms" {
  statement {
    sid       = "AccountAdmin"
    actions   = ["kms:*"]
    resources = ["*"]
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
  }
}
resource "aws_kms_key" "this" {
  description             = "${var.name} data platform key"
  enable_key_rotation     = true # annual automatic rotation; old versions stay usable for decrypt
  deletion_window_in_days = var.kms_deletion_window_days
  policy                  = data.aws_iam_policy_document.kms.json
  tags                    = var.tags
}
resource "aws_kms_alias" "this" {
  name          = "alias/${var.name}"
  target_key_id = aws_kms_key.this.key_id
}

# ---- Least-privilege role for pipelines ----------------------------------
data "aws_iam_policy_document" "assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "AWS"
      identifiers = var.trusted_principal_arns
    }
  }
}
resource "aws_iam_role" "pipeline" {
  name                 = "${var.name}-pipeline"
  assume_role_policy   = data.aws_iam_policy_document.assume.json
  max_session_duration = 3600
  tags                 = var.tags
}

data "aws_iam_policy_document" "pipeline" {
  dynamic "statement" {
    for_each = length(var.read_zones) > 0 ? [1] : []
    content {
      sid       = "ReadObjects"
      actions   = ["s3:GetObject", "s3:GetObjectVersion"]
      resources = [for z in var.read_zones : "${var.bucket_arns[z]}/*"]
    }
  }
  dynamic "statement" {
    for_each = length(var.write_zones) > 0 ? [1] : []
    content {
      sid       = "WriteObjects"
      actions   = ["s3:PutObject", "s3:AbortMultipartUpload"] # note: no s3:DeleteObject
      resources = [for z in var.write_zones : "${var.bucket_arns[z]}/*"]
    }
  }
  statement {
    sid       = "ListBuckets"
    actions   = ["s3:ListBucket", "s3:GetBucketLocation"]
    resources = [for z in distinct(concat(var.read_zones, var.write_zones)) : var.bucket_arns[z]]
  }
  statement {
    sid       = "UseKey"
    actions   = ["kms:Decrypt", "kms:GenerateDataKey", "kms:DescribeKey"]
    resources = [aws_kms_key.this.arn]
  }
}
resource "aws_iam_role_policy" "pipeline" {
  name   = "lake-access"
  role   = aws_iam_role.pipeline.id
  policy = data.aws_iam_policy_document.pipeline.json
}

# ---- Secrets: generated, stored, and NEVER written to Terraform state ------
# `ephemeral` resources exist only during a plan/apply run. `secret_string_wo` is a
# WRITE-ONLY argument: sent to the API but not persisted in plan or state.
ephemeral "random_password" "warehouse" {
  length  = 32
  special = false
}
resource "aws_secretsmanager_secret" "warehouse" {
  name                    = "${var.name}/warehouse/postgres"
  kms_key_id              = aws_kms_key.this.arn
  recovery_window_in_days = var.secret_recovery_window_days
  tags                    = var.tags
}
resource "aws_secretsmanager_secret_version" "warehouse" {
  secret_id                = aws_secretsmanager_secret.warehouse.id
  secret_string_wo         = ephemeral.random_password.warehouse.result
  secret_string_wo_version = var.warehouse_secret_version
}
