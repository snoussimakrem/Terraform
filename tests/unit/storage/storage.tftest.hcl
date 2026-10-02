mock_provider "aws" {}

variables {
  name_prefix = "dp-test"
  kms_key_arn = "arn:aws:kms:us-east-1:111111111111:key/abc"
}

run "three_default_zones" {
  command = plan
  assert {
    condition     = length(aws_s3_bucket.zone) == 3
    error_message = "raw/curated/analytics expected."
  }
}
run "every_bucket_blocks_public_access" {
  command = plan
  assert {
    condition     = alltrue([for p in aws_s3_bucket_public_access_block.zone : p.block_public_acls && p.restrict_public_buckets])
    error_message = "Public access must be blocked on every bucket."
  }
}
run "only_raw_gets_ia_transition" {
  command = plan
  assert {
    condition     = length(aws_s3_bucket_lifecycle_configuration.zone["raw"].rule) == 2 && length(aws_s3_bucket_lifecycle_configuration.zone["curated"].rule) == 1
    error_message = "Dynamic rule should only appear on raw."
  }
}
run "rejects_bad_zone_name" {
  command = plan
  variables {
    zones = ["Bad Zone"]
  }
  expect_failures = [var.zones]
}
