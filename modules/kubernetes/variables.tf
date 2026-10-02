variable "namespaces" {
  description = "Namespace baseline: quotas, isolation (default-deny NetworkPolicy), RBAC."
  type = map(object({
    labels                = optional(map(string), {})
    pod_security          = optional(string, "baseline") # privileged | baseline | restricted
    isolate               = optional(bool, false)        # default-deny ingress+egress
    peers                 = optional(list(string), [])   # namespaces allowed both directions
    allow_external_egress = optional(bool, false)        # internet / object storage
    quota                 = optional(object({ cpu = string, memory = string, pods = string }))
    viewers               = optional(list(string), [])   # IdP groups -> ClusterRole view
    editors               = optional(list(string), [])   # IdP groups -> ClusterRole edit
  }))
  validation {
    condition     = alltrue([for k, v in var.namespaces : contains(["privileged", "baseline", "restricted"], v.pod_security)])
    error_message = "pod_security must be privileged, baseline or restricted."
  }
}
variable "monitoring_namespace" {
  description = "Namespace allowed to scrape isolated namespaces."
  type        = string
  default     = "monitoring"
}
