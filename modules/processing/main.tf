resource "helm_release" "spark_operator" {
  name       = "spark-operator"
  namespace  = var.spark_namespace
  repository = "https://kubeflow.github.io/spark-operator"
  chart      = "spark-operator"
  version    = var.spark_operator_chart_version

  values = [yamlencode({
    spark = { jobNamespaces = var.spark_job_namespaces }
    controller = { replicas = 1 }
    webhook    = { enable = true }
  })]

  wait            = true
  wait_for_jobs   = true
  timeout         = var.timeout_seconds
  atomic          = true
  cleanup_on_fail = true
}

resource "helm_release" "airflow" {
  name       = "airflow"
  namespace  = var.airflow_namespace
  repository = "https://airflow.apache.org"
  chart      = "airflow"
  version    = var.airflow_chart_version

  values = [yamlencode({
    executor = "KubernetesExecutor" # one pod per task: no idle workers => cheaper locally
    postgresql = { enabled = true } # chart-embedded metadata DB; use managed DB in prod
    redis      = { enabled = false }
    createUserJob = { defaultUser = { username = "admin", role = "Admin", email = "admin@example.com" } }
  })]
  set_sensitive {
    name  = "createUserJob.defaultUser.password"
    value = var.airflow_admin_password
  }

  # Airflow's chart runs DB-migration Jobs. Without wait_for_jobs, Terraform reports success
  # while migrations are still running and the first login fails.
  wait            = true
  wait_for_jobs   = true
  timeout         = var.timeout_seconds
  atomic          = true
  cleanup_on_fail = true

  depends_on = [helm_release.spark_operator] # not data-dependent; ordered so DAGs can submit Spark on day one
}
