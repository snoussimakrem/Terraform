output "warehouse_host" { value = module.database.host }
output "kafka_bootstrap_servers" { value = module.streaming.bootstrap_servers }
