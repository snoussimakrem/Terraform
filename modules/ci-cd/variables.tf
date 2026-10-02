variable "name_prefix" { type = string }
variable "github_repository" {
  description = "owner/repo that may assume these roles. Anything else is rejected by the trust policy."
  type        = string
  validation {
    condition     = can(regex("^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$", var.github_repository))
    error_message = "Use the form owner/repo."
  }
}
variable "environments" {
  description = "One plan role + one apply role is created per environment."
  type        = set(string)
  default     = ["dev", "staging", "prod"]
}
variable "state_bucket_arn" { type = string }
variable "state_kms_key_arn" {
  type    = string
  default = null
}
variable "apply_policy_arns" {
  description = "env => managed policy ARNs for the APPLY role (what Terraform may create). Keep narrow; this is where least privilege is won or lost."
  type        = map(list(string))
  default     = {}
}
variable "permissions_boundary_arn" {
  description = "Hard ceiling on what these roles can ever do, even if someone attaches AdministratorAccess later."
  type        = string
  default     = null
}
variable "tags" {
  type    = map(string)
  default = {}
}
