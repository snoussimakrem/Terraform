variable "database_mode" {
  description = "k8s (free) or rds (paid / limited free tier)."
  type        = string
  default     = "k8s"
}
variable "chart_versions" {
  description = "VERIFY each with `helm search repo <chart> --versions`."
  type = object({
    redpanda       = string
    spark_operator = string
    airflow        = string
  })
}
variable "kafka_replicas" {
  type    = number
  default = 1
}
variable "kafka_memory" {
  type    = string
  default = "2Gi"
}
variable "tls_enabled" {
  type    = bool
  default = true
}
variable "airflow_admin_password" {
  description = "Supply via TF_VAR_airflow_admin_password or a CI secret. NEVER in a .tfvars file."
  type        = string
  sensitive   = true
}
