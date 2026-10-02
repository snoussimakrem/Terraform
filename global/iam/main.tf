# Permission BOUNDARY = a ceiling. Even if someone later attaches AdministratorAccess to a CI role,
# the effective permissions are the INTERSECTION of the role policy and this boundary.
data "aws_iam_policy_document" "boundary" {
  statement {
    sid    = "AllowPlatformServices"
    effect = "Allow"
    actions = [
      "ec2:*", "s3:*", "kms:*", "secretsmanager:*", "eks:*", "route53:*", "logs:*",
      "ssm:*", "elasticloadbalancing:*", "autoscaling:*", "rds:*", "sts:*",
      "iam:Get*", "iam:List*", "iam:CreateRole", "iam:DeleteRole", "iam:PutRolePolicy",
      "iam:DeleteRolePolicy", "iam:AttachRolePolicy", "iam:DetachRolePolicy", "iam:TagRole",
      "iam:UntagRole", "iam:PassRole", "iam:UpdateAssumeRolePolicy", "iam:CreateServiceLinkedRole",
      "iam:CreateOpenIDConnectProvider", "iam:DeleteOpenIDConnectProvider", "iam:TagOpenIDConnectProvider",
    ]
    resources = ["*"]
  }
  statement {
    sid       = "DenyDangerous"
    effect    = "Deny"
    actions   = ["iam:CreateUser", "iam:CreateAccessKey", "iam:CreateLoginProfile", "organizations:*", "account:*"]
    resources = ["*"]
  }
}
resource "aws_iam_policy" "boundary" {
  name   = "dp-ci-permissions-boundary"
  policy = data.aws_iam_policy_document.boundary.json
}

module "ci_cd" {
  source = "../../modules/ci-cd"

  name_prefix              = "dp"
  github_repository        = var.github_repository
  state_bucket_arn         = "arn:aws:s3:::${var.state_bucket_name}"
  state_kms_key_arn        = var.state_kms_key_arn
  apply_policy_arns        = var.apply_policy_arns
  permissions_boundary_arn = aws_iam_policy.boundary.arn
}
