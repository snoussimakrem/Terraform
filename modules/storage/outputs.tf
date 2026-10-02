output "bucket_arns" { value = { for z, b in aws_s3_bucket.zone : z => b.arn } }
output "bucket_names" { value = { for z, b in aws_s3_bucket.zone : z => b.bucket } }
