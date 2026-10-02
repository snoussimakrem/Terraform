data "terraform_remote_state" "network" {
  backend = "s3"
  config  = merge(local.state_conn, { key = "${var.environment}/10-network.tfstate" })
}
data "terraform_remote_state" "lake" {
  backend = "s3"
  config  = merge(local.state_conn, { key = "${var.environment}/15-data-lake.tfstate" })
}
data "terraform_remote_state" "platform" {
  backend = "s3"
  config  = merge(local.state_conn, { key = "${var.environment}/30-platform.tfstate" })
}

locals {
  ns   = data.terraform_remote_state.platform.outputs.namespaces
  lake = data.terraform_remote_state.lake.outputs
  net  = data.terraform_remote_state.network.outputs
}

# EPHEMERAL: the secret is fetched during this run only. It never enters plan or state.
# It can only flow into ephemeral variables / write-only arguments (compiler-enforced).
ephemeral "aws_secretsmanager_secret_version" "warehouse" {
  secret_id = local.lake.warehouse_secret_arn
}

module "database" {
  source = "../../../modules/database"

  name      = "warehouse"
  mode      = var.database_mode
  namespace = local.ns["data"]
  password  = ephemeral.aws_secretsmanager_secret_version.warehouse.secret_string
  tags      = local.tags

  # rds mode only
  subnet_ids         = local.net.private_subnet_ids
  security_group_ids = [local.net.security_group_ids["internal"]]
  kms_key_arn        = local.lake.kms_key_arn
  deletion_protection = var.environment == "prod"
  multi_az           = var.environment == "prod"
}

module "streaming" {
  source = "../../../modules/streaming"

  namespace     = local.ns["streaming"]
  chart_version = var.chart_versions.redpanda
  replicas      = var.kafka_replicas
  memory        = var.kafka_memory
  tls_enabled   = var.tls_enabled
}

module "processing" {
  source = "../../../modules/processing"

  spark_namespace              = local.ns["data"]
  airflow_namespace            = local.ns["orchestration"]
  spark_job_namespaces         = [local.ns["data"]]
  spark_operator_chart_version = var.chart_versions.spark_operator
  airflow_chart_version        = var.chart_versions.airflow
  airflow_admin_password       = var.airflow_admin_password
}
