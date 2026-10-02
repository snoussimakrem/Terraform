variable "namespace" { type = string }
variable "chart_version" {
  description = "Pinned Helm chart version. Required: no default, so upgrades are always deliberate."
  type        = string
}
variable "replicas" {
  description = "1 for dev. 3 for real fault tolerance (Raft quorum)."
  type        = number
  default     = 1
  validation {
    condition     = var.replicas % 2 == 1
    error_message = "Use an odd replica count (Raft quorum)."
  }
}
variable "storage_size" {
  type    = string
  default = "10Gi"
}
variable "memory" {
  description = "Container memory limit. Redpanda needs >= ~1.5Gi to be comfortable; adjust for your laptop."
  type        = string
  default     = "2Gi"
}
variable "tls_enabled" {
  description = "Encryption in transit between brokers/clients. Needs cert-manager issuer."
  type        = bool
  default     = true
}
variable "cluster_issuer" {
  type    = string
  default = "local-ca"
}
variable "timeout_seconds" {
  type    = number
  default = 900
}
