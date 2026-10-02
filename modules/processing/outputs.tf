output "airflow_release" { value = helm_release.airflow.name }
output "spark_operator_release" { value = helm_release.spark_operator.name }
