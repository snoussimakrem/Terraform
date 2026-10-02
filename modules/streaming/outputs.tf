output "bootstrap_servers" {
  value = "redpanda.${var.namespace}.svc.cluster.local:9093"
}
