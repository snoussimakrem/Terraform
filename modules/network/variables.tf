variable "name" {
  description = "Name prefix for all resources."
  type        = string
}
variable "cidr_block" {
  description = "VPC CIDR. Subnets are carved from it with cidrsubnet()."
  type        = string
  validation {
    condition     = can(cidrhost(var.cidr_block, 0))
    error_message = "cidr_block must be a valid CIDR such as 10.0.0.0/16."
  }
}
variable "azs" {
  description = "Availability zones. One public + one private subnet is created per AZ."
  type        = list(string)
  validation {
    condition     = length(var.azs) >= 2 && length(var.azs) <= 8
    error_message = "Use 2-8 AZs (2 minimum for resilience; 8 is the room reserved per tier)."
  }
}
variable "subnet_newbits" {
  description = "Bits added to the VPC prefix per subnet (/16 + 4 = /20)."
  type        = number
  default     = 4
}
variable "enable_nat" {
  description = "COST WARNING: NAT gateways are billed hourly (~$32/mo each) on real AWS."
  type        = bool
  default     = false
}
variable "single_nat_gateway" {
  description = "true = one shared NAT (cheap, one-AZ risk). false = one per AZ (HA, N x cost)."
  type        = bool
  default     = true
}
variable "allowed_ingress_cidrs" {
  description = "CIDRs allowed to reach the 'web' security group on 80/443."
  type        = list(string)
  default     = []
}
variable "tags" {
  type    = map(string)
  default = {}
}
