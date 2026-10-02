environment   = "dev"
cluster_mode  = "kind"
state_bucket  = "tfstate-platform-local"
database_mode = "k8s"
kafka_replicas = 1
kafka_memory   = "1536Mi"  # fits an 8GB Docker allocation; raise if you have more
tls_enabled    = true

# VERIFY with `helm search repo <chart> --versions`
chart_versions = {
  redpanda       = "5.9.13"
  spark_operator = "2.1.0"
  airflow        = "1.15.0"
}
# airflow_admin_password: export TF_VAR_airflow_admin_password=... (never put it here)
