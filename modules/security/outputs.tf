output "kms_key_arn" { value = aws_kms_key.this.arn }
output "kms_key_id" { value = aws_kms_key.this.key_id }
output "pipeline_role_arn" { value = aws_iam_role.pipeline.arn }
output "warehouse_secret_arn" { value = aws_secretsmanager_secret.warehouse.arn }
