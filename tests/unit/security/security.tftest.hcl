mock_provider "aws" {}
mock_provider "random" {}

variables {
  name                   = "dp-test"
  bucket_arns            = { raw = "arn:aws:s3:::r", curated = "arn:aws:s3:::c", analytics = "arn:aws:s3:::a" }
  trusted_principal_arns = ["arn:aws:iam::111111111111:root"]
}

run "key_rotation_enabled" {
  command = plan
  assert {
    condition     = aws_kms_key.this.enable_key_rotation
    error_message = "KMS rotation must be on."
  }
}
run "rejects_unknown_zone" {
  command = plan
  variables {
    write_zones = ["does-not-exist"]
  }
  expect_failures = [var.write_zones]
}
run "rejects_empty_trust" {
  command = plan
  variables {
    trusted_principal_arns = []
  }
  expect_failures = [var.trusted_principal_arns]
}
