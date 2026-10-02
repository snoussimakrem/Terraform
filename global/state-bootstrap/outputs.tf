output "state_bucket" { value = aws_s3_bucket.state.bucket }
output "state_bucket_arn" { value = aws_s3_bucket.state.arn }
output "state_kms_key_arn" { value = aws_kms_key.state.arn }
output "backend_hcl_snippet" {
  value = <<-EOT
    bucket       = "${aws_s3_bucket.state.bucket}"
    region       = "${var.region}"
    encrypt      = true
    use_lockfile = true
    kms_key_id   = "${aws_kms_alias.state.name}"
  EOT
}
