variable "chart_versions" {
  description = "Pinned chart versions. VERIFY with `helm search repo <chart> --versions` before first apply."
  type = object({
    cilium                = string
    cert_manager          = string
    traefik               = string
    kube_prometheus_stack = string
    loki                  = string
    alloy                 = string
  })
}
variable "namespace_quotas" {
  description = "namespace => {cpu, memory, pods} hard quota."
  type        = map(object({ cpu = string, memory = string, pods = string }))
  default     = {}
}
variable "enable_loki" {
  type    = bool
  default = true
}
variable "editor_groups" {
  description = "IdP groups allowed to edit workloads in app namespaces."
  type        = list(string)
  default     = []
}
variable "viewer_groups" {
  type    = list(string)
  default = []
}
