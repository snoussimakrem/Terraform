variable "github_repository" {
  description = "owner/repo allowed to assume the CI roles."
  type        = string
}
variable "state_bucket_name" {
  type    = string
  default = "tfstate-platform-local"
}
variable "state_kms_key_arn" {
  type    = string
  default = null
}
variable "apply_policy_arns" {
  description = "env => extra managed policies for the APPLY role. Start empty and add only what plans prove is needed."
  type        = map(list(string))
  default     = {}
}
