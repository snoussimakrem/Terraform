resource "aws_s3_bucket" "zone" {
  for_each      = var.zones
  bucket        = "${var.name_prefix}-${each.key}"
  force_destroy = var.force_destroy
  tags          = merge(var.tags, { Zone = each.key })

  lifecycle {
    postcondition {
      condition     = length(self.bucket) <= 63
      error_message = "Bucket name exceeds the 63-char S3 limit."
    }
  }
}

resource "aws_s3_bucket_versioning" "zone" {
  for_each = aws_s3_bucket.zone
  bucket   = each.value.id
  versioning_configuration { status = "Enabled" }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "zone" {
  for_each = aws_s3_bucket.zone
  bucket   = each.value.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = var.kms_key_arn
    }
    bucket_key_enabled = true # cuts KMS request cost dramatically
  }
}

resource "aws_s3_bucket_public_access_block" "zone" {
  for_each                = aws_s3_bucket.zone
  bucket                  = each.value.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "zone" {
  for_each   = aws_s3_bucket.zone
  bucket     = each.value.id
  depends_on = [aws_s3_bucket_versioning.zone] # lifecycle on versioned buckets needs versioning first

  rule {
    id     = "abort-multipart-and-expire-old-versions"
    status = "Enabled"
    filter {}
    abort_incomplete_multipart_upload { days_after_initiation = 7 }
    noncurrent_version_expiration { noncurrent_days = var.noncurrent_expire_days }
  }
  dynamic "rule" {
    for_each = each.key == "raw" ? [1] : []
    content {
      id     = "raw-to-infrequent-access"
      status = "Enabled"
      filter {}
      transition {
        days          = var.raw_ia_after_days
        storage_class = "STANDARD_IA"
      }
    }
  }
}

data "aws_iam_policy_document" "tls_only" {
  for_each = aws_s3_bucket.zone
  statement {
    sid       = "DenyInsecureTransport"
    effect    = "Deny"
    actions   = ["s3:*"]
    resources = [each.value.arn, "${each.value.arn}/*"]
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}
resource "aws_s3_bucket_policy" "tls_only" {
  for_each   = aws_s3_bucket.zone
  bucket     = each.value.id
  policy     = data.aws_iam_policy_document.tls_only[each.key].json
  depends_on = [aws_s3_bucket_public_access_block.zone] # avoid API races between policy + PAB
}
