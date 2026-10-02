variable "name" { type = string }
variable "tags" {
  type    = map(string)
  default = {}
}
variable "kms_deletion_window_days" {
  type    = number
  default = 7
}
variable "bucket_arns" {
  description = "Map zone => bucket ARN (from the storage module)."
  type        = map(string)
}
variable "read_zones" {
  description = "Zones the pipeline role may read."
  type        = list(string)
  default     = ["raw", "curated", "analytics"]
  validation {
    condition     = alltrue([for z in var.read_zones : contains(keys(var.bucket_arns), z)])
    error_message = "read_zones must be keys of bucket_arns."
  }
}
variable "write_zones" {
  description = "Zones the pipeline role may write. Least privilege: no write to raw by default."
  type        = list(string)
  default     = ["curated", "analytics"]
  validation {
    condition     = alltrue([for z in var.write_zones : contains(keys(var.bucket_arns), z)])
    error_message = "write_zones must be keys of bucket_arns."
  }
}
variable "trusted_principal_arns" {
  description = "Who may assume the pipeline role. Must be explicit: no wildcard default."
  type        = list(string)
  validation {
    condition     = length(var.trusted_principal_arns) > 0
    error_message = "Provide at least one trusted principal."
  }
}
variable "secret_recovery_window_days" {
  description = "0 = delete immediately (dev only). 7-30 in real environments."
  type        = number
  default     = 7
}
variable "warehouse_secret_version" {
  description = "Bump this number to push a NEW random password (write-only args only resend when this changes)."
  type        = number
  default     = 1
}
