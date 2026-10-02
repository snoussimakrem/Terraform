output "vpc_id" { value = aws_vpc.this.id }
output "vpc_cidr_block" { value = aws_vpc.this.cidr_block }
output "public_subnet_ids" {
  description = "Ordered like var.azs."
  value       = [for az in var.azs : aws_subnet.public[az].id]
}
output "private_subnet_ids" {
  value = [for az in var.azs : aws_subnet.private[az].id]
}
output "security_group_ids" {
  value = { web = aws_security_group.web.id, internal = aws_security_group.internal.id }
}
output "nat_gateway_ids" { value = [for k in sort(keys(aws_nat_gateway.this)) : aws_nat_gateway.this[k].id] }
