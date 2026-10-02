output "host" {
  value = var.mode == "k8s" ? "${var.name}.${var.namespace}.svc.cluster.local" : one(aws_db_instance.this[*].address)
}
output "port" { value = 5432 }
output "username" { value = var.username }
