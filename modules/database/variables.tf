variable "name" { type = string }
variable "mode" {
  description = "k8s = Postgres StatefulSet in the cluster ($0). rds = Amazon RDS (free tier is limited/time-boxed: verify; otherwise COSTS MONEY)."
  type        = string
  default     = "k8s"
  validation {
    condition     = contains(["k8s", "rds"], var.mode)
    error_message = "mode must be k8s or rds."
  }
}
variable "username" {
  type    = string
  default = "warehouse"
}
variable "password" {
  description = "EPHEMERAL: exists only during the run, never stored in state."
  type        = string
  ephemeral   = true
  sensitive   = true
}
variable "password_version" {
  description = "Bump to re-send the password to write-only arguments."
  type        = number
  default     = 1
}
variable "tags" {
  type    = map(string)
  default = {}
}
# k8s mode
variable "namespace" {
  type    = string
  default = "data"
}
variable "storage_size" {
  type    = string
  default = "5Gi"
}
variable "postgres_image" {
  description = "Pin by tag (better: by digest) so rebuilds are reproducible."
  type        = string
  default     = "postgres:16.4-alpine"
}
# rds mode
variable "subnet_ids" {
  type    = list(string)
  default = []
}
variable "security_group_ids" {
  type    = list(string)
  default = []
}
variable "kms_key_arn" {
  type    = string
  default = null
}
variable "multi_az" {
  type    = bool
  default = false
}
variable "deletion_protection" {
  type    = bool
  default = true
}
variable "instance_class" {
  type    = string
  default = "db.t4g.micro"
}
