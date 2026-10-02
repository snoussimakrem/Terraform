output "zone_id" { value = one(aws_route53_zone.this[*].zone_id) }
output "name_servers" { value = one(aws_route53_zone.this[*].name_servers) }
