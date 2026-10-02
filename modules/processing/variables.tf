variable "spark_namespace" { type = string }
variable "airflow_namespace" { type = string }
variable "spark_operator_chart_version" { type = string }
variable "airflow_chart_version" { type = string }
variable "spark_job_namespaces" {
  description = "Namespaces where SparkApplications may run."
  type        = list(string)
}
variable "airflow_admin_password" {
  description = <<-EOT
    Initial Airflow admin password. KNOWN LIMITATION: Helm values land in Terraform state
    (the helm provider has no write-only value support). Mitigations: encrypted+locked state,
    rotate after first login, or switch to external-secrets (docs/decisions/0007).
  EOT
  type        = string
  sensitive   = true
}
variable "timeout_seconds" {
  type    = number
  default = 1200
}
