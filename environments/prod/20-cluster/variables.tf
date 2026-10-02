variable "cluster_mode" {
  description = "kind = free local cluster. eks = REAL AWS, ~$73/mo control plane + nodes. Plan-only unless you accept the cost."
  type        = string
  default     = "kind"
}
variable "kubernetes_version" { type = string }
variable "worker_count" {
  type    = number
  default = 2
}
variable "kubeconfig_path" {
  type    = string
  default = "~/.kube/config"
}
variable "node_groups" {
  type = map(object({
    instance_types = list(string)
    min_size       = number
    max_size       = number
    desired_size   = number
    capacity_type  = optional(string, "ON_DEMAND")
    labels         = optional(map(string), {})
  }))
  default = {}
}
variable "public_endpoint" {
  type    = bool
  default = false
}
variable "public_access_cidrs" {
  type    = list(string)
  default = []
}
