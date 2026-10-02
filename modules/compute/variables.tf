variable "mode" {
  description = "kind = local Docker cluster ($0). eks = real AWS (control plane ~$73/mo + nodes: COSTS MONEY)."
  type        = string
  default     = "kind"
  validation {
    condition     = contains(["kind", "eks"], var.mode)
    error_message = "mode must be 'kind' or 'eks'."
  }
}
variable "cluster_name" { type = string }
variable "kubernetes_version" {
  description = "kind: node image tag like v1.31.4. eks: minor like 1.31."
  type        = string
}
variable "tags" {
  type    = map(string)
  default = {}
}

# --- kind ---
variable "worker_count" {
  type    = number
  default = 2
}
variable "http_host_port" {
  type    = number
  default = 80
}
variable "https_host_port" {
  type    = number
  default = 443
}
variable "kubeconfig_path" {
  type    = string
  default = "~/.kube/config"
}

# --- eks ---
variable "subnet_ids" {
  description = "Private subnet IDs (eks mode)."
  type        = list(string)
  default     = []
}
variable "kms_key_arn" {
  description = "Encrypts Kubernetes Secrets in etcd (eks mode)."
  type        = string
  default     = null
}
variable "public_endpoint" {
  description = "Expose the API publicly? Default false; if true restrict public_access_cidrs."
  type        = bool
  default     = false
}
variable "public_access_cidrs" {
  type    = list(string)
  default = []
}
variable "node_groups" {
  description = "Managed node groups (eks mode). for_each over this map => add a pool = add a map entry."
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
