output "kms_key_arn" { value = module.security.kms_key_arn }
output "bucket_arns" { value = module.storage.bucket_arns }
output "bucket_names" { value = module.storage.bucket_names }
output "pipeline_role_arn" { value = module.security.pipeline_role_arn }
output "warehouse_secret_arn" { value = module.security.warehouse_secret_arn }
