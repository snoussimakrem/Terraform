output "grafana_url" { value = "http://${var.grafana_host}" }
output "loki_url" { value = local.loki_url }
