variable "name_prefix" {
  description = "Bucket name prefix. S3 names are GLOBAL: include account/env to avoid collisions."
  type        = string
}
variable "zones" {
  description = "Data-lake zones (medallion-style): raw -> curated -> analytics."
  type        = set(string)
  default     = ["raw", "curated", "analytics"]
  validation {
    condition     = alltrue([for z in var.zones : can(regex("^[a-z][a-z0-9-]{1,20}$", z))])
    error_message = "Zone names must be lowercase letters/digits/hyphens."
  }
}
variable "kms_key_arn" { type = string }
variable "force_destroy" {
  description = "true deletes non-empty buckets on destroy. dev only!"
  type        = bool
  default     = false
}
variable "raw_ia_after_days" {
  type    = number
  default = 30
}
variable "noncurrent_expire_days" {
  type    = number
  default = 90
}
variable "tags" {
  type    = map(string)
  default = {}
}
