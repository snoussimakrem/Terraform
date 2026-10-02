variable "vpc_cidr" { type = string }
variable "azs" { type = list(string) }
variable "enable_nat" {
  description = "COST: ~$32/mo per NAT gateway on real AWS."
  type        = bool
  default     = false
}
variable "single_nat_gateway" {
  type    = bool
  default = true
}
variable "allowed_ingress_cidrs" {
  type    = list(string)
  default = []
}
