variable "namespace" { type = string }
variable "chart_versions" {
  description = "Pinned versions. No defaults on purpose."
  type = object({
    kube_prometheus_stack = string
    loki                  = string
    alloy                 = string
  })
}
variable "retention" {
  type    = string
  default = "7d"
}
variable "prometheus_storage" {
  type    = string
  default = "10Gi"
}
variable "grafana_host" {
  description = "Hostname for the Grafana ingress. *.localtest.me resolves to 127.0.0.1."
  type        = string
  default     = "grafana.localtest.me"
}
variable "ingress_class" {
  type    = string
  default = "traefik"
}
variable "enable_loki" {
  type    = bool
  default = true
}
variable "timeout_seconds" {
  type    = number
  default = 900
}
