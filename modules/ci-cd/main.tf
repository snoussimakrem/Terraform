locals {
  oidc_host = "token.actions.githubusercontent.com"
}

# The trust anchor: "AWS, believe tokens signed by GitHub". AWS validates GitHub's
# signing keys itself, so no thumbprint is required with current provider versions.
resource "aws_iam_openid_connect_provider" "github" {
  url            = "https://${local.oidc_host}"
  client_id_list = ["sts.amazonaws.com"]
  tags           = var.tags
}

# ---------- trust policies: WHO may assume ----------
data "aws_iam_policy_document" "trust_plan" {
  for_each = var.environments
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }
    condition {
      test     = "StringEquals"
      variable = "${local.oidc_host}:aud"
      values   = ["sts.amazonaws.com"]
    }
    condition { # plan runs on pull requests and on main (the pre-apply plan)
      test     = "StringLike"
      variable = "${local.oidc_host}:sub"
      values = [
        "repo:${var.github_repository}:pull_request",
        "repo:${var.github_repository}:ref:refs/heads/main",
      ]
    }
  }
}
data "aws_iam_policy_document" "trust_apply" {
  for_each = var.environments
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }
    condition {
      test     = "StringEquals"
      variable = "${local.oidc_host}:aud"
      values   = ["sts.amazonaws.com"]
    }
    condition { # ONLY a job bound to the GitHub *Environment* (which has required reviewers) can apply
      test     = "StringEquals"
      variable = "${local.oidc_host}:sub"
      values   = ["repo:${var.github_repository}:environment:${each.key}"]
    }
  }
}

# ---------- permission policies: WHAT they may do ----------
data "aws_iam_policy_document" "state_access" {
  for_each = var.environments
  statement {
    sid       = "ListStateBucket"
    actions   = ["s3:ListBucket"]
    resources = [var.state_bucket_arn]
    condition { # each env may only see its own prefix
      test     = "StringLike"
      variable = "s3:prefix"
      values   = ["${each.key}/*"]
    }
  }
  statement {
    sid       = "ReadWriteOwnStateAndLockFiles" # native S3 locking writes <key>.tflock
    actions   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
    resources = ["${var.state_bucket_arn}/${each.key}/*"]
  }
  dynamic "statement" {
    for_each = var.state_kms_key_arn == null ? [] : [1]
    content {
      sid       = "StateKey"
      actions   = ["kms:Decrypt", "kms:GenerateDataKey"]
      resources = [var.state_kms_key_arn]
    }
  }
}

resource "aws_iam_role" "plan" {
  for_each             = var.environments
  name                 = "${var.name_prefix}-gha-${each.key}-plan"
  assume_role_policy   = data.aws_iam_policy_document.trust_plan[each.key].json
  permissions_boundary = var.permissions_boundary_arn
  max_session_duration = 3600
  tags                 = var.tags
}
resource "aws_iam_role_policy_attachment" "plan_readonly" {
  for_each   = var.environments
  role       = aws_iam_role.plan[each.key].name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess" # plan only reads
}
resource "aws_iam_role_policy" "plan_state" {
  for_each = var.environments
  name     = "state"
  role     = aws_iam_role.plan[each.key].id
  policy   = data.aws_iam_policy_document.state_access[each.key].json
}

resource "aws_iam_role" "apply" {
  for_each             = var.environments
  name                 = "${var.name_prefix}-gha-${each.key}-apply"
  assume_role_policy   = data.aws_iam_policy_document.trust_apply[each.key].json
  permissions_boundary = var.permissions_boundary_arn
  max_session_duration = 3600
  tags                 = var.tags
}
resource "aws_iam_role_policy" "apply_state" {
  for_each = var.environments
  name     = "state"
  role     = aws_iam_role.apply[each.key].id
  policy   = data.aws_iam_policy_document.state_access[each.key].json
}
resource "aws_iam_role_policy_attachment" "apply_extra" {
  for_each = {
    for p in flatten([
      for env, arns in var.apply_policy_arns : [for a in arns : { key = "${env}|${a}", env = env, arn = a }]
    ]) : p.key => p if contains(var.environments, p.env)
  }
  role       = aws_iam_role.apply[each.value.env].name
  policy_arn = each.value.arn
}
