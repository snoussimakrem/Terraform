resource "aws_route53_zone" "this" {
  count   = var.create_zone ? 1 : 0
  name    = var.domain_name
  comment = "Managed by Terraform (global/dns)"
}
# Locally we use *.localtest.me, which resolves to 127.0.0.1 with no zone needed.
