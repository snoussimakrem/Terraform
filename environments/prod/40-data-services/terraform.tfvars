environment    = "prod"
cluster_mode   = "eks"
state_bucket   = "REPLACE-WITH-STATE-BUCKET"
database_mode  = "rds"   # COST: RDS bills hourly; free tier is limited/time-boxed (verify)
kafka_replicas = 3
kafka_memory   = "4Gi"
tls_enabled    = true

chart_versions = {
  redpanda       = "5.9.13"
  spark_operator = "2.1.0"
  airflow        = "1.15.0"
}
