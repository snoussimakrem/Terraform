output "plan_role_arns" { value = { for e, r in aws_iam_role.plan : e => r.arn } }
output "apply_role_arns" { value = { for e, r in aws_iam_role.apply : e => r.arn } }
output "oidc_provider_arn" { value = aws_iam_openid_connect_provider.github.arn }
